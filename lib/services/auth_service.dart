import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'encryption_service.dart';

/// Service for handling authentication (biometrics + PIN)
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  final _encryptionService = EncryptionService();

  bool _isAuthenticated = false;
  DateTime? _lastActivityTime;

  /// Check if user is currently authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Check if session has timed out
  bool get hasSessionTimedOut {
    if (_lastActivityTime == null) return true;
    final elapsed = DateTime.now().difference(_lastActivityTime!);
    return elapsed > AppConstants.sessionTimeout;
  }

  /// Initialize auth service
  Future<void> initialize() async {
    await _encryptionService.initialize();
  }

  /// Check if biometric authentication is available on device
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      return canCheck && await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric auth is enabled by user
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.storageKeyBiometricEnabled) ?? false;
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.storageKeyBiometricEnabled, enabled);
  }

  /// Check if PIN is set up
  Future<bool> isPinSetup() async {
    final pinHash = await _secureStorage.read(
      key: AppConstants.storageKeyPinHash,
    );
    return pinHash != null;
  }

  /// Set up PIN for first time
  Future<void> setupPin(String pin) async {
    if (pin.length != AppConstants.pinLength) {
      throw AuthException('PIN must be ${AppConstants.pinLength} digits');
    }

    final pinHash = await _encryptionService.hashPin(pin);
    await _secureStorage.write(
      key: AppConstants.storageKeyPinHash,
      value: pinHash,
    );

    // Reset failed attempts
    await _resetFailedAttempts();
  }

  /// Authenticate with PIN
  Future<bool> authenticateWithPin(String pin) async {
    // Check if locked out
    if (await _isLockedOut()) {
      final remainingTime = await _getRemainingLockoutTime();
      throw LockoutException(
        'Too many failed attempts. Try again in ${remainingTime.inMinutes} minutes.',
      );
    }

    final storedHash = await _secureStorage.read(
      key: AppConstants.storageKeyPinHash,
    );

    if (storedHash == null) {
      throw AuthException('PIN not set up');
    }

    final isValid = await _encryptionService.verifyPin(pin, storedHash);

    if (isValid) {
      await _resetFailedAttempts();
      await _markAuthenticated();
      return true;
    } else {
      await _incrementFailedAttempts();
      return false;
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      final biometricsEnabled = await isBiometricEnabled();
      if (!biometricsEnabled) {
        throw AuthException('Biometric authentication not enabled');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason ?? AppStrings.biometricPrompt,
        // Core modern parameters:
        biometricOnly: true,                    // Force biometrics only (no PIN fallback)
        persistAcrossBackgrounding: true,       // ≈ old stickyAuth: true
        // authTimeout: Duration(minutes: 1),   // optional - uncomment if needed
        // useErrorDialogs is gone - system handles it now
      );

      if (authenticated) {
        await _markAuthenticated();
      }

      return authenticated;
    } catch (e) {
      // You can now catch more specific LocalAuthException if desired
      throw AuthException('Biometric authentication failed: $e');
    }
  }

  /// Authenticate with biometrics or fallback to PIN
  Future<bool> authenticate({String? reason}) async {
    try {
      // Try biometrics first if enabled
      if (await isBiometricEnabled()) {
        return await authenticateWithBiometrics(reason: reason);
      }
    } catch (e) {
      // Fall through to PIN authentication
    }

    // If biometrics fail or not enabled, use PIN
    // (UI will need to show PIN prompt)
    return false;
  }

  /// Mark user as authenticated
  Future<void> _markAuthenticated() async {
    _isAuthenticated = true;
    _lastActivityTime = DateTime.now();
  }

  /// Update last activity time (call on user interaction)
  void updateActivity() {
    if (_isAuthenticated) {
      _lastActivityTime = DateTime.now();
    }
  }

  /// Lock the app (require re-authentication)
  Future<void> lock() async {
    _isAuthenticated = false;
    _lastActivityTime = null;
  }

  /// Logout (clear session)
  Future<void> logout() async {
    await lock();
    await _encryptionService.clearKeys();
  }

  /// Change PIN
  Future<void> changePin(String oldPin, String newPin) async {
    // Verify old PIN first
    final isValid = await authenticateWithPin(oldPin);
    if (!isValid) {
      throw AuthException('Invalid current PIN');
    }

    // Set new PIN
    await setupPin(newPin);
  }

  /// Get number of failed attempts
  Future<int> _getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.storageKeyFailedAttempts) ?? 0;
  }

  /// Increment failed login attempts
  Future<void> _incrementFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = await _getFailedAttempts();
    final newAttempts = attempts + 1;

    await prefs.setInt(AppConstants.storageKeyFailedAttempts, newAttempts);

    if (newAttempts >= AppConstants.maxFailedAttempts) {
      await prefs.setInt(
        AppConstants.storageKeyLastFailedTime,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  /// Reset failed attempts counter
  Future<void> _resetFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.storageKeyFailedAttempts);
    await prefs.remove(AppConstants.storageKeyLastFailedTime);
  }

  /// Check if account is locked out
  Future<bool> _isLockedOut() async {
    final attempts = await _getFailedAttempts();
    if (attempts < AppConstants.maxFailedAttempts) {
      return false;
    }

    final lockoutTime = await _getRemainingLockoutTime();
    return lockoutTime.inSeconds > 0;
  }

  /// Get remaining lockout time
  Future<Duration> _getRemainingLockoutTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFailedTimestamp = prefs.getInt(
      AppConstants.storageKeyLastFailedTime,
    );

    if (lastFailedTimestamp == null) {
      return Duration.zero;
    }

    final lastFailedTime = DateTime.fromMillisecondsSinceEpoch(lastFailedTimestamp);
    final attempts = await _getFailedAttempts();

    // Escalating lockout duration
    final lockoutIndex = (attempts ~/ AppConstants.maxFailedAttempts) - 1;
    final lockoutMinutes = lockoutIndex < AppConstants.lockoutDurations.length
        ? AppConstants.lockoutDurations[lockoutIndex]
        : AppConstants.lockoutDurations.last;

    final lockoutDuration = Duration(minutes: lockoutMinutes);
    final unlockTime = lastFailedTime.add(lockoutDuration);
    final remaining = unlockTime.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.storageKeyOnboardingComplete) ?? false;
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.storageKeyOnboardingComplete, true);
  }

  /// Reset app (clear all auth data) - USE WITH CAUTION
  Future<void> resetApp() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await logout();
  }
}

/// Authentication exception
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Lockout exception (too many failed attempts)
class LockoutException implements Exception {
  final String message;
  LockoutException(this.message);

  @override
  String toString() => 'LockoutException: $message';
}