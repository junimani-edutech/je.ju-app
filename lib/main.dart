import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .env opsional pada Fase 1. Jika belum ada, aplikasi tetap jalan.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Diabaikan: .env belum wajib sampai Fase 2.
  }
  runApp(const JeJuApp());
}

class JeJuApp extends StatelessWidget {
  const JeJuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JeJu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('JeJu — Fondasi siap'))),
    );
  }
}
