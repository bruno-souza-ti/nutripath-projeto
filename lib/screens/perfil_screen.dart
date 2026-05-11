import 'package:flutter/material.dart';
import '../../main.dart';
import '../database/nutri_repository.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = NutriRepository();
  int _usuarioId = 1;

  // Dados do perfil
  String _nome = '';
  String _email = '';
  double _pesoAtual = 0;
  double _alturaAtual = 0;
  double _imcAtual = 0;
  String _objetivo = '';
  bool _isLoading = true;

  // Histórico
  List<Map<String, dynamic>> _historico = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _usuarioId = args['usuarioId'] ?? 1;
    }
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final dados = await _repo.getDashboard(_usuarioId);
    final perfil = await _repo.getPerfil(_usuarioId);
    final historico = await _repo.getHistoricoPeso(_usuarioId);
    setState(() {
      _nome = dados['nome'] ?? 'Usuário';
      _email = perfil['email'] ?? '';
      _pesoAtual = (dados['peso_kg'] as num?)?.toDouble() ?? 0;
      _alturaAtual = (dados['altura_cm'] as num?)?.toDouble() ?? 0;
      _imcAtual = (dados['imc'] as num?)?.toDouble() ?? 0;
      _objetivo = perfil['objetivo'] ?? '';
      _historico = historico;
      _isLoading = false;
    });
  }

  String _imcClassificacao(double imc) {
    if (imc == 0) return '—';
    if (imc < 18.5) return 'Abaixo do peso';
    if (imc < 25.0) return 'Peso normal';
    if (imc < 30.0) return 'Sobrepeso';
    if (imc < 35.0) return 'Obesidade grau I';
    if (imc < 40.0) return 'Obesidade grau II';
    return 'Obesidade grau III';
  }

  Color _imcCor(double imc) {
    if (imc == 0) return AppTheme.textLight;
    if (imc < 18.5) return Colors.orange;
    if (imc < 25.0) return AppTheme.primary;
    if (imc < 30.0) return Colors.orange;
    return Colors.red;
  }

  // ─── DIALOG: Editar Perfil ─────────────────────────────────────────────────
  Future<void> _editarPerfil() async {
    final nomeCtrl = TextEditingController(text: _nome);
    final objetivoCtrl = TextEditingController(text: _objetivo);
    String? objetivoSelecionado = _objetivo.isNotEmpty ? _objetivo : null;

    final objetivos = [
      'Perder peso',
      'Manter peso',
      'Ganhar massa muscular',
      'Melhorar saúde geral',
      'Controlar diabetes',
      'Reduzir colesterol',
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Text('✏️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Editar Perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: objetivoSelecionado,
                  decoration: InputDecoration(
                    labelText: 'Objetivo',
                    prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: objetivos
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => objetivoSelecionado = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(100, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (nomeCtrl.text.trim().isNotEmpty) {
                  await _repo.atualizarPerfil(
                    usuarioId: _usuarioId,
                    nome: nomeCtrl.text.trim(),
                    objetivo: objetivoSelecionado ?? '',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _carregarDados();
                }
              },
              child: const Text('Salvar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DIALOG: Adicionar Medição ─────────────────────────────────────────────
  Future<void> _adicionarMedicao({Map<String, dynamic>? edicao}) async {
    final pesoCtrl = TextEditingController(
        text: edicao != null ? '${edicao['peso_kg']}' : '');
    final alturaCtrl = TextEditingController(
        text: edicao != null
            ? '${(edicao['altura_cm'] as num).toInt()}'
            : _alturaAtual > 0
                ? _alturaAtual.toStringAsFixed(0)
                : '');
    final gorduraCtrl = TextEditingController(
        text: edicao != null && edicao['gordura_corporal'] != null
            ? '${edicao['gordura_corporal']}'
            : '');
    final musculoCtrl = TextEditingController(
        text: edicao != null && edicao['massa_muscular'] != null
            ? '${edicao['massa_muscular']}'
            : '');

    final isEditing = edicao != null;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(isEditing ? '✏️' : '➕',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(isEditing ? 'Editar Medição' : 'Nova Medição',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pesoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Peso (kg)',
                        hintText: 'Ex: 70.5',
                        prefixIcon: const Icon(
                            Icons.monitor_weight_outlined,
                            size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: alturaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Altura (cm)',
                        hintText: 'Ex: 170',
                        prefixIcon: const Icon(Icons.height_rounded, size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: gorduraCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Gordura (%)',
                        hintText: 'Opcional',
                        prefixIcon: const Icon(Icons.percent_rounded, size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: musculoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Músculo (kg)',
                        hintText: 'Opcional',
                        prefixIcon: const Icon(Icons.fitness_center_rounded,
                            size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.primary, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'O IMC é calculado automaticamente com peso e altura.',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final peso =
                  double.tryParse(pesoCtrl.text.replaceAll(',', '.'));
              final altura =
                  double.tryParse(alturaCtrl.text.replaceAll(',', '.'));
              if (peso == null || altura == null || altura <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Preencha peso e altura corretamente.'),
                      backgroundColor: Colors.redAccent),
                );
                return;
              }
              final gordura = double.tryParse(
                  gorduraCtrl.text.replaceAll(',', '.'));
              final musculo = double.tryParse(
                  musculoCtrl.text.replaceAll(',', '.'));

              if (isEditing) {
                await _repo.atualizarMedicao(
                  id: edicao!['id'] as int,
                  pesoKg: peso,
                  alturaCm: altura,
                  gorduraCorporal: gordura,
                  massaMuscular: musculo,
                );
              } else {
                await _repo.registrarPeso(
                  usuarioId: _usuarioId,
                  pesoKg: peso,
                  alturaCm: altura,
                  gorduraCorporal: gordura,
                  massaMuscular: musculo,
                );
              }

              if (ctx.mounted) Navigator.pop(ctx);
              await _carregarDados();
              if (mounted) {
                final imc = peso / ((altura / 100) * (altura / 100));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isEditing
                      ? '✅ Medição atualizada! IMC: ${imc.toStringAsFixed(1)}'
                      : '✅ Medição registrada! IMC: ${imc.toStringAsFixed(1)}'),
                  backgroundColor: AppTheme.primary,
                ));
              }
            },
            child: Text(isEditing ? 'Atualizar' : 'Salvar',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── CONFIRMAR EXCLUSÃO ────────────────────────────────────────────────────
  Future<void> _confirmarExclusao(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir medição?'),
        content: const Text(
            'Essa ação não pode ser desfeita. Deseja continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _repo.deletarMedicao(id);
      await _carregarDados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Medição excluída.'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverHeader()],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPerfilTab(),
                  _buildHistoricoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarMedicao,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nova Medição',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppTheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: _editarPerfil,
          tooltip: 'Editar Perfil',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (_email.isNotEmpty)
                              Text(_email,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13)),
                            if (_objetivo.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '🎯 $_objetivo',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textLight,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2.5,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Meu Perfil'),
          Tab(text: 'Histórico de Medições'),
        ],
      ),
    );
  }

  // ─── ABA 1: PERFIL ─────────────────────────────────────────────────────────
  Widget _buildPerfilTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards de métricas atuais
          _buildSectionTitle('Métricas Atuais'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: '⚖️',
                  label: 'Peso',
                  value: _pesoAtual > 0
                      ? '${_pesoAtual.toStringAsFixed(1)} kg'
                      : '—',
                  color: const Color(0xFF9B59B6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: '📏',
                  label: 'Altura',
                  value: _alturaAtual > 0
                      ? '${_alturaAtual.toStringAsFixed(0)} cm'
                      : '—',
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Card do IMC
          if (_imcAtual > 0) _buildImcCard(),
          const SizedBox(height: 24),

          // Informações do perfil
          _buildSectionTitle('Informações Pessoais'),
          const SizedBox(height: 14),
          _buildInfoCard(),
          const SizedBox(height: 24),

          // Guia de IMC
          _buildSectionTitle('Tabela de IMC'),
          const SizedBox(height: 14),
          _buildImcTable(),
        ],
      ),
    );
  }

  Widget _buildImcCard() {
    final cor = _imcCor(_imcAtual);
    final classificacao = _imcClassificacao(_imcAtual);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _imcAtual.toStringAsFixed(1),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cor),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IMC (Índice de Massa Corporal)',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textLight)),
                const SizedBox(height: 2),
                Text(
                  classificacao,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cor),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_imcAtual / 40).clamp(0.0, 1.0),
                  backgroundColor: cor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(cor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Nome',
              value: _nome),
          const Divider(color: AppTheme.divider, height: 20),
          _InfoRow(
              icon: Icons.mail_outline_rounded,
              label: 'E-mail',
              value: _email.isNotEmpty ? _email : '—'),
          const Divider(color: AppTheme.divider, height: 20),
          _InfoRow(
              icon: Icons.flag_outlined,
              label: 'Objetivo',
              value: _objetivo.isNotEmpty ? _objetivo : 'Não definido'),
          const Divider(color: AppTheme.divider, height: 20),
          _InfoRow(
              icon: Icons.format_list_numbered_rounded,
              label: 'Medições registradas',
              value: '${_historico.length}'),
        ],
      ),
    );
  }

  Widget _buildImcTable() {
    final faixas = [
      {'faixa': 'Abaixo de 18.5', 'class': 'Abaixo do peso', 'cor': Colors.orange},
      {'faixa': '18.5 – 24.9', 'class': 'Peso normal', 'cor': AppTheme.primary},
      {'faixa': '25.0 – 29.9', 'class': 'Sobrepeso', 'cor': Colors.orange},
      {'faixa': '30.0 – 34.9', 'class': 'Obesidade grau I', 'cor': Colors.deepOrange},
      {'faixa': '35.0 – 39.9', 'class': 'Obesidade grau II', 'cor': Colors.red},
      {'faixa': '≥ 40.0', 'class': 'Obesidade grau III', 'cor': Colors.red.shade900},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Faixa de IMC',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMedium)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Classificação',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMedium)),
                ),
              ],
            ),
          ),
          ...faixas.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            final cor = f['cor'] as Color;
            final isDestaque = _imcAtual > 0 &&
                _imcClassificacao(_imcAtual) == f['class'];
            return Container(
              decoration: BoxDecoration(
                color: isDestaque ? cor.withOpacity(0.08) : Colors.transparent,
                border: Border(
                  bottom: i < faixas.length - 1
                      ? const BorderSide(color: AppTheme.divider)
                      : BorderSide.none,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(f['faixa'] as String,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                            fontWeight: isDestaque
                                ? FontWeight.w600
                                : FontWeight.w400)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: cor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(f['class'] as String,
                            style: TextStyle(
                                fontSize: 13,
                                color: cor,
                                fontWeight: FontWeight.w600)),
                        if (isDestaque) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('← você',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── ABA 2: HISTÓRICO ──────────────────────────────────────────────────────
  Widget _buildHistoricoTab() {
    if (_historico.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Nenhuma medição registrada',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMedium)),
            const SizedBox(height: 6),
            const Text('Toque em "Nova Medição" para começar.',
                style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Cabeçalho da tabela
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: AppTheme.divider),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: _ColHeader('Data')),
              Expanded(flex: 2, child: _ColHeader('Peso')),
              Expanded(flex: 2, child: _ColHeader('Altura')),
              Expanded(flex: 2, child: _ColHeader('IMC')),
              SizedBox(width: 60, child: _ColHeader('Ações')),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            children: _historico.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final data = DateTime.parse(r['registrado_em'] as String);
              final imc = (r['imc'] as num?)?.toDouble() ?? 0;
              final cor = _imcCor(imc);
              final isLast = i == _historico.length - 1;

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: isLast
                        ? BorderSide.none
                        : const BorderSide(color: AppTheme.divider),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark),
                          ),
                          Text(
                            '${data.year}',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${(r['peso_kg'] as num).toStringAsFixed(1)} kg',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${(r['altura_cm'] as num).toStringAsFixed(0)} cm',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textMedium),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: cor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          imc.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cor),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _adicionarMedicao(edicao: r),
                            child: const Icon(Icons.edit_outlined,
                                color: AppTheme.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () =>
                                _confirmarExclusao(r['id'] as int),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_historico.length} medição(ões) registrada(s)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: -0.3));
  }
}

// ─── Widgets Auxiliares ────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textLight),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textLight)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMedium));
  }
}
