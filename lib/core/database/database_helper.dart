import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/anime_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'anime_hat.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Anime Table
    await db.execute('''
      CREATE TABLE animes (
        id TEXT PRIMARY KEY,
        animeId TEXT,
        enTitle TEXT,
        jpTitle TEXT,
        arTitle TEXT,
        synonyms TEXT,
        genres TEXT,
        season TEXT,
        premiered TEXT,
        aired TEXT,
        broadcast TEXT,
        duration TEXT,
        thumbnail TEXT,
        trailer TEXT,
        ytTrailer TEXT,
        creators TEXT,
        status TEXT,
        episodes TEXT,
        score TEXT,
        rank TEXT,
        popularity TEXT,
        rating TEXT,
        type TEXT,
        views TEXT,
        malId TEXT
      )
    ''');

    // Episodes Table
    await db.execute('''
      CREATE TABLE episodes (
        eId TEXT PRIMARY KEY,
        animeId TEXT,
        episodeNumber TEXT,
        okLink TEXT,
        maLink TEXT,
        frLink TEXT,
        gdLink TEXT,
        svLink TEXT,
        released TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_episodes_animeId ON episodes(animeId)');

    // News Table
    await db.execute('''
      CREATE TABLE news_items (
        id TEXT PRIMARY KEY,
        title TEXT,
        glance TEXT,
        date TEXT,
        thumbnail TEXT,
        views TEXT,
        editorName TEXT,
        editorImage TEXT
      )
    ''');

    // Trending Items Table
    await db.execute('''
      CREATE TABLE trending_items (
        id TEXT PRIMARY KEY,
        title TEXT,
        photo TEXT,
        type TEXT,
        animeId TEXT,
        episodeId TEXT
      )
    ''');
  }

  // --- Anime Operations ---
  Future<void> insertAnime(Anime anime) async {
    final db = await database;
    await db.insert(
      'animes',
      anime.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAnimes(List<Anime> animes) async {
    final db = await database;
    final batch = db.batch();
    for (var anime in animes) {
      batch.insert(
        'animes',
        anime.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Anime?> getAnime(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'animes',
      where: 'id = ? OR animeId = ?',
      whereArgs: [id, id],
    );
    if (maps.isEmpty) return null;
    return Anime.fromJson(maps.first);
  }

  Future<List<Anime>> getAllAnimes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('animes');
    return maps.map((json) => Anime.fromJson(json)).toList();
  }

  // --- Episode Operations ---
  Future<void> insertEpisodes(List<Episode> episodes) async {
    final db = await database;
    final batch = db.batch();
    for (var ep in episodes) {
      batch.insert(
        'episodes',
        ep.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Episode>> getEpisodes(String animeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'episodes',
      where: 'animeId = ?',
      whereArgs: [animeId],
    );
    return maps.map((json) => Episode.fromJson(json)).toList();
  }

  // --- News Operations ---
  Future<void> insertNews(List<NewsItem> news) async {
    final db = await database;
    final batch = db.batch();
    for (var item in news) {
      batch.insert(
        'news_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<NewsItem>> getNews() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('news_items');
    return maps.map((json) => NewsItem.fromJson(json)).toList();
  }

  // --- Utility ---
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('animes');
    await db.delete('episodes');
    await db.delete('news_items');
    await db.delete('trending_items');
  }
}
