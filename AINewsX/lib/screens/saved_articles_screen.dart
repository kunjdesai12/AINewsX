// lib/screens/saved_articles_screen.dart
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/database_service.dart';
import '../widgets/article_card.dart';

/// Screen for displaying and managing saved articles.
/// Supports pull-to-refresh, confirmation dialogs, and smooth deletions.
class SavedArticlesScreen extends StatefulWidget {
  const SavedArticlesScreen({super.key});

  @override
  State<SavedArticlesScreen> createState() => _SavedArticlesScreenState();
}

class _SavedArticlesScreenState extends State<SavedArticlesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Article> _savedArticles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedArticles();
  }

  /// Loads saved articles from database with error handling.
  Future<void> _loadSavedArticles() async {
    setState(() => _isLoading = true);
    try {
      final articles = await _databaseService.getSavedArticles();
      if (mounted) {
        setState(() {
          _savedArticles = articles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error loading saved articles: $e');
      }
    }
  }

  /// Deletes an article with confirmation dialog and animation.
  Future<void> _deleteArticle(String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirm Delete'),
          ],
        ),
        content: const Text('Are you sure you want to delete this article? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final success = await _databaseService.deleteArticle(title);
      if (success && mounted) {
        // Animate removal from list.
        final index = _savedArticles.indexWhere((a) => a.title == title);
        if (index != -1) {
          setState(() => _savedArticles.removeAt(index));
        }
        _showSuccess('Article deleted successfully');
      } else {
        throw Exception('Delete operation failed');
      }
    } catch (e) {
      _showError('Error deleting article: $e');
    }
  }

  /// Shows a success SnackBar.
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Shows an error SnackBar.
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Articles'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedArticles,
        color: Theme.of(context).primaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _savedArticles.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No saved articles yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Save articles from news lists to see them here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _savedArticles.length,
          itemBuilder: (context, index) {
            final article = _savedArticles[index];
            return ArticleCard(
              article: article,
              isSaved: true, // Always saved in this screen.
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteArticle(article.title),
                tooltip: 'Delete Article',
              ),
            );
          },
        ),
      ),
    );
  }
}