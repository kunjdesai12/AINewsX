// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../providers/theme_provider.dart';
import '../models/article.dart'; // Added for Article type in news list.
import 'categories_screen.dart';
import 'country_news_screen.dart';
import 'fake_news_screen.dart';
import 'news_detail_screen.dart'; // Added for navigating to article details.
import 'chat_screen.dart';  // New import for chat navigation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  static const int _infiniteScrollCount = 10000;
  bool _isAutoScrollEnabled = true;

  final List<String> _imagePaths = [
    'lib/assets/news_banner_0.jpg',
    'lib/assets/news_banner_1.jpg',
    'lib/assets/news_banner_2.jpg',
    'lib/assets/news_banner_3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = _infiniteScrollCount ~/ 2;
    _pageController = PageController(initialPage: _currentPage);
    _startAutoScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NewsProvider>(context, listen: false).fetchNewsForCategory('general');
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isAutoScrollEnabled && _pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrollEnabled = !_isAutoScrollEnabled;
      if (!_isAutoScrollEnabled) {
        _autoScrollTimer?.cancel();
      } else {
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentImageIndex = _currentPage % _imagePaths.length;
    final newsProvider = Provider.of<NewsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final List<Article>? generalNews = newsProvider.newsByCategory['general'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AINewsX',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search News',
            onPressed: () => Navigator.pushNamed(context, '/search'),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FakeNewsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.public, color: Colors.blue),
              title: const Text('Top News by Country'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CountryNewsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.green),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
              },
            ),
            // New: Chat with AI News Bot entry
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
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => newsProvider.fetchNewsForCategory('general'),
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

              // Dynamic auto-scrolling banner (Always visible)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _infiniteScrollCount,
                  itemBuilder: (context, index) {
                    final actualIndex = index % _imagePaths.length;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            _imagePaths[actualIndex],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image, size: 48, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        // Overlay gradient for readability
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        // Play/Pause button
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: InkWell(
                              onTap: _toggleAutoScroll,
                              child: Icon(
                                _isAutoScrollEnabled ? Icons.pause : Icons.play_arrow,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Dots indicator
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_imagePaths.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: currentImageIndex == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: currentImageIndex == index
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Top News by Country Hero Card (Always visible)
              _buildTopNewsByCountryCard(context),

              // Combined Categories and Fake News Row (Always visible)
              _buildFeatureCardsRow(context),

              // Latest News Section (Conditional: Loading, Error, Empty, or List)
              const SizedBox(height: 16),
              _buildLatestNewsSection(context, newsProvider),

              // Subtle bottom spacer for perfect scroll end.
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the Latest News section: Shows skeleton on load, error banner on fail, list on success, empty on none.
  Widget _buildLatestNewsSection(BuildContext context, NewsProvider newsProvider) {
    final List<Article>? generalNews = newsProvider.newsByCategory['general'];

    if (newsProvider.isLoading) {
      return _buildNewsSkeleton(context); // Professional skeleton loader.
    } else if (newsProvider.errorMessage != null) {
      return _buildErrorBanner(context, newsProvider); // Inline error banner.
    } else if (generalNews == null || generalNews.isEmpty) {
      return _buildEmptyNewsCard(context); // Subtle empty state.
    } else {
      return _buildNewsList(context, generalNews); // Actual news cards.
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
          itemCount: 3, // Show 3 placeholders.
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

  /// Inline dismissible error banner for offline/network issues.
  Widget _buildErrorBanner(BuildContext context, NewsProvider newsProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => newsProvider.fetchNewsForCategory('general'), // Tap to retry.
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
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
                      newsProvider.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => newsProvider.fetchNewsForCategory('general'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  Widget _buildEmptyNewsCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.article_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No latest news available',
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

  /// List of latest news articles (compact cards).
  Widget _buildNewsList(BuildContext context, List<Article> articles) {
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
              Text(
                'Latest News',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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

  String _formatTime(String publishedAt) {
    // Simple time formatting; use timeago if needed.
    try {
      final date = DateTime.parse(publishedAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recent';
    }
  }

  /// Builds a professional hero card for Top News by Country (unchanged).
  Widget _buildTopNewsByCountryCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CountryNewsScreen(),
              settings: const RouteSettings(name: '/country_news'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.public,
                  size: 28,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Top News by Country',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore global headlines from your favorite countries',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a professional row of feature cards for Categories and Fake News Detection.
  Widget _buildFeatureCardsRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoriesRowCard(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildFakeNewsRowCard(context),
          ),
        ],
      ),
    );
  }

  /// Builds a compact professional card for Categories in the row.
  Widget _buildCategoriesRowCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoriesScreen(),
              settings: const RouteSettings(name: '/categories'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.green.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.category,
                  size: 24,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Browse all news',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a compact professional card for Fake News Detection in the row.
  Widget _buildFakeNewsRowCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FakeNewsScreen(),
              settings: const RouteSettings(name: '/fake_news'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.red.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.report,
                  size: 24,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fake News Detection',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Analyze with AI',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}