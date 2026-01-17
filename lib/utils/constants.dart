import 'package:flutter/material.dart';

/// Application-wide constants and configuration
class AppConstants {
  // App Information
  static const String appName = 'IDGuard';
  static const String appTagline = 'Your Secure Digital ID Wallet';
  static const String appVersion = '1.0.0';

  // Security Configuration
  static const int pinLength = 6;
  static const int maxFailedAttempts = 5;
  static const Duration sessionTimeout = Duration(minutes: 5);
  static const Duration lockoutDuration = Duration(minutes: 1);

  // Lockout escalation (in minutes)
  static const List<int> lockoutDurations = [1, 5, 15, 60];

  // Encryption
  static const int encryptionKeyLength = 32; // 256 bits
  static const int pbkdf2Iterations = 10000;
  static const String encryptionAlgorithm = 'AES-256-GCM';

  // Storage Keys
  static const String storageKeyDocuments = 'encrypted_documents';
  static const String storageKeyMasterKey = 'master_encryption_key';
  static const String storageKeyPinHash = 'pin_hash';
  static const String storageKeyBiometricEnabled = 'biometric_enabled';
  static const String storageKeyFailedAttempts = 'failed_attempts';
  static const String storageKeyLastFailedTime = 'last_failed_time';
  static const String storageKeyOnboardingComplete = 'onboarding_complete';
  static const String storageKeyThemeMode = 'theme_mode';

  // Notifications
  static const int expiryWarningDays = 30;
  static const String notificationChannelId = 'idguard_expiry';
  static const String notificationChannelName = 'Document Expiry Alerts';

  // Image Processing
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int imageQuality = 90;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

/// Color scheme for the application
class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF1a237e); // Indigo 900
  static const Color primaryLight = Color(0xFF534bae);
  static const Color primaryDark = Color(0xFF000051);

  // Accent Colors
  static const Color accentColor = Color(0xFF00bcd4); // Cyan
  static const Color accentLight = Color(0xFF62efff);
  static const Color accentDark = Color(0xFF008ba3);

  // Status Colors
  static const Color successColor = Color(0xFF4caf50);
  static const Color warningColor = Color(0xFFff9800);
  static const Color errorColor = Color(0xFFf44336);
  static const Color infoColor = Color(0xFF2196f3);

  // Neutral Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  // Security Indicators
  static const Color secureGreen = Color(0xFF4caf50);
  static const Color warningOrange = Color(0xFFff9800);
  static const Color dangerRed = Color(0xFFf44336);
}

/// Text styles for consistent typography
class AppTextStyles {
  static const String fontFamily = 'Roboto';

  // Headlines
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.75,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );
}

/// Document type icons and metadata
class DocumentTypeConfig {
  static const Map<String, IconData> icons = {
    'national_id': Icons.badge,
    'passport': Icons.airplanemode_active,
    'drivers_license': Icons.drive_eta,
    'residence_permit': Icons.home,
    'health_insurance': Icons.medical_services,
    'student_id': Icons.school,
    'employee_badge': Icons.work,
    'other': Icons.description,
  };

  static const Map<String, Color> colors = {
    'national_id': Color(0xFF1976d2),
    'passport': Color(0xFF388e3c),
    'drivers_license': Color(0xFFf57c00),
    'residence_permit': Color(0xFF7b1fa2),
    'health_insurance': Color(0xFFd32f2f),
    'student_id': Color(0xFF0097a7),
    'employee_badge': Color(0xFF5d4037),
    'other': Color(0xFF616161),
  };

  static const Map<String, String> labels = {
    'national_id': 'National ID Card',
    'passport': 'Passport',
    'drivers_license': 'Driver\'s License',
    'residence_permit': 'Residence Permit',
    'health_insurance': 'Health Insurance Card',
    'student_id': 'Student ID',
    'employee_badge': 'Employee Badge',
    'other': 'Other Document',
  };
}

/// Error messages and user-facing text
class AppStrings {
  // Authentication
  static const String authRequired = 'Authentication Required';
  static const String biometricPrompt = 'Verify your identity to access documents';
  static const String enterPin = 'Enter your PIN';
  static const String setupPin = 'Create a secure PIN';
  static const String confirmPin = 'Confirm your PIN';
  static const String pinMismatch = 'PINs do not match';
  static const String invalidPin = 'Invalid PIN';
  static const String tooManyAttempts = 'Too many failed attempts. Please try again later.';

  // Documents
  static const String noDocuments = 'No documents yet';
  static const String addFirstDocument = 'Add your first document to get started';
  static const String scanDocument = 'Scan Document';
  static const String importDocument = 'Import from Gallery';
  static const String documentAdded = 'Document added successfully';
  static const String documentDeleted = 'Document deleted';
  static const String documentUpdated = 'Document updated';

  // Expiry
  static const String expiresIn = 'Expires in';
  static const String expired = 'Expired';
  static const String expiryWarning = 'Document expiring soon!';

  // Security
  static const String encryptionEnabled = 'All data is encrypted';
  static const String biometricEnabled = 'Biometric authentication enabled';
  static const String secureStorage = 'Stored securely on device only';

  // Settings
  static const String settings = 'Settings';
  static const String security = 'Security';
  static const String privacy = 'Privacy';
  static const String about = 'About';
  static const String exportBackup = 'Export Encrypted Backup';
  static const String importBackup = 'Import Backup';

  // Legal
  static const String legalDisclaimer =
      'LEGAL DISCLAIMER: This app does NOT replace official physical documents. '
      'Always carry original documents when required by law. Digital copies may '
      'not be legally accepted for official identification.';

  // Errors
  static const String errorGeneric = 'An error occurred';
  static const String errorCamera = 'Camera access denied';
  static const String errorStorage = 'Storage access denied';
  static const String errorBiometric = 'Biometric authentication failed';
  static const String errorEncryption = 'Encryption error';
  static const String errorNetwork = 'Network error';
}

/// Asset paths
class AppAssets {
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  static const String animationsPath = 'assets/animations/';

  // Onboarding
  static const String onboarding1 = '${imagesPath}onboarding_1.png';
  static const String onboarding2 = '${imagesPath}onboarding_2.png';
  static const String onboarding3 = '${imagesPath}onboarding_3.png';

  // Placeholders
  static const String placeholder = '${imagesPath}placeholder.png';
  static const String logoLight = '${imagesPath}logo_light.png';
  static const String logoDark = '${imagesPath}logo_dark.png';
}