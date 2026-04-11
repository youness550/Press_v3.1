import 'package:flutter/material.dart';
import 'package:pressing_under_pressure/screens/menu_screen.dart';
import 'package:pressing_under_pressure/screens/game_screen.dart';
import 'package:pressing_under_pressure/services/ads_service.dart';

/// App entrypoint. Keeps `main.dart` minimal: app initialization
/// and route configuration only.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdsService().initialize();
  runApp(const PressingUnderPressure());
}

class PressingUnderPressure extends StatelessWidget {
  const PressingUnderPressure({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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