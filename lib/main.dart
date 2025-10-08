import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/firebase_options.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/main_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setUpLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Turbo Disc Golf',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: const Color(
            0xFF9D7FFF,
          ), // Brighter purple (30% more vibrant)
          secondary: const Color(0xFF10E5FF), // Brighter electric blue
          surface: const Color(
            0xFF242938,
          ), // Lighter surface for better separation
          error: const Color(0xFFFF7A7A), // Brighter warm red
          onPrimary: const Color(0xFFF5F5F5), // 96% white (WCAG AAA)
          onSecondary: const Color(0xFFF5F5F5), // 96% white
          onSurface: const Color(0xFFF5F5F5), // 96% white
          onError: const Color(0xFF0A0E17), // Dark on error
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        cardTheme: const CardThemeData(
          color: Color(0xFF242938),
          elevation: 6,
          shadowColor: Colors.black87,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF242938),
          foregroundColor: Color(0xFFF5F5F5),
          elevation: 3,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFFF5F5F5)),
          displayMedium: TextStyle(color: Color(0xFFF5F5F5)),
          displaySmall: TextStyle(color: Color(0xFFF5F5F5)),
          headlineLarge: TextStyle(color: Color(0xFFF5F5F5)),
          headlineMedium: TextStyle(color: Color(0xFFF5F5F5)),
          headlineSmall: TextStyle(color: Color(0xFFF5F5F5)),
          titleLarge: TextStyle(color: Color(0xFFF5F5F5)),
          titleMedium: TextStyle(color: Color(0xFFF5F5F5)),
          titleSmall: TextStyle(color: Color(0xFFF5F5F5)),
          bodyLarge: TextStyle(color: Color(0xFFF5F5F5)),
          bodyMedium: TextStyle(color: Color(0xFFF5F5F5)),
          bodySmall: TextStyle(color: Color(0xFFC0C0C0)),
          labelLarge: TextStyle(color: Color(0xFFF5F5F5)),
          labelMedium: TextStyle(color: Color(0xFFF5F5F5)),
          labelSmall: TextStyle(color: Color(0xFFC0C0C0)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF242938),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF9D7FFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4A4F5E)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF9D7FFF), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFFC0C0C0)),
          hintStyle: const TextStyle(color: Color(0xFF8A8F9E)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9D7FFF),
            foregroundColor: const Color(0xFFF5F5F5),
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF10E5FF)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF5F5F5)),
      ),
      home: const MainWrapper(),
    );
  }
}
