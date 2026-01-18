import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../home/home_screen.dart';

/// Screen for initial PIN setup
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _authService = AuthService();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isPinEntered = false;
  bool _isLoading = false;
  bool _enableBiometrics = false;
  bool _biometricAvailable = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _authService.canAuthenticateWithBiometrics();
    setState(() {
      _biometricAvailable = available;
      _enableBiometrics = available;
    });
  }

  Future<void> _setupPin() async {
    if (!_isPinEntered) {
      // First PIN entry
      if (_pinController.text.length != AppConstants.pinLength) {
        setState(() {
          _errorMessage = 'PIN must be ${AppConstants.pinLength} digits';
        });
        return;
      }

      setState(() {
        _isPinEntered = true;
        _errorMessage = null;
      });
      return;
    }

    // Confirm PIN
    if (_pinController.text != _confirmPinController.text) {
      setState(() {
        _errorMessage = AppStrings.pinMismatch;
        _confirmPinController.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Setup PIN
      await _authService.setupPin(_pinController.text);

      // Enable biometrics if user wants
      if (_enableBiometrics && _biometricAvailable) {
        await _authService.setBiometricEnabled(true);
        if (mounted) {
          context.read<AuthProvider>().setBiometricEnabled(true);
        }
      }

      // Mark onboarding as complete
      await _authService.completeOnboarding();

      // Mark as authenticated
      if (mounted) {
        context.read<AuthProvider>().setAuthenticated(true);
      }

      // Navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to setup PIN: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goBack() {
    if (_isPinEntered) {
      setState(() {
        _isPinEntered = false;
        _confirmPinController.clear();
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Security'),
        leading: _isPinEntered
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lock Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 50,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                _isPinEntered ? AppStrings.confirmPin : AppStrings.setupPin,
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                _isPinEntered
                    ? 'Re-enter your PIN to confirm'
                    : 'Choose a ${AppConstants.pinLength}-digit PIN to protect your documents',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // PIN Input
              if (!_isPinEntered) ...[
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: AppConstants.pinLength,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '● ● ● ● ● ●',
                    errorText: _errorMessage,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _setupPin(),
                ),
              ] else ...[
                TextField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: AppConstants.pinLength,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '● ● ● ● ● ●',
                    errorText: _errorMessage,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _setupPin(),
                ),
              ],
              const SizedBox(height: 32),

              // Biometric option (only on first screen)
              if (!_isPinEntered && _biometricAvailable) ...[
                SwitchListTile(
                  title: const Text('Enable Biometric Authentication'),
                  subtitle: const Text('Use fingerprint or Face ID'),
                  value: _enableBiometrics,
                  onChanged: (value) {
                    setState(() {
                      _enableBiometrics = value;
                    });
                  },
                  secondary: const Icon(Icons.fingerprint),
                ),
                const SizedBox(height: 24),
              ],

              // Continue Button
              ElevatedButton(
                onPressed: _isLoading ? null : _setupPin,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
                    : Text(_isPinEntered ? 'Complete Setup' : 'Continue'),
              ),

              const SizedBox(height: 24),

              // Security info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.infoColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your PIN is encrypted and stored securely. '
                            'Never share it with anyone.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}