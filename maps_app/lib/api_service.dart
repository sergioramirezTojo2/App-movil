import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://cdrada.pythonanywhere.com';

  static Future<bool> guardarPunto(double lat, double lng, String nombre) async {
    final url = Uri.parse('$baseUrl/guardar');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lat': lat, 'lng': lng, 'nombre': nombre}),
    );
    return response.statusCode == 201;
  }
static Future<List<Map<String, dynamic>>> obtenerPuntos() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/puntos'));
    if (response.statusCode != 200) throw Exception('Error en el servidor');
    
    final List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData
        .where((p) => p['lat'] != null && p['lng'] != null)
        .map((p) => {
              'nombre': p['nombre'] ?? 'Sin nombre',
              'lat': p['lat'],
              'lng': p['lng'],
            })
        .toList();
  } catch (e) {
    throw Exception('BIENVENIDO GUARDA UN PUNTO DE INTERES');
  }
}


  static Future<bool> eliminarPunto(String nombre) async {
    final url = Uri.parse('$baseUrl/eliminar');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre}),
    );
    return response.statusCode == 200;
  }
}
