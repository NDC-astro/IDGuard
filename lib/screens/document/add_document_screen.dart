import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';

/// Screen for adding a new document
class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  DocumentType _selectedType = DocumentType.nationalId;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  Uint8List? _frontImage;
  Uint8List? _backImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSide side) async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: AppConstants.maxImageWidth.toDouble(),
        maxHeight: AppConstants.maxImageHeight.toDouble(),
        imageQuality: AppConstants.imageQuality,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          if (side == ImageSide.front) {
            _frontImage = bytes;
          } else {
            _backImage = bytes;
          }
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_frontImage == null) {
      _showErrorSnackbar('Please add at least a front image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save images
      final images = <DocumentImage>[];

      if (_frontImage != null) {
        final frontPath = await _storageService.saveImage(_frontImage!);
        images.add(DocumentImage(
          side: ImageSide.front,
          encryptedPath: frontPath,
          fileSize: _frontImage!.length,
        ));
      }

      if (_backImage != null) {
        final backPath = await _storageService.saveImage(_backImage!);
        images.add(DocumentImage(
          side: ImageSide.back,
          encryptedPath: backPath,
          fileSize: _backImage!.length,
        ));
      }

      // Create document
      final document = Document(
        title: _titleController.text,
        type: _selectedType,
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        images: images,
      );

      // Save to storage
      await context.read<DocumentProvider>().addDocument(document);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.documentAdded)),
        );
        _resetForm();
      }
    } catch (e) {
      _showErrorSnackbar('Failed to save document: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _notesController.clear();
    setState(() {
      _selectedType = DocumentType.nationalId;
      _issueDate = null;
      _expiryDate = null;
      _frontImage = null;
      _backImage = null;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Document'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveDocument,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Document Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Type',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<DocumentType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                      ),
                      items: DocumentType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                DocumentTypeConfig.icons[type.key],
                                color: DocumentTypeConfig.colors[type.key],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(type.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title',
                        hintText: 'e.g., My Passport',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Additional information',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dates',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Issue Date'),
                      subtitle: Text(
                        _issueDate != null
                            ? DateFormat.yMMMd().format(_issueDate!)
                            : 'Not set',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _issueDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _issueDate = date);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Expiry Date'),
                      subtitle: Text(
                        _expiryDate != null
                            ? DateFormat.yMMMd().format(_expiryDate!)
                            : 'Not set',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _expiryDate ?? DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _expiryDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Images
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Images',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),
                    _buildImagePicker(
                      'Front Side',
                      ImageSide.front,
                      _frontImage,
                    ),
                    const SizedBox(height: 16),
                    _buildImagePicker(
                      'Back Side (optional)',
                      ImageSide.back,
                      _backImage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, ImageSide side, Uint8List? image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickImage(side),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: image != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                image,
                fit: BoxFit.cover,
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to add image',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        if (image != null)
          TextButton.icon(
            onPressed: () {
              setState(() {
                if (side == ImageSide.front) {
                  _frontImage = null;
                } else {
                  _backImage = null;
                }
              });
            },
            icon: const Icon(Icons.delete),
            label: const Text('Remove'),
          ),
      ],
    );
  }
}