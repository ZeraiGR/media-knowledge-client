import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:media_knowledge/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Media Knowledge',
      packageName: 'dev.zeraigr.mediaKnowledge',
      version: '0.1.1',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  for (final code in [404, 500]) {
    testWidgets(
      'Manual update check shows progress and result for HTTP $code',
      (tester) async {
        final pending = Completer<http.Response>();
        var requests = 0;
        final client = MockClient((_) {
          requests++;
          return requests == 1
              ? Future.value(http.Response('{}', 404))
              : pending.future;
        });
        await tester.pumpWidget(
          MaterialApp(home: InfrastructureScreen(client: client)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Новых версий пока нет.'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);

        await tester.tap(find.text('Проверить обновления'));
        await tester.pump();
        expect(find.text('Проверяем обновления…'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Проверяем…'),
        );
        expect(button.onPressed, isNull);
        expect(requests, 2);

        pending.complete(http.Response('{}', code));
        await tester.pumpAndSettle();
        final result = code == 404
            ? 'Новых версий пока нет.'
            : 'Не удалось проверить обновления. Попробуйте позже.';
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(result),
          ),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          tester
              .widget<TextButton>(
                find.widgetWithText(TextButton, 'Проверить обновления'),
              )
              .onPressed,
          isNotNull,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
