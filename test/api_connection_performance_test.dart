import 'dart:io';

import 'package:diet_time/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a stalled body times out without closing other concurrent requests',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final stalled = <HttpResponse>[];
      server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/stall') {
          stalled.add(request.response);
          request.response.write('{');
          await request.response.flush();
        } else {
          request.response.write('{"data":[]}');
          await request.response.close();
        }
      });
      final api = ApiClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        requestTimeout: const Duration(milliseconds: 500),
      );
      try {
        final timeout = expectLater(
          api.request(method: 'GET', path: '/stall'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.failure,
              'failure',
              ApiFailure.timeout,
            ),
          ),
        );
        final success = await api.request(method: 'GET', path: '/ok');
        expect(success.isSuccess, isTrue);
        await timeout;
        expect(
          (await api.request(method: 'GET', path: '/ok')).isSuccess,
          isTrue,
        );
      } finally {
        api.close();
        await server.close(force: true);
      }
    },
  );

  test('pooled requests send only the current request credentials', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final authorization = <String?>[];
    server.listen((request) async {
      authorization.add(request.headers.value(HttpHeaders.authorizationHeader));
      request.response.write('{}');
      await request.response.close();
    });
    final api = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
    try {
      await api.request(
        method: 'GET',
        path: '/ok',
        headers: {'Authorization': 'Bearer customer-a'},
      );
      await api.request(
        method: 'GET',
        path: '/ok',
        headers: {'Authorization': 'Bearer customer-b'},
      );
      await api.request(method: 'GET', path: '/ok');
      expect(authorization, ['Bearer customer-a', 'Bearer customer-b', null]);
    } finally {
      api.close();
      await server.close(force: true);
    }
  });
  test(
    'sequential requests reuse a connection; local transport benchmark',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final ports = <int>{};
      server.listen((request) async {
        ports.add(request.connectionInfo!.remotePort);
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"data":[]}');
        await request.response.close();
      });
      final api = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
      final watch = Stopwatch()..start();
      try {
        for (var i = 0; i < 6; i++) {
          final response = await api.request(method: 'GET', path: '/benchmark');
          expect(response.isSuccess, isTrue);
        }
        // ignore: avoid_print
        print(
          'TRANSPORT_BENCHMARK requests=6 connections=${ports.length} '
          'elapsed_us=${watch.elapsedMicroseconds}',
        );
        expect(ports.length, 1);
      } finally {
        api.close();
        await server.close(force: true);
      }
    },
  );
}
