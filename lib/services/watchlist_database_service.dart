import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/watchlist_item.dart';

class WatchlistDatabaseService {
  final String? databasePath;
  Database? _db;

  WatchlistDatabaseService({this.databasePath});

  Future<Database> get _database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final path = databasePath ?? '${await getDatabasesPath()}/watchlist.db';
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE watchlist (
            id    INTEGER PRIMARY KEY,
            data  TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<WatchlistItem>> getWatchlist() async {
    final db = await _database;
    final rows = await db.query('watchlist');
    return rows
        .map((row) => WatchlistItem.fromJson(jsonDecode(row['data'] as String)))
        .toList();
  }

  Future<void> saveWatchlist(List<WatchlistItem> items) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('watchlist');
      for (final item in items) {
        await txn.insert('watchlist', {
          'id':   item.serie.id,
          'data': jsonEncode(item.toJson()),
        });
      }
    });
  }

  Future<void> clearWatchlist() async {
    final db = await _database;
    await db.delete('watchlist');
  }

  Future<void> close() async => _db?.close();
}
