import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class FinanceiroRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getContas({
    int limit = 100,
    String? alunoId,
    String? status,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (alunoId != null && alunoId.isNotEmpty) queryParams['aluno_id'] = alunoId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (dataInicio != null && dataInicio.isNotEmpty) queryParams['data_inicio'] = dataInicio;
      if (dataFim != null && dataFim.isNotEmpty) queryParams['data_fim'] = dataFim;

      final response = await _apiClient.dio.get(
        '/core/financeiro/contas',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
      );
      
      print('DEBUG CACHE: Retornou ${(response.data["items"] as List).length} itens da API.');
      
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

  Future<List<dynamic>> getAlunos({String? search, int? limit}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.dio.get(
        '/core/alunos',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar alunos: $e');
    }
  }
}