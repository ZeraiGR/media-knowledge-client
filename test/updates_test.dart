import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:media_knowledge/updates.dart';

Map<String, dynamic> manifest(String version, {String? url}) => {
  'schemaVersion': 1,
  'version': version,
  'packages': {
    'android': {
      'url':
          url ??
          'https://github.com/ZeraiGR/media-knowledge-client/releases/download/v$version/app.apk',
      'sha256': 'a' * 64,
    },
  },
};

void main() {
  test('Offers only a newer stable package for the current platform', () {
    expect(
      AppUpdate.parse(manifest('0.2.0'), '0.1.0', 'android')?.version,
      '0.2.0',
    );
    expect(AppUpdate.parse(manifest('0.1.0'), '0.1.0', 'android'), isNull);
    expect(AppUpdate.parse(manifest('0.0.9'), '0.1.0', 'android'), isNull);
    expect(
      AppUpdate.parse(manifest('0.2.0-beta.1'), '0.1.0', 'android'),
      isNull,
    );
    expect(AppUpdate.parse(manifest('0.2.0'), '0.1.0', 'ios'), isNull);
  });
  test('Rejects downloads outside the trusted release', () {
    for (final url in [
      'http://github.com/file',
      'https://evil.example/app.apk',
      'https://github.com/other/repo/app.apk',
    ]) {
      expect(
        () => AppUpdate.parse(manifest('0.2.0', url: url), '0.1.0', 'android'),
        throwsFormatException,
      );
    }
  });
  test('Missing first release is a normal state', () async {
    final client = MockClient((_) async => http.Response('{}', 404));
    expect(await checkForUpdate(client, '0.1.0', 'android'), isNull);
  });
  test('Rejects manifest with version different from release tag', () async {
    final client = MockClient(
      (request) async => request.url.host == 'api.github.com'
          ? http.Response(
              jsonEncode({
                'tag_name': 'v0.3.0',
                'assets': [
                  {
                    'name': 'update-manifest.json',
                    'browser_download_url':
                        'https://github.com/ZeraiGR/media-knowledge-client/releases/download/v0.3.0/update-manifest.json',
                  },
                ],
              }),
              200,
            )
          : http.Response(jsonEncode(manifest('0.2.0')), 200),
    );
    expect(checkForUpdate(client, '0.1.0', 'android'), throwsFormatException);
  });
}
