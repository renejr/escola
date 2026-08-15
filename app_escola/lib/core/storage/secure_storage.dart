import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  
  static const _keyToken = 'jwt_token';
  static const _keyTenantId = 'tenant_id';
  static const _keyRole = 'user_role';
  static const _keyEmail = 'user_email';
  static const _keyName = 'user_name';
  static const _keyRememberedEmail = 'saved_user_email';

  // Salvar Token JWT
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  // Ler Token JWT
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Salvar Tenant ID (escola_id)
  static Future<void> saveTenantId(String tenantId) async {
    await _storage.write(key: _keyTenantId, value: tenantId);
  }

  // Ler Tenant ID
  static Future<String?> getTenantId() async {
    return await _storage.read(key: _keyTenantId);
  }

  // Salvar Role (papel)
  static Future<void> saveRole(String role) async {
    await _storage.write(key: _keyRole, value: role);
  }

  // Ler Role
  static Future<String?> getRole() async {
    return await _storage.read(key: _keyRole);
  }

  // Salvar Email
  static Future<void> saveEmail(String email) async {
    await _storage.write(key: _keyEmail, value: email);
  }

  // Ler Email
  static Future<String?> getEmail() async {
    return await _storage.read(key: _keyEmail);
  }

  // Salvar Nome
  static Future<void> saveName(String name) async {
    await _storage.write(key: _keyName, value: name);
  }

  // Ler Nome
  static Future<String?> getName() async {
    return await _storage.read(key: _keyName);
  }

  // Salvar E-mail lembrado (Lembrar-me)
  static Future<void> saveRememberedEmail(String email) async {
    await _storage.write(key: _keyRememberedEmail, value: email);
  }

  // Ler E-mail lembrado
  static Future<String?> getRememberedEmail() async {
    return await _storage.read(key: _keyRememberedEmail);
  }

  // Deletar E-mail lembrado
  static Future<void> deleteRememberedEmail() async {
    await _storage.delete(key: _keyRememberedEmail);
  }

  // Limpar todos os dados (Logout)
  static Future<void> clearAll() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyTenantId);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyName);
    // Nota: O _keyRememberedEmail NÃO deve ser deletado no clearAll() para continuar lembrando o e-mail na tela de login.
  }
}
