import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AiService {
  static const String _baseUrl = 'https://mobile-ios-ia.zani0x03.eti.br/api';

  static Future<String> chat(String prompt) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/chat'),
            headers: headers,
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ??
            data['message'] ??
            data['content'] ??
            data['answer'] ??
            data['text'] ??
            'Não consegui processar sua pergunta.';
      }

      if (response.statusCode == 401) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }

      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erro ao consultar a IA.');
    } on SocketException {
      throw Exception('Sem conexão com a internet.');
    } on TimeoutException {
      throw Exception('O servidor demorou muito para responder. Tente novamente.');
    } on HttpException {
      throw Exception('Servidor de IA indisponível.');
    } on FormatException {
      throw Exception('Resposta inválida do servidor.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
}