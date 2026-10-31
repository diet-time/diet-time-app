import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_time/core/network/api_client.dart';

void main() {
  for (final method in ['GET', 'POST', 'PUT', 'PATCH']) {
    test(
      '$method requests identify Flutter while retaining authentication',
      () async {
        final client = _Client();
        final result = await ApiClient(clientFactory: () => client).request(
          method: method,
          path: '/api/v1/test',
          headers: {'Authorization': 'Bearer test-token'},
        );
        expect(result.statusCode, 200);
        expect(client.requestHeaders.values['X-Client-App'], 'FLUTTER');
        expect(
          client.requestHeaders.values['Authorization'],
          'Bearer test-token',
        );
      },
    );
  }
}

class _Headers implements HttpHeaders {
  final values = <String, Object>{};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      values[name] = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Client implements HttpClient {
  final requestHeaders = _Headers();
  @override
  set connectionTimeout(Duration? value) {}
  Future<HttpClientRequest> request() async => _Request(requestHeaders);
  @override
  Future<HttpClientRequest> getUrl(Uri url) => request();
  @override
  Future<HttpClientRequest> postUrl(Uri url) => request();
  @override
  Future<HttpClientRequest> putUrl(Uri url) => request();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => request();
  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Request implements HttpClientRequest {
  _Request(this.headers);
  @override
  final HttpHeaders headers;
  @override
  Future<HttpClientResponse> close() async => _Response();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(utf8.encode('{}')).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
