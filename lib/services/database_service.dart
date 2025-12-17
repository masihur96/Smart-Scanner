import 'package:path/path.dart';
import 'package:smart_qr/models/scan_model.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_qr.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rawValue TEXT,
            type INTEGER,
            timestamp TEXT,
            isFavorite INTEGER
          )
        ''');
      },
    );
  }

  Future<int> insertScan(ScanModel scan) async {
    final db = await database;
    return await db.insert('history', scan.toMap());
  }

  Future<List<ScanModel>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ScanModel.fromMap(maps[i]));
  }

  Future<int> deleteScan(int id) async {
    final db = await database;
    return await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearHistory() async {
    final db = await database;
    return await db.delete('history');
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'history',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
