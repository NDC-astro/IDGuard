import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../auth/auth_screen.dart';

/// Settings and configuration screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _storageService = StorageService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Security Section
          _buildSectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Use Face ID or Fingerprint'),
            trailing: Switch(
              value: context.watch<AuthProvider>().isBiometricEnabled,
              onChanged: context.watch<AuthProvider>().isBiometricAvailable
                  ? (value) => _toggleBiometric(value)
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your security PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePinDialog,
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Auto-lock Timeout'),
            subtitle: Text('Lock after ${AppConstants.sessionTimeout.inMinutes} minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showTimeoutInfo,
          ),

          const Divider(),

          // Backup Section
          _buildSectionHeader('Backup & Restore'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Export Encrypted Backup'),
            subtitle: const Text('Create a password-protected backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportBackup,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore from encrypted backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _importBackup,
          ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: context.watch<ThemeProvider>().isDarkMode,
              onChanged: (value) {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ),

          const Divider(),

          // Storage Section
          _buildSectionHeader('Storage'),
          FutureBuilder<StorageStats>(
            future: _storageService.getStorageStats(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final stats = snapshot.data!;
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.folder),
                      title: const Text('Documents'),
                      trailing: Text('${stats.documentCount}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.image),
                      title: const Text('Images'),
                      trailing: Text('${stats.imageCount}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('Storage Used'),
                      trailing: Text('${stats.totalSizeMB.toStringAsFixed(2)} MB'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.errorColor),
            title: const Text('Clear All Data'),
            subtitle: const Text('Permanently delete all documents'),
            onTap: _clearAllData,
          ),

          const Divider(),

          // About Section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            trailing: Text(
              AppConstants.appVersion,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('Legal Disclaimer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLegalDisclaimer,
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Security Info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPrivacyInfo,
          ),

          const SizedBox(height: 32),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorColor,
                side: const BorderSide(color: AppColors.errorColor),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Future<void> _toggleBiometric(bool enabled) async {
    try {
      if (enabled) {
        // Test biometric authentication first
        final authenticated = await _authService.authenticateWithBiometrics(
          reason: 'Enable biometric authentication',
        );
        if (!authenticated) return;
      }

      await _authService.setBiometricEnabled(enabled);
      if (mounted) {
        context.read<AuthProvider>().setBiometricEnabled(enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Biometric authentication enabled'
                  : 'Biometric authentication disabled',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e')),
        );
      }
    }
  }

  Future<void> _showChangePinDialog() async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              decoration: const InputDecoration(labelText: 'Current PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: AppConstants.pinLength,
            ),
            TextField(
              controller: newPinController,
              decoration: const InputDecoration(labelText: 'New PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: AppConstants.pinLength,
            ),
            TextField(
              controller: confirmPinController,
              decoration: const InputDecoration(labelText: 'Confirm New PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: AppConstants.pinLength,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newPinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.pinMismatch)),
                );
                return;
              }

              try {
                await _authService.changePin(
                  oldPinController.text,
                  newPinController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN changed successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to change PIN: $e')),
                  );
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-lock Timeout'),
        content: Text(
          'The app will automatically lock after ${AppConstants.sessionTimeout.inMinutes} minutes of inactivity for security.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a password to encrypt your backup:'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final backup = await _storageService.exportBackup(password);

      // Save to file and share
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/idguard_backup_${DateTime.now().millisecondsSinceEpoch}.igb');
      await file.writeAsString(backup);

      await Share.shareXFiles([XFile(file.path)]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final backupData = await file.readAsString();

      final passwordController = TextEditingController();
      final password = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the backup password:'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (password == null || password.isEmpty) return;

      setState(() => _isLoading = true);

      await _storageService.importBackup(backupData, password);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup imported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'WARNING: This will permanently delete ALL documents and cannot be undone. '
              'Make sure you have a backup if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _storageService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear data: $e')),
        );
      }
    }
  }

  void _showLegalDisclaimer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legal Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(AppStrings.legalDisclaimer),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔒 AES-256-GCM Encryption',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Military-grade encryption protects all your documents.'),
              SizedBox(height: 16),
              Text('📱 100% Offline',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('No internet required. All data stays on your device.'),
              SizedBox(height: 16),
              Text('🙈 No Tracking',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Zero analytics, no data collection, complete privacy.'),
              SizedBox(height: 16),
              Text('🔑 Biometric Protection',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Use Face ID or fingerprint for secure access.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        context.read<AuthProvider>().logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
        );
      }
    }
  }
}