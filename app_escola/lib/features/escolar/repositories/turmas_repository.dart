import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/turma.dart';

class TurmasRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Turma>> getTurmas() async {
    try {
      final response = await _apiClient.dio.get('/core/turmas');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Turma.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao buscar turmas');
    }
  }

  Future<Turma> createTurma(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/core/turmas', data: data);
      return Turma.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao criar turma');
    }
  }

  Future<Turma> updateTurma(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/core/turmas/$id', data: data);
      return Turma.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao atualizar turma');
    }
  }

  Future<void> toggleStatus(String id, bool ativo) async {
    try {
      await _apiClient.dio.patch('/core/turmas/$id/status', queryParameters: {'ativo': ativo});
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao alterar status da turma');
    }
  }

  Future<List<TurmaAluno>> getAlunosDaTurma(String id) async {
    try {
      final response = await _apiClient.dio.get('/core/turmas/$id/alunos');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => TurmaAluno.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao buscar alunos da turma');
    }
  }

  Future<List<TurmaGrade>> getGradeDaTurma(String id) async {
    try {
      final response = await _apiClient.dio.get('/core/turmas/$id/grade');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => TurmaGrade.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao buscar grade da turma');
    }
  }
}