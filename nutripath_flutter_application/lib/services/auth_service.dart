import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // iOS Simulator  → 127.0.0.1
  // Android Emulator → 10.0.2.2
  static const String _baseUrl = 'https://nutripath-api.onrender.com';
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // ── Login ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': senha}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        await _saveUser(data['usuario']);
        return {'sucesso': true, 'usuario': data['usuario']};
      }

      return {
        'sucesso': false,
        'erro': data['erro'] ?? 'Erro desconhecido.'
      };
    } catch (_) {
      return {'sucesso': false, 'erro': 'Sem conexão com o servidor.'};
    }
  }

  // ── Registro ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
      String nome, String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await _saveToken(data['token']);
        await _saveUser(data['usuario']);
        return {'sucesso': true, 'usuario': data['usuario']};
      }

      return {
        'sucesso': false,
        'erro': data['erro'] ?? 'Erro desconhecido.'
      };
    } catch (_) {
      return {'sucesso': false, 'erro': 'Sem conexão com o servidor.'};
    }
  }

  // ── Salvar token e usuário localmente ──────────────────────────────────────
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // ── Recuperar token e usuário ──────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    return raw != null ? jsonDecode(raw) : null;
  }

  // ── Header com Bearer Token ────────────────────────────────────────────────
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}