import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_dev/utils/json_utils.dart';
import 'package:open_dev/views/json_view.dart';
import 'package:open_dev/widgets/json/json_viewer_widget.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  test('objects, arrays and scalars survive formatting', () {
    for (final input in ['{"active":true}', '[1,{"id":"00123"}]', 'null']) {
      final formatted = prettyJson(input);
      expect(jsonDecode(formatted), jsonDecode(input));
      expect(minifyJson(formatted), input);
    }
    expect(prettyJson('[1,2,3]'), '[\n  1,\n  2,\n  3\n]');
  });

  test('reports line and clolum for offsets in LF and CRLF input', () {
    for (final source in ['{\n  "id": 42,\n}', '{\r\n  "id": 42,\r\n}']) {
      try {
        jsonDecode(source);
        fail('Expected invalid JSON to throw');
      } on FormatException catch (e) {
        final desc = describeJsonError(e, source);
        expect(desc, startsWith('Line 3, column 1:'));
      }
    }
  });

  test('handles a missing offset and an error at the end of input', () {
    expect(describeJsonError(const FormatException('Invalid'), ''), 'Invalid');
    expect(describeJsonError(const FormatException('EOF', null, 2), '[\n'),
        'Line 2, column 1: EOF');
  });

  testWidgets('preview switches to arrays and clears a recovered error',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: JsonView())));
    final editor = tester.widget<CodeEditor>(find.byType(CodeEditor));
    editor.controller!.text = '{\n  "id": 42,\n}';
    await tester.tap(find.text('parse'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Line 3, column 1:'), findsOneWidget);

    editor.controller!.text = '[{"id": "42"}, null]';
    await tester.tap(find.text('parse'));
    await tester.pumpAndSettle();
    expect(find.byType(JsonArrayViewerWidget), findsOneWidget);
    expect(find.textContaining('Line 3, column 1:'), findsNothing);

    editor.controller!.text = '[{"id": "42"}, true, null]';
    await tester.tap(find.text('parse'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    editor.controller!.text = '{"id": 42}';
    await tester.tap(find.text('parse'));
    await tester.pumpAndSettle();
    expect(find.byType(JsonViewerWidget), findsOneWidget);
  });
}
