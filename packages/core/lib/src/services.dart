import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ===========================================================================
// DatabaseService Region
// ===========================================================================

/// Servicio centralizado genérico para manejar la persistencia local con SQLite.
class DatabaseService {
  Database? _database;

  final String dbName;
  final int version;
  final Future<void> Function(Database, int) onCreate;

  DatabaseService({
    required this.dbName,
    required this.version,
    required this.onCreate,
  });

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: version,
      onCreate: onCreate,
    );
  }
}

// ===========================================================================
// Fin de DatabaseService Region
// ===========================================================================
