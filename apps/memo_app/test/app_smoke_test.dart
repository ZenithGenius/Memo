import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/app.dart';

void main() {
  testWidgets("l'application démarre sur l'accueil", (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MemoApp()));
    await tester.pumpAndSettle();
    expect(find.text('Memo'), findsWidgets);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
