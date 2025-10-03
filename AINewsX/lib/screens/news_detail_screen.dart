// lib/screens/news_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../services/database_service.dart';


/// Screen for displaying detailed article view with save/share functionality.
/// Handles reactive save state and professional UI feedback.
class NewsDetailScreen extends StatefulWidget {
  final Article article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isSaved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  /// Checks if the current article is saved and updates state.
  Future<void> _checkIfSaved() async {
    try {
      final isSaved = await _databaseService.isArticleSaved(widget.article.title);
      if (mounted) {
        setState(() => _isSaved = isSaved);
      }
    } catch (e) {
      _showError('Failed to check save status: $e');
    }
  }

  /// Toggles save state with loading indicator and user feedback.
  Future<void> _toggleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final success = _isSaved
          ? await _databaseService.deleteArticle(widget.article.title)
          : await _databaseService.saveArticle(widget.article);

      if (!success) {
        throw Exception('Operation failed');
      }

      if (mounted) {
        setState(() => _isSaved = !_isSaved);
        final message = _isSaved ? 'Article saved successfully' : 'Article removed from saved';
        _showSuccess(message);
      }
    } catch (e) {
      _showError('Error toggling save: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Shares the article via system share sheet.
  Future<void> _shareArticle() async {
    try {
      await Share.share('${widget.article.title}\n${widget.article.url}');
    } catch (e) {
      _showError('Error sharing article: $e');
    }
  }

  /// Launches the article URL in external browser.
  Future<void> _launchUrl() async {
    final url = Uri.parse(widget.article.url);
    if (!await canLaunchUrl(url)) {
      _showError('Could not open article');
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Shows a success SnackBar with optional action.
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Saved',
          onPressed: () => _navigateToSaved(),
        ),
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
      ),
    );
  }

  /// Navigates to saved articles screen.
  void _navigateToSaved() {
    // Assuming you have a route for SavedArticlesScreen; adjust as needed.
    Navigator.pushNamed(context, '/saved_articles');
  }

  @override
  Widget build(BuildContext context) {
    final publishedDate = DateTime.tryParse(widget.article.publishedAt) ?? DateTime.now();
    final timeAgo = timeago.format(publishedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Details'),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                key: ValueKey(_isSaved),
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: _isSaved ? Colors.amber : null,
              ),
            ),
            onPressed: _isSaving ? null : _toggleSave,
            tooltip: _isSaved ? 'Remove from Saved' : 'Save Article',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareArticle,
            tooltip: 'Share Article',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.article.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.article.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              timeAgo,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              widget.article.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              widget.article.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchUrl,
                icon: const Icon(Icons.launch),
                label: const Text('Read Full Article'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}