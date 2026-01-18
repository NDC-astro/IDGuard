import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../services/auth_service.dart';
import '../../auth/pin_setup_screen.dart';

/// Onboarding screen with intro slides
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Secure Storage',
      description: 'Your documents are encrypted with military-grade AES-256 encryption. Only you can access them.',
      icon: Icons.lock_outline,
      color: AppColors.primaryColor,
    ),
    OnboardingPage(
      title: 'Complete Privacy',
      description: 'Everything stays on your device. No cloud storage, no tracking, 100% offline.',
      icon: Icons.shield_outlined,
      color: AppColors.accentColor,
    ),
    OnboardingPage(
      title: 'Biometric Protection',
      description: 'Use Face ID, fingerprint, or a secure PIN to protect your digital identity.',
      icon: Icons.fingerprint,
      color: AppColors.successColor,
    ),
    OnboardingPage(
      title: 'Legal Disclaimer',
      description: AppStrings.legalDisclaimer,
      icon: Icons.gavel,
      color: AppColors.warningColor,
      isLegal: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: AppConstants.mediumAnimation,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishOnboarding() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: const Text('Skip'),
                ),
              ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                    (index) => _buildIndicator(index == _currentPage),
              ),
            ),
            const SizedBox(height: 32),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: AppTextStyles.h1.copyWith(
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Legal agreement checkbox
          if (page.isLegal) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warningColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warningColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By continuing, you acknowledge this disclaimer.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: AppConstants.shortAnimation,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Model for onboarding page
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isLegal;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isLegal = false,
  });
}