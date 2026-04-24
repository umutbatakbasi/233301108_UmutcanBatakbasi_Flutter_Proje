import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klinik_app/app.dart';

void main() {
  testWidgets('App starts test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}