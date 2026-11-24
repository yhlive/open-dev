import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_dev/utils/csv_utils.dart';
import 'package:open_dev/views/csv_view.dart';

void main() {
  final cases = [
    (
      imput: 'id,flag\n00123,true',
      delimiter: ',',
      text: {'id': '00123', 'flag': 'true'},
      typed: {"id": 123, "flag": true}
    ),
    (
      imput: 'zip;amount\r\n002108;004.50',
      delimiter: ';',
      text: {'zip': '002108', 'amount': '004.50'},
      typed: {"zip": 2108, "amount": 4.5}
    ),
    (
      imput: 'id,note\n007,"first, line\nsecond ""quoted"""',
      delimiter: ',',
      text: {'id': '007', 'note': 'first, line\nsecond "quoted"'},
      typed: {"id": 7, "note": 'first, line\nsecond "quoted"'}
    ),
    (
      imput: 'id\tflag\tempty\tmissing\n00123\tnull\t',
      delimiter: '\t',
      text: {'id': '00123', 'flag': 'null', 'empty': '', 'missing': null},
      typed: {"id": 123, "flag": null, "empty": '', "missing": null}
    )
  ];

  for (final (index, input) in cases.indexed) {
    test('keeps text or coerces cells for fixture ${index + 1}', () {
      final json = CsvUtils.csvToJson(input.imput,
          delimiter: input.delimiter, keepValuesAsText: true);
      expect(jsonDecode(json), [input.text]);
      final typedJson = CsvUtils.csvToJson(input.imput,
          delimiter: input.delimiter, keepValuesAsText: false);
      expect(jsonDecode(typedJson), [input.typed]);
    });

    test('jsonToCsv throws on non-array root #$index', () {
      const nonArrayJson = '{"id": 42}';
      expect(
          () => CsvUtils.jsonToCsv(nonArrayJson, delimiter: input.delimiter),
          throwsA(isA<FormatException>().having((e) => e.message, 'message',
              contains('JSON root must be an array'))));
    });

    test('jsonToCsv throws on non-object array element #$index', () {
      const nonObjectJson = '[{"id": 42}, 123]';
      expect(
          () => CsvUtils.jsonToCsv(nonObjectJson, delimiter: input.delimiter),
          throwsA(isA<FormatException>().having((e) => e.message, 'message',
              contains('JSON array must contain objects'))));
    });

    testWidgets('converts in text mode and stale output on error',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: CsvView())));
      final input = find.byType(TextField).first;
      String output() => tester
          .widget<TextField>(find.byType(TextField).last)
          .controller!
          .text;

      await tester.enterText(input, 'id,zip\n00123,02108');
      await tester.tap(find.text('Convert'));
      await tester.pumpAndSettle();
      expect(jsonDecode(output()), [
        {"id": 123, "zip": 2108}
      ]);

      await tester.tap(find.text('Keep values as text'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Convert'));
      await tester.pumpAndSettle();
      expect(jsonDecode(output()), [
        {"id": "00123", "zip": "02108"}
      ]);

      await tester.enterText(input, 'id,id\n00123,00456');
      await tester.tap(find.text('Convert'));
      await tester.pumpAndSettle();
      expect(find.text('Duplicate header name: "id" at column 2.'),
          findsOneWidget);
      expect(output(), isEmpty);
    });
  }
}
