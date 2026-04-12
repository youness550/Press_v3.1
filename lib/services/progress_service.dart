import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  // Singleton pattern
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- High Scores --- //
  int getBestScore(String difficulty) {
    return _prefs.getInt('bestScore_${difficulty.toLowerCase()}') ?? 0;
  }

  Future<void> saveBestScore(String difficulty, int score) async {
    final currentScore = getBestScore(difficulty);
    if (score > currentScore) {
      await _prefs.setInt('bestScore_${difficulty.toLowerCase()}', score);
    }
  }

  // --- Unlock Flags --- //
  // Easy, Medium, Hard are always unlocked by default.
  
  bool isMasterUnlocked() {
    return _prefs.getBool('isHardCompleted') ?? false;
  }

  bool isExtremeUnlocked() {
    return _prefs.getBool('isMasterCompleted') ?? false;
  }

  Future<void> markHardCompleted() async {
    await _prefs.setBool('isHardCompleted', true);
  }

  Future<void> markMasterCompleted() async {
    await _prefs.setBool('isMasterCompleted', true);
  }
}
