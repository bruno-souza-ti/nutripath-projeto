// lib/screens/camera_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../database/nutri_repository.dart';
import '../services/auth_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final NutriRepository _repo = NutriRepository();

  int? _usuarioId;
  File? _imagemSelecionada;
  String _tipoRegistro = 'alimento'; // 'alimento' ou 'progresso'
  bool _enviando = false;
  String? _descricao;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolverUsuario();
  }

  Future<void> _resolverUsuario() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      final id = int.tryParse(args['usuarioId']?.toString() ?? '');
      if (id != null) {
        setState(() => _usuarioId = id);
        return;
      }
    }
    final id = await AuthService.getLocalUsuarioId();
    if (id == null && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    setState(() => _usuarioId = id);
  }

  // ─── Captura de imagem ───────────────────────────────────────────────────

  Future<void> _abrirCamera() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (foto != null) {
        setState(() => _imagemSelecionada = File(foto.path));
      }
    } catch (e) {
      _mostrarErro('Não foi possível acessar a câmera. Verifique as permissões nas configurações do iPhone.');
    }
  }

  Future<void> _abrirGaleria() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (foto != null) {
        setState(() => _imagemSelecionada = File(foto.path));
      }
    } catch (e) {
      _mostrarErro('Não foi possível acessar a galeria. Verifique as permissões nas configurações do iPhone.');
    }
  }

  void _descartarImagem() {
    setState(() {
      _imagemSelecionada = null;
      _descricao = null;
    });
  }

  // ─── Confirmação do registro ─────────────────────────────────────────────

  Future<void> _confirmarRegistro() async {
    if (_imagemSelecionada == null || _usuarioId == null) return;

    // Solicita descrição antes de salvar
    final descricaoDigitada = await _mostrarDialogoDescricao();
    if (descricaoDigitada == null) return; // cancelou

    setState(() => _enviando = true);

    try {
      if (_tipoRegistro == 'alimento') {
        await _repo.registrarRefeicao(
          usuarioId: _usuarioId!,
          descricao: descricaoDigitada.isNotEmpty
              ? descricaoDigitada
              : 'Refeição fotografada',
          calorias: 0, // IA pode estimar depois
          tipo: 'foto',
        );
      } else {
        await _repo.registrarPeso(
          usuarioId: _usuarioId!,
          pesoKg: 0,    // preenchido depois no perfil
          alturaCm: 100, // placeholder
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tipoRegistro == 'alimento'
                  ? '📸 Alimento registrado com sucesso!'
                  : '📸 Foto de progresso salva!',
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
        setState(() {
          _imagemSelecionada = null;
          _descricao = null;
        });
      }
    } catch (e) {
      _mostrarErro('Erro ao salvar o registro. Tente novamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<String?> _mostrarDialogoDescricao() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(
              _tipoRegistro == 'alimento' ? '🥗' : '💪',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 8),
            Text(
              _tipoRegistro == 'alimento'
                  ? 'Descrever alimento'
                  : 'Descrever progresso',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: _tipoRegistro == 'alimento'
                ? 'Ex: Salada de frango com legumes'
                : 'Ex: Treino de peito – semana 3',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Câmera & Galeria',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seletor de tipo
            _buildTipoSelector(),
            const SizedBox(height: 24),

            // Área da imagem
            _imagemSelecionada == null
                ? _buildAreaVazia()
                : _buildPreviewImagem(),

            const SizedBox(height: 24),

            // Botões de ação
            if (_imagemSelecionada == null) _buildBotoesCaptura(),
            if (_imagemSelecionada != null) _buildBotoesConfirmacao(),

            const SizedBox(height: 32),
            _buildDica(),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TipoBtn(
            label: '🥗  Alimento',
            ativo: _tipoRegistro == 'alimento',
            onTap: () => setState(() => _tipoRegistro = 'alimento'),
          ),
          _TipoBtn(
            label: '💪  Progresso',
            ativo: _tipoRegistro == 'progresso',
            onTap: () => setState(() => _tipoRegistro = 'progresso'),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaVazia() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: AppTheme.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma foto selecionada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use os botões abaixo para fotografar\nou escolher da galeria',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewImagem() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _imagemSelecionada!,
            width: double.infinity,
            height: 320,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: _descartarImagem,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _tipoRegistro == 'alimento' ? '🥗 Alimento' : '💪 Progresso',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotoesCaptura() {
    return Row(
      children: [
        Expanded(
          child: _BotaoAcao(
            icon: Icons.camera_alt_rounded,
            label: 'Câmera',
            cor: AppTheme.primary,
            onTap: _abrirCamera,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BotaoAcao(
            icon: Icons.photo_library_rounded,
            label: 'Galeria',
            cor: const Color(0xFF5B4FCF),
            onTap: _abrirGaleria,
          ),
        ),
      ],
    );
  }

  Widget _buildBotoesConfirmacao() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _enviando ? null : _confirmarRegistro,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, color: Colors.white),
            label: Text(
              _enviando ? 'Salvando...' : 'Confirmar registro',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _descartarImagem,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMedium),
            label: const Text(
              'Tirar outra foto',
              style: TextStyle(
                color: AppTheme.textMedium,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDica() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dica',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tipoRegistro == 'alimento'
                      ? 'Fotografe o prato de frente, com boa iluminação. Isso ajuda a IA a identificar os alimentos e estimar as calorias.'
                      : 'Para progresso físico, use ângulos consistentes (frente, lado, costas) e sempre no mesmo horário do dia.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _TipoBtn extends StatelessWidget {
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _TipoBtn({
    required this.label,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: ativo ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: ativo
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
              color: ativo ? AppTheme.primary : AppTheme.textLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoAcao extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color cor;
  final VoidCallback onTap;

  const _BotaoAcao({
    required this.icon,
    required this.label,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: cor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cor, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
