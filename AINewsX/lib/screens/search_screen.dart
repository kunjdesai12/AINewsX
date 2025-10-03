// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../services/news_service.dart';
import '../services/database_service.dart';
import '../providers/news_provider.dart';
import '../widgets/article_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NewsService _newsService = NewsService();
  final DatabaseService _databaseService = DatabaseService();
  List<Article> _searchResults = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchMoreResults();
    }
  }

  Future<void> _fetchResults(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _currentQuery = query;
      _currentPage = 1;
      _searchResults = [];
      _hasMore = true;
    });

    try {
      final results = await _newsService.searchNews(query, page: _currentPage);
      setState(() {
        _searchResults = results;
        _isLoading = false;
        _hasMore = results.length >= 20; // Assume pageSize is 20
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    }
  }

  Future<void> _fetchMoreResults() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      _currentPage++;
      final results = await _newsService.searchNews(_currentQuery, page: _currentPage);
      setState(() {
        _searchResults.addAll(results);
        _isLoading = false;
        _hasMore = results.length >= 20;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more: $e')),
        );
      }
    }
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasSaved ? 'Removed from saved' : 'Article saved'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Toggle failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling save: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NewsProvider>.value(
      value: Provider.of<NewsProvider>(context),
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search news...',
              border: InputBorder.none,
              suffixIcon: Icon(Icons.search),
            ),
            onSubmitted: _fetchResults,
          ),
        ),
        body: Consumer<NewsProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () => _fetchResults(_currentQuery),
              child: _isLoading && _searchResults.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? const Center(child: Text('Search for news articles'))
                  : ListView.builder(
                controller: _scrollController,
                itemCount: _searchResults.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _searchResults.length) {
                    final article = _searchResults[index];
                    return ArticleCard(
                      article: article,
                      isSaved: provider.savedArticles.any((a) => a.title == article.title),
                      onToggleSave: () => _toggleSave(article),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}