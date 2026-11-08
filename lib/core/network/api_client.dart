import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:diet_time/core/performance/performance_trace.dart';

import 'package:diet_time/core/config/app_environment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    languageCode: () => ref.read(languageControllerProvider).languageCode,
  );
  ref.onDispose(client.close);
  return client;
});

class ApiClient {
  ApiClient({
    HttpClient Function()? clientFactory,
    String Function()? languageCode,
    this.requestTimeout = const Duration(seconds: 40),
    this.baseUrl = AppEnvironment.apiBaseUrl,
  }) : _languageCode = languageCode,
       _clientFactory = clientFactory ?? HttpClient.new;

  final HttpClient Function() _clientFactory;
  final String Function()? _languageCode;
  final Duration requestTimeout;
  final String baseUrl;
  HttpClient? _client;
  bool _closed = false;

  void close() {
    _closed = true;
    _client?.close(force: true);
    _client = null;
  }

  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).resolve(path).replace(queryParameters: queryParameters);
    if (_closed) throw StateError('ApiClient is closed');
    final client = _client ??= (_clientFactory()
      ..connectionTimeout = const Duration(seconds: 15));
    final watch = Stopwatch()..start();
    HttpClientRequest? pending;
    var expired = false;
    var outcome = 'failure';
    Duration remaining(Duration limit) {
      final available = requestTimeout - watch.elapsed;
      if (available <= Duration.zero) {
        throw TimeoutException('Request deadline');
      }
      return available < limit ? available : limit;
    }

    try {
      final openBudget = remaining(const Duration(seconds: 15));
      final opening = switch (method) {
        'GET' => client.getUrl(uri),
        'POST' => client.postUrl(uri),
        'PUT' => client.putUrl(uri),
        'PATCH' => client.patchUrl(uri),
        _ => throw ArgumentError.value(method, 'method'),
      };
      final request = await opening
          .then((request) {
            if (expired || _closed) {
              request.abort();
              throw TimeoutException(
                'Connection finished after request deadline',
              );
            }
            pending = request;
            return request;
          })
          .timeout(openBudget);
      remaining(requestTimeout);
      request.headers
        ..set('X-Client-App', 'FLUTTER')
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set(HttpHeaders.contentTypeHeader, 'application/json');
      if (_languageCode != null) {
        request.headers.set(HttpHeaders.acceptLanguageHeader, _languageCode());
      }
      headers.forEach(request.headers.set);
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(
        remaining(const Duration(seconds: 25)),
      );
      final bodyBudget = remaining(requestTimeout);
      final text = await _readBody(response, bodyBudget);
      outcome = '${response.statusCode}';
      Map<String, dynamic> decoded = const {};
      if (text.trim().isNotEmpty) {
        final value = jsonDecode(text);
        if (value is Map<String, dynamic>) decoded = value;
      }
      return ApiResponse(statusCode: response.statusCode, body: decoded);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      expired = true;
      pending?.abort();
      outcome = 'timeout';
      throw const ApiException(ApiFailure.timeout);
    } on SocketException {
      throw const ApiException(ApiFailure.network);
    } on Object {
      throw const ApiException(ApiFailure.invalidResponse);
    } finally {
      final family = path.endsWith('/orders/dashboard')
          ? 'dashboard_summary'
          : path.endsWith('/tomorrow-menu')
          ? 'tomorrow_menu'
          : path.endsWith('/package-management')
          ? 'package_management'
          : path.endsWith('/upcoming-meals')
          ? 'delivery_calendar'
          : path.contains('/service-days/')
          ? 'service_day'
          : path.contains('/orders')
          ? 'orders'
          : path.contains('meal-plan')
          ? 'meal_plans'
          : path.contains('auth')
          ? 'auth'
          : 'other';
      PerformanceTrace.record('api.$method.$family', watch, outcome: outcome);
    }
  }

  Future<String> _readBody(HttpClientResponse response, Duration budget) async {
    final complete = Completer<String>();
    final buffer = StringBuffer();
    final subscription = utf8.decoder
        .bind(response)
        .listen(
          buffer.write,
          onError: (Object error, StackTrace stack) {
            if (!complete.isCompleted) complete.completeError(error, stack);
          },
          onDone: () {
            if (!complete.isCompleted) complete.complete(buffer.toString());
          },
          cancelOnError: true,
        );
    final deadline = Timer(budget, () {
      if (complete.isCompleted) return;
      unawaited(subscription.cancel());
      complete.completeError(TimeoutException('Response body deadline'));
    });
    try {
      return await complete.future;
    } finally {
      deadline.cancel();
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
