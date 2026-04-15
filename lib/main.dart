import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pressing_under_pressure/screens/menu_screen.dart';
import 'package:pressing_under_pressure/screens/game_screen.dart';
import 'package:pressing_under_pressure/screens/no_internet_screen.dart';
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
      // Connectivity gate wraps the entire app
      home: const ConnectivityGate(),
    );
  }
}

/// Wraps the app with a connectivity check.
/// Shows [NoInternetScreen] when offline and the main app when online.
/// Continuously listens for connectivity changes.
class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({super.key});

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  bool _isConnected = true; // optimistic default
  bool _initialCheckDone = false;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _hasInternetConnection(List<ConnectivityResult> results) {
    return results.isNotEmpty && 
           !results.any((result) => result == ConnectivityResult.none);
  }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();

    // Listen for real-time changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final connected = _hasInternetConnection(results);
      if (mounted) {
        setState(() => _isConnected = connected);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final connected = _hasInternetConnection(results);
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _initialCheckDone = true;
        });
      }
    } catch (_) {
      // If check fails, fail closed to enforce Wi-Fi requirement.
      if (mounted) {
        setState(() {
          _isConnected = false;
          _initialCheckDone = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show nothing while checking (very brief)
    if (!_initialCheckDone) {
      return const Scaffold(
        backgroundColor: Color(0xFF000a00),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF66)),
        ),
      );
    }

    if (!_isConnected) {
      return NoInternetScreen(
        onRetry: () => _checkConnectivity(),
      );
    }

    // Connected — show the main app with navigator
    return Navigator(
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/game':
            final args = settings.arguments;
            final difficulty = (args is String) ? args : 'medium';
            return MaterialPageRoute(
              builder: (_) => GameScreen(difficulty: difficulty),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const MainMenuScreen(),
              settings: settings,
            );
        }
      },
    );
  }
}