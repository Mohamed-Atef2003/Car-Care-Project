import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  final String baseUrl = 'https://your-api-base-url.com';

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      body: json.encode(body),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
