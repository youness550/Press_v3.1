import 'package:flutter/foundation.dart';

/// Simple global notifier used to signal the game that a full-screen ad
/// is visible and gameplay should be paused. Other parts of the game can
/// listen to `GamePauseNotifier.instance.notifier` to react immediately.
class GamePauseNotifier {
  GamePauseNotifier._private();
  static final GamePauseNotifier instance = GamePauseNotifier._private();

  final ValueNotifier<bool> notifier = ValueNotifier<bool>(false);

  void pauseForAd() {
    notifier.value = true;
  }

  void resumeFromAd() {
    notifier.value = false;
  }
}