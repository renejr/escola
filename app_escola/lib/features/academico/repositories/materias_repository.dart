import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/materia.dart';

class MateriasRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Materia>> getMaterias() async {
    try {
      final response = await _apiClient.dio.get('/core/materias');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Materia.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao buscar matérias');
    }
  }

  Future<Materia> createMateria(String nome, String? areaConhecimento) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/materias',
        data: {
          'nome': nome,
          'area_conhecimento': areaConhecimento,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Materia.fromJson(response.data);
      }
      throw Exception('Falha ao criar matéria');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao criar matéria');
    }
  }

  Future<Materia> updateMateria(String id, String nome, String? areaConhecimento) async {
    try {
      final response = await _apiClient.dio.put(
        '/core/materias/$id',
        data: {
          'nome': nome,
          'area_conhecimento': areaConhecimento,
        },
      );
      if (response.statusCode == 200) {
        return Materia.fromJson(response.data);
      }
      throw Exception('Falha ao atualizar matéria');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao atualizar matéria');
    }
  }

  Future<void> deleteMateria(String id) async {
    try {
      await _apiClient.dio.delete('/core/materias/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao excluir matéria');
    }
  }
}
