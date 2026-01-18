import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../home/home_screen.dart';
import 'pin_setup_screen.dart';

/// Authentication screen for app unlock
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _tryBiometricAuth();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricAuth() async {
    try {
      if (await _authService.isBiometricEnabled()) {
        final authenticated = await _authService.authenticateWithBiometrics();
        if (authenticated && mounted) {
          _onAuthSuccess();
        }
      }
    } catch (e) {
      // Biometric failed, show PIN input
    }
  }

  Future<void> _authenticateWithPin() async {
    if (_pinController.text.length != AppConstants.pinLength) {
      setState(() {
        _errorMessage = 'Please enter ${AppConstants.pinLength} digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await _authService.authenticateWithPin(
        _pinController.text,
      );

      if (authenticated) {
        _onAuthSuccess();
      } else {
        setState(() {
          _failedAttempts++;
          _errorMessage = 'Invalid PIN';
          _pinController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onAuthSuccess() {
    context.read<AuthProvider>().setAuthenticated(true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  AppStrings.authRequired,
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  AppStrings.enterPin,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),

                // PIN Input
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
                  onSubmitted: (_) => _authenticateWithPin(),
                ),
                const SizedBox(height: 24),

                // Unlock Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _authenticateWithPin,
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
                        : const Text('Unlock'),
                  ),
                ),
                const SizedBox(height: 16),

                // Biometric Button
                if (context.watch<AuthProvider>().isBiometricEnabled)
                  OutlinedButton.icon(
                    onPressed: _tryBiometricAuth,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use Biometrics'),
                  ),

                // Failed attempts warning
                if (_failedAttempts >= 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: AppColors.warningColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Warning: ${AppConstants.maxFailedAttempts - _failedAttempts} attempts remaining',
                              style: const TextStyle(
                                color: AppColors.warningColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}