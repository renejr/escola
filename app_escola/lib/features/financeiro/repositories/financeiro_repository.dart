import '../../../core/network/api_client.dart';

class FinanceiroRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getContas() async {
    try {
      final response = await _apiClient.dio.get('/core/financeiro/contas');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar contas a receber: $e');
    }
  }

  Future<List<dynamic>> createConta(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/financeiro/contas',
        data: data,
      );
      return response.data;
    } catch (e) {
      throw Exception('Erro ao criar cobrança: $e');
    }
  }

  Future<List<dynamic>> getAlunos() async {
    try {
      final response = await _apiClient.dio.get('/core/alunos');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar alunos: $e');
    }
  }
}