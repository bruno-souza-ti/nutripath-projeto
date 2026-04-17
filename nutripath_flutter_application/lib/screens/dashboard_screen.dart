import 'package:flutter/material.dart';
import '../../main.dart';
import '../database/nutri_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _repo = NutriRepository();
  int _usuarioId = 1;

  // Dados do SQLite
  String _userName = '';
  double _waterProgress = 0;
  double _calorieProgress = 0;
  int _consumedCalories = 0;
  int _goalCalories = 2000;
  int _goalAguaMl = 2000;
  int _aguaMl = 0;
  double _weightKg = 0;
  double _alturaCm = 0;
  double _bmiValue = 0;
  double _gorduraCorporal = 0;
  double _massaMuscular = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
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
    setState(() {
      _userName = dados['nome'] ?? 'Usuário';
      _consumedCalories = dados['calorias_consumidas'] ?? 0;
      _goalCalories = dados['meta_calorias'] ?? 2000;
      _aguaMl = dados['agua_ml'] ?? 0;
      _goalAguaMl = dados['meta_agua_ml'] ?? 2000;
      _weightKg = (dados['peso_kg'] as num?)?.toDouble() ?? 0;
      _alturaCm = (dados['altura_cm'] as num?)?.toDouble() ?? 0;
      _bmiValue = (dados['imc'] as num?)?.toDouble() ?? 0;
      _gorduraCorporal = (dados['gordura_corporal'] as num?)?.toDouble() ?? 0;
      _massaMuscular = (dados['massa_muscular'] as num?)?.toDouble() ?? 0;
      _calorieProgress = _goalCalories > 0 ? _consumedCalories / _goalCalories : 0;
      _waterProgress = _goalAguaMl > 0 ? _aguaMl / _goalAguaMl : 0;
      _isLoading = false;
    });
  }

  Future<void> _registrarAgua() async {
    await _repo.registrarAgua(_usuarioId, 250);
    await _carregarDados();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('💧 250ml registrados!'), backgroundColor: Colors.blue),
      );
    }
  }

  Future<void> _registrarRefeicao() async {
    final descController = TextEditingController();
    final calController = TextEditingController();
    String tipoSelecionado = 'almoco';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Refeição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descrição')),
            const SizedBox(height: 8),
            TextField(controller: calController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calorias (kcal)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: tipoSelecionado,
              items: const [
                DropdownMenuItem(value: 'cafe_manha', child: Text('Café da manhã')),
                DropdownMenuItem(value: 'almoco', child: Text('Almoço')),
                DropdownMenuItem(value: 'lanche', child: Text('Lanche')),
                DropdownMenuItem(value: 'jantar', child: Text('Jantar')),
              ],
              onChanged: (v) => tipoSelecionado = v ?? 'almoco',
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (descController.text.isNotEmpty && calController.text.isNotEmpty) {
                await _repo.registrarRefeicao(
                  usuarioId: _usuarioId,
                  descricao: descController.text,
                  calorias: int.tryParse(calController.text) ?? 0,
                  tipo: tipoSelecionado,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await _carregarDados();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registrarPeso() async {
    final pesoController = TextEditingController();
    final alturaController = TextEditingController();

    // Pré-preenche a altura com o valor mais recente, se houver
    if (_alturaCm > 0) {
      alturaController.text = _alturaCm.toStringAsFixed(0);
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⚖️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Registrar Peso',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pesoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Peso (kg)',
                hintText: 'Ex: 65.4',
                prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alturaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Altura (cm)',
                hintText: 'Ex: 170',
                prefixIcon: const Icon(Icons.height_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'O IMC será calculado automaticamente.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final peso = double.tryParse(pesoController.text.replaceAll(',', '.'));
              final altura = double.tryParse(alturaController.text.replaceAll(',', '.'));
              if (peso != null && altura != null && altura > 0) {
                await _repo.registrarPeso(
                  usuarioId: _usuarioId,
                  pesoKg: peso,
                  alturaCm: altura,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await _carregarDados();
                if (mounted) {
                  final imc = peso / ((altura / 100) * (altura / 100));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✅ Peso registrado! IMC: ${imc.toStringAsFixed(1)}'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha peso e altura corretamente.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _verHistorico() async {
    final historico = await _repo.getHistoricoPeso(_usuarioId);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('📊', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Histórico de Peso',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: historico.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhum registro ainda.',
                      textAlign: TextAlign.center),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: historico.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = historico[i];
                    final data =
                        DateTime.parse(r['registrado_em'] as String);
                    final altura = (r['altura_cm'] as num?)?.toDouble() ?? 0;
                    final imc = (r['imc'] as num?)?.toDouble() ?? 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.monitor_weight_outlined,
                            color: AppTheme.primary, size: 20),
                      ),
                      title: Text(
                        '${r['peso_kg']} kg${altura > 0 ? '  •  ${altura.toStringAsFixed(0)} cm' : ''}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'IMC ${imc.toStringAsFixed(1)}  •  ${data.day}/${data.month}/${data.year}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textLight),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'))
        ],
      ),
    );
  }


  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goToChat() {
    Navigator.pushNamed(context, AppRoutes.chat);
  }

  void _handleLogout() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildGreeting(),
                  const SizedBox(height: 24),
                  _buildAIBanner(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Resumo do Dia'),
                  const SizedBox(height: 14),
                  _buildCalorieCard(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildWaterCard()),
                      const SizedBox(width: 14),
                      Expanded(child: _buildWeightCard()),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Biometria'),
                  const SizedBox(height: 14),
                  _buildBiometricsCard(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Ações Rápidas'),
                  const SizedBox(height: 14),
                  _buildQuickActions(),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildChatFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.surface,
      expandedHeight: 0,
      toolbarHeight: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'NutriPath',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      leadingWidth: 160,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded,
              color: AppTheme.textDark, size: 24),
        ),
        IconButton(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout_rounded,
              color: AppTheme.textDark, size: 22),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $_userName! 🌿',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Veja como está seu progresso hoje.',
          style: TextStyle(fontSize: 14, color: AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildAIBanner() {
    return GestureDetector(
      onTap: _goToChat,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✨ IA Disponível',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Converse com\nsua nutricionista IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Iniciar chat →',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text('🥗', style: TextStyle(fontSize: 60)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildCalorieCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Calorias',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              Text(
                '$_consumedCalories / $_goalCalories kcal',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _calorieProgress,
              minHeight: 10,
              backgroundColor: AppTheme.accent,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF6A623)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_calorieProgress * 100).toInt()}% da meta diária atingida',
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard() {
    return GestureDetector(
      onTap: _registrarAgua,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💧', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 10),
            const Text(
              'Água',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_aguaMl ml',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _waterProgress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFE3F2FD),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_waterProgress * 100).clamp(0, 100).toInt()}% · toque +250ml',
              style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚖️', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 10),
          const Text(
            'Peso',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_weightKg.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '↓ 0.3 kg esta semana',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricsCard() {
    String _imcStatus(double imc) {
      if (imc == 0) return 'Sem dado';
      if (imc < 18.5) return 'Abaixo do peso';
      if (imc < 25.0) return 'Normal';
      if (imc < 30.0) return 'Sobrepeso';
      return 'Obesidade';
    }

    Color _imcColor(double imc) {
      if (imc == 0) return AppTheme.textLight;
      if (imc < 18.5) return Colors.orange;
      if (imc < 25.0) return AppTheme.primary;
      if (imc < 30.0) return Colors.orange;
      return Colors.red;
    }

    return _Card(
      child: Column(
        children: [
          if (_alturaCm > 0) ...[
            _BiometricRow(
              label: 'Altura',
              value: _alturaCm.toStringAsFixed(0),
              unit: 'cm',
              status: 'Registrada',
              statusColor: const Color(0xFF2196F3),
            ),
            const Divider(color: AppTheme.divider, height: 24),
          ],
          _BiometricRow(
            label: 'IMC',
            value: _bmiValue > 0 ? _bmiValue.toStringAsFixed(1) : '--',
            unit: 'kg/m²',
            status: _imcStatus(_bmiValue),
            statusColor: _imcColor(_bmiValue),
          ),
          const Divider(color: AppTheme.divider, height: 24),
          _BiometricRow(label: 'Gordura Corporal', value: _gorduraCorporal > 0 ? _gorduraCorporal.toStringAsFixed(1) : '--', unit: '%', status: 'Ideal', statusColor: AppTheme.primaryLight),
          const Divider(color: AppTheme.divider, height: 24),
          _BiometricRow(label: 'Massa Muscular', value: _massaMuscular > 0 ? _massaMuscular.toStringAsFixed(1) : '--', unit: 'kg', status: 'Boa', statusColor: const Color(0xFF2196F3)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Registrar\nRefeição',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.refeicoes,
              arguments: {'usuarioId': _usuarioId},
            ).then((_) => _carregarDados()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.monitor_weight_outlined,
            label: 'Registrar\nPeso',
            onTap: _registrarPeso,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.person_outline_rounded,
            label: 'Meu\nPerfil',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.perfil,
              arguments: {'usuarioId': _usuarioId},
            ).then((_) => _carregarDados()),
          ),
        ),
      ],
    );
  }

  Widget _buildChatFAB() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FloatingActionButton.extended(
          onPressed: _goToChat,
          backgroundColor: AppTheme.primary,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.chat_bubble_outline_rounded,
              color: Colors.white, size: 20),
          label: const Text(
            'Consultar Nutricionista IA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Componentes Auxiliares ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BiometricRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;

  const _BiometricRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textMedium)),
        Row(
          children: [
            RichText(
              text: TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
                children: [
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMedium,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
