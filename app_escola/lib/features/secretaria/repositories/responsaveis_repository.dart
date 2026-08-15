import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/responsavel.dart';

class ResponsaveisRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Responsavel>> getResponsaveis() async {
    try {
      final response = await _apiClient.dio.get('/core/responsaveis');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Responsavel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Erro ao buscar responsáveis: $e');
    }
  }

  Future<Responsavel> createResponsavel(Responsavel responsavel) async {
    try {
      final response = await _apiClient.dio.post(
        '/core/responsaveis',
        data: responsavel.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Responsavel(
          id: response.data['id'],
          nome: responsavel.nome,
          cpf: responsavel.cpf,
          email: responsavel.email,
          celular: responsavel.celular,
          emergenciaNome: responsavel.emergenciaNome,
          emergenciaTelefone: responsavel.emergenciaTelefone,
          cep: responsavel.cep,
          logradouro: responsavel.logradouro,
          numero: responsavel.numero,
          complemento: responsavel.complemento,
          bairro: responsavel.bairro,
          cidade: responsavel.cidade,
          estado: responsavel.estado,
          fotoUrl: responsavel.fotoUrl,
          comprovanteUrl: responsavel.comprovanteUrl,
          ativo: responsavel.ativo,
        );
      }
      throw Exception('Falha ao criar responsável.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? 'Dados inválidos.');
      }
      throw Exception('Erro de rede ao criar responsável.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> updateResponsavel(Responsavel responsavel) async {
    if (responsavel.id == null) throw Exception('ID não informado');
    try {
      await _apiClient.dio.put(
        '/core/responsaveis/${responsavel.id}',
        data: responsavel.toJson(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? 'Dados inválidos.');
      }
      throw Exception('Erro de rede ao atualizar responsável.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> deleteResponsavel(String id) async {
    try {
      await _apiClient.dio.delete('/core/responsaveis/$id');
    } catch (e) {
      throw Exception('Erro ao deletar responsável: $e');
    }
  }
}
