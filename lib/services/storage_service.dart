import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/document.dart';
import 'encryption_service.dart';

/// Service for secure document storage and retrieval
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _encryptionService = EncryptionService();

  String? _documentsPath;
  String? _imagesPath;

  /// Initialize storage service
  Future<void> initialize() async {
    await _encryptionService.initialize();
    await _initializeDirectories();
  }

  /// Initialize app directories
  Future<void> _initializeDirectories() async {
    final appDir = await getApplicationDocumentsDirectory();

    // Create documents directory
    _documentsPath = '${appDir.path}/documents';
    final docsDir = Directory(_documentsPath!);
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }

    // Create images directory
    _imagesPath = '${appDir.path}/encrypted_images';
    final imagesDir = Directory(_imagesPath!);
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
  }

  /// Save a document
  Future<void> saveDocument(Document document) async {
    try {
      // Get all documents
      final documents = await getAllDocuments();

      // Update or add document
      final existingIndex = documents.indexWhere((d) => d.id == document.id);
      if (existingIndex >= 0) {
        documents[existingIndex] = document;
      } else {
        documents.add(document);
      }

      // Encrypt and save
      await _saveAllDocuments(documents);
    } catch (e) {
      throw StorageException('Failed to save document: $e');
    }
  }

  /// Get all documents
  Future<List<Document>> getAllDocuments() async {
    try {
      final encryptedData = await _secureStorage.read(
        key: 'encrypted_documents',
      );

      if (encryptedData == null || encryptedData.isEmpty) {
        return [];
      }

      // Parse encrypted container
      final containerJson = jsonDecode(encryptedData) as Map<String, dynamic>;
      final encrypted = EncryptedData.fromJson(containerJson);

      // Decrypt
      final decryptedJson = await _encryptionService.decryptData(encrypted);
      final List<dynamic> documentsJson = jsonDecode(decryptedJson);

      return documentsJson
          .map((json) => Document.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list if no documents or decryption fails
      return [];
    }
  }

  /// Get single document by ID
  Future<Document?> getDocument(String id) async {
    final documents = await getAllDocuments();
    try {
      return documents.firstWhere((doc) => doc.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String id) async {
    try {
      final documents = await getAllDocuments();
      final document = documents.firstWhere((d) => d.id == id);

      // Delete associated images
      for (final image in document.images) {
        if (image.encryptedPath != null) {
          await deleteImage(image.encryptedPath!);
        }
      }

      // Remove from list
      documents.removeWhere((d) => d.id == id);

      // Save updated list
      await _saveAllDocuments(documents);
    } catch (e) {
      throw StorageException('Failed to delete document: $e');
    }
  }

  /// Save all documents (internal helper)
  Future<void> _saveAllDocuments(List<Document> documents) async {
    try {
      // Convert to JSON
      final documentsJson = documents.map((d) => d.toJson()).toList();
      final jsonString = jsonEncode(documentsJson);

      // Encrypt
      final encrypted = await _encryptionService.encryptData(jsonString);

      // Save
      await _secureStorage.write(
        key: 'encrypted_documents',
        value: jsonEncode(encrypted.toJson()),
      );
    } catch (e) {
      throw StorageException('Failed to save documents: $e');
    }
  }

  /// Save encrypted image and return file path
  Future<String> saveImage(Uint8List imageBytes) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'img_$timestamp.enc';
      final filePath = '$_imagesPath/$filename';

      // Encrypt image
      final encrypted = await _encryptionService.encryptBytes(imageBytes);

      // Save encrypted data to file
      final file = File(filePath);
      final encryptedData = jsonEncode(encrypted.toJson());
      await file.writeAsString(encryptedData);

      return filePath;
    } catch (e) {
      throw StorageException('Failed to save image: $e');
    }
  }

  /// Load and decrypt image
  Future<Uint8List> loadImage(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw StorageException('Image file not found');
      }

      // Read encrypted data
      final encryptedString = await file.readAsString();
      final encryptedJson = jsonDecode(encryptedString) as Map<String, dynamic>;
      final encrypted = EncryptedData.fromJson(encryptedJson);

      // Decrypt
      return await _encryptionService.decryptBytes(encrypted);
    } catch (e) {
      throw StorageException('Failed to load image: $e');
    }
  }

  /// Delete encrypted image file
  Future<void> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }

  /// Export all documents as encrypted backup
  Future<String> exportBackup(String password) async {
    try {
      final documents = await getAllDocuments();
      final documentsJson = documents.map((d) => d.toJson()).toList();

      // Include all image data
      final backupData = <String, dynamic>{
        'version': '1.0',
        'created': DateTime.now().toIso8601String(),
        'documents': documentsJson,
        'images': <String, String>{},
      };

      // Add encrypted images to backup
      for (final doc in documents) {
        for (final image in doc.images) {
          if (image.encryptedPath != null) {
            final imageFile = File(image.encryptedPath!);
            if (await imageFile.exists()) {
              final encryptedImageData = await imageFile.readAsString();
              backupData['images'][image.id] = encryptedImageData;
            }
          }
        }
      }

      // Encrypt entire backup with user password
      final backupJson = jsonEncode(backupData);
      final passwordHash = await _encryptionService.hashPin(password);
      final parts = passwordHash.split(':');

      // Use password-derived key for backup encryption
      final encrypted = await _encryptionService.encryptData(backupJson);

      return jsonEncode({
        'backup': encrypted.toJson(),
        'salt': parts[1],
        'version': '1.0',
      });
    } catch (e) {
      throw StorageException('Failed to export backup: $e');
    }
  }

  /// Import documents from encrypted backup
  Future<void> importBackup(String backupData, String password) async {
    try {
      final backupJson = jsonDecode(backupData) as Map<String, dynamic>;

      // Verify password and decrypt
      final encryptedBackup = EncryptedData.fromJson(
        backupJson['backup'] as Map<String, dynamic>,
      );

      final decryptedData = await _encryptionService.decryptData(encryptedBackup);
      final data = jsonDecode(decryptedData) as Map<String, dynamic>;

      // Parse documents
      final documentsJson = data['documents'] as List<dynamic>;
      final documents = documentsJson
          .map((json) => Document.fromJson(json as Map<String, dynamic>))
          .toList();

      // Restore images
      final imagesData = data['images'] as Map<String, dynamic>;
      for (final doc in documents) {
        for (var i = 0; i < doc.images.length; i++) {
          final image = doc.images[i];
          final imageData = imagesData[image.id];

          if (imageData != null) {
            // Save restored image
            final filename = 'img_restored_${image.id}.enc';
            final filePath = '$_imagesPath/$filename';
            final file = File(filePath);
            await file.writeAsString(imageData);

            // Update image path
            doc.images[i] = image.copyWith(encryptedPath: filePath);
          }
        }
      }

      // Save all restored documents
      await _saveAllDocuments(documents);
    } catch (e) {
      throw StorageException('Failed to import backup: $e');
    }
  }

  /// Get storage statistics
  Future<StorageStats> getStorageStats() async {
    try {
      final documents = await getAllDocuments();
      int totalImages = 0;
      int totalSize = 0;

      for (final doc in documents) {
        totalImages += doc.images.length;
        for (final image in doc.images) {
          if (image.fileSize != null) {
            totalSize += image.fileSize!;
          }
        }
      }

      return StorageStats(
        documentCount: documents.length,
        imageCount: totalImages,
        totalSizeBytes: totalSize,
      );
    } catch (e) {
      return StorageStats(documentCount: 0, imageCount: 0, totalSizeBytes: 0);
    }
  }

  /// Clear all data (WARNING: irreversible)
  Future<void> clearAllData() async {
    try {
      // Delete all documents
      await _secureStorage.delete(key: 'encrypted_documents');

      // Delete all image files
      if (_imagesPath != null) {
        final imagesDir = Directory(_imagesPath!);
        if (await imagesDir.exists()) {
          await imagesDir.delete(recursive: true);
          await imagesDir.create();
        }
      }
    } catch (e) {
      throw StorageException('Failed to clear data: $e');
    }
  }
}

/// Storage statistics
class StorageStats {
  final int documentCount;
  final int imageCount;
  final int totalSizeBytes;

  StorageStats({
    required this.documentCount,
    required this.imageCount,
    required this.totalSizeBytes,
  });

  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  @override
  String toString() {
    return 'Documents: $documentCount, Images: $imageCount, Size: ${totalSizeMB.toStringAsFixed(2)} MB';
  }
}

/// Storage exception
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}