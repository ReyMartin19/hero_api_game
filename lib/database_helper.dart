import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hero_api.db');
    return _database!;
  }

  Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE active_cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_data TEXT,
        state TEXT DEFAULT 'active'
      )
    ''');
    await db.execute('''
      CREATE TABLE bot_active_cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_data TEXT,
        state TEXT DEFAULT 'active'
      )
    ''');
    await db.execute('''
      CREATE TABLE used_cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE favorite_heroes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hero_data TEXT
      )
    ''');
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE api_key(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT
        )
      ''');
        await createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS favorite_heroes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              hero_data TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> saveApiKey(String apiKey) async {
    final db = await database;
    await db.delete('api_key'); // Clear existing API key
    await db.insert('api_key', {'key': apiKey}); // Insert new API key
  }

  Future<String?> getApiKey() async {
    final db = await database;
    final result = await db.query('api_key', limit: 1);

    if (result.isNotEmpty) {
      return result.first['key'] as String;
    } else {
      return null;
    }
  }

  Future<void> saveActiveCards(
    List<Map<String, dynamic>> userCards,
    List<Map<String, dynamic>> botCards,
  ) async {
    final db = await database;

    // Update the state of all existing cards to 'used'
    await db.update('active_cards', {'state': 'used'});
    await db.update('bot_active_cards', {'state': 'used'});

    // Insert new cards with state 'active'
    for (var card in userCards) {
      await db.insert('active_cards', {
        'card_data': json.encode(card),
        'state': 'active',
      });
    }
    for (var card in botCards) {
      await db.insert('bot_active_cards', {
        'card_data': json.encode(card),
        'state': 'active',
      });
    }
  }

  Future<List<Map<String, dynamic>>> getUserActiveCards() async {
    final db = await database;
    final result = await db.query('active_cards');
    return result
        .map<Map<String, dynamic>>(
          (row) => json.decode(row['card_data'] as String),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getBotActiveCards() async {
    final db = await database;
    final result = await db.query('bot_active_cards');
    return result
        .map<Map<String, dynamic>>(
          (row) => json.decode(row['card_data'] as String),
        )
        .toList();
  }

  Future<void> moveCardToUsed(Map<String, dynamic> card) async {
    // Removed logic for moving cards to used_cards
  }

  Future<void> clearActiveCards() async {
    final db = await database;
    await db.delete('active_cards'); // Clear user active cards
    await db.delete('bot_active_cards'); // Clear bot active cards
  }

  Future<void> saveGameState({
    required List<Map<String, dynamic>> userDeck,
    required List<Map<String, dynamic>> botDeck,
    required int userScore,
    required int botScore,
  }) async {
    final db = await database;

    // Clear existing game state
    await clearActiveCards();
    // Removed clearing of used_cards

    // Save user and bot decks
    for (var card in userDeck) {
      await db.insert('active_cards', {'card_data': json.encode(card)});
    }
    for (var card in botDeck) {
      await db.insert('bot_active_cards', {'card_data': json.encode(card)});
    }

    // Save scores
    await db.insert('active_cards', {
      'card_data': json.encode({'userScore': userScore, 'botScore': botScore}),
    });
  }

  Future<Map<String, dynamic>> loadGameState() async {
    final db = await database;

    // Load user and bot decks
    final userDeckResult = await db.query('active_cards');
    final botDeckResult = await db.query('bot_active_cards');

    final userDeck =
        userDeckResult.isNotEmpty
            ? userDeckResult
                .map((row) => json.decode(row['card_data'] as String))
                .where((card) => card != null && card['image']?['url'] != null)
                .toList()
            : [];
    final botDeck =
        botDeckResult.isNotEmpty
            ? botDeckResult
                .map((row) => json.decode(row['card_data'] as String))
                .where((card) => card != null && card['image']?['url'] != null)
                .toList()
            : [];

    // Load scores
    final scoresResult = await db.query('active_cards', limit: 1);
    final scores =
        scoresResult.isNotEmpty
            ? json.decode(scoresResult.first['card_data'] as String)
            : {'userScore': 0, 'botScore': 0};

    return {
      'userDeck': userDeck,
      'botDeck': botDeck,
      'userScore': scores['userScore'] ?? 0,
      'botScore': scores['botScore'] ?? 0,
    };
  }

  Future<void> updateCardState(
    String tableName,
    int cardId,
    String newState,
  ) async {
    final db = await database;
    await db.update(
      tableName,
      {'state': newState},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<List<Map<String, dynamic>>> getActiveCards(String tableName) async {
    final db = await database;
    final result = await db.query(
      tableName,
      where: 'state = ?',
      whereArgs: ['active'],
    );
    return result
        .map<Map<String, dynamic>>(
          (row) => json.decode(row['card_data'] as String),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUsedCardsFromTable(
    String tableName,
  ) async {
    final db = await database;
    final result = await db.query(
      tableName,
      where: 'state = ?',
      whereArgs: ['used'],
    );
    return result
        .map<Map<String, dynamic>>(
          (row) => json.decode(row['card_data'] as String),
        )
        .toList();
  }

  Future<void> addCardToUsed(Map<String, dynamic> card) async {
    final db = await database;
    await db.insert('used_cards', {'card_data': json.encode(card)});
  }

  Future<List<Map<String, dynamic>>> getUsedCards() async {
    final db = await database;
    final result = await db.query('used_cards');
    return result
        .map<Map<String, dynamic>>(
          (row) => json.decode(row['card_data'] as String),
        )
        .toList();
  }

  Future<void> clearUsedCards() async {
    final db = await database;
    await db.delete('used_cards'); // Clear all data from the used_cards table
  }

  Future<void> clearMatchData() async {
    final db = await database;
    await db.delete('used_cards'); // Clear used cards
    await db.delete('active_cards'); // Clear user active cards
    await db.delete('bot_active_cards'); // Clear bot active cards
  }

  Future<void> addFavoriteHero(Map<String, dynamic> hero) async {
    final db = await database;
    await db.insert('favorite_heroes', {'hero_data': json.encode(hero)});
  }

  Future<List<Map<String, dynamic>>> getFavoriteHeroes() async {
    final db = await database;
    final result = await db.query('favorite_heroes');

    debugPrint('Found ${result.length} favorites in database');

    return result
        .map<Map<String, dynamic>>((row) {
          try {
            final hero = json.decode(row['hero_data'] as String);
            debugPrint('Hero ID: ${hero['id']}, DB ID: ${row['id']}');
            return hero;
          } catch (e) {
            debugPrint('Error decoding hero data: $e');
            return {};
          }
        })
        .where((hero) => hero.isNotEmpty)
        .toList();
  }

  Future<void> removeFavoriteHero(int heroId) async {
  final db = await database;
  
  // Get all favorites to find matching hero
  final favorites = await db.query('favorite_heroes');
  
  for (var fav in favorites) {
    try {
      final heroData = json.decode(fav['hero_data'] as String);
      // Compare IDs - handle both String and int types
      if (heroData['id'].toString() == heroId.toString()) {
        // Delete by database row ID
        final rowsDeleted = await db.delete(
          'favorite_heroes',
          where: 'id = ?',
          whereArgs: [fav['id']],
        );
        
        debugPrint('Deleted $rowsDeleted row(s) for hero ID $heroId');
        return;
      }
    } catch (e) {
      debugPrint('Error processing favorite: $e');
    }
  }
  
  debugPrint('Hero ID $heroId not found in database');
  throw Exception('Hero not found in database');
}
}
