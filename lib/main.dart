import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ZinkApp(),
    ),
  );
}

class ZinkApp extends StatelessWidget {
  const ZinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zink',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8DD5F2),
          primary: const Color(0xFF8DD5F2),
          secondary: const Color(0xFFF2CB9B),
          tertiary: const Color(0xFFF25C05),
          error: const Color(0xFFF23005),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8DD5F2),
          primary: const Color(0xFF8DD5F2),
          secondary: const Color(0xFFF2CB9B),
          tertiary: const Color(0xFFF25C05),
          error: const Color(0xFFF23005),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Welcome to Zink!'),
        ),
      ),
    );
  }
}
