import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../utils/constants.dart';
import '../../../models/document.dart';
import '../../../widgets/document_card.dart';
import '../document/add_document_screen.dart';
import '../document/document_viewer_screen.dart';
import '../settings/settings_screen.dart';

/// Main home screen with document grid/list
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    await context.read<DocumentProvider>().loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: _navigateToAddDocument,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDocumentsList();
      case 1:
        return const AddDocumentScreen();
      case 2:
        return const SettingsScreen();
      default:
        return _buildDocumentsList();
    }
  }

  Widget _buildDocumentsList() {
    return Consumer<DocumentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDocuments,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!provider.hasDocuments) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadDocuments,
          child: Column(
            children: [
              // Expiry warnings
              if (provider.getExpiringDocuments().isNotEmpty ||
                  provider.getExpiredDocuments().isNotEmpty)
                _buildExpiryWarnings(provider),

              // Documents grid/list
              Expanded(
                child: _isGridView
                    ? _buildGridView(provider.documents)
                    : _buildListView(provider.documents),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpiryWarnings(DocumentProvider provider) {
    final expiring = provider.getExpiringDocuments();
    final expired = provider.getExpiredDocuments();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: expired.isNotEmpty
            ? AppColors.errorColor.withOpacity(0.1)
            : AppColors.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expired.isNotEmpty
              ? AppColors.errorColor
              : AppColors.warningColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: expired.isNotEmpty
                ? AppColors.errorColor
                : AppColors.warningColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              expired.isNotEmpty
                  ? '${expired.length} document(s) expired'
                  : '${expiring.length} document(s) expiring soon',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Document> documents) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        return DocumentCard(
          document: documents[index],
          onTap: () => _navigateToViewer(documents[index]),
        );
      },
    );
  }

  Widget _buildListView(List<Document> documents) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        return DocumentCard(
          document: documents[index],
          isListView: true,
          onTap: () => _navigateToViewer(documents[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noDocuments,
              style: AppTextStyles.h2.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.addFirstDocument,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddDocument,
              icon: const Icon(Icons.add),
              label: const Text('Add Document'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddDocument() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _navigateToViewer(Document document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(document: document),
      ),
    );
  }

  void _showSearch() {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search feature coming soon')),
    );
  }
}