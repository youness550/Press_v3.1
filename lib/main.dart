import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pressing_under_pressure/screens/menu_screen.dart';
import 'package:pressing_under_pressure/screens/game_screen.dart';
import 'package:pressing_under_pressure/services/ads_service.dart';
import 'package:pressing_under_pressure/services/progress_service.dart';

/// App entrypoint. Keeps `main.dart` minimal: app initialization
/// and route configuration only.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait for best game experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Immersive status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));
  await ProgressService().init();
  await AdsService().initialize();
  runApp(const PressingUnderPressure());
}

class PressingUnderPressure extends StatelessWidget {
  const PressingUnderPressure({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000a00),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FF66),
          brightness: Brightness.dark,
          surface: const Color(0xFF0a0a0a),
        ),
        fontFamily: 'Courier',
        splashColor: const Color(0x2200FF66),
        highlightColor: const Color(0x1100FF66),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
      // Define named routes for simple navigation between menu and game.
      routes: {
        '/': (c) => const MainMenuScreen(),
        '/game': (c) {
          final args = ModalRoute.of(c)?.settings.arguments;
          final difficulty = (args is String) ? args : 'medium';
          return GameScreen(difficulty: difficulty);
        },
      },
      initialRoute: '/',
    );
  }
}