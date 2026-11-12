import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  const InfrastructureScreen({super.key, this.client});
  final http.Client? client;
  @override
  State<InfrastructureScreen> createState() => _InfrastructureScreenState();
}

class _InfrastructureScreenState extends State<InfrastructureScreen>
    with WidgetsBindingObserver {
  late final _client = widget.client ?? http.Client();
  final _server = TextEditingController();
  String _serverStatus = 'Укажите HTTPS-адрес сервера из личных настроек.';
  Timer? _timer;
  AppUpdate? _update;
  String _status = 'Проверяем обновления…';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    _loadServer();
    _timer = Timer.periodic(const Duration(hours: 4), (_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _loadServer() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _server.text = prefs.getString('serverUrl') ?? '';
    if (_server.text.isNotEmpty) await _connect();
  }

  Future<void> _connect() async {
    final uri = Uri.tryParse(_server.text.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      setState(
        () =>
            _serverStatus = 'Нужен HTTPS-адрес без пути, пароля и параметров.',
      );
      return;
    }
    setState(() => _serverStatus = 'Подключаемся…');
    try {
      final response = await _client
          .get(uri.resolve('/api/readyz'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw const FormatException('Server not ready');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('serverUrl', uri.origin);
      if (mounted) {
        setState(
          () => _serverStatus =
              'Сервер доступен. Адрес сохранён на этом устройстве.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _serverStatus =
              'Сервер недоступен. Проверьте адрес и подключение Tailscale.',
        );
      }
    }
  }

  Future<void> _check({bool manual = false}) async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _status = 'Проверяем обновления…';
    });
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
      if (mounted) {
        setState(() => _checking = false);
        if (manual) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(content: Text(_status)));
        }
      }
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
    _server.dispose();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Media Knowledge')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
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
                TextField(
                  controller: _server,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Адрес сервера',
                    hintText: 'https://server.example:10001',
                  ),
                ),
                TextButton(
                  onPressed: _connect,
                  child: const Text('Подключиться'),
                ),
                Text(_serverStatus),
                const SizedBox(height: 24),
                Text(_status),
                const SizedBox(height: 16),
                if (_update != null)
                  FilledButton(
                    onPressed: _download,
                    child: const Text('Скачать новую версию'),
                  ),
                TextButton.icon(
                  onPressed: _checking ? null : () => _check(manual: true),
                  icon: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _checking ? 'Проверяем…' : 'Проверить обновления',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
