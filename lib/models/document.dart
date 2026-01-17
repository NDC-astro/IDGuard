import 'package:uuid/uuid.dart';

/// Represents a document type category
enum DocumentType {
  nationalId,
  passport,
  driversLicense,
  residencePermit,
  healthInsurance,
  studentId,
  employeeBadge,
  other;

  String get key {
    switch (this) {
      case DocumentType.nationalId:
        return 'national_id';
      case DocumentType.passport:
        return 'passport';
      case DocumentType.driversLicense:
        return 'drivers_license';
      case DocumentType.residencePermit:
        return 'residence_permit';
      case DocumentType.healthInsurance:
        return 'health_insurance';
      case DocumentType.studentId:
        return 'student_id';
      case DocumentType.employeeBadge:
        return 'employee_badge';
      case DocumentType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case DocumentType.nationalId:
        return 'National ID Card';
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.driversLicense:
        return 'Driver\'s License';
      case DocumentType.residencePermit:
        return 'Residence Permit';
      case DocumentType.healthInsurance:
        return 'Health Insurance Card';
      case DocumentType.studentId:
        return 'Student ID';
      case DocumentType.employeeBadge:
        return 'Employee Badge';
      case DocumentType.other:
        return 'Other Document';
    }
  }

  static DocumentType fromKey(String key) {
    return DocumentType.values.firstWhere(
          (type) => type.key == key,
      orElse: () => DocumentType.other,
    );
  }
}

/// Represents a stored identity document
class Document {
  final String id;
  final String title;
  final DocumentType type;
  final DateTime createdAt;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? notes;
  final List<DocumentImage> images;
  final Map<String, dynamic>? customFields;

  Document({
    String? id,
    required this.title,
    required this.type,
    DateTime? createdAt,
    this.issueDate,
    this.expiryDate,
    this.notes,
    List<DocumentImage>? images,
    this.customFields,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        images = images ?? [];

  /// Check if document is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Check if document expires within warning period
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  /// Days until expiry (can be negative if expired)
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// Get front image
  DocumentImage? get frontImage {
    try {
      return images.firstWhere((img) => img.side == ImageSide.front);
    } catch (_) {
      return images.isNotEmpty ? images.first : null;
    }
  }

  /// Get back image
  DocumentImage? get backImage {
    try {
      return images.firstWhere((img) => img.side == ImageSide.back);
    } catch (_) {
      return null;
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.key,
      'createdAt': createdAt.toIso8601String(),
      'issueDate': issueDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'notes': notes,
      'images': images.map((img) => img.toJson()).toList(),
      'customFields': customFields,
    };
  }

  /// Create from JSON
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      title: json['title'] as String,
      type: DocumentType.fromKey(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      issueDate: json['issueDate'] != null
          ? DateTime.parse(json['issueDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      notes: json['notes'] as String?,
      images: (json['images'] as List?)
          ?.map((img) => DocumentImage.fromJson(img))
          .toList() ??
          [],
      customFields: json['customFields'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy with updated fields
  Document copyWith({
    String? title,
    DocumentType? type,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    List<DocumentImage>? images,
    Map<String, dynamic>? customFields,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      createdAt: createdAt,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      images: images ?? this.images,
      customFields: customFields ?? this.customFields,
    );
  }

  @override
  String toString() {
    return 'Document(id: $id, title: $title, type: ${type.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Document && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents which side of a document (front/back)
enum ImageSide {
  front,
  back;

  String get key {
    return name;
  }

  static ImageSide fromKey(String key) {
    return ImageSide.values.firstWhere(
          (side) => side.key == key,
      orElse: () => ImageSide.front,
    );
  }
}

/// Represents an image associated with a document
class DocumentImage {
  final String id;
  final ImageSide side;
  final DateTime capturedAt;
  final String? encryptedPath; // Path to encrypted image file
  final int? fileSize;

  DocumentImage({
    String? id,
    required this.side,
    DateTime? capturedAt,
    this.encryptedPath,
    this.fileSize,
  })  : id = id ?? const Uuid().v4(),
        capturedAt = capturedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'side': side.key,
      'capturedAt': capturedAt.toIso8601String(),
      'encryptedPath': encryptedPath,
      'fileSize': fileSize,
    };
  }

  factory DocumentImage.fromJson(Map<String, dynamic> json) {
    return DocumentImage(
      id: json['id'] as String,
      side: ImageSide.fromKey(json['side'] as String),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      encryptedPath: json['encryptedPath'] as String?,
      fileSize: json['fileSize'] as int?,
    );
  }

  DocumentImage copyWith({
    ImageSide? side,
    String? encryptedPath,
    int? fileSize,
  }) {
    return DocumentImage(
      id: id,
      side: side ?? this.side,
      capturedAt: capturedAt,
      encryptedPath: encryptedPath ?? this.encryptedPath,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}

/// Encrypted container for storing document data
class EncryptedDocument {
  final String id;
  final String encryptedData; // Base64 encrypted JSON
  final String iv; // Initialization vector for decryption
  final DateTime lastModified;

  EncryptedDocument({
    required this.id,
    required this.encryptedData,
    required this.iv,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'encryptedData': encryptedData,
      'iv': iv,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory EncryptedDocument.fromJson(Map<String, dynamic> json) {
    return EncryptedDocument(
      id: json['id'] as String,
      encryptedData: json['encryptedData'] as String,
      iv: json['iv'] as String,
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }
}