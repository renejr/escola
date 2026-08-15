import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class MemoryRepository {
  final ApiClient _apiClient = ApiClient();

  Future<bool> saveMemory(String text, String contextType) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/ia/memoria',
        data: {
          'texto': text,
          'tipo_contexto': contextType,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Falha ao salvar memória: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('A geração de embeddings demorou muito (Timeout).');
      }
      throw Exception('Erro de rede: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
}
