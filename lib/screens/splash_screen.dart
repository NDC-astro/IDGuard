import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../providers/document_provider.dart';
// import '../providers/auth_provider.dart';
import 'onboarding/onboarding_screen.dart';
import 'auth/auth_screen.dart';
import 'home/home_screen.dart';

/// Splash screen shown at app launch
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.longAnimation,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize services
      await _authService.initialize();

      // Initialize providers
      await context.read<DocumentProvider>().initialize();

      // Check biometric availability
      final biometricAvailable = await _authService.canAuthenticateWithBiometrics();
      final biometricEnabled = await _authService.isBiometricEnabled();

      if (mounted) {
        context.read<AuthProvider>().setBiometricAvailable(biometricAvailable);
        context.read<AuthProvider>().setBiometricEnabled(biometricEnabled);
      }

      // Wait for animation
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate based on app state
      final onboardingComplete = await _authService.isOnboardingComplete();

      if (!onboardingComplete) {
        _navigateToOnboarding();
      } else {
        _navigateToAuth();
      }
    } catch (e) {
      // Show error and retry
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text('Failed to initialize app: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 60,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Name
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    AppConstants.appTagline,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Loading Indicator
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}