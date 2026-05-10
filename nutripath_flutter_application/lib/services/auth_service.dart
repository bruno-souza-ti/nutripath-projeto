// lib/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _loginBaseUrl =
      'https://mobile-ios-login.zani0x03.eti.br/api';
  static const String _iaBaseUrl =
      'https://mobile-ios-ia.zani0x03.eti.br/api';

  static const String _sistemaId = 'c72e5498-a9bd-4903-b320-0aa3abe1ad91';

  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // ── Login ──────────────────────────────────────────────────────────────────
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

      debugPrint('LOGIN status: ${response.statusCode}');
      debugPrint('LOGIN body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'] ?? data['accessToken'] ?? '';
        await _saveToken(token);

        final usuario = data['usuario'] ??
            {
              'id': data['id'] ?? 1,
              'nome': data['name'] ?? username,
              'email': data['email'] ?? '',
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
    } catch (e) {
      debugPrint('LOGIN erro: $e');
      return {'sucesso': false, 'erro': 'Erro inesperado. Tente novamente.'};
    }
  }

  // ── Registro ───────────────────────────────────────────────────────────────
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

      debugPrint('REGISTER status: ${response.statusCode}');
      debugPrint('REGISTER body: ${response.body}');

      // A API retorna 201 com texto simples "User registered successfully."
      // então verificamos o statusCode ANTES de tentar parsear JSON
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'sucesso': true};
      }

      // Tenta pegar mensagem de erro do JSON
      try {
        final data = jsonDecode(response.body);
        return {
          'sucesso': false,
          'erro': data['message'] ?? data['erro'] ?? 'Erro ao criar conta. (${response.statusCode})',
        };
      } catch (_) {
        return {
          'sucesso': false,
          'erro': response.body.isNotEmpty
              ? response.body.substring(0, response.body.length.clamp(0, 200))
              : 'Erro ao criar conta. (${response.statusCode})',
        };
      }
    } on SocketException {
      return {'sucesso': false, 'erro': 'Sem conexão com a internet.'};
    } on HttpException {
      return {'sucesso': false, 'erro': 'Servidor indisponível.'};
    } catch (e) {
      debugPrint('REGISTER erro: $e');
      return {'sucesso': false, 'erro': 'Erro inesperado. Tente novamente.'};
    }
  }

  static String get iaBaseUrl => _iaBaseUrl;

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

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

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
