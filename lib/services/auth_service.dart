// lib/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ── URLs da API do professor ──────────────────────────────────────────────
  static const String _loginBaseUrl =
      'https://mobile-ios-login.zani0x03.eti.br/api';
  static const String _iaBaseUrl =
      'https://mobile-ios-ia.zani0x03.eti.br/api';

  // sistemaId do grupo — não alterar
  static const String _sistemaId = 'c72e5498-a9bd-4903-b320-0aa3abe1ad91';

  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // ── Login ──────────────────────────────────────────────────────────────────
  // A API do professor usa "username" (login cadastrado) e "password"
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_loginBaseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
              'sistemaId': _sistemaId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ CORRIGIDO: a API retorna "access_token" (com underscore)
        final token =
            data['access_token'] ?? data['token'] ?? data['accessToken'] ?? '';
        await _saveToken(token);

        // Monta um objeto de usuário compatível com o restante do app
        final usuario = data['usuario'] ??
            {
              'id': data['id'] ?? 1,
              'nome': data['name'] ?? username,
              'email': data['email'] ?? username,
            };
        await _saveUser(Map<String, dynamic>.from(usuario));

        return {'sucesso': true, 'usuario': usuario};
      }

      return {
        'sucesso': false,
        'erro': data['message'] ?? data['erro'] ?? 'Credenciais inválidas.',
      };
    } on SocketException {
      return {'sucesso': false, 'erro': 'Sem conexão com a internet.'};
    } on HttpException {
      return {'sucesso': false, 'erro': 'Servidor indisponível.'};
    } on FormatException {
      return {'sucesso': false, 'erro': 'Resposta inválida do servidor.'};
    } catch (_) {
      return {'sucesso': false, 'erro': 'Erro inesperado. Tente novamente.'};
    }
  }

  // ── Registro ───────────────────────────────────────────────────────────────
  // A API do professor espera: name, surname, login, email, password, sistemaId
  // A API retorna 201 com texto puro — NÃO tenta fazer jsonDecode direto
  static Future<Map<String, dynamic>> register(
      String nome,
      String sobrenome,
      String login,
      String email,
      String senha) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_loginBaseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': nome,
              'surname': sobrenome,
              'login': login,
              'email': email,
              'password': senha,
              'sistemaId': _sistemaId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      // ✅ CORRIGIDO: verifica statusCode ANTES de tentar jsonDecode
      // porque a API retorna texto puro "User registered successfully."
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'sucesso': true};
      }

      // Só tenta parsear JSON se deu erro
      try {
        final data = jsonDecode(response.body);
        return {
          'sucesso': false,
          'erro': data['message'] ?? data['erro'] ??
              'Não foi possível criar a conta. (${response.statusCode})',
        };
      } catch (_) {
        return {
          'sucesso': false,
          'erro': 'Não foi possível criar a conta. (${response.statusCode})',
        };
      }
    } on SocketException {
      return {'sucesso': false, 'erro': 'Sem conexão com a internet.'};
    } on HttpException {
      return {'sucesso': false, 'erro': 'Servidor indisponível.'};
    } on FormatException {
      return {'sucesso': false, 'erro': 'Resposta inválida do servidor.'};
    } catch (_) {
      return {'sucesso': false, 'erro': 'Erro inesperado. Tente novamente.'};
    }
  }

  // ── URL base da IA (para o chat_screen usar) ──────────────────────────────
  static String get iaBaseUrl => _iaBaseUrl;

  // ── Persistência local ────────────────────────────────────────────────────
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // ── Recuperação ───────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      await prefs.remove(_userKey);
      return null;
    }
  }

  // ── Header com Bearer Token ───────────────────────────────────────────────
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ── Verifica se há sessão ativa ───────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}