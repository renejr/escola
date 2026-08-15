import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/evento_agenda.dart';

class AgendaRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<EventoAgenda>> getEventos() async {
    try {
      final response = await _apiClient.dio.get('/core/agenda');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => EventoAgenda.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao buscar eventos');
    }
  }

  Future<EventoAgenda> createEvento(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/core/agenda', data: data);
      return EventoAgenda.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao criar evento');
    }
  }

  Future<EventoAgenda> updateEvento(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/core/agenda/$id', data: data);
      return EventoAgenda.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao atualizar evento');
    }
  }

  Future<void> deleteEvento(String id) async {
    try {
      await _apiClient.dio.delete('/core/agenda/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erro ao deletar evento');
    }
  }
}