import 'package:flutter/material.dart';
import '../../main.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // Campos conforme a API: name, surname, login, email, password
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureSenha = true;
  bool _obscureConfirmar = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _handleCadastro() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await AuthService.register(
      _nomeController.text.trim(),
      _sobrenomeController.text.trim(),
      _loginController.text.trim(),
      _emailController.text.trim(),
      _senhaController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso! Faça login. 🎉'),
          backgroundColor: Color(0xFF2D6A4F),
        ),
      );
      // Volta para login após cadastro (user precisa logar com a API do professor)
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['erro'] ?? 'Erro ao criar conta.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF7EE), Color(0xFFF8FDF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Botão voltar
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: AppTheme.textDark, size: 20),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.eco_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NutriPath',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark,
                                      letterSpacing: -0.5)),
                              Text('AI',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryLight,
                                      letterSpacing: 1.5)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Criar sua\nconta 🌿',
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                            height: 1.15,
                            letterSpacing: -1.0),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Comece sua jornada nutricional\npersonalizada com IA.',
                        style: TextStyle(
                            fontSize: 15, color: AppTheme.textLight, height: 1.5),
                      ),
                      const SizedBox(height: 32),

                      // Nome
                      TextFormField(
                        controller: _nomeController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          hintText: 'Seu nome',
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: AppTheme.textLight, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe seu nome';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Sobrenome
                      TextFormField(
                        controller: _sobrenomeController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Sobrenome',
                          hintText: 'Seu sobrenome',
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: AppTheme.textLight, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe seu sobrenome';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Login (username único)
                      TextFormField(
                        controller: _loginController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Usuário (login)',
                          hintText: 'seu_usuario',
                          prefixIcon: Icon(Icons.alternate_email_rounded,
                              color: AppTheme.textLight, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe o nome de usuário';
                          if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // E-mail
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'seu@email.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded,
                              color: AppTheme.textLight, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o e-mail';
                          if (!v.contains('@') || !v.contains('.')) return 'E-mail inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Senha
                      TextFormField(
                        controller: _senhaController,
                        obscureText: _obscureSenha,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: AppTheme.textLight, size: 20),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscureSenha = !_obscureSenha),
                            icon: Icon(
                              _obscureSenha
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textLight,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe a senha';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirmar senha
                      TextFormField(
                        controller: _confirmarController,
                        obscureText: _obscureConfirmar,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleCadastro(),
                        decoration: InputDecoration(
                          labelText: 'Confirmar senha',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: AppTheme.textLight, size: 20),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscureConfirmar = !_obscureConfirmar),
                            icon: Icon(
                              _obscureConfirmar
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textLight,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Confirme sua senha';
                          if (v != _senhaController.text) return 'As senhas não coincidem';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleCadastro,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Criar conta',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3)),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Já tem conta? ',
                              style: TextStyle(
                                  color: AppTheme.textMedium, fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('Entrar',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
