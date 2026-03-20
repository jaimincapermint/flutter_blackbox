// Single import — everything comes from one package now
import 'package:flutter_blackbox/flutter_blackbox.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

void main() {
  BlackBox.setup(
    httpAdapters: [DioBlackBoxAdapter(dio)], // Option A — Dio
    // httpAdapters: [HttpBlackBoxAdapter()],        // Option B — http package
    logAdapter: PrintLogAdapter(),
    flagAdapter: LocalFlagAdapter(flags: {
      'new_checkout': const FlagConfig(defaultValue: false, group: 'Checkout'),
      'show_banner': const FlagConfig(defaultValue: true, group: 'Marketing'),
    }),
    trigger: const BlackBoxTrigger.floatingButton(),
    enabled: kDebugMode,
  );

  BlackBox.mock(
    pattern: '/api/orders',
    method: 'GET',
    response:
        const MockResponse(statusCode: 200, body: {'orders': <dynamic>[]}),
  );

  runApp(const BlackBoxOverlay(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'devkit example',
        theme: ThemeData.dark(useMaterial3: true),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('devkit example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Tile('Log info',
              () => BlackBox.log('hello', level: LogLevel.info, tag: 'Home')),
          _Tile('Log error',
              () => BlackBox.log('failed', level: LogLevel.error, tag: 'Pay')),
          _Tile('debugPrint', () => debugPrint('[Auth] token refreshed')),
          const _Tile('Open BlackBox', BlackBox.open),
          _Tile('GET /api/orders (mock)', () async {
            try {
              await dio.get<dynamic>('/api/orders');
            } catch (_) {}
          }),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.title, this.onTap);
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
