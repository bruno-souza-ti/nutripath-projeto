// lib/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  // CORREÇÃO: _database não é mais estático em si, mas é gerenciado pela
  // instância singleton. Adicionamos reset() para invalidar o cache
  // entre sessões caso necessário.
  Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Fecha e invalida o banco em cache. Útil ao trocar de usuário
  /// para garantir que não há estado residual na conexão.
  Future<void> resetDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nutripath.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE usuarios ADD COLUMN objetivo TEXT NOT NULL DEFAULT ""',
        );
      } catch (_) {}
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS interview_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          usuario_id INTEGER NOT NULL,
          mensagem TEXT NOT NULL,
          remetente TEXT NOT NULL,
          criado_em TEXT NOT NULL,
          sincronizado INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        senha TEXT NOT NULL,
        objetivo TEXT NOT NULL DEFAULT "",
        criado_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE biometria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        peso_kg REAL NOT NULL,
        altura_cm REAL NOT NULL,
        imc REAL NOT NULL,
        gordura_corporal REAL,
        massa_muscular REAL,
        registrado_em TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE refeicoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        descricao TEXT NOT NULL,
        calorias INTEGER NOT NULL,
        proteinas REAL,
        carboidratos REAL,
        gorduras REAL,
        tipo TEXT NOT NULL,
        registrado_em TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE agua (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        quantidade_ml INTEGER NOT NULL,
        registrado_em TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE metas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL UNIQUE,
        meta_calorias INTEGER NOT NULL DEFAULT 2000,
        meta_agua_ml INTEGER NOT NULL DEFAULT 2000,
        meta_peso_kg REAL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE interview_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        mensagem TEXT NOT NULL,
        remetente TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }
}
