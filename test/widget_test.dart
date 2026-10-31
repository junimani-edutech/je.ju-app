import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/main.dart';

void main() {
  testWidgets('JeJuApp renders without crashing', (tester) async {
    await tester.pumpWidget(const JeJuApp());

    // Cari teks judul di layar
    expect(find.text('JeJu — Fondasi siap'), findsOneWidget);

    // Pastikan MaterialApp terpasang
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
