import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:diet_time/core/config/app_environment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  ApiClient({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? HttpClient.new;

  final HttpClient Function() _clientFactory;

  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      AppEnvironment.apiBaseUrl,
    ).resolve(path).replace(queryParameters: queryParameters);
    final client = _clientFactory()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await switch (method) {
        'GET' => client.getUrl(uri),
        'POST' => client.postUrl(uri),
        'PUT' => client.putUrl(uri),
        'PATCH' => client.patchUrl(uri),
        _ => throw ArgumentError.value(method, 'method'),
      }.timeout(const Duration(seconds: 15));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set(HttpHeaders.contentTypeHeader, 'application/json');
      headers.forEach(request.headers.set);
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      final text = await utf8.decoder.bind(response).join();
      Map<String, dynamic> decoded = const {};
      if (text.trim().isNotEmpty) {
        final value = jsonDecode(text);
        if (value is Map<String, dynamic>) decoded = value;
      }
      return ApiResponse(statusCode: response.statusCode, body: decoded);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(ApiFailure.timeout);
    } on SocketException {
      throw const ApiException(ApiFailure.network);
    } on Object {
      throw const ApiException(ApiFailure.invalidResponse);
    } finally {
      client.close(force: true);
    }
  }
}

class ApiResponse {
  const ApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

enum ApiFailure {
  network,
  timeout,
  validation,
  unauthorized,
  notFound,
  conflict,
  server,
  invalidResponse,
}

class ApiException implements Exception {
  const ApiException(
    this.failure, {
    this.statusCode,
    this.message,
    this.code,
    this.fieldErrors = const {},
  });

  factory ApiException.fromResponse(ApiResponse response) {
    final errors = response.body['errors'];
    String? message;
    String? code;
    final fieldErrors = <String, String>{};
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map<String, dynamic>) {
        message = first['message']?.toString();
        code = first['code']?.toString();
      }
    }
    if (message?.trim().isNotEmpty != true && errors is Map) {
      for (final entry in errors.entries) {
        final value = entry.value;
        String? fieldMessage;
        if (value is List && value.isNotEmpty) {
          fieldMessage = value.first?.toString();
        } else if (value != null) {
          fieldMessage = value.toString();
        }
        if (fieldMessage?.trim().isNotEmpty == true) {
          fieldErrors[entry.key.toString()] = fieldMessage!.trim();
          message ??= fieldMessage;
        }
      }
    }
    message ??=
        response.body['detail']?.toString() ??
        response.body['message']?.toString() ??
        response.body['title']?.toString();
    code ??= response.body['code']?.toString();
    final failure = switch (response.statusCode) {
      400 => ApiFailure.validation,
      401 => ApiFailure.unauthorized,
      404 => ApiFailure.notFound,
      409 => ApiFailure.conflict,
      >= 500 => ApiFailure.server,
      _ => ApiFailure.invalidResponse,
    };
    return ApiException(
      failure,
      statusCode: response.statusCode,
      message: message,
      code: code,
      fieldErrors: Map.unmodifiable(fieldErrors),
    );
  }

  final ApiFailure failure;
  final int? statusCode;
  final String? message;
  final String? code;
  final Map<String, String> fieldErrors;
}
