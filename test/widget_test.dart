import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrymatch106/main.dart';

void main() {
  testWidgets('PantryMatch app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const PantryMatchApp());

    expect(find.byType(MaterialApp), findsOneWidget);

    // Dispose the splash before its timer fires.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
