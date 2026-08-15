import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/aluno.dart';

class AlunosRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Aluno>> getAlunos([String? turmaId]) async {
    try {
      final queryParams = turmaId != null ? {'turma_id': turmaId} : null;
      final response = await _apiClient.dio.get('/core/alunos', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Aluno.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Erro ao buscar alunos: $e');
    }
  }

  Future<Aluno> createAluno(Aluno aluno) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/alunos',
        data: aluno.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Aluno(
          id: response.data['id'],
          nome: aluno.nome,
          dataNascimento: aluno.dataNascimento,
          cpf: aluno.cpf,
          matriculaRa: aluno.matriculaRa,
          turmaId: aluno.turmaId,
          fotoUrl: aluno.fotoUrl,
          ativo: aluno.ativo,
          responsaveis: aluno.responsaveis,
        );
      }
      throw Exception('Falha ao criar aluno.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? 'Dados inválidos.');
      }
      throw Exception('Erro de rede ao criar aluno.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> updateAluno(Aluno aluno) async {
    if (aluno.id == null) throw Exception('ID não informado');
    try {
      await _apiClient.dio.put(
        '/core/alunos/${aluno.id}',
        data: aluno.toJson(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? 'Dados inválidos.');
      }
      throw Exception('Erro de rede ao atualizar aluno.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> deleteAluno(String id) async {
    try {
      await _apiClient.dio.delete('/core/alunos/$id');
    } catch (e) {
      throw Exception('Erro ao deletar aluno: $e');
    }
  }
}
