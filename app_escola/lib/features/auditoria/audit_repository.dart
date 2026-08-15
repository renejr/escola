import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class AuditRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 50, int offset = 0}) async {
    try {
      final response = await _apiClient.dio.get(
        '/core/auditoria',
        queryParameters: {
          'limite': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Falha ao carregar trilha de auditoria.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Acesso negado: permissão insuficiente.');
      }
      throw Exception('Erro de comunicação com o servidor: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
}
