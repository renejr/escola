import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import '../storage/secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    // Para resolver de forma dinâmica a base_url baseada no SO
    String getPlatformBaseUrl() {
      // Se estiver em produção (Release Mode), forçamos a URL da VPS
      if (kReleaseMode) {
        return 'https://api.mdxhq.com.br/escola';
      }

      // kIsWeb verifica de forma segura se o app está rodando no navegador (Chrome/Edge)
      if (kIsWeb) {
        return 'http://127.0.0.1:8080';
      }
      
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
      
      // Para Windows, macOS, Linux ou iOS simulador
      return 'http://127.0.0.1:8080';
    }

    dio = Dio(BaseOptions(
      baseUrl: getPlatformBaseUrl(),
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Adicionando o Interceptor Inteligente
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Se for a rota de login, não tentamos injetar o token
          if (!options.path.contains('/auth/login')) {
            final token = await SecureStorage.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options); // Continua a requisição
        },
        onError: (DioException e, handler) {
          // Aqui poderíamos tratar erros globais (ex: 401 Unauthorized para deslogar)
          if (e.response?.statusCode == 401) {
            SecureStorage.clearAll();
            // TODO: Redirecionar para tela de login usando seu gerenciador de rotas
          }
          return handler.next(e);
        },
      ),
    );
  }
}
