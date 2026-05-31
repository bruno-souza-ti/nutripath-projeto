// lib/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _loginBaseUrl =
      'https://mobile-ios-login.zani0x03.eti.br/api';
  static const String _iaBaseUrl = 'https://mobile-ios-ia.zani0x03.eti.br/api';

  static const String _sistemaId = 'c72e5498-a9bd-4903-b320-0aa3abe1ad91';

  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';
  static const String _localUserIdKey = 'local_usuario_id';

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
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
        final token =
            data['access_token'] ?? data['token'] ?? data['accessToken'] ?? '';
        await _saveToken(token);

        final usuario = Map<String, dynamic>.from(
          data['usuario'] ??
              {
                'id': data['id'] ?? '',
                'nome': data['name'] ?? username,
                'name': data['name'] ?? username,
                'email': data['email'] ?? '',
              },
        );

        // Garante que nome e name existem
        usuario['nome'] ??= username;
        usuario['name'] ??= username;

        // CORREÇÃO: normaliza o email — nunca deixa vazio sem identificador único
        final emailRaw = (usuario['email'] as String? ?? '').trim();
        final userId = usuario['id']?.toString() ?? '';
        if (emailRaw.isEmpty) {
          // Fallback determinístico usando username (login), que é único na API
          usuario['email'] = '${username.trim()}@local';
        }

        await _saveUser(usuario);

        return {'sucesso': true, 'usuario': usuario};
      }

      return {
        'sucesso': false,
        'erro': data['message'] ?? data['erro'] ?? 'Credenciais inválidas.',
      };
    } on SocketException {
      return {'sucesso': false, 'erro': 'Sem conexão com a internet.'};
    } on TimeoutException {
      return {
        'sucesso': false,
        'erro': 'Servidor demorou para responder. Tente novamente.',
      };
    } on HttpException {
      return {'sucesso': false, 'erro': 'Servidor indisponível.'};
    } on FormatException {
      return {'sucesso': false, 'erro': 'Resposta inválida do servidor.'};
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String nome,
    String sobrenome,
    String login,
    String email,
    String senha,
  ) async {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'sucesso': true};
      }

      String mensagemErro;
      try {
        final data = jsonDecode(response.body);
        mensagemErro =
            data['message'] ??
            data['erro'] ??
            data['error'] ??
            'Não foi possível criar a conta. (${response.statusCode})';
      } catch (_) {
        final bodyText = response.body.trim();
        mensagemErro = bodyText.isNotEmpty
            ? bodyText
            : 'Não foi possível criar a conta. (${response.statusCode})';
      }
      return {'sucesso': false, 'erro': mensagemErro};
    } on SocketException {
      return {'sucesso': false, 'erro': 'Sem conexão com a internet.'};
    } on TimeoutException {
      return {
        'sucesso': false,
        'erro': 'Servidor demorou para responder. Tente novamente.',
      };
    } on HttpException {
      return {'sucesso': false, 'erro': 'Servidor indisponível.'};
    } on FormatException {
      return {'sucesso': false, 'erro': 'Resposta inválida do servidor.'};
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro: $e'};
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

  static Future<void> saveUserPublic(Map<String, dynamic> user) async {
    await _saveUser(user);
  }

  static Future<void> saveLocalUsuarioId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_localUserIdKey, id);
  }

  static Future<int?> getLocalUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_localUserIdKey)
        ? prefs.getInt(_localUserIdKey)
        : null;
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

  /// CORREÇÃO: limpa TODA a sessão antes de permitir novo login.
  /// Chamado tanto no logout explícito quanto antes de cada login.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_localUserIdKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
