# IDGuard – Digital ID Wallet

A secure, privacy-focused mobile application for storing digital copies of identity documents offline with military-grade encryption.

## ⚠️ LEGAL DISCLAIMER

**IMPORTANT: This application does NOT replace official physical documents.**

- Always carry original physical documents when required by law
- Digital copies may not be legally accepted for official identification
- This app is for personal backup and convenience purposes only
- Check local laws regarding digital ID acceptance before relying on this app
- The developers assume no liability for misuse or legal issues arising from use

## 🔐 Security Features

- **AES-256-GCM Encryption**: All documents encrypted at rest
- **Biometric Authentication**: Face ID, fingerprint, or iris scanning
- **Secure PIN Fallback**: 6-digit PIN with lockout protection
- **No Cloud Storage**: 100% offline, local-only storage
- **Tamper Detection**: Basic jailbreak/root detection
- **Auto-lock**: App locks on background or after timeout
- **Secure Memory**: Sensitive data cleared from memory after use

## 🚀 How to Run

### Prerequisites

- Flutter SDK 3.0.0 or higher
- iOS 12.0+ / Android 6.0+
- Physical device recommended (biometrics don't work well in simulators)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd idguard
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create required asset folders:
```bash
mkdir -p assets/{images,icons,fonts,animations}
```

4. Add placeholder images (replace with actual assets):
- `assets/icons/app_icon.png` (1024x1024)
- `assets/icons/app_icon_foreground.png` (1024x1024)
- `assets/images/splash_logo.png` (512x512)

5. Generate launcher icons and splash screen:
```bash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

6. Configure platform-specific permissions:

**iOS (ios/Runner/Info.plist):**
```xml
<key>NSCameraUsageDescription</key>
<string>Required to scan identity documents</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Required to import documents from gallery</string>
<key>NSFaceIDUsageDescription</key>
<string>Required to securely access your documents</string>
```

**Android (android/app/src/main/AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

7. Run the app:
```bash
flutter run
```

## 📱 Features

### Document Management
- Scan documents using camera with auto-detection
- Import from gallery or file system
- Support for multiple document types:
    - National ID cards
    - Passports
    - Driver's licenses
    - Residence permits
    - Health insurance cards
    - Student/employee IDs
    - Custom documents

### Security & Privacy
- End-to-end encryption
- Biometric unlock
- Selective field redaction
- Encrypted backup/export
- Screenshot protection warnings
- Automatic app lock

### Smart Features
- Expiry date tracking
- Push notifications (30 days before expiry)
- Dark mode support
- Accessibility features
- Beautiful Material 3 UI

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── document.dart
│   ├── document_type.dart
│   └── encrypted_document.dart
├── services/                    # Business logic
│   ├── auth_service.dart
│   ├── encryption_service.dart
│   ├── storage_service.dart
│   ├── scanner_service.dart
│   ├── notification_service.dart
│   └── biometric_service.dart
├── providers/                   # State management
│   ├── document_provider.dart
│   ├── auth_provider.dart
│   └── theme_provider.dart
├── screens/                     # UI Screens
│   ├── splash_screen.dart
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── document/
│   └── settings/
├── widgets/                     # Reusable components
│   ├── document_card.dart
│   ├── secure_image.dart
│   └── biometric_prompt.dart
└── utils/                       # Utilities
    ├── constants.dart
    ├── validators.dart
    └── helpers.dart
```

## 🔧 Configuration

### Encryption
- Algorithm: AES-256-GCM
- Key derivation: PBKDF2 with 10,000 iterations
- Biometric-protected key storage

### Authentication
- Failed attempts before lockout: 5
- Lockout duration: Progressive (1min, 5min, 15min, 1hr)
- Session timeout: 5 minutes of inactivity

### Notifications
- Expiry warning: 30 days before
- Daily reminder if document expired

## 🧪 Testing

Run tests:
```bash
flutter test
```

Test on physical devices for biometrics:
```bash
flutter run --release
```

## 📝 Best Practices

1. **Never store plaintext documents** - All encryption happens before storage
2. **Clear sensitive data** - Memory cleared after authentication/viewing
3. **Regular backups** - Encourage users to create encrypted backups
4. **Physical documents** - Always remind users to carry originals
5. **App updates** - Keep dependencies updated for security patches

## 🔒 Privacy Considerations

- **No analytics or tracking** - Zero data collection
- **No internet required** - Fully offline operation
- **No cloud sync** - All data stays on device
- **User-controlled** - User manages all data and backups
- **Open source** - Code is auditable (if published)

## 🐛 Known Limitations

- Biometric authentication quality depends on device hardware
- OCR/text extraction not included (future feature)
- No multi-device sync (by design for security)
- Maximum image resolution limited to conserve storage

## 🤝 Contributing

While this is a security-focused app, contributions are welcome:
1. Security audits and penetration testing reports
2. Accessibility improvements
3. Localization (translations)
4. Bug fixes with tests

## 📄 License

[Insert your license here - recommend GPL-3.0 for security apps]

## 🆘 Support

For issues or questions:
- Open an issue on GitHub
- Email: support@idguard.app (if available)

## 🙏 Acknowledgments

- Built with Flutter
- Uses Google ML Kit for document scanning
- Inspired by modern password managers' security models

---

**Remember: Digital convenience should never compromise security. Always verify the legal status of digital documents in your jurisdiction before relying on them.**