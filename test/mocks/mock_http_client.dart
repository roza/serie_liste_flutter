import 'dart:convert';
import 'package:http/http.dart' as http;

class MockHttpClient extends http.BaseClient {
  final int statusCode;
  final dynamic body;

  MockHttpClient({this.statusCode = 200, required this.body});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(
      Stream.value(bytes),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

class MockHttpClientError extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw Exception('Pas de connexion réseau');
  }
}
