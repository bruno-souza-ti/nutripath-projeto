// lib/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'https://nutripath-api.onrender.com';
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // ── Login ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String senha) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        await _saveUser(data['usuario']);
        return {'sucesso': true, 'usuario': data['usuario']};
      }

      return {
        'sucesso': false,
        'erro': data['erro'] ?? 'Credenciais inválidas.',
      };
    } on SocketException {
      return {'sucesso': false, 'erro': 'Sem conexão com a internet.'};
    } on HttpException {
      return {'sucesso': false, 'erro': 'Servidor indisponível.'};
    } on FormatException {
      return {'sucesso': false, 'erro': 'Resposta inválida do servidor.'};
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro inesperado. Tente novamente.'};
    }
  }

  // ── Registro ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
      String nome, String email, String senha) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await _saveToken(data['token']);
        await _saveUser(data['usuario']);
        return {'sucesso': true, 'usuario': data['usuario']};
      }

      return {
        'sucesso': false,
        'erro': data['erro'] ?? 'Não foi possível criar a conta.',
      };
    } on SocketException {
      return {'sucesso': false, 'erro': 'Sem conexão com a internet.'};
    } on HttpException {
      return {'sucesso': false, 'erro': 'Servidor indisponível.'};
    } on FormatException {
      return {'sucesso': false, 'erro': 'Resposta inválida do servidor.'};
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro inesperado. Tente novamente.'};
    }
  }

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
      // dado corrompido no storage — limpa e força novo login
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