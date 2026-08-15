import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/notificacao.dart';

class NotificacoesRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Notificacao>> getNotificacoesNaoLidas() async {
    try {
      final response = await _apiClient.dio.get('/core/notificacoes', queryParameters: {'apenas_nao_lidas': true});
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Notificacao.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao buscar notificações');
    }
  }

  Future<void> marcarComoLida(String id) async {
    try {
      await _apiClient.dio.put('/core/notificacoes/$id/ler');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao marcar notificação como lida');
    }
  }
}