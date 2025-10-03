// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'models/article.dart';
import 'providers/theme_provider.dart';
import 'providers/news_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/category_screen.dart'; // Explicit import for CategoryScreen class.
import 'screens/search_screen.dart';
import 'screens/fake_news_screen.dart';
import 'screens/saved_articles_screen.dart';
import 'screens/country_news_screen.dart';
import 'screens/news_detail_screen.dart';
import 'screens/chat_screen.dart'; // New import for ChatScreen.
import 'utils/theme.dart';
import 'utils/timeago_locales.dart';

/// Initializes sqflite for desktop/web platforms.
void initializeSqflite() {
  if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeSqflite(); // Initialize sqflite for cross-platform support.
  // Set up timeago localizations for Hindi and Gujarati
  timeago.setLocaleMessages('hi', HindiMessages());
  timeago.setLocaleMessages('gu', GujaratiMessages());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        // Handle dynamic routes with arguments.
        if (settings.name == '/category') {
          final category = settings.arguments as String? ?? 'Technology News';
          return MaterialPageRoute(
            builder: (context) => CategoryScreen(category: category), // Fixed: Direct class instantiation.
          );
        }
        if (settings.name == '/article') {
          final article = settings.arguments as Article?;
          if (article == null) {
            // Fallback to empty article or error screen.
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Article not found')),
              ),
            );
          }
          return MaterialPageRoute(
            builder: (context) => NewsDetailScreen(article: article),
          );
        }
        // Default routes.
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/search': (context) => const SearchScreen(),
        '/fake_news': (context) => const FakeNewsScreen(),
        '/saved_articles': (context) => const SavedArticlesScreen(),
        '/country_news': (context) => const CountryNewsScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/chat': (context) => const ChatScreen(), // New route for AI News Bot chat.
      },
    );
  }
}