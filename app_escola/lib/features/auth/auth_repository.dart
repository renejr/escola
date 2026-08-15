import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

import 'package:flutter/foundation.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['access_token'];
        final tenantId = data['escola_id'];
        final role = data['role'];
        final nome = data['nome'];
        
        if (token != null) {
          await SecureStorage.saveToken(token);
        }
        if (tenantId != null) {
          await SecureStorage.saveTenantId(tenantId.toString());
        }
        if (role != null) {
          await SecureStorage.saveRole(role.toString());
        }
        if (nome != null) {
          await SecureStorage.saveName(nome.toString());
        }
        await SecureStorage.saveEmail(email); // Salva o e-mail digitado no login
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Email ou senha incorretos.');
      }
      throw Exception('Erro de comunicação com o servidor. Verifique sua conexão.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/forgot-password',
        data: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'E-mail de recuperação enviado.';
      }
      throw Exception('Falha ao solicitar recuperação de senha.');
    } on DioException catch (_) {
      throw Exception('Erro de comunicação com o servidor. Verifique sua conexão.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (e) {
      // Ignorar erros na API para garantir que o armazenamento local seja limpo
      debugPrint('Erro ao registrar logout no servidor: $e');
    } finally {
      await SecureStorage.clearAll();
    }
  }
}
