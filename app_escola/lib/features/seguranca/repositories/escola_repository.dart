import '../../../core/network/api_client.dart';
import '../models/escola.dart';

class EscolaRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Escola> getMinhaInstituicao() async {
    try {
      final response = await _apiClient.dio.get('/core/escola/minha-instituicao');
      return Escola.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao buscar dados da instituição: $e');
    }
  }

  Future<void> updateMinhaInstituicao(Escola escola) async {
    try {
      await _apiClient.dio.put('/core/escola/minha-instituicao', data: escola.toJson());
    } catch (e) {
      throw Exception('Erro ao atualizar dados da instituição: $e');
    }
  }
}
