import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../services/storage_service.dart';

/// Provider for managing document state
class DocumentProvider with ChangeNotifier {
  final _storageService = StorageService();

  List<Document> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasDocuments => _documents.isNotEmpty;

  /// Initialize and load documents
  Future<void> initialize() async {
    await _storageService.initialize();
    await loadDocuments();
  }

  /// Load all documents
  Future<void> loadDocuments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _documents = await _storageService.getAllDocuments();

      // Sort by created date (newest first)
      _documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load documents: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new document
  Future<void> addDocument(Document document) async {
    try {
      await _storageService.saveDocument(document);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to add document: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update existing document
  Future<void> updateDocument(Document document) async {
    try {
      await _storageService.saveDocument(document);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to update document: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Delete document
  Future<void> deleteDocument(String id) async {
    try {
      await _storageService.deleteDocument(id);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to delete document: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get document by ID
  Document? getDocumentById(String id) {
    try {
      return _documents.firstWhere((doc) => doc.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get documents by type
  List<Document> getDocumentsByType(DocumentType type) {
    return _documents.where((doc) => doc.type == type).toList();
  }

  /// Get expiring documents (within 30 days)
  List<Document> getExpiringDocuments() {
    return _documents.where((doc) => doc.isExpiringSoon).toList();
  }

  /// Get expired documents
  List<Document> getExpiredDocuments() {
    return _documents.where((doc) => doc.isExpired).toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Provider for authentication state
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void setBiometricAvailable(bool value) {
    _isBiometricAvailable = value;
    notifyListeners();
  }

  void setBiometricEnabled(bool value) {
    _isBiometricEnabled = value;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}

/// Provider for theme management
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}