import 'dart:convert';
import 'package:http/http.dart' as http;
import '../util/env.dart';

class HttpClient {
  final _base = baseUrl;
  final _token = apiToken;

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? headers, Map<String, String>? query}) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: {
      'Accept': 'application/json',
      if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      ...?headers,
    });
    if (res.statusCode >= 400) throw Exception('GET $path ${res.statusCode}: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}