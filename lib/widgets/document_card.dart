import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document.dart';
import '../utils/constants.dart';

/// Card widget for displaying a document in grid or list view
class DocumentCard extends StatelessWidget {
  final Document document;
  final bool isListView;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DocumentCard({
    super.key,
    required this.document,
    this.isListView = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: isListView ? _buildListView(context) : _buildGridView(context),
      ),
    );
  }

  Widget _buildGridView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document preview/placeholder
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getTypeColor().withOpacity(0.7),
                  _getTypeColor(),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getTypeIcon(),
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                if (document.isExpired || document.isExpiringSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: document.isExpired
                          ? AppColors.errorColor
                          : AppColors.warningColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      document.isExpired ? 'EXPIRED' : 'EXPIRING SOON',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Document info
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                document.type.displayName,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (document.expiryDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  _getExpiryText(),
                  style: AppTextStyles.caption.copyWith(
                    color: document.isExpired
                        ? AppColors.errorColor
                        : document.isExpiringSoon
                        ? AppColors.warningColor
                        : Colors.grey[600],
                    fontWeight: document.isExpired || document.isExpiringSoon
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getTypeColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getTypeIcon(),
              color: _getTypeColor(),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  document.type.displayName,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (document.expiryDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getExpiryText(),
                    style: AppTextStyles.caption.copyWith(
                      color: document.isExpired
                          ? AppColors.errorColor
                          : document.isExpiringSoon
                          ? AppColors.warningColor
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status badge
          if (document.isExpired || document.isExpiringSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: document.isExpired
                    ? AppColors.errorColor.withOpacity(0.1)
                    : AppColors.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: document.isExpired
                      ? AppColors.errorColor
                      : AppColors.warningColor,
                ),
              ),
              child: Icon(
                Icons.warning_amber,
                size: 16,
                color: document.isExpired
                    ? AppColors.errorColor
                    : AppColors.warningColor,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    return DocumentTypeConfig.icons[document.type.key] ?? Icons.description;
  }

  Color _getTypeColor() {
    return DocumentTypeConfig.colors[document.type.key] ?? Colors.grey;
  }

  String _getExpiryText() {
    if (document.expiryDate == null) return '';

    if (document.isExpired) {
      final daysPassed = DateTime.now().difference(document.expiryDate!).inDays;
      return 'Expired $daysPassed days ago';
    }

    if (document.isExpiringSoon) {
      return 'Expires in ${document.daysUntilExpiry} days';
    }

    return 'Expires ${DateFormat.yMMMd().format(document.expiryDate!)}';
  }
}