import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Talks to the Phase 1 backend. Dev auth = x-user-id header (see config.dart).
class ApiClient {
  final http.Client _http;
  final String baseUrl;
  ApiClient({http.Client? client, String? baseUrl})
      : _http = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-user-id': AppConfig.devUserId,
      };

  Future<dynamic> _get(String path) async {
    final res = await _http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await _http.post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body));
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    dynamic body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      body = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = (body is Map && body['message'] != null) ? body['message'].toString() : 'HTTP ${res.statusCode}';
    throw ApiException(msg, res.statusCode);
  }

  /// Operator auto-detect for a typed number (backend endpoint added in Phase 2).
  Future<OperatorInfo> detectOperator(String e164) async {
    final j = await _get('/topups/detect-operator?phone=${Uri.encodeQueryComponent(e164)}');
    return OperatorInfo.fromJson(j as Map<String, dynamic>);
  }

  Future<List<OperatorInfo>> operatorsForCountry(String iso) async {
    final j = await _get('/catalog/countries/$iso/operators');
    return (j as List).map((e) => OperatorInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TopupCreated> createTopup({
    required String recipientPhone,
    required int operatorId,
    required num amountLocalMajor,
    required String idempotencyKey,
  }) async {
    final j = await _post('/topups', {
      'recipientPhone': recipientPhone,
      'operatorId': operatorId,
      'amountLocalMajor': amountLocalMajor,
      'idempotencyKey': idempotencyKey,
    });
    return TopupCreated.fromJson(j as Map<String, dynamic>);
  }

  Future<TopupHistoryItem?> getTopup(String id) async {
    final j = await _get('/topups/$id');
    if (j == null) return null;
    return TopupHistoryItem.fromJson(j as Map<String, dynamic>);
  }

  Future<List<TopupHistoryItem>> myTopups() async {
    final j = await _get('/topups/mine');
    return (j as List).map((e) => TopupHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
