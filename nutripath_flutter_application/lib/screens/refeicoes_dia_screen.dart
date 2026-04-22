import 'package:flutter/material.dart';
import '../../main.dart';
import '../database/nutri_repository.dart';

class RefeicoesDiaScreen extends StatefulWidget {
  const RefeicoesDiaScreen({super.key});

  @override
  State<RefeicoesDiaScreen> createState() => _RefeicoesDiaScreenState();
}

class _RefeicoesDiaScreenState extends State<RefeicoesDiaScreen> {
  final _repo = NutriRepository();
  int _usuarioId = 1;
  bool _iniciado = false;

  List<Map<String, dynamic>> _refeicoes = [];
  bool _isLoading = true;
  DateTime _dataSelecionada = DateTime.now();

  static const Map<String, String> _tipoLabel = {
    'cafe_manha': '☀️ Café da manhã',
    'almoco': '🍽️ Almoço',
    'lanche': '🍎 Lanche',
    'jantar': '🌙 Jantar',
    'outro': '🍴 Outro',
  };

  static const Map<String, Color> _tipoColor = {
    'cafe_manha': Color(0xFFFFF3CD),
    'almoco': Color(0xFFD8F3DC),
    'lanche': Color(0xFFFFE0B2),
    'jantar': Color(0xFFE8EAF6),
    'outro': Color(0xFFF3E5F5),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciado) {
      _iniciado = true;
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) _usuarioId = (args['usuarioId'] as int?) ?? 1;
      _carregarRefeicoes();
    }
  }

  Future<void> _carregarRefeicoes() async {
    setState(() => _isLoading = true);
    final lista = await _repo.getRefeicoesDe(_usuarioId, _dataSelecionada);
    if (!mounted) return;
    setState(() {
      _refeicoes = lista;
      _isLoading = false;
    });
  }

  int get _totalCalorias => _refeicoes.fold(
      0, (sum, r) => sum + ((r['calorias'] as num?)?.toInt() ?? 0));

  Future<void> _mudarData(int dias) async {
    setState(() {
      _dataSelecionada = _dataSelecionada.add(Duration(days: dias));
    });
    await _carregarRefeicoes();
  }

  Future<void> _deletarRefeicao(int id) async {
    await _repo.deletarRefeicao(id);
    await _carregarRefeicoes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Refeição removida.'),
          backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _abrirFormulario() async {
    final descController = TextEditingController();
    final calController = TextEditingController();
    final protController = TextEditingController();
    final carbController = TextEditingController();
    final gordController = TextEditingController();
    String tipoSelecionado = 'almoco';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Registrar Refeição',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: descController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descrição *',
                    hintText: 'Ex: Frango grelhado com arroz',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipoSelecionado,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de refeição'),
                  items: const [
                    DropdownMenuItem(
                        value: 'cafe_manha',
                        child: Text('☀️ Café da manhã')),
                    DropdownMenuItem(
                        value: 'almoco', child: Text('🍽️ Almoço')),
                    DropdownMenuItem(
                        value: 'lanche', child: Text('🍎 Lanche')),
                    DropdownMenuItem(
                        value: 'jantar', child: Text('🌙 Jantar')),
                    DropdownMenuItem(
                        value: 'outro', child: Text('🍴 Outro')),
                  ],
                  onChanged: (v) =>
                      setModalState(() => tipoSelecionado = v ?? 'almoco'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: calController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calorias (kcal) *',
                    hintText: 'Ex: 400',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: protController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Proteínas (g)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: carbController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Carboidratos (g)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: gordController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Gorduras (g)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final desc = descController.text.trim();
                    final cal = int.tryParse(calController.text);
                    if (desc.isEmpty || cal == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Preencha a descrição e as calorias.')),
                      );
                      return;
                    }
                    await _repo.registrarRefeicao(
                      usuarioId: _usuarioId,
                      descricao: desc,
                      calorias: cal,
                      proteinas: double.tryParse(protController.text),
                      carboidratos: double.tryParse(carbController.text),
                      gorduras: double.tryParse(gordController.text),
                      tipo: tipoSelecionado,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _carregarRefeicoes();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Salvar refeição',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _dataFormatada {
    final hoje = DateTime.now();
    final ontem = hoje.subtract(const Duration(days: 1));
    final d = _dataSelecionada;
    if (d.year == hoje.year && d.month == hoje.month && d.day == hoje.day)
      return 'Hoje';
    if (d.year == ontem.year && d.month == ontem.month && d.day == ontem.day)
      return 'Ontem';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  bool get _isHoje {
    final hoje = DateTime.now();
    return _dataSelecionada.year == hoje.year &&
        _dataSelecionada.month == hoje.month &&
        _dataSelecionada.day == hoje.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
        ),
        title: const Text('Refeições',
            style: TextStyle(
                color: AppTheme.textDark, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _abrirFormulario,
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Seletor de data
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _mudarData(-1),
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: AppTheme.textDark, size: 32),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dataSelecionada,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _dataSelecionada = picked);
                      await _carregarRefeicoes();
                    }
                  },
                  child: Column(
                    children: [
                      Text(
                        _dataFormatada,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark),
                      ),
                      const Text('toque para escolher data',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textLight)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isHoje ? null : () => _mudarData(1),
                  icon: Icon(Icons.chevron_right_rounded,
                      color: _isHoje
                          ? AppTheme.divider
                          : AppTheme.textDark,
                      size: 32),
                ),
              ],
            ),
          ),
          // Card total calorias
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🔥 Total do dia',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text('$_totalCalorias kcal',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _refeicoes.isEmpty
                    ? _buildEmpty()
                    : _buildLista(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Adicionar',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Nenhuma refeição registrada',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text(
            'Toque em + para adicionar sua\nprimeira refeição do dia.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppTheme.textLight, height: 1.5),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: _refeicoes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = _refeicoes[i];
        final tipo = (r['tipo'] as String?) ?? 'outro';
        final corFundo =
            _tipoColor[tipo] ?? const Color(0xFFF3E5F5);
        final label = _tipoLabel[tipo] ?? '🍴 Outro';
        final hora = DateTime.parse(r['registrado_em'] as String);
        final proteinas = r['proteinas'] as num?;
        final carboidratos = r['carboidratos'] as num?;
        final gorduras = r['gorduras'] as num?;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: corFundo,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark)),
                    ),
                    const Spacer(),
                    Text(
                      '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textLight),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remover refeição'),
                          content: const Text(
                              'Deseja remover esta refeição?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _deletarRefeicao(r['id'] as int);
                              },
                              child: const Text('Remover',
                                  style:
                                      TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.textLight, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(r['descricao'] as String,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip('🔥 ${r['calorias']} kcal',
                        const Color(0xFFFFF3CD)),
                    if (proteinas != null)
                      _Chip(
                          '💪 ${proteinas.toStringAsFixed(0)}g prot',
                          const Color(0xFFE8F5E9)),
                    if (carboidratos != null)
                      _Chip(
                          '🌾 ${carboidratos.toStringAsFixed(0)}g carb',
                          const Color(0xFFFFF8E1)),
                    if (gorduras != null)
                      _Chip(
                          '🧈 ${gorduras.toStringAsFixed(0)}g gord',
                          const Color(0xFFFCE4EC)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark)),
    );
  }
}
