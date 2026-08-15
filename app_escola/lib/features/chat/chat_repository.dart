import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class ChatRepository {
  final ApiClient _apiClient = ApiClient();

  Future<String> askQuestion(String question) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/ia/perguntar',
        data: {'pergunta': question},
      );

      if (response.statusCode == 200) {
        // Assume que a resposta da IA está na chave 'resposta'. 
        // Adapte se o backend retornar outra estrutura.
        return response.data['resposta'] ?? 'Sem resposta gerada.';
      } else {
        throw Exception('Falha ao obter resposta: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('A IA demorou muito para responder (Timeout).');
      }
      throw Exception('Erro de rede: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
}
