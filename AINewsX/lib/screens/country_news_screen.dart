// lib/screens/country_news_screen.dart (Updated for Provider integration and professional offline handling)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../providers/theme_provider.dart';
import '../models/article.dart';
import 'news_detail_screen.dart';
import 'search_screen.dart';

/// Screen for selecting countries and displaying top news by country.
class CountryNewsScreen extends StatefulWidget {
  const CountryNewsScreen({super.key});

  @override
  State<CountryNewsScreen> createState() => _CountryNewsScreenState();
}

class _CountryNewsScreenState extends State<CountryNewsScreen> {
  String _selectedCountryCode = 'us'; // Default to US
  final Map<String, String> _countries = {
    // Extended list of NewsAPI supported countries (name: code for easy display).
    'United States': 'us',
    'United Kingdom': 'gb',
    'India': 'in',
    'Canada': 'ca',
    'Australia': 'au',
    'Germany': 'de',
    'France': 'fr',
    'Japan': 'jp',
    'Brazil': 'br',
    'Russia': 'ru',
    'China': 'cn',
    'Italy': 'it',
    'Spain': 'es',
    'Mexico': 'mx',
    'South Korea': 'kr',
    'Netherlands': 'nl',
    'Sweden': 'se',
    'Norway': 'no',
    'Switzerland': 'ch',
    'Belgium': 'be',
  };

  @override
  void initState() {
    super.initState();
    // Fetch default US news on init.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NewsProvider>(context, listen: false).fetchNewsByCountry(_selectedCountryCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final List<Article>? countryNews = newsProvider.newsByCountry[_selectedCountryCode];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top News by Country'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search News',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.amber,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => themeProvider.toggleTheme(themeProvider.themeMode != ThemeMode.dark),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'AINewsX',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your AI News Companion',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark, color: Colors.amber),
              title: const Text('Saved Articles'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/saved_articles');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Fake News Detection'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/fake_news');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.green),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/categories');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Colors.purple),
              title: const Text('Chat with AI News Bot'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chat');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => newsProvider.fetchNewsByCountry(_selectedCountryCode),
        color: Theme.of(context).primaryColor,
        displacement: 20,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar (Always visible)
              Container(
                margin: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search all news...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.mic, color: Colors.grey),
                      onPressed: () {
                        // Implement voice search if needed.
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (query) {
                    Navigator.pushNamed(
                      context,
                      '/search',
                      arguments: query,
                    );
                  },
                ),
              ),
              // Countries Selector (Horizontal chips for better UX)
              Container(
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final entry = _countries.entries.elementAt(index);
                    final code = entry.value;
                    final name = entry.key;
                    final isSelected = code == _selectedCountryCode;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          '$name\n(${code.toUpperCase()})',
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                        onPressed: () => _selectCountry(code),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // News Section for Selected Country (Conditional states)
              _buildCountryNewsSection(context, newsProvider, countryNews),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _selectCountry(String code) {
    if (code != _selectedCountryCode) {
      setState(() {
        _selectedCountryCode = code;
      });
      // Fetch news for new country.
      Provider.of<NewsProvider>(context, listen: false).fetchNewsByCountry(code);
    }
  }

  /// Builds the news section: loading skeleton, error banner, empty, or list.
  Widget _buildCountryNewsSection(BuildContext context, NewsProvider newsProvider, List<Article>? countryNews) {
    final countryName = _countries.entries
        .firstWhere((entry) => entry.value == _selectedCountryCode)
        .key;

    if (newsProvider.isLoading) {
      return _buildNewsSkeleton(context);
    } else if (newsProvider.errorMessage != null) {
      return _buildErrorBanner(context, newsProvider, _selectedCountryCode);
    } else if (countryNews == null || countryNews.isEmpty) {
      return _buildEmptyNewsCard(context, countryName);
    } else {
      return _buildNewsList(context, countryNews);
    }
  }

  /// Professional skeleton loader for news section.
  Widget _buildNewsSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: double.infinity, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(height: 12, width: 200, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(height: 8, width: 100, color: Colors.grey[300]),
                    const Spacer(),
                    Container(height: 8, width: 80, color: Colors.grey[300]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Inline dismissible error banner for network issues.
  Widget _buildErrorBanner(BuildContext context, NewsProvider newsProvider, String countryCode) {
    final countryName = _countries.entries
        .firstWhere((entry) => entry.value == countryCode)
        .key;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => newsProvider.fetchNewsByCountry(countryCode), // Tap to retry.
        borderRadius: BorderRadius.circular(12),
        splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off_outlined, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network Issue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${newsProvider.errorMessage} for $countryName.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => newsProvider.fetchNewsByCountry(countryCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Subtle empty state for no news.
  Widget _buildEmptyNewsCard(BuildContext context, String countryName) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.public_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No news available for $countryName',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pull to refresh for updates.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// List of news articles (compact cards with save toggle).
  Widget _buildNewsList(BuildContext context, List<Article> articles) {
    final newsProvider = Provider.of<NewsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Top Headlines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: articles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final article = articles[index];
            final isSaved = newsProvider.savedArticles.any((a) => a.title == article.title);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/article',
                    arguments: article,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            article.imageUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        article.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(article.publishedAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: Colors.amber,
                            ),
                            onPressed: () async {
                              await _toggleSave(article, newsProvider);
                            },
                          ),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[500]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Toggle save for article (using provider).
  Future<void> _toggleSave(Article article, NewsProvider newsProvider) async {
    try {
      final isCurrentlySaved = await newsProvider.isArticleSaved(article.title);
      // Note: You'll need to implement save/delete in DatabaseService and call here.
      // For now, assume DatabaseService has saveArticle and deleteArticle methods.
      // After toggle, notify provider to refresh saved list.
      if (isCurrentlySaved) {
        // await _databaseService.deleteArticle(article.title); // Uncomment if available.
      } else {
        // await _databaseService.saveArticle(article); // Uncomment if available.
      }
      newsProvider.notifySavedChange();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlySaved ? 'Removed from saved' : 'Article saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling save: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTime(String publishedAt) {
    try {
      final date = DateTime.parse(publishedAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recent';
    }
  }
}