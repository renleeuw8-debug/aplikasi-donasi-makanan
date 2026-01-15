import 'package:flutter/material.dart';
import 'screens/donatur/auth_gate.dart';
import 'screens/donatur/splash_page.dart';
import 'screens/donatur/home_page.dart';
import 'screens/petugas/petugas_home_page.dart';
import 'screens/penerima/penerima_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase if available (some pages may still use it)
  try {
    // Initialize Firebase with minimal config - only if needed
    // Since we're using backend MySQL, this is optional
    // await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization skipped or failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF388E3C), // hijau utama
      onPrimary: Colors.white,
      secondary: const Color(0xFF43A047), // hijau aksen
      onSecondary: Colors.white,
      error: const Color(0xFFD32F2F), // merah dialog
      onError: Colors.white,
      background: Colors.white,
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
      primaryContainer: const Color(0xFF388E3C),
      onPrimaryContainer: Colors.white,
      secondaryContainer: const Color(0xFF43A047),
      onSecondaryContainer: Colors.white,
    );
    return MaterialApp(
      title: 'Donasi Makanan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: scheme.background,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.primary.withOpacity(0.18)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.primary.withOpacity(0.18)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.primary, width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: BorderSide(color: scheme.primary, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: scheme.secondary.withOpacity(0.08),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          surfaceTintColor: scheme.surface,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          contentTextStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: scheme.primaryContainer,
          surfaceTintColor: scheme.surface,
          backgroundColor: scheme.background,
        ),
      ),
      home: const SplashGate(),
      routes: {
        '/donatur-home': (context) => const HomeShell(),
        '/penerima-home': (context) => const PenerimaHomeShell(),
        '/petugas-home': (context) => const PetugasHomeShell(),
      },
    );
  }
}

// SplashGate menampilkan splash lalu lanjut ke AuthGate
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashPage();
    }
    return const AuthGate();
  }
}

// Alias untuk route navigation
// PenerimaHomeShell sudah diimport langsung dari penerima/penerima_home_page.dart
