import '../../core/network/api_client.dart';

class EscolarRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await _apiClient.dio.get('/core/dashboard');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Falha ao carregar dashboard');
    } catch (e) {
      throw Exception('Erro ao carregar dashboard: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTurmas() async {
    try {
      final response = await _apiClient.dio.get('/core/turmas');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Falha ao carregar turmas');
    } catch (e) {
      throw Exception('Erro ao carregar turmas: $e');
    }
  }

  Future<bool> createTurma(String nome) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/turmas',
        data: {'nome': nome},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar turma: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAlunos(String turmaId) async {
    try {
      final response = await _apiClient.dio.get(
        '/core/alunos',
        queryParameters: {'turma_id': turmaId},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Falha ao carregar alunos');
    } catch (e) {
      throw Exception('Erro ao carregar alunos: $e');
    }
  }

  Future<bool> createAluno(String nome, String matricula, String turmaId) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/alunos',
        data: {
          'nome': nome,
          'matricula': matricula,
          'turma_id': turmaId,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar aluno: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotasAluno(String alunoId) async {
    try {
      final response = await _apiClient.dio.get('/core/notas/$alunoId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Falha ao carregar notas');
    } catch (e) {
      throw Exception('Erro ao carregar notas: $e');
    }
  }

  Future<bool> addNota(String alunoId, String disciplina, double valor, int bimestre) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/notas',
        data: {
          'aluno_id': alunoId,
          'disciplina': disciplina,
          'valor_nota': valor,
          'bimestre': bimestre,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao adicionar nota: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFrequencia(String turmaId, String data) async {
    try {
      final response = await _apiClient.dio.get(
        '/core/frequencia/$turmaId',
        queryParameters: {'data': data},
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = response.data;
        return responseData.cast<Map<String, dynamic>>();
      }
      throw Exception('Falha ao carregar frequência');
    } catch (e) {
      throw Exception('Erro ao carregar frequência: $e');
    }
  }

  Future<bool> registrarFrequencia(String turmaId, String data, List<Map<String, dynamic>> frequencias) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/frequencia',
        data: {
          'turma_id': turmaId,
          'data': data,
          'frequencias': frequencias,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao registrar frequência: $e');
    }
  }
}
