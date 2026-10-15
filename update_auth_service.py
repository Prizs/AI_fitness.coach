path = 'mobile_app/lib/services/auth_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_login_block = """  Future<bool> login(String cedula, String password) async {
    lastError = null;
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cedula': cedula, 'password': password}),
      ).timeout(const Duration(seconds: 5));
    } on Exception {
      lastError = 'No se pudo conectar con el servidor.';
      return false;
    }"""

new_login_block = """  Future<bool> login(String cedula, String password) async {
    lastError = null;
    http.Response? response;

    // 1. Intentar con el servidor primario
    try {
      response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cedula': cedula, 'password': password}),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      response = null;
    }

    // 2. Si falla, intentar automaticamente con el servidor alterno (Local o Render)
    if (response == null || response.statusCode == 502 || response.statusCode == 503) {
      final alternateUrl = apiBaseUrl.contains('localhost') || apiBaseUrl.contains('127.0.0.1')
          ? 'https://ai-fitness-coach-818a.onrender.com'
          : 'http://localhost:8000';
      try {
        final altResponse = await http.post(
          Uri.parse('$alternateUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'cedula': cedula, 'password': password}),
        ).timeout(const Duration(seconds: 15));

        if (altResponse.statusCode >= 200 && altResponse.statusCode < 500) {
          response = altResponse;
          _apiBaseUrl = alternateUrl; // Conmutacion automatica exitosa
          saveServerConfig(alternateUrl);
        }
      } catch (_) {}
    }

    if (response == null) {
      lastError = 'No se pudo conectar con el servidor (intentado Local y Nube).';
      return false;
    }"""

text = text.replace(old_login_block, new_login_block)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Updated AuthService with automatic failover!")
