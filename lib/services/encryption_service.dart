import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

/// Service for handling all encryption/decryption operations
/// Uses AES-256-GCM for authenticated encryption
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  encrypt_lib.Key? _masterKey;
  final _random = Random.secure();

  /// Initialize the encryption service
  /// Generates or retrieves the master encryption key
  Future<void> initialize() async {
    try {
      // Try to retrieve existing master key
      final existingKey = await _secureStorage.read(
        key: AppConstants.storageKeyMasterKey,
      );

      if (existingKey != null) {
        _masterKey = encrypt_lib.Key.fromBase64(existingKey);
      } else {
        // Generate new master key
        await _generateMasterKey();
      }
    } catch (e) {
      throw EncryptionException('Failed to initialize encryption: $e');
    }
  }

  /// Generate and store a new master encryption key
  Future<void> _generateMasterKey() async {
    try {
      // Generate 256-bit random key
      final keyBytes = _generateRandomBytes(AppConstants.encryptionKeyLength);
      _masterKey = encrypt_lib.Key(keyBytes);

      // Store securely
      await _secureStorage.write(
        key: AppConstants.storageKeyMasterKey,
        value: _masterKey!.base64,
      );
    } catch (e) {
      throw EncryptionException('Failed to generate master key: $e');
    }
  }

  /// Encrypt data with AES-256-GCM
  Future<EncryptedData> encryptData(String plaintext) async {
    if (_masterKey == null) {
      await initialize();
    }

    try {
      // Generate random IV for this encryption
      final iv = encrypt_lib.IV.fromSecureRandom(16);

      // Create encrypter with GCM mode
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_masterKey!, mode: encrypt_lib.AESMode.gcm),
      );

      // Encrypt
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      return EncryptedData(
        ciphertext: encrypted.base64,
        iv: iv.base64,
      );
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Decrypt data with AES-256-GCM
  Future<String> decryptData(EncryptedData encryptedData) async {
    if (_masterKey == null) {
      await initialize();
    }

    try {
      final iv = encrypt_lib.IV.fromBase64(encryptedData.iv);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_masterKey!, mode: encrypt_lib.AESMode.gcm),
      );

      final encrypted = encrypt_lib.Encrypted.fromBase64(encryptedData.ciphertext);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Encrypt binary data (e.g., images)
  Future<EncryptedData> encryptBytes(Uint8List data) async {
    if (_masterKey == null) {
      await initialize();
    }

    try {
      final iv = encrypt_lib.IV.fromSecureRandom(16);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_masterKey!, mode: encrypt_lib.AESMode.gcm),
      );

      final encrypted = encrypter.encryptBytes(data, iv: iv);

      return EncryptedData(
        ciphertext: encrypted.base64,
        iv: iv.base64,
      );
    } catch (e) {
      throw EncryptionException('Byte encryption failed: $e');
    }
  }

  /// Decrypt binary data
  Future<Uint8List> decryptBytes(EncryptedData encryptedData) async {
    if (_masterKey == null) {
      await initialize();
    }

    try {
      final iv = encrypt_lib.IV.fromBase64(encryptedData.iv);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_masterKey!, mode: encrypt_lib.AESMode.gcm),
      );

      final encrypted = encrypt_lib.Encrypted.fromBase64(encryptedData.ciphertext);
      return Uint8List.fromList(encrypter.decryptBytes(encrypted, iv: iv));
    } catch (e) {
      throw EncryptionException('Byte decryption failed: $e');
    }
  }

  /// Hash PIN using PBKDF2
  Future<String> hashPin(String pin, {String? salt}) async {
    try {
      final actualSalt = salt ?? _generateSalt();
      final bytes = utf8.encode(pin + actualSalt);

      // Use PBKDF2 with SHA-256
      List<int> hash = bytes;
      for (var i = 0; i < AppConstants.pbkdf2Iterations; i++) {
        hash = sha256.convert(hash).bytes;
      }

      return '${base64.encode(hash)}:$actualSalt';
    } catch (e) {
      throw EncryptionException('PIN hashing failed: $e');
    }
  }

  /// Verify PIN against stored hash
  Future<bool> verifyPin(String pin, String storedHash) async {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;

      final salt = parts[1];
      final computedHash = await hashPin(pin, salt: salt);

      return computedHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// Generate random bytes
  Uint8List _generateRandomBytes(int length) {
    return Uint8List.fromList(
      List.generate(length, (_) => _random.nextInt(256)),
    );
  }

  /// Generate random salt for hashing
  String _generateSalt() {
    return base64.encode(_generateRandomBytes(16));
  }

  /// Clear master key from memory (on logout)
  Future<void> clearKeys() async {
    _masterKey = null;
  }

  /// Reset encryption (WARNING: destroys all encrypted data)
  Future<void> resetEncryption() async {
    await _secureStorage.delete(key: AppConstants.storageKeyMasterKey);
    _masterKey = null;
    await initialize();
  }

  /// Export master key for backup (encrypted with user password)
  Future<String> exportKeyWithPassword(String password) async {
    if (_masterKey == null) {
      await initialize();
    }

    try {
      // Use password to derive encryption key
      final passwordHash = await hashPin(password);
      final parts = passwordHash.split(':');
      final derivedKey = encrypt_lib.Key.fromBase64(parts[0]);

      final iv = encrypt_lib.IV.fromSecureRandom(16);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(derivedKey, mode: encrypt_lib.AESMode.gcm),
      );

      final encrypted = encrypter.encrypt(_masterKey!.base64, iv: iv);

      return jsonEncode({
        'encrypted_key': encrypted.base64,
        'iv': iv.base64,
        'salt': parts[1],
      });
    } catch (e) {
      throw EncryptionException('Key export failed: $e');
    }
  }

  /// Import master key from backup
  Future<void> importKeyWithPassword(String encryptedKeyData, String password) async {
    try {
      final data = jsonDecode(encryptedKeyData) as Map<String, dynamic>;

      // Derive key from password
      final passwordHash = await hashPin(password, salt: data['salt']);
      final parts = passwordHash.split(':');
      final derivedKey = encrypt_lib.Key.fromBase64(parts[0]);

      final iv = encrypt_lib.IV.fromBase64(data['iv']);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(derivedKey, mode: encrypt_lib.AESMode.gcm),
      );

      final encrypted = encrypt_lib.Encrypted.fromBase64(data['encrypted_key']);
      final decryptedKey = encrypter.decrypt(encrypted, iv: iv);

      // Store the imported key
      _masterKey = encrypt_lib.Key.fromBase64(decryptedKey);
      await _secureStorage.write(
        key: AppConstants.storageKeyMasterKey,
        value: _masterKey!.base64,
      );
    } catch (e) {
      throw EncryptionException('Key import failed: $e');
    }
  }
}

/// Container for encrypted data and its IV
class EncryptedData {
  final String ciphertext;
  final String iv;

  EncryptedData({
    required this.ciphertext,
    required this.iv,
  });

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'iv': iv,
  };

  factory EncryptedData.fromJson(Map<String, dynamic> json) => EncryptedData(
    ciphertext: json['ciphertext'],
    iv: json['iv'],
  );
}

/// Custom exception for encryption errors
class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}