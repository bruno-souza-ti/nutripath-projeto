// lib/screens/logs_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/log_service.dart';
import '../main.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  HistoricoLog? _historico;
  bool _carregando = true;
  String _filtroTipo = 'todos';
  int _usuarioId = 0;
  String _nomeUsuario = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _usuarioId = prefs.getInt('local_usuario_id') ?? 0;
      // Extrai nome do JSON de sessão salvo pelo AuthService
      final rawUser = prefs.getString('user_data');
      if (rawUser != null) {
        try {
          final userData = jsonDecode(rawUser) as Map<String, dynamic>;
          _nomeUsuario = userData['nome'] ?? userData['name'] ?? 'Usuário';
        } catch (_) {
          _nomeUsuario = 'Usuário';
        }
      }

      final hist = await LogService.instance.lerHistorico(_usuarioId, _nomeUsuario);
      if (mounted) setState(() => _historico = hist);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<EntradaLog> get _entradasFiltradas {
    if (_historico == null) return [];
    final entradas = List<EntradaLog>.from(_historico!.entradas)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (_filtroTipo == 'todos') return entradas;
    return entradas
        .where((e) => e.tipo.name == _filtroTipo)
        .toList();
  }

  // ── Diálogo: Registar Suplemento ────────────────────────────────────────

  void _abrirDialogoSuplemento() {
    final nomeCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('💊', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            const Text(
              'Registar Suplemento',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do suplemento',
                  hintText: 'Ex: Whey Protein, Creatina…',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: doseCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dose',
                  hintText: 'Ex: 30 g, 1 cápsula, 5 mg…',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  hintText: 'Ex: Pós-treino com água',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(100, 40),
            ),
            onPressed: () async {
              if (nomeCtrl.text.trim().isEmpty || doseCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Preencha nome e dose')),
                );
                return;
              }
              Navigator.pop(ctx);
              await LogService.instance.logarSuplemento(
                usuarioId: _usuarioId,
                nomeUsuario: _nomeUsuario,
                nome: nomeCtrl.text.trim(),
                dose: doseCtrl.text.trim(),
                observacao: obsCtrl.text.trim(),
              );
              await _carregarDados();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Suplemento registado no log ✓'),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ── Exportar logs ────────────────────────────────────────────────────────

  void _exportarLogs() async {
    if (_historico == null || _historico!.entradas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum registo para exportar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Mostra opção: TXT ou JSON
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('📤', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Exportar Logs', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('Escolha o formato para exportar e partilhar:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.data_object_rounded),
            label: const Text('JSON'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _partilharFicheiro(json: true);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            icon: const Icon(Icons.text_snippet_rounded, color: Colors.white),
            label: const Text('TXT', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _partilharFicheiro(json: false);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _partilharFicheiro({required bool json}) async {
    final caminho = json
        ? await LogService.instance.caminhoArquivoJson(_usuarioId)
        : await LogService.instance.caminhoArquivoTxt(_usuarioId);

    if (caminho == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ficheiro ainda não gerado. Registe algo primeiro.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await Share.shareXFiles(
      [XFile(caminho)],
      subject: 'NutriPath – Histórico de Dieta',
      text: 'Histórico de dieta e suplementação exportado pelo NutriPath AI',
    );
  }

  // ── Limpar histórico ──────────────────────────────────────────────────────

  void _confirmarLimpar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Limpar histórico?'),
        content: const Text(
          'Todos os registos serão apagados dos ficheiros locais. '
          'Esta acção não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await LogService.instance.limparHistorico(_usuarioId, _nomeUsuario);
              await _carregarDados();
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  // ── Mostrar caminho do ficheiro ───────────────────────────────────────────

  void _mostrarCaminhos() async {
    final json = await LogService.instance.caminhoArquivoJson(_usuarioId);
    final txt = await LogService.instance.caminhoArquivoTxt(_usuarioId);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ficheiros locais'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Os logs são guardados nestes ficheiros no dispositivo:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 16),
            _CaminhoCard(label: 'JSON (estruturado)', caminho: json),
            const SizedBox(height: 8),
            _CaminhoCard(label: 'TXT (legível)', caminho: txt),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Logs de Dieta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Exportar logs',
            onPressed: _exportarLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Limpar histórico',
            onPressed: _confirmarLimpar,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Histórico'),
            Tab(text: 'Resumo'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogoSuplemento,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Suplemento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAbaHistorico(),
                _buildAbaResumo(),
              ],
            ),
    );
  }

  // ── Aba: Histórico ────────────────────────────────────────────────────────

  Widget _buildAbaHistorico() {
    final entradas = _entradasFiltradas;
    return Column(
      children: [
        _buildFiltros(),
        Expanded(
          child: entradas.isEmpty
              ? _buildVazio()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: entradas.length,
                  itemBuilder: (_, i) => _EntradaCard(entrada: entradas[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    final opcoes = [
      ('todos', 'Todos', '📋'),
      ('refeicao', 'Refeições', '🍽️'),
      ('suplemento', 'Suplementos', '💊'),
      ('agua', 'Água', '💧'),
      ('peso', 'Peso', '⚖️'),
      ('chat', 'Chat IA', '🤖'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: opcoes.map((op) {
          final selecionado = _filtroTipo == op.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${op.$3} ${op.$2}'),
              selected: selecionado,
              onSelected: (_) => setState(() => _filtroTipo = op.$1),
              selectedColor: AppTheme.accent,
              checkmarkColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: selecionado ? AppTheme.primary : AppTheme.textMedium,
                fontWeight:
                    selecionado ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _filtroTipo == 'suplemento' ? '💊' : '📋',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            _filtroTipo == 'todos'
                ? 'Nenhum registo ainda'
                : 'Sem registos para este filtro',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'As refeições e medições registadas\naparecem aqui automaticamente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  // ── Aba: Resumo ───────────────────────────────────────────────────────────

  Widget _buildAbaResumo() {
    if (_historico == null || _historico!.entradas.isEmpty) {
      return _buildVazio();
    }

    final entradas = _historico!.entradas;
    final refeicoes = entradas.where((e) => e.tipo == TipoEntradaLog.refeicao).length;
    final suplementos = entradas.where((e) => e.tipo == TipoEntradaLog.suplemento).length;
    final agua = entradas.where((e) => e.tipo == TipoEntradaLog.agua).length;
    final peso = entradas.where((e) => e.tipo == TipoEntradaLog.peso).length;
    final chat = entradas.where((e) => e.tipo == TipoEntradaLog.chat).length;

    // Total de calorias somado das entradas de refeição
    int totalCalorias = 0;
    for (final e in entradas.where((e) => e.tipo == TipoEntradaLog.refeicao)) {
      final calStr = (e.detalhes['calorias'] as String?)?.replaceAll(' kcal', '') ?? '0';
      totalCalorias += int.tryParse(calStr) ?? 0;
    }

    // Suplementos únicos
    final nomesSupl = entradas
        .where((e) => e.tipo == TipoEntradaLog.suplemento)
        .map((e) => e.titulo)
        .toSet()
        .toList()
      ..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ResumoCard(
          titulo: 'Total de registos',
          valor: '${entradas.length}',
          subtitulo: 'desde ${_formatarDataCurta(_historico!.criadoEm)}',
          icone: '📊',
          cor: AppTheme.primary,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ResumoCard(
                titulo: 'Refeições',
                valor: '$refeicoes',
                subtitulo: '$totalCalorias kcal total',
                icone: '🍽️',
                cor: const Color(0xFF52B788),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ResumoCard(
                titulo: 'Suplementos',
                valor: '$suplementos',
                subtitulo: '${nomesSupl.length} diferentes',
                icone: '💊',
                cor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ResumoCard(
                titulo: 'Água',
                valor: '$agua',
                subtitulo: 'registos',
                icone: '💧',
                cor: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ResumoCard(
                titulo: 'Pesagens',
                valor: '$peso',
                subtitulo: 'medições',
                icone: '⚖️',
                cor: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ResumoCard(
          titulo: 'Chat com IA',
          valor: '$chat',
          subtitulo: 'mensagens registadas',
          icone: '🤖',
          cor: const Color(0xFF0369A1),
        ),
        if (nomesSupl.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Suplementos Registados',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: nomesSupl.map((nome) => Chip(
              label: Text(nome, style: const TextStyle(fontSize: 12)),
              avatar: const Text('💊'),
              backgroundColor: const Color(0xFFF3E8FF),
            )).toList(),
          ),
        ],
        const SizedBox(height: 20),
        _InfoFicheiro(usuarioId: _usuarioId),
        const SizedBox(height: 100),
      ],
    );
  }

  String _formatarDataCurta(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _EntradaCard extends StatelessWidget {
  final EntradaLog entrada;
  const _EntradaCard({required this.entrada});

  Color get _cor {
    switch (entrada.tipo) {
      case TipoEntradaLog.refeicao:
        return const Color(0xFFD8F3DC);
      case TipoEntradaLog.suplemento:
        return const Color(0xFFF3E8FF);
      case TipoEntradaLog.agua:
        return const Color(0xFFDCEEFD);
      case TipoEntradaLog.peso:
        return const Color(0xFFFFEDED);
      case TipoEntradaLog.chat:
        return const Color(0xFFE0F2FE);
    }
  }

  Color get _corTexto {
    switch (entrada.tipo) {
      case TipoEntradaLog.refeicao:
        return const Color(0xFF2D6A4F);
      case TipoEntradaLog.suplemento:
        return const Color(0xFF6D28D9);
      case TipoEntradaLog.agua:
        return const Color(0xFF1D4ED8);
      case TipoEntradaLog.peso:
        return const Color(0xFFDC2626);
      case TipoEntradaLog.chat:
        return const Color(0xFF0369A1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hora = '${entrada.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entrada.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _cor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(entrada.icone, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _cor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entrada.tipoLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _corTexto,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        hora,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entrada.titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...entrada.detalhes.entries.map(
                    (e) => Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final String icone;
  final Color cor;

  const _ResumoCard({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icone, style: const TextStyle(fontSize: 20)),
              const Spacer(),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}

class _CaminhoCard extends StatelessWidget {
  final String label;
  final String? caminho;
  const _CaminhoCard({required this.label, this.caminho});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  caminho ?? 'Ainda não criado',
                  style: TextStyle(
                    fontSize: 11,
                    color: caminho != null
                        ? AppTheme.textDark
                        : AppTheme.textLight,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (caminho != null)
                GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: caminho!)),
                  child: const Icon(Icons.copy, size: 16, color: AppTheme.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoFicheiro extends StatefulWidget {
  final int usuarioId;
  const _InfoFicheiro({required this.usuarioId});

  @override
  State<_InfoFicheiro> createState() => _InfoFicheiroState();
}

class _InfoFicheiroState extends State<_InfoFicheiro> {
  String? _caminhoJson;
  String? _caminhoTxt;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final j = await LogService.instance.caminhoArquivoJson(widget.usuarioId);
    final t = await LogService.instance.caminhoArquivoTxt(widget.usuarioId);
    if (mounted) setState(() { _caminhoJson = j; _caminhoTxt = t; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.folder_rounded, color: AppTheme.primary, size: 18),
              SizedBox(width: 6),
              Text(
                'Ficheiros no Dispositivo',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _LinhaFicheiro(
            icone: Icons.data_object_rounded,
            label: 'JSON',
            caminho: _caminhoJson,
          ),
          const SizedBox(height: 6),
          _LinhaFicheiro(
            icone: Icons.text_snippet_rounded,
            label: 'TXT',
            caminho: _caminhoTxt,
          ),
        ],
      ),
    );
  }
}

class _LinhaFicheiro extends StatelessWidget {
  final IconData icone;
  final String label;
  final String? caminho;
  const _LinhaFicheiro({
    required this.icone,
    required this.label,
    this.caminho,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          '$label  ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        Expanded(
          child: Text(
            caminho ?? 'Ainda não gerado',
            style: TextStyle(
              fontSize: 11,
              color: caminho != null ? AppTheme.textDark : AppTheme.textLight,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (caminho != null)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: caminho!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Caminho copiado'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.copy, size: 14, color: AppTheme.primary),
            ),
          ),
      ],
    );
  }
}
