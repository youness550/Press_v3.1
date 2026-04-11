import '../data/questions_data.dart';

enum ValidationResult { win, fail }

class GameLogic {
  GameLogic({List<Map<String, dynamic>>? questions}) : questions = questions ?? questionsForDifficulty('medium');

  final List<Map<String, dynamic>> questions;

  bool checkWin(int currentQuestionIndex, int clicks, double progress) {
    final lvl = questions[currentQuestionIndex];
    if (lvl['type'] == 'click' && clicks == lvl['target']) return true;
    if (lvl['type'] == 'wait' && clicks == 0) return true;
    if (lvl['type'] == 'last_second' && clicks == 1 && progress >= 0.9) return true;
    return false;
  }

  ValidationResult validate(int currentQuestionIndex, int clicks, double progress) {
    return checkWin(currentQuestionIndex, clicks, progress) ? ValidationResult.win : ValidationResult.fail;
  }

  int getCheckpointIndex(int currentIndex) {
    if (currentIndex < 17) return 0;
    if (currentIndex < 34) return 17;
    return 34;
  }

  int finalScoreFromIndex(int currentIndex) => currentIndex;
}
