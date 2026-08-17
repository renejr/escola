import '../../../core/network/api_client.dart';

class DiarioRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getPeriodosLetivos() async {
    try {
      final response = await _apiClient.dio.get('/core/diario/periodos');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar períodos letivos: $e');
    }
  }

  Future<List<dynamic>> getFrequencia(String turmaId, String materiaId, String dataAula) async {
    try {
      final response = await _apiClient.dio.get(
        '/core/diario/frequencia',
        queryParameters: {
          'turma_id': turmaId,
          'materia_id': materiaId,
          'data_aula': dataAula,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar frequência: $e');
    }
  }

  Future<void> saveFrequenciaBulk(Map<String, dynamic> payload) async {
    try {
      await _apiClient.dio.post('/core/diario/frequencia/bulk', data: payload);
    } catch (e) {
      throw Exception('Erro ao salvar frequência em lote: $e');
    }
  }

  Future<List<dynamic>> getNotas(String turmaId, String materiaId, String periodoId) async {
    try {
      final response = await _apiClient.dio.get(
        '/core/diario/notas',
        queryParameters: {
          'turma_id': turmaId,
          'materia_id': materiaId,
          'periodo_letivo_id': periodoId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar notas: $e');
    }
  }

  Future<void> saveNotasBulk(Map<String, dynamic> payload) async {
    try {
      await _apiClient.dio.post('/core/diario/notas/bulk', data: payload);
    } catch (e) {
      throw Exception('Erro ao salvar notas em lote: $e');
    }
  }

  // We need endpoints to load Turmas and Materias for the dropdowns
  Future<List<dynamic>> getTurmas() async {
    try {
      final response = await _apiClient.dio.get('/core/turmas');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar turmas: $e');
    }
  }

  Future<List<dynamic>> getMaterias() async {
    try {
      final response = await _apiClient.dio.get('/core/materias');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar materias: $e');
    }
  }
  
  Future<List<dynamic>> getAlunosPorTurma(String turmaId) async {
    try {
      final response = await _apiClient.dio.get('/core/turmas/$turmaId/alunos');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar alunos da turma: $e');
    }
  }
}