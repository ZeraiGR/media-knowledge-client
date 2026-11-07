import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

const releases =
    'https://api.github.com/repos/ZeraiGR/media-knowledge-client/releases/latest';

class AppUpdate {
  final String version;
  final Uri download;
  final String sha256;
  AppUpdate(this.version, this.download, this.sha256);

  static AppUpdate? parse(
    Map<String, dynamic> manifest,
    String current,
    String platform,
  ) {
    if (manifest['schemaVersion'] != 1) {
      throw const FormatException('Unsupported update manifest');
    }
    final version = Version.parse(manifest['version'] as String);
    if (version.isPreRelease || version <= Version.parse(current)) return null;
    final packages = manifest['packages'] as Map<String, dynamic>;
    final package = packages[platform] as Map<String, dynamic>?;
    if (package == null) return null;
    final uri = Uri.parse(package['url'] as String);
    final hash = package['sha256'] as String;
    if (uri.scheme != 'https' ||
        uri.host != 'github.com' ||
        !uri.path.startsWith(
          '/ZeraiGR/media-knowledge-client/releases/download/v$version/',
        ) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
      throw const FormatException('Invalid download');
    }
    return AppUpdate(version.toString(), uri, hash);
  }
}

Future<AppUpdate?> checkForUpdate(
  http.Client client,
  String current,
  String platform,
) async {
  final release = await client
      .get(
        Uri.parse(releases),
        headers: {'Accept': 'application/vnd.github+json'},
      )
      .timeout(const Duration(seconds: 10));
  if (release.statusCode == 404) return null;
  if (release.statusCode != 200) {
    throw const FormatException('Update service unavailable');
  }
  final data = jsonDecode(release.body) as Map<String, dynamic>;
  if (data['draft'] == true || data['prerelease'] == true) return null;
  final assets = data['assets'] as List<dynamic>;
  final manifests = assets.where((a) => a['name'] == 'update-manifest.json');
  if (manifests.isEmpty) return null;
  final uri = Uri.parse(manifests.first['browser_download_url'] as String);
  if (uri.scheme != 'https' ||
      uri.host != 'github.com' ||
      !uri.path.startsWith(
        '/ZeraiGR/media-knowledge-client/releases/download/',
      )) {
    throw const FormatException('Invalid manifest location');
  }
  final response = await client.get(uri).timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw const FormatException('Manifest unavailable');
  }
  final manifest = jsonDecode(response.body) as Map<String, dynamic>;
  if ('v${manifest['version']}' != data['tag_name']) {
    throw const FormatException('Version mismatch');
  }
  return AppUpdate.parse(manifest, current, platform);
}
