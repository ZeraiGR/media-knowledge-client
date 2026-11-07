import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'updates.dart';

void main() => runApp(const MediaKnowledgeApp());

class MediaKnowledgeApp extends StatelessWidget {
  const MediaKnowledgeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Media Knowledge',
    theme: ThemeData(
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark,
    ),
    home: const InfrastructureScreen(),
  );
}

class InfrastructureScreen extends StatefulWidget {
  const InfrastructureScreen({super.key});
  @override
  State<InfrastructureScreen> createState() => _InfrastructureScreenState();
}

class _InfrastructureScreenState extends State<InfrastructureScreen>
    with WidgetsBindingObserver {
  final _client = http.Client();
  Timer? _timer;
  AppUpdate? _update;
  String _status = 'Проверяем обновления…';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    _timer = Timer.periodic(const Duration(hours: 4), (_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      if (Platform.isIOS) {
        if (mounted) {
          setState(
            () => _status =
                'Канал обновлений iOS подключим после настройки Apple Developer.',
          );
        }
        return;
      }
      final info = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isMacOS
          ? 'macos'
          : 'windows';
      final update = await checkForUpdate(_client, info.version, platform);
      if (mounted) {
        setState(() {
          _update = update;
          _status = update == null
              ? 'Новых версий пока нет.'
              : 'Доступна версия ${update.version}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _status = 'Не удалось проверить обновления. Попробуйте позже.',
        );
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _download() async {
    final update = _update;
    if (update == null) return;
    final opened = await launchUrl(
      update.download,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() => _status = 'Не удалось открыть загрузку установщика.');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Media Knowledge')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Подготовка медиатеки',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text('Библиотека и плеер появятся в следующих версиях.'),
              const SizedBox(height: 24),
              Text(_status),
              const SizedBox(height: 16),
              if (_update != null)
                FilledButton(
                  onPressed: _download,
                  child: const Text('Скачать новую версию'),
                ),
              TextButton(
                onPressed: _check,
                child: const Text('Проверить обновления'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
