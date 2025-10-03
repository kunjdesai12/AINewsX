import 'dart:io'; // Added for SocketException handling.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../services/news_service.dart';
import '../services/database_service.dart';

/// Provider for managing news data, search, and now saved articles reactivity.
/// Notifies listeners on save changes for app-wide updates.
class NewsProvider with ChangeNotifier {
  final NewsService _newsService = NewsService();
  final DatabaseService _databaseService = DatabaseService();
  Map<String, List<Article>> _newsByCategory = {};
  Map<String, List<Article>> _newsByCountry = {}; // Added for country-specific news.
  List<Article> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Cached saved articles for reactivity.
  List<Article> _savedArticles = [];
  bool _isSavedLoading = false;

  Map<String, List<Article>> get newsByCategory => _newsByCategory;
  Map<String, List<Article>> get newsByCountry => _newsByCountry; // Added getter.
  List<Article> get searchResults => _searchResults;
  List<String> get searchHistory => _searchHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Article> get savedArticles => _savedArticles;
  bool get isSavedLoading => _isSavedLoading;

  NewsProvider() {
    _loadSavedArticles(); // Init on creation.
    loadSearchHistory();
  }

  /// Fetches news for a category.
  Future<void> fetchNewsForCategory(String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final articles = await _newsService.fetchTopHeadlines(category.toLowerCase());
      _newsByCategory[category] = articles;
    } catch (e) {
      if (e is SocketException) {
        _errorMessage = 'No internet connection. Please check your network and try again.';
      } else {
        _errorMessage = 'Failed to load news. Please try again later.';
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Added: Fetches top headlines for a specific country.
  Future<void> fetchNewsByCountry(String countryCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final articles = await _newsService.fetchTopHeadlinesByCountry(countryCode);
      _newsByCountry[countryCode] = articles;
    } catch (e) {
      if (e is SocketException) {
        _errorMessage = 'No internet connection. Please check your network and try again.';
      } else {
        _errorMessage = 'Failed to load news for $countryCode. Please try again later.';
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Searches news with history management.
  Future<void> searchNews(String query, {bool reset = true}) async {
    if (query.isEmpty) return;
    _isLoading = true;
    if (reset) _searchResults = [];
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await _newsService.searchNews(query);
      _searchResults = results;
      await _addToSearchHistory(query);
    } catch (e) {
      if (e is SocketException) {
        _errorMessage = 'No internet connection. Please check your network and try again.';
      } else {
        _errorMessage = 'Failed to search news. Please try again later.';
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Adds query to search history (limited to 10).
  Future<void> _addToSearchHistory(String query) async {
    if (_searchHistory.contains(query)) return;
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('searchHistory', _searchHistory);
    notifyListeners();
  }

  /// Loads search history from SharedPreferences.
  Future<void> loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList('searchHistory') ?? [];
    notifyListeners();
  }

  /// Clears search history.
  Future<void> clearSearchHistory() async {
    _searchHistory = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('searchHistory');
    notifyListeners();
  }

  /// Loads saved articles reactively.
  Future<void> _loadSavedArticles() async {
    _isSavedLoading = true;
    notifyListeners();
    try {
      _savedArticles = await _databaseService.getSavedArticles();
    } catch (e) {
      // Handle error silently or log.
    }
    _isSavedLoading = false;
    notifyListeners();
  }

  /// Checks if an article is saved (cached for performance).
  Future<bool> isArticleSaved(String title) async {
    if (_savedArticles.isNotEmpty) {
      return _savedArticles.any((a) => a.title == title);
    }
    await _loadSavedArticles();
    return _savedArticles.any((a) => a.title == title);
  }

  /// Added: Saves an article to the database.
  Future<bool> saveArticle(Article article) async {
    try {
      final success = await _databaseService.saveArticle(article);
      if (success) {
        await _loadSavedArticles(); // Reload for reactivity.
        notifyListeners();
      }
      return success;
    } catch (e) {
      // Log error if needed.
      return false;
    }
  }

  /// Added: Deletes a saved article by title from the database.
  Future<bool> deleteArticle(String title) async {
    try {
      final success = await _databaseService.deleteArticle(title);
      if (success) {
        await _loadSavedArticles(); // Reload for reactivity.
        notifyListeners();
      }
      return success;
    } catch (e) {
      // Log error if needed.
      return false;
    }
  }

  /// Notifies on save/delete changes to reload saved list.
  void notifySavedChange() {
    _loadSavedArticles();
  }

  @override
  void dispose() {
    _databaseService.close();
    super.dispose();
  }
}