import 'package:core/core.dart';
import 'package:flutter/material.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  late final DatabaseService _dbService;

  factory AppDatabase() {
    return _instance;
  }

  AppDatabase._internal() {
    _dbService = DatabaseService(
      dbName: 'petcare.db',
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<Database> get database => _dbService.database;

  Future<void> _onCreate(Database db, int version) async {
    // 1. Crear esquema de base de datos (Tablas)
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        correo TEXT,
        contrasena TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        edad INTEGER,
        raza TEXT,
        peso REAL,
        imagen INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        avatar_path TEXT
      )
    ''');

    // 2. Poblar con datos de iniciales
    await _seedInitialData(db);
  }

  /// Verifica las credenciales del usuario y retorna un mapa con sus datos si son correctas.
  /// Si no coinciden, retorna null.
  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'correo = ? AND contrasena = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  /// Retorna la lista de mascotas registradas.
  Future<List<Map<String, dynamic>>> getPets() async {
    final db = await database;
    return await db.query('pets');
  }

  /// Obtiene el perfil del usuario combinando datos con la tabla users.
  Future<Map<String, dynamic>?> getProfile(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT p.id, p.user_id, p.avatar_path, u.nombre, u.correo
      FROM profiles p
      INNER JOIN users u ON p.user_id = u.id
      WHERE p.user_id = ?
    ''',
      [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // DATOS INICIALES (SEED)
  // ---------------------------------------------------------------------------

  /// Inserta datos de prueba (mock) al inicializar la base de datos por primera vez.
  Future<void> _seedInitialData(Database db) async {
    // Insertar usuario base
    await db.insert('users', {
      'id': 1,
      'nombre': 'Administrador',
      'correo': 'admin@petcare.com',
      'contrasena': 'PetCare123*',
    });

    // Insertar mascotas base
    final mascotas = [
      {
        'nombre': 'Firulais',
        'edad': 3,
        'raza': 'Mestizo',
        'peso': 12.5,
        'imagen': Icons.pets.codePoint,
      },
      {
        'nombre': 'Luna',
        'edad': 2,
        'raza': 'Golden Retriever',
        'peso': 20.0,
        'imagen': Icons.cruelty_free.codePoint,
      },
      {
        'nombre': 'Max',
        'edad': 5,
        'raza': 'Bulldog',
        'peso': 18.2,
        'imagen': Icons.shield.codePoint,
      },
      {
        'nombre': 'Rocky',
        'edad': 1,
        'raza': 'Pastor Alemán',
        'peso': 15.0,
        'imagen': Icons.bolt.codePoint,
      },
    ];

    for (var mascota in mascotas) {
      await db.insert('pets', mascota);
    }

    // Insertar perfil base para el Administrador (id = 1)
    await db.insert('profiles', {
      'user_id': 1,
      'avatar_path': 'images/avatar.png',
    });
  }
}
