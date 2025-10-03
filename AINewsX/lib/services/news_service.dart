// lib/services/news_service.dart (Updated with fetchTopHeadlinesByCountry)
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import 'api_keys.dart';

class NewsService {
  static const String baseUrl = 'https://newsapi.org/v2';
  static const int pageSize = 20;

  Future<List<Article>> fetchTopHeadlines(String category, {int page = 1}) async {
    final url = Uri.parse('$baseUrl/top-headlines?category=$category&pageSize=$pageSize&page=$page&apiKey=${ApiKeys.newsApiKey}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['articles'] as List).map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load headlines: ${response.reasonPhrase}');
    }
  }

  Future<List<Article>> fetchTopHeadlinesByCountry(String countryCode, {int page = 1}) async {
    final url = Uri.parse('$baseUrl/top-headlines?country=$countryCode&pageSize=$pageSize&page=$page&apiKey=${ApiKeys.newsApiKey}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['articles'] as List).map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load headlines for $countryCode: ${response.reasonPhrase}');
    }
  }

  Future<List<Article>> searchNews(String query, {int page = 1}) async {
    final url = Uri.parse('$baseUrl/everything?q=$query&pageSize=$pageSize&page=$page&apiKey=${ApiKeys.newsApiKey}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['articles'] as List).map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search news: ${response.reasonPhrase}');
    }
  }

// Add more methods as needed, e.g., for fake news detection in a separate service file later.
}