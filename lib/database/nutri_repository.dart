// lib/database/nutri_repository.dart

import '../database/database_helper.dart';

class NutriRepository {
  final _db = DatabaseHelper.instance;

  // ─── USUÁRIO ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> login(String email, String senha) async {
    final db = await _db.database;
    final result = await db.query(
      'usuarios',
      where: 'email = ? AND senha = ?',
      whereArgs: [email, senha],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> cadastrarUsuario(String nome, String email, String senha) async {
    final db = await _db.database;
    final id = await db.insert('usuarios', {
      'nome': nome,
      'email': email,
      'senha': senha,
      'criado_em': DateTime.now().toIso8601String(),
    });
    await db.insert('metas', {
      'usuario_id': id,
      'meta_calorias': 2000,
      'meta_agua_ml': 2000,
    });
    return id;
  }

  /// Retorna o ID local (SQLite) do usuário identificado pelo e-mail.
  /// Se não existir, cria o registro. Garante isolamento de dados por conta.
  ///
  /// CORREÇÃO: usa transação para evitar race condition de inserção dupla
  /// caso o método seja chamado simultaneamente.
  Future<int> getOuCriarUsuarioLocal({
    required String email,
    required String nome,
  }) async {
    final db = await _db.database;

    return await db.transaction((txn) async {
      final existing = await txn.query(
        'usuarios',
        columns: ['id'],
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existing.isNotEmpty) {
        final id = existing.first['id'] as int;
        await txn.update(
          'usuarios',
          {'nome': nome},
          where: 'id = ?',
          whereArgs: [id],
        );
        return id;
      }

      final id = await txn.insert('usuarios', {
        'nome': nome,
        'email': email,
        'senha': '',
        'objetivo': '',
        'criado_em': DateTime.now().toIso8601String(),
      });

      await txn.insert('metas', {
        'usuario_id': id,
        'meta_calorias': 2000,
        'meta_agua_ml': 2000,
      });

      return id;
    });
  }

  Future<Map<String, dynamic>> getPerfil(int usuarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
    if (result.isEmpty) return {};
    return Map<String, dynamic>.from(result.first);
  }

  Future<void> atualizarPerfil({
    required int usuarioId,
    required String nome,
    required String objetivo,
  }) async {
    final db = await _db.database;
    await db.update(
      'usuarios',
      {'nome': nome, 'objetivo': objetivo},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }

  // ─── DASHBOARD ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboard(int usuarioId) async {
    final db = await _db.database;

    return await db.transaction((txn) async {
      final hoje = DateTime.now();
      final inicioDia = DateTime(
        hoje.year,
        hoje.month,
        hoje.day,
      ).toIso8601String();
      final fimDia = DateTime(
        hoje.year,
        hoje.month,
        hoje.day,
        23,
        59,
        59,
      ).toIso8601String();

      final caloriasResult = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(calorias), 0) as total
        FROM refeicoes
        WHERE usuario_id = ? AND registrado_em BETWEEN ? AND ?
      ''',
        [usuarioId, inicioDia, fimDia],
      );

      final aguaResult = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(quantidade_ml), 0) as total
        FROM agua
        WHERE usuario_id = ? AND registrado_em BETWEEN ? AND ?
      ''',
        [usuarioId, inicioDia, fimDia],
      );

      final biometria = await txn.query(
        'biometria',
        where: 'usuario_id = ?',
        whereArgs: [usuarioId],
        orderBy: 'registrado_em DESC',
        limit: 1,
      );

      final metas = await txn.query(
        'metas',
        where: 'usuario_id = ?',
        whereArgs: [usuarioId],
      );

      final usuario = await txn.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [usuarioId],
      );

      return {
        'nome': usuario.isNotEmpty ? usuario.first['nome'] : 'Usuário',
        'calorias_consumidas':
            (caloriasResult.first['total'] as num?)?.toInt() ?? 0,
        'meta_calorias': metas.isNotEmpty ? metas.first['meta_calorias'] : 2000,
        'agua_ml': (aguaResult.first['total'] as num?)?.toInt() ?? 0,
        'meta_agua_ml': metas.isNotEmpty ? metas.first['meta_agua_ml'] : 2000,
        'peso_kg':
            (biometria.isNotEmpty ? biometria.first['peso_kg'] : 0.0)
                as double? ??
            0.0,
        'altura_cm':
            (biometria.isNotEmpty ? biometria.first['altura_cm'] : 0.0)
                as double? ??
            0.0,
        'imc':
            (biometria.isNotEmpty ? biometria.first['imc'] : 0.0) as double? ??
            0.0,
        'gordura_corporal':
            (biometria.isNotEmpty ? biometria.first['gordura_corporal'] : 0.0)
                as double? ??
            0.0,
        'massa_muscular':
            (biometria.isNotEmpty ? biometria.first['massa_muscular'] : 0.0)
                as double? ??
            0.0,
      };
    });
  }

  // ─── REFEIÇÕES ────────────────────────────────────────────────────────────

  Future<int> registrarRefeicao({
    required int usuarioId,
    required String descricao,
    required int calorias,
    double? proteinas,
    double? carboidratos,
    double? gorduras,
    required String tipo,
  }) async {
    final db = await _db.database;
    return await db.insert('refeicoes', {
      'usuario_id': usuarioId,
      'descricao': descricao,
      'calorias': calorias,
      'proteinas': proteinas,
      'carboidratos': carboidratos,
      'gorduras': gorduras,
      'tipo': tipo,
      'registrado_em': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getRefeicoesDe(
    int usuarioId,
    DateTime data,
  ) async {
    final db = await _db.database;
    final inicio = DateTime(data.year, data.month, data.day).toIso8601String();
    final fim = DateTime(
      data.year,
      data.month,
      data.day,
      23,
      59,
      59,
    ).toIso8601String();
    return await db.query(
      'refeicoes',
      where: 'usuario_id = ? AND registrado_em BETWEEN ? AND ?',
      whereArgs: [usuarioId, inicio, fim],
      orderBy: 'registrado_em ASC',
    );
  }

  Future<void> deletarRefeicao(int id) async {
    final db = await _db.database;
    await db.delete('refeicoes', where: 'id = ?', whereArgs: [id]);
  }

  // ─── ÁGUA ─────────────────────────────────────────────────────────────────

  Future<int> registrarAgua(int usuarioId, int quantidadeMl) async {
    final db = await _db.database;
    return await db.insert('agua', {
      'usuario_id': usuarioId,
      'quantidade_ml': quantidadeMl,
      'registrado_em': DateTime.now().toIso8601String(),
    });
  }

  // ─── PESO / BIOMETRIA ─────────────────────────────────────────────────────

  Future<int> registrarPeso({
    required int usuarioId,
    required double pesoKg,
    required double alturaCm,
    double? gorduraCorporal,
    double? massaMuscular,
  }) async {
    final db = await _db.database;
    final imc = pesoKg / ((alturaCm / 100) * (alturaCm / 100));
    return await db.insert('biometria', {
      'usuario_id': usuarioId,
      'peso_kg': pesoKg,
      'altura_cm': alturaCm,
      'imc': double.parse(imc.toStringAsFixed(1)),
      'gordura_corporal': gorduraCorporal,
      'massa_muscular': massaMuscular,
      'registrado_em': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHistoricoPeso(int usuarioId) async {
    final db = await _db.database;
    return await db.query(
      'biometria',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'registrado_em DESC',
      limit: 30,
    );
  }

  Future<void> atualizarMedicao({
    required int id,
    required double pesoKg,
    required double alturaCm,
    double? gorduraCorporal,
    double? massaMuscular,
  }) async {
    final db = await _db.database;
    final imc = pesoKg / ((alturaCm / 100) * (alturaCm / 100));
    await db.update(
      'biometria',
      {
        'peso_kg': pesoKg,
        'altura_cm': alturaCm,
        'imc': double.parse(imc.toStringAsFixed(1)),
        'gordura_corporal': gorduraCorporal,
        'massa_muscular': massaMuscular,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletarMedicao(int id) async {
    final db = await _db.database;
    await db.delete('biometria', where: 'id = ?', whereArgs: [id]);
  }

  // ─── METAS ────────────────────────────────────────────────────────────────

  Future<void> atualizarMetas({
    required int usuarioId,
    int? metaCalorias,
    int? metaAguaMl,
    double? metaPesoKg,
  }) async {
    final db = await _db.database;
    final updates = <String, dynamic>{};
    if (metaCalorias != null) updates['meta_calorias'] = metaCalorias;
    if (metaAguaMl != null) updates['meta_agua_ml'] = metaAguaMl;
    if (metaPesoKg != null) updates['meta_peso_kg'] = metaPesoKg;
    await db.update(
      'metas',
      updates,
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );
  }

  // ─── INTERVIEW LOGS (Chat com IA) ─────────────────────────────────────────

  Future<int> salvarMensagemChat({
    required int usuarioId,
    required String mensagem,
    required String remetente,
  }) async {
    final db = await _db.database;
    return await db.insert('interview_logs', {
      'usuario_id': usuarioId,
      'mensagem': mensagem,
      'remetente': remetente,
      'criado_em': DateTime.now().toIso8601String(),
      'sincronizado': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getHistoricoChat(int usuarioId) async {
    final db = await _db.database;
    return await db.query(
      'interview_logs',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'criado_em ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getMensagensPendentes(
    int usuarioId,
  ) async {
    final db = await _db.database;
    return await db.query(
      'interview_logs',
      where: 'usuario_id = ? AND sincronizado = 0',
      whereArgs: [usuarioId],
      orderBy: 'criado_em ASC',
    );
  }

  Future<void> marcarMensagensComoSincronizadas(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _db.database;
    final placeholders = ids.map((_) => '?').join(', ');
    await db.rawUpdate(
      'UPDATE interview_logs SET sincronizado = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  Future<void> limparHistoricoChat(int usuarioId) async {
    final db = await _db.database;
    await db.delete(
      'interview_logs',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );
  }
}
