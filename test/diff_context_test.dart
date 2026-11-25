import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_dev/utils/diff_utils.dart';
import 'package:open_dev/views/diff_view.dart';

List<String> labels(int count) => List.generate(count, (i) => 'event ${i + 1}');

void main() {
  test('context keeps original objects, gutter line numbers and totals', () {
    // Test implementation
    final original = labels(21);
    final updated = [...original]..[9] = 'updated event';
    final full = DiffUtils.lineDiff(original.join('\n'), updated.join('\n'));
    final visible = DiffUtils.withChangeContext(full);

    expect(visible.map((row) => row.text), [
      ...original.sublist(6, 9),
      'event 10',
      'updated event',
      ...original.sublist(10, 13),
    ]);

    expect(visible[3].leftLineNo, 10);
    expect(visible[4].rightLineNo, 10);
    expect(identical(visible[3], full[9]), isTrue);
    expect(DiffUtils.stats(full), (added: 1, removed: 1, unchanged: 20));
  });

  test('overlapping contexts emit shared rows once', () {
    final original = labels(20);
    final updated = [...original]
      ..[5] = 'first change'
      ..[9] = 'second change';
    final result = DiffUtils.withChangeContext(
        DiffUtils.lineDiff(original.join('\n'), updated.join('\n')));
    expect(result.where((row) => row.text == 'event 8'), hasLength(1));
    expect(result.first.text, 'event 3');
    expect(result.last.text, 'event 13');
    expect(result.length, 13);
  });

  test('identical input has no changes and context zero keeps only changes',
      () {
    expect(
        DiffUtils.withChangeContext(DiffUtils.lineDiff('a\nb\nc', 'a\nb\nc')),
        isEmpty);
    final full = DiffUtils.lineDiff('a\nb', 'a\nc');
    expect(DiffUtils.withChangeContext(full, context: 0).map((row) => row.op),
        [DiffOp.delete, DiffOp.insert]);
    final original = labels(20);
    final updated = [...original];
    final result = DiffUtils.withChangeContext(
        DiffUtils.lineDiff(original.join('\n'), updated.join('\n')));
    expect(result.length, 0);
  });

  testWidgets('toggle preserves totals and shows the identical state',
      (WidgetTester tester) async {
    // Test implementation
    await tester.binding.setSurfaceSize(const Size(565, 650));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DiffView())),
    );
    final inputs = find.byType(TextField);
    final contents = labels(12).join('\n');

    await tester.enterText(inputs.first, contents);
    await tester.enterText(inputs.last, contents);
    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();
    expect(find.text('event 1'), findsOneWidget);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(find.text('No changes to show.'), findsOneWidget);
    expect(find.text('12 unchanged'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(find.text('event 1'), findsOneWidget);
  });
}
