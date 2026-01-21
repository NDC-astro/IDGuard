import 'package:flutter/material.dart';
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
