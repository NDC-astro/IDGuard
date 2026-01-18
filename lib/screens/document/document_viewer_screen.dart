import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';

/// Full-screen document viewer with zoom capabilities
class DocumentViewerScreen extends StatefulWidget {
  final Document document;

  const DocumentViewerScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final _storageService = StorageService();
  bool _showingFront = true;
  Map<String, Uint8List?> _loadedImages = {};
  bool _isLoading = true;
  double _brightness = 1.0;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);

    try {
      for (final image in widget.document.images) {
        if (image.encryptedPath != null) {
          final bytes = await _storageService.loadImage(image.encryptedPath!);
          _loadedImages[image.id] = bytes;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load images: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
          'Are you sure you want to delete this document? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<DocumentProvider>().deleteDocument(widget.document.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.documentDeleted)),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = _showingFront
        ? widget.document.frontImage
        : widget.document.backImage;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.document.title),
        actions: [
          IconButton(
            icon: Icon(_showInfo ? Icons.info : Icons.info_outline),
            onPressed: () {
              setState(() => _showInfo = !_showInfo);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteDocument();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.errorColor),
                    SizedBox(width: 12),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Image Viewer
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (currentImage != null && _loadedImages[currentImage.id] != null)
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(_brightness),
                BlendMode.modulate,
              ),
              child: PhotoView(
                imageProvider: MemoryImage(_loadedImages[currentImage.id]!),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
              ),
            )
          else
            const Center(
              child: Text(
                'No image available',
                style: TextStyle(color: Colors.white),
              ),
            ),

          // Info Overlay
          if (_showInfo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: _buildDocumentInfo(),
              ),
            ),

          // Controls
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                // Brightness Control
                FloatingActionButton.small(
                  heroTag: 'brightness',
                  onPressed: _showBrightnessDialog,
                  child: const Icon(Icons.brightness_6),
                ),
                const SizedBox(height: 8),

                // Toggle Front/Back
                if (widget.document.backImage != null)
                  FloatingActionButton.small(
                    heroTag: 'flip',
                    onPressed: () {
                      setState(() => _showingFront = !_showingFront);
                    },
                    child: const Icon(Icons.flip),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.document.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.document.type.displayName,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
        if (widget.document.issueDate != null ||
            widget.document.expiryDate != null) ...[
          const SizedBox(height: 16),
          if (widget.document.issueDate != null)
            _buildInfoRow(
              Icons.calendar_today,
              'Issued',
              DateFormat.yMMMd().format(widget.document.issueDate!),
            ),
          if (widget.document.expiryDate != null)
            _buildInfoRow(
              Icons.event,
              'Expires',
              DateFormat.yMMMd().format(widget.document.expiryDate!),
              isExpiry: true,
            ),
        ],
        if (widget.document.notes != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.document.notes!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          _showingFront ? 'Front Side' : 'Back Side',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isExpiry = false}) {
    Color textColor = Colors.white;
    if (isExpiry) {
      if (widget.document.isExpired) {
        textColor = AppColors.errorColor;
      } else if (widget.document.isExpiringSoon) {
        textColor = AppColors.warningColor;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showBrightnessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Brightness'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _brightness,
                  min: 0.5,
                  max: 1.5,
                  divisions: 10,
                  label: '${(_brightness * 100).round()}%',
                  onChanged: (value) {
                    setDialogState(() {
                      setState(() {
                        _brightness = value;
                      });
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('50%', style: TextStyle(color: Colors.grey[600])),
                    Text('150%', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}