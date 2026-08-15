import '../../../core/network/api_client.dart';

class WhatsappRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _apiClient.dio.get('/core/whatsapp/status');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao obter status: $e');
    }
  }

  Future<Map<String, dynamic>> gerarQrCode() async {
    try {
      final response = await _apiClient.dio.get('/core/whatsapp/qr');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao gerar QR Code: $e');
    }
  }
}
