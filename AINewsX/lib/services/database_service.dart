import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/article.dart';

/// Singleton service for managing local SQLite database operations for saved articles.
/// Ensures thread-safety and atomic transactions for reliability.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  static const String _dbName = 'ainewsx.db';
  static const int _dbVersion = 1;

  /// Initializes and returns the database instance.
  /// Creates the articles table if it doesn't exist.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE articles (
            title TEXT PRIMARY KEY,
            description TEXT,
            content TEXT,
            imageUrl TEXT,
            url TEXT,
            publishedAt TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Handle future schema migrations here if needed.
      },
    );
  }

  /// Saves or replaces an article in the database using a transaction for atomicity.
  /// Returns true on success.
  Future<bool> saveArticle(Article article) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.insert(
          'articles',
          article.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      return true;
    } catch (e) {
      print('Database save error: $e'); // Log for debugging; use a logger in production.
      rethrow;
    }
  }

  /// Retrieves all saved articles from the database.
  /// Returns an empty list on error.
  Future<List<Article>> getSavedArticles() async {
    try {
      final db = await database;
      final maps = await db.query('articles', orderBy: 'publishedAt DESC');
      return maps.map((map) => Article.fromJson(map)).toList();
    } catch (e) {
      print('Database query error: $e');
      return [];
    }
  }

  /// Deletes an article by title using a transaction.
  /// Returns true on success.
  Future<bool> deleteArticle(String title) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete(
          'articles',
          where: 'title = ?',
          whereArgs: [title],
        );
      });
      return true;
    } catch (e) {
      print('Database delete error: $e');
      rethrow;
    }
  }

  /// Checks if an article is saved by title.
  /// Returns true if found.
  Future<bool> isArticleSaved(String title) async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM articles WHERE title = ?', [title]),
      );
      return count == 1;
    } catch (e) {
      print('Database check error: $e');
      return false;
    }
  }

  /// Closes the database connection (call in app dispose if needed).
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}