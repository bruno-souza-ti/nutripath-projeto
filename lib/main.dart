import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/register_screen.dart';
import 'screens/refeicoes_dia_screen.dart';
import 'screens/perfil_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const NutriPathApp());
}

class NutriPathApp extends StatelessWidget {
  const NutriPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriPath AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.chat: (_) => const ChatScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.refeicoes: (_) => const RefeicoesDiaScreen(),
        AppRoutes.perfil: (_) => const PerfilScreen(),
      },
    );
  }
}

// ─── Rotas ──────────────────────────────────────────────────────────────────
class AppRoutes {
  static const String login = '/';
  static const String dashboard = '/dashboard';
  static const String chat = '/chat';
  static const String register = '/register';
  static const String refeicoes = '/refeicoes';
  static const String perfil = '/perfil';
}

// ─── Tema Global ─────────────────────────────────────────────────────────────
class AppTheme {
  // Paleta
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color accent = Color(0xFFD8F3DC);
  static const Color surface = Color(0xFFF8FDF9);
  static const Color textDark = Color(0xFF1B1F1C);
  static const Color textMedium = Color(0xFF4A5568);
  static const Color textLight = Color(0xFF718096);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: primaryLight,
          surface: surface,
        ),
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: textDark),
          titleTextStyle: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          hintStyle: const TextStyle(color: textLight, fontSize: 15),
          labelStyle: const TextStyle(color: textMedium),
        ),
      );
}
