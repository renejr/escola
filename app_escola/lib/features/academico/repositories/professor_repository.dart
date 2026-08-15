import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/professor.dart';

class ProfessorRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Professor>> getProfessores() async {
    try {
      final response = await _apiClient.dio.get('/core/professores');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Professor.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao buscar professores');
    }
  }

  Future<Professor> createProfessor(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/core/professores', data: data);
      return Professor.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao criar professor');
    }
  }

  Future<Professor> updateProfessor(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/core/professores/$id', data: data);
      return Professor.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao atualizar professor');
    }
  }

  Future<void> inativarProfessor(String id) async {
    try {
      await _apiClient.dio.delete('/core/professores/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao inativar professor');
    }
  }

  Future<void> ativarProfessor(String id) async {
    try {
      await _apiClient.dio.patch('/core/professores/$id/ativar');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao ativar professor');
    }
  }
}
