import '../../../core/network/api_client.dart';

class PeriodosRepository {
  final ApiClient _apiClient = ApiClient();

  // --- Anos Letivos ---
  Future<List<dynamic>> getAnosLetivos() async {
    try {
      final response = await _apiClient.dio.get('/core/periodos/anos');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar anos letivos: $e');
    }
  }

  Future<void> createAnoLetivo(String ano) async {
    try {
      await _apiClient.dio.post('/core/periodos/anos', data: {'ano': ano});
    } catch (e) {
      throw Exception('Erro ao criar ano letivo: $e');
    }
  }

  Future<void> ativarAnoLetivo(String id) async {
    try {
      await _apiClient.dio.patch('/core/periodos/anos/$id/ativar');
    } catch (e) {
      throw Exception('Erro ao ativar ano letivo: $e');
    }
  }

  // --- Períodos Letivos ---
  Future<List<dynamic>> getPeriodos(String anoId) async {
    try {
      final response = await _apiClient.dio.get('/core/periodos/anos/$anoId/periodos');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar períodos letivos: $e');
    }
  }

  Future<void> createPeriodo(String anoId, String nome, String dataInicio, String dataFim) async {
    try {
      await _apiClient.dio.post('/core/periodos/periodos', data: {
        'ano_letivo_id': anoId,
        'nome': nome,
        'data_inicio': dataInicio,
        'data_fim': dataFim,
      });
    } catch (e) {
      throw Exception('Erro ao criar período letivo: $e');
    }
  }
}