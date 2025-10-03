// screens/category_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../services/news_service.dart';
import '../services/database_service.dart';
import '../providers/news_provider.dart'; // Corrected import path (adjust if needed, e.g., to '../providers/news_provider.dart')
import '../widgets/article_card.dart';

/// Screen for displaying articles in a specific category with infinite scroll and save integration.
/// Fetches articles paginated and supports reactive save toggles via Provider.
class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final NewsService _newsService = NewsService();
  final DatabaseService _databaseService = DatabaseService();
  final ScrollController _scrollController = ScrollController();
  List<Article> _articles = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
    _scrollController.addListener(_onScroll);
  }

  /// Fetches initial articles for the category.
  Future<void> _fetchArticles({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    setState(() => _isLoading = true);
    try {
      final articles = await _newsService.fetchTopHeadlines(
        widget.category.toLowerCase(),
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _articles = isRefresh ? articles : [..._articles, ...articles];
          _isLoading = false;
          _hasMore = articles.length >= 20; // Matches pageSize.
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error loading articles: $e');
      }
    }
  }

  /// Fetches additional pages on scroll.
  Future<void> _fetchMoreArticles() async {
    if (_isLoading || !_hasMore) return;
    _currentPage++;
    await _fetchArticles(isRefresh: false);
  }

  /// Handles scroll-based pagination.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchMoreArticles();
    }
  }

  /// Toggles save for an article and notifies Provider.
  Future<void> _toggleSave(Article article) async {
    try {
      final wasSaved = await _databaseService.isArticleSaved(article.title);
      final success = wasSaved
          ? await _databaseService.deleteArticle(article.title)
          : await _databaseService.saveArticle(article);

      if (success && mounted) {
        // Notify Provider for app-wide reactivity.
        final provider = Provider.of<NewsProvider>(context, listen: false);
        provider.notifySavedChange();
        _showSuccess(wasSaved ? 'Removed from saved' : 'Article saved');
      } else {
        throw Exception('Toggle failed');
      }
    } catch (e) {
      _showError('Error toggling save: $e');
    }
  }

  /// Shows success feedback.
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Shows error feedback.
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NewsProvider>.value( // Ensure provider is available; adjust if global.
      value: Provider.of<NewsProvider>(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.category),
          elevation: 0,
        ),
        body: Consumer<NewsProvider>(
          builder: (context, provider, child) {
            // Safe access: provider is non-null inside Consumer.
            return RefreshIndicator(
              onRefresh: () => _fetchArticles(isRefresh: true),
              color: Theme.of(context).primaryColor,
              child: _isLoading && _articles.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _articles.isEmpty
                  ? const Center(child: Text('No articles found'))
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _articles.length + (_hasMore && !_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _articles.length) {
                    final article = _articles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ArticleCard(
                        article: article,
                        isSaved: provider.savedArticles.any((a) => a.title == article.title), // Use cached list for efficiency.
                        onToggleSave: () => _toggleSave(article),
                      ),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}