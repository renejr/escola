import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../seguranca/models/escola.dart';

class SuperAdminRepository {
  final ApiClient _apiClient = ApiClient();

  String _handleError(dynamic e, String defaultMessage) {
    if (e is DioException) {
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['detail'] != null) {
          return e.response?.data['detail'];
        }
      }
    }
    return defaultMessage;
  }

  Future<Map<String, dynamic>> getKpis() async {
    try {
      final response = await _apiClient.dio.get('/core/superadmin/kpis');
      return response.data;
    } catch (e) {
      throw Exception(_handleError(e, 'Erro ao buscar KPIs.'));
    }
  }

  Future<List<Escola>> getEscolas() async {
    try {
      final response = await _apiClient.dio.get('/core/superadmin/escolas');
      return (response.data as List).map((e) => Escola.fromJson(e)).toList();
    } catch (e) {
      throw Exception(_handleError(e, 'Erro ao buscar escolas.'));
    }
  }

  Future<void> createEscola(Map<String, dynamic> escolaData) async {
    try {
      await _apiClient.dio.post('/core/superadmin/escolas', data: escolaData);
    } catch (e) {
      throw Exception(_handleError(e, 'Erro ao criar escola e administrador.'));
    }
  }

  Future<void> updateEscola(String id, Escola escola) async {
    try {
      await _apiClient.dio.put('/core/superadmin/escolas/$id', data: escola.toJson());
    } catch (e) {
      throw Exception(_handleError(e, 'Erro ao atualizar escola.'));
    }
  }

  Future<void> toggleStatus(String id) async {
    try {
      await _apiClient.dio.patch('/core/superadmin/escolas/$id/toggle-status');
    } catch (e) {
      throw Exception(_handleError(e, 'Erro ao alterar status.'));
    }
  }
}
