import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/grade_curricular.dart';

class GradeRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<GradeCurricular>> getGradePorTurma(String turmaId) async {
    try {
      final response = await _apiClient.dio.get('/core/grade/$turmaId');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => GradeCurricular.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao buscar grade curricular');
    }
  }

  Future<GradeCurricular> adicionarMateriaNaGrade(
    String turmaId,
    String materiaId,
    String professorId,
    int cargaHoraria,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/grade',
        data: {
          'turma_id': turmaId,
          'materia_id': materiaId,
          'professor_id': professorId,
          'carga_horaria': cargaHoraria,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return GradeCurricular.fromJson(response.data);
      }
      throw Exception('Falha ao adicionar matéria na grade');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao adicionar matéria na grade');
    }
  }

  Future<void> removerMateriaDaGrade(String gradeId) async {
    try {
      await _apiClient.dio.delete('/core/grade/$gradeId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao remover matéria da grade');
    }
  }
}
