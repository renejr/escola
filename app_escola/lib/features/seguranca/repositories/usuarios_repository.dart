import '../../../core/network/api_client.dart';
import '../models/usuario.dart';

class UsuariosRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Usuario>> getUsuarios() async {
    try {
      final response = await _apiClient.dio.get('/core/usuarios');
      if (response.statusCode == 200) {
        return (response.data as List).map((json) => Usuario.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }

  Future<Usuario> createUsuario(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/core/usuarios', data: data);
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao criar usuário: $e');
    }
  }

  Future<Usuario> updateUsuario(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/core/usuarios/$id', data: data);
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  Future<Usuario> toggleStatus(String id) async {
    try {
      final response = await _apiClient.dio.patch('/core/usuarios/$id/ativar');
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao alterar status do usuário: $e');
    }
  }
}