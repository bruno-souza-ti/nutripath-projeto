import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nutripath.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
            'ALTER TABLE usuarios ADD COLUMN objetivo TEXT NOT NULL DEFAULT ""');
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de usuários
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

    // Tabela de biometria
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

    // Tabela de refeições
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

    // Tabela de consumo de água
    await db.execute('''
      CREATE TABLE agua (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        quantidade_ml INTEGER NOT NULL,
        registrado_em TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    // Tabela de metas diárias
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

    // Inserir usuário de teste
    await db.insert('usuarios', {
      'nome': 'Ana',
      'email': 'ana@email.com',
      'senha': '123456',
      'criado_em': DateTime.now().toIso8601String(),
    });

    // Inserir metas padrão para o usuário de teste
    await db.insert('metas', {
      'usuario_id': 1,
      'meta_calorias': 2000,
      'meta_agua_ml': 2000,
      'meta_peso_kg': 62.0,
    });

    // Inserir biometria inicial
    await db.insert('biometria', {
      'usuario_id': 1,
      'peso_kg': 65.4,
      'altura_cm': 169.0,
      'imc': 22.8,
      'gordura_corporal': 22.4,
      'massa_muscular': 45.2,
      'registrado_em': DateTime.now().toIso8601String(),
    });

    // Inserir consumo de água de hoje
    await db.insert('agua', {
      'usuario_id': 1,
      'quantidade_ml': 1200,
      'registrado_em': DateTime.now().toIso8601String(),
    });

    // Inserir refeições de hoje
    final hoje = DateTime.now().toIso8601String();
    await db.insert('refeicoes', {
      'usuario_id': 1,
      'descricao': 'Café da manhã - Aveia com frutas',
      'calorias': 350,
      'proteinas': 10.0,
      'carboidratos': 55.0,
      'gorduras': 8.0,
      'tipo': 'cafe_manha',
      'registrado_em': hoje,
    });
    await db.insert('refeicoes', {
      'usuario_id': 1,
      'descricao': 'Almoço - Frango grelhado com salada',
      'calorias': 520,
      'proteinas': 38.0,
      'carboidratos': 30.0,
      'gorduras': 12.0,
      'tipo': 'almoco',
      'registrado_em': hoje,
    });
    await db.insert('refeicoes', {
      'usuario_id': 1,
      'descricao': 'Lanche - Iogurte com granola',
      'calorias': 280,
      'proteinas': 12.0,
      'carboidratos': 40.0,
      'gorduras': 6.0,
      'tipo': 'lanche',
      'registrado_em': hoje,
    });
    await db.insert('refeicoes', {
      'usuario_id': 1,
      'descricao': 'Jantar - Salmão com legumes',
      'calorias': 310,
      'proteinas': 30.0,
      'carboidratos': 20.0,
      'gorduras': 10.0,
      'tipo': 'jantar',
      'registrado_em': hoje,
    });
  }
}
