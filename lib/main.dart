import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/firebase_options.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/record_round/record_round_screen.dart';

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
      home: const MyHomePage(title: 'Turbo Disc Golf'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.sports_golf,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Turbo Disc Golf',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Record your round with voice input',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecordRoundScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.mic),
              label: const Text('Start Recording Round'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
