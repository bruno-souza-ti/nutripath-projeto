// lib/services/log_service.dart
//
// Responsável por toda a manipulação direta de ficheiros locais:
//   • nutripath_log.json  – histórico estruturado (dieta + suplementação)
//   • nutripath_log.txt   – versão legível para exportação
//
// Dependência externa: path_provider (adicionar ao pubspec.yaml)

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Modelos ──────────────────────────────────────────────────────────────────

enum TipoEntradaLog { refeicao, suplemento, agua, peso, chat }

class EntradaLog {
  final String id;
  final TipoEntradaLog tipo;
  final DateTime timestamp;
  final String titulo;
  final Map<String, dynamic> detalhes;

  EntradaLog({
    required this.id,
    required this.tipo,
    required this.timestamp,
    required this.titulo,
    required this.detalhes,
  });

  factory EntradaLog.fromJson(Map<String, dynamic> json) => EntradaLog(
        id: json['id'] as String,
        tipo: TipoEntradaLog.values.firstWhere(
          (e) => e.name == json['tipo'],
          orElse: () => TipoEntradaLog.refeicao,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        titulo: json['titulo'] as String,
        detalhes: Map<String, dynamic>.from(json['detalhes'] as Map),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.name,
        'timestamp': timestamp.toIso8601String(),
        'titulo': titulo,
        'detalhes': detalhes,
      };

  String get tipoLabel {
    switch (tipo) {
      case TipoEntradaLog.refeicao:
        return 'Refeição';
      case TipoEntradaLog.suplemento:
        return 'Suplemento';
      case TipoEntradaLog.agua:
        return 'Água';
      case TipoEntradaLog.peso:
        return 'Peso';
      case TipoEntradaLog.chat:
        return 'Chat IA';
    }
  }

  String get icone {
    switch (tipo) {
      case TipoEntradaLog.refeicao:
        return '🍽️';
      case TipoEntradaLog.suplemento:
        return '💊';
      case TipoEntradaLog.agua:
        return '💧';
      case TipoEntradaLog.peso:
        return '⚖️';
      case TipoEntradaLog.chat:
        return '🤖';
    }
  }
}

// ─── Estrutura do ficheiro JSON ───────────────────────────────────────────────

class HistoricoLog {
  final int usuarioId;
  final String nomeUsuario;
  final DateTime criadoEm;
  DateTime atualizadoEm;
  final List<EntradaLog> entradas;

  HistoricoLog({
    required this.usuarioId,
    required this.nomeUsuario,
    required this.criadoEm,
    required this.atualizadoEm,
    required this.entradas,
  });

  factory HistoricoLog.novo(int usuarioId, String nomeUsuario) => HistoricoLog(
        usuarioId: usuarioId,
        nomeUsuario: nomeUsuario,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
        entradas: [],
      );

  factory HistoricoLog.fromJson(Map<String, dynamic> json) => HistoricoLog(
        usuarioId: json['usuario_id'] as int,
        nomeUsuario: json['nome_usuario'] as String,
        criadoEm: DateTime.parse(json['criado_em'] as String),
        atualizadoEm: DateTime.parse(json['atualizado_em'] as String),
        entradas: (json['entradas'] as List)
            .map((e) => EntradaLog.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'usuario_id': usuarioId,
        'nome_usuario': nomeUsuario,
        'criado_em': criadoEm.toIso8601String(),
        'atualizado_em': atualizadoEm.toIso8601String(),
        'versao': '1.0',
        'entradas': entradas.map((e) => e.toJson()).toList(),
      };
}

// ─── Serviço ──────────────────────────────────────────────────────────────────

class LogService {
  static final LogService instance = LogService._internal();
  LogService._internal();

  // Retorna o directório de documentos do app (persistente, não limpo pelo SO)
  Future<Directory> get _dir async => getApplicationDocumentsDirectory();

  String _nomeArquivoJson(int usuarioId) => 'nutripath_log_$usuarioId.json';
  String _nomeArquivoTxt(int usuarioId) => 'nutripath_log_$usuarioId.txt';

  Future<File> _arquivoJson(int usuarioId) async {
    final dir = await _dir;
    return File('${dir.path}/${_nomeArquivoJson(usuarioId)}');
  }

  Future<File> _arquivoTxt(int usuarioId) async {
    final dir = await _dir;
    return File('${dir.path}/${_nomeArquivoTxt(usuarioId)}');
  }

  // ── Leitura ──────────────────────────────────────────────────────────────

  Future<HistoricoLog> lerHistorico(int usuarioId, String nomeUsuario) async {
    // Fallback: se id não foi resolvido ainda, busca no SharedPreferences
    if (usuarioId <= 0) {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getInt('local_usuario_id');
      if (savedId != null && savedId > 0) usuarioId = savedId;
      // Tenta extrair nome do JSON de sessão salvo pelo AuthService
      final rawUser = prefs.getString('user_data');
      if (rawUser != null) {
        try {
          final userData = jsonDecode(rawUser) as Map<String, dynamic>;
          final nome = userData['nome'] ?? userData['name'];
          if (nome != null && (nome as String).isNotEmpty) nomeUsuario = nome;
        } catch (_) {}
      }
    }
    final arquivo = await _arquivoJson(usuarioId);

    if (!await arquivo.exists()) {
      return HistoricoLog.novo(usuarioId, nomeUsuario);
    }

    try {
      final conteudo = await arquivo.readAsString();
      final json = jsonDecode(conteudo) as Map<String, dynamic>;
      return HistoricoLog.fromJson(json);
    } catch (_) {
      // Ficheiro corrompido → começa novo
      return HistoricoLog.novo(usuarioId, nomeUsuario);
    }
  }

  // ── Escrita ──────────────────────────────────────────────────────────────

  Future<void> _salvarHistorico(HistoricoLog historico) async {
    final arquivo = await _arquivoJson(historico.usuarioId);
    historico.atualizadoEm = DateTime.now();

    final json = const JsonEncoder.withIndent('  ').convert(historico.toJson());
    await arquivo.writeAsString(json, flush: true);

    // Regenera o .txt sempre que o JSON muda
    await _gerarTxt(historico);
  }

  Future<void> _gerarTxt(HistoricoLog historico) async {
    final arquivo = await _arquivoTxt(historico.usuarioId);
    final buffer = StringBuffer();

    buffer.writeln('╔══════════════════════════════════════════════╗');
    buffer.writeln('║         NutriPath – Histórico de Dieta       ║');
    buffer.writeln('╚══════════════════════════════════════════════╝');
    buffer.writeln();
    buffer.writeln('Utilizador : ${historico.nomeUsuario}');
    buffer.writeln('Gerado em  : ${_formatarData(historico.atualizadoEm)}');
    buffer.writeln('Total de registos: ${historico.entradas.length}');
    buffer.writeln();

    // Agrupa por data
    final Map<String, List<EntradaLog>> porDia = {};
    for (final e in historico.entradas) {
      final chave = _soData(e.timestamp);
      porDia.putIfAbsent(chave, () => []).add(e);
    }

    final diasOrdenados = porDia.keys.toList()..sort((a, b) => b.compareTo(a));

    for (final dia in diasOrdenados) {
      buffer.writeln('──────────────────────────────────────────────');
      buffer.writeln('  📅  $dia');
      buffer.writeln('──────────────────────────────────────────────');

      for (final entrada in porDia[dia]!) {
        buffer.writeln();
        buffer.writeln(
          '  ${entrada.icone}  [${entrada.tipoLabel.toUpperCase()}]  '
          '${_soHora(entrada.timestamp)}',
        );
        buffer.writeln('     ${entrada.titulo}');
        entrada.detalhes.forEach((chave, valor) {
          buffer.writeln('       • $chave: $valor');
        });
      }
      buffer.writeln();
    }

    buffer.writeln('══════════════════════════════════════════════');
    buffer.writeln('  Ficheiro gerado automaticamente pelo NutriPath AI');

    await arquivo.writeAsString(buffer.toString(), flush: true);
  }

  // ── API pública ───────────────────────────────────────────────────────────

  /// Regista uma refeição no log local.
  Future<void> logarRefeicao({
    required int usuarioId,
    required String nomeUsuario,
    required String descricao,
    required int calorias,
    double? proteinas,
    double? carboidratos,
    double? gorduras,
    required String tipo,
  }) async {
    final historico = await lerHistorico(usuarioId, nomeUsuario);

    final detalhes = <String, dynamic>{
      'tipo_refeição': tipo,
      'calorias': '$calorias kcal',
    };
    if (proteinas != null) detalhes['proteínas'] = '${proteinas.toStringAsFixed(1)} g';
    if (carboidratos != null) detalhes['carboidratos'] = '${carboidratos.toStringAsFixed(1)} g';
    if (gorduras != null) detalhes['gorduras'] = '${gorduras.toStringAsFixed(1)} g';

    historico.entradas.add(EntradaLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: TipoEntradaLog.refeicao,
      timestamp: DateTime.now(),
      titulo: descricao,
      detalhes: detalhes,
    ));

    await _salvarHistorico(historico);
  }

  /// Regista um suplemento no log local.
  Future<void> logarSuplemento({
    required int usuarioId,
    required String nomeUsuario,
    required String nome,
    required String dose,
    String? observacao,
  }) async {
    final historico = await lerHistorico(usuarioId, nomeUsuario);

    final detalhes = <String, dynamic>{'dose': dose};
    if (observacao != null && observacao.isNotEmpty) {
      detalhes['observação'] = observacao;
    }

    historico.entradas.add(EntradaLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: TipoEntradaLog.suplemento,
      timestamp: DateTime.now(),
      titulo: nome,
      detalhes: detalhes,
    ));

    await _salvarHistorico(historico);
  }

  /// Regista consumo de água.
  Future<void> logarAgua({
    required int usuarioId,
    required String nomeUsuario,
    required int quantidadeMl,
  }) async {
    final historico = await lerHistorico(usuarioId, nomeUsuario);

    historico.entradas.add(EntradaLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: TipoEntradaLog.agua,
      timestamp: DateTime.now(),
      titulo: 'Consumo de Água',
      detalhes: {'quantidade': '$quantidadeMl ml'},
    ));

    await _salvarHistorico(historico);
  }

  /// Regista medição de peso/biometria.
  Future<void> logarPeso({
    required int usuarioId,
    required String nomeUsuario,
    required double pesoKg,
    required double alturaCm,
    required double imc,
    double? gorduraCorporal,
    double? massaMuscular,
  }) async {
    final historico = await lerHistorico(usuarioId, nomeUsuario);

    final detalhes = <String, dynamic>{
      'peso': '${pesoKg.toStringAsFixed(1)} kg',
      'altura': '${alturaCm.toStringAsFixed(0)} cm',
      'IMC': imc.toStringAsFixed(1),
    };
    if (gorduraCorporal != null) {
      detalhes['gordura corporal'] = '${gorduraCorporal.toStringAsFixed(1)}%';
    }
    if (massaMuscular != null) {
      detalhes['massa muscular'] = '${massaMuscular.toStringAsFixed(1)} kg';
    }

    historico.entradas.add(EntradaLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: TipoEntradaLog.peso,
      timestamp: DateTime.now(),
      titulo: 'Medição de Peso',
      detalhes: detalhes,
    ));

    await _salvarHistorico(historico);
  }

  /// Regista mensagem do chat com a IA.
  Future<void> logarMensagemChat({
    required int usuarioId,
    required String nomeUsuario,
    required String mensagem,
    required String remetente, // 'usuario' ou 'ia'
  }) async {
    final historico = await lerHistorico(usuarioId, nomeUsuario);

    final titulo = remetente == 'usuario' ? 'Você' : 'NutriPath IA';
    // Trunca mensagens longas no título
    final preview = mensagem.length > 80
        ? '${mensagem.substring(0, 80)}…'
        : mensagem;

    historico.entradas.add(EntradaLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: TipoEntradaLog.chat,
      timestamp: DateTime.now(),
      titulo: titulo,
      detalhes: {'mensagem': preview, 'de': remetente},
    ));

    await _salvarHistorico(historico);
  }

  /// Remove todas as entradas do utilizador.
  Future<void> limparHistorico(int usuarioId, String nomeUsuario) async {
    final historico = HistoricoLog.novo(usuarioId, nomeUsuario);
    await _salvarHistorico(historico);
  }

  /// Retorna o caminho do ficheiro .txt para partilha/exibição.
  Future<String?> caminhoArquivoTxt(int usuarioId) async {
    final arquivo = await _arquivoTxt(usuarioId);
    return (await arquivo.exists()) ? arquivo.path : null;
  }

  /// Retorna o caminho do ficheiro .json.
  Future<String?> caminhoArquivoJson(int usuarioId) async {
    final arquivo = await _arquivoJson(usuarioId);
    return (await arquivo.exists()) ? arquivo.path : null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatarData(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _soData(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  String _soHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}
