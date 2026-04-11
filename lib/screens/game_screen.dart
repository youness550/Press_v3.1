// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pressing_under_pressure/services/audio_manager.dart';
import 'package:pressing_under_pressure/services/ads_service.dart';
import 'package:pressing_under_pressure/services/game_pause.dart';
import 'package:pressing_under_pressure/game/game_logic.dart';
import 'package:pressing_under_pressure/data/questions_data.dart';
import 'package:pressing_under_pressure/ui/components/image_style_timer_painter.dart';
import 'package:pressing_under_pressure/ui/components/background_beams.dart';

// Helper to create a color with explicit opacity without using deprecated
// `withOpacity` to avoid precision-loss deprecation warnings.
Color _colorWithOpacity(Color c, double opacity) =>
  Color.fromRGBO(c.red, c.green, c.blue, opacity);

/// Main game screen that presents the challenge nodes and handles
/// gameplay animations, timers, scoring and transitions.
class GameScreen extends StatefulWidget {
  final String difficulty;
  const GameScreen({super.key, this.difficulty = 'medium'});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  int currentQuestionIndex = 0;
  int clicks = 0;
  double progress = 0.0;
  Timer? timer;
  bool isPressed = false;
  bool isFailing = false;

  late AnimationController _shakeController;
  late AnimationController _colorController;
  late AnimationController _dramaticController;
  late Animation<double> _shakeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _dramaticScale;
  late Animation<double> _dramaticRotate;
  late Animation<double> _dramaticOverlay;

  // Press animation for 3D button effect
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  // Game over navigation guards
  bool _shouldShowGameOver = false;
  int _pendingCheckpointIndex = 0;
  int bestScore = 0;

  Color currentColor = const Color(0xFF00FF00); // Green
  late List<Map<String, dynamic>> questions;
  late String difficulty;

  // Pause state
  bool _isPaused = false;
  bool _pausedByAd = false;
  late GameLogic gameLogic;

  @override
  void initState() {
    super.initState();
    difficulty = widget.difficulty;
    questions = questionsForDifficulty(difficulty);
    _prepareQuestionsForDifficulty();
    gameLogic = GameLogic(questions: questions);

    // Animation controllers for dramatic fail sequence and small shake/color effects
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.bounceIn),
    );
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: const Color(0xFF00FF00),
      end: const Color(0xFFFF0000),
    ).animate(_colorController);
    _shakeController.addListener(() => setState(() {}));
    _colorController.addListener(() => setState(() {}));

    _dramaticController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _dramaticScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _dramaticController, curve: Curves.easeInOut),
    );
    _dramaticRotate = Tween<double>(begin: 0.0, end: 0.12).animate(
      CurvedAnimation(parent: _dramaticController, curve: Curves.easeInOut),
    );
    _dramaticOverlay = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dramaticController, curve: Curves.easeIn),
    );
    _dramaticController.addStatusListener(_onDramaticStatus);

    // Press animation controller (3D press effect)
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
    _pressController.addListener(() => setState(() {}));

    // Initialize background music and SFX via the AudioManager service
    _loadAudioPreferencesAndStart();

    // Listen for ad pause/resume signals
    GamePauseNotifier.instance.notifier.addListener(_onAdPauseChanged);

    startLevel();
  }

  @override
  void dispose() {
    try { GamePauseNotifier.instance.notifier.removeListener(_onAdPauseChanged); } catch (_) {}
    timer?.cancel();
    // Do not dispose the shared AudioManager here; keep it alive across screens
    // so returning to the game does not lose audio session/players.
    _shakeController.dispose();
    _colorController.dispose();
    _dramaticController.dispose();
    try {
      _pressController.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _onAdPauseChanged() {
    final adShowing = GamePauseNotifier.instance.notifier.value;
    if (adShowing) {
      // Pause gameplay and remember that ad paused it
      _pausedByAd = !_isPaused; // only mark if we are not already paused
      timer?.cancel();
      setState(() {
        _isPaused = true;
      });
    } else {
      // Resume only if the ad had paused gameplay
      if (_pausedByAd) {
        _pausedByAd = false;
        setState(() {
          _isPaused = false;
        });
        // Restart the timer where it left off
        startLevelTimer();
        try { if (AudioManager().musicEnabled) { AudioManager().resumeBackground(); } } catch (_) {}
      }
    }
  }

  Future<void> _loadAudioPreferencesAndStart() async {
    try {
      await AudioManager().init();
      // sync local UI state if needed
      setState(() {});
      if (AudioManager().musicEnabled) {
        try {
          await AudioManager().playBackground('sounds/bg_loop.mp3');
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Audio init/load prefs failed: $e');
    }
  }

  /// Start or restart the current level: reset counters and resume timers.
  void startLevel() {
    if (!mounted) return;
    setState(() {
      clicks = 0;
      progress = 0.0;
      _isPaused = false;
    });
    startLevelTimer();
  }

  void _prepareQuestionsForDifficulty() {
    // For easy: first two must always be Q1 (PRESS) and Q2 (NOT PRESS)
    if (difficulty.toLowerCase() == 'easy') {
      // assume easyQuestions first two are Q1 and Q2 as defined in data
      final List<Map<String, dynamic>> q = List<Map<String, dynamic>>.from(questions);
      // extract first two special items
      final Map<String, dynamic> first = q.removeAt(0);
      final Map<String, dynamic> second = q.removeAt(0);
      // shuffle their order only
      final rand = Random();
      final List<Map<String, dynamic>> firstTwo = rand.nextBool() ? [first, second] : [second, first];
      // shuffle remaining
      q.shuffle();
      questions = [...firstTwo, ...q];
    } else {
      // medium/hard: normal shuffle
      questions.shuffle();
    }
    // reset indices when preparing new list
    currentQuestionIndex = 0;
    clicks = 0;
    progress = 0.0;
    // update gameLogic to reference the fresh list
    gameLogic = GameLogic(questions: questions);
  }

  /// Periodic timer that advances the progress bar and fires validation
  /// when time runs out.
  void startLevelTimer() {
    timer?.cancel();
    if (_isPaused) return;

    timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (_isPaused) return;
      setState(() {
        if (progress < 1.0) {
          progress += 0.05 / questions[currentQuestionIndex]['sec'];
        } else {
          t.cancel();
          validate();
        }
      });
    });
  }

  /// Validate the current level using `GameLogic` and either advance
  /// or trigger the failure animation.
  void validate() {
    final result = gameLogic.validate(currentQuestionIndex, clicks, progress);
    if (result == ValidationResult.win) {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
        // Removed: showInterstitial (dead code)
        AudioManager().playSfx('ping.wav');
        startLevel();
      } else {
        _showResult("SYSTEM FULLY COMPROMISED 🎉", isWin: true);
      }
    } else {
      // Removed: showInterstitial (dead code)
      _triggerFailureAnimation();
    }
  }

  /// Handle the dramatic animation lifecycle to show the Game Over dialog
  /// and respond to the user's choice (restart or return to menu).
  void _onDramaticStatus(AnimationStatus status) async {
    if (status != AnimationStatus.completed) return;
    if (!_shouldShowGameOver) return; // guard against reentrancy
    _shouldShowGameOver = false;

    if (!mounted) return;

    final int checkpointIndex = _pendingCheckpointIndex;
    final int finalScore = currentQuestionIndex;
    setState(() {
      if (finalScore > bestScore) bestScore = finalScore;
    });

    dynamic restart;
    try {
      // Show GameOver screen, ad logic handled inside GameOverScreen
      final navigator = Navigator.of(context);
      restart = await navigator.push<dynamic>(MaterialPageRoute(
        builder: (c) => GameOverScreen(score: finalScore, bestScore: bestScore),
        fullscreenDialog: true,
      ));
    } catch (_) {
      restart = false;
    }
    if (!mounted) return;

    if (restart == 'continue') {
      // User watched rewarded ad and chose to continue from the same node
      if (!mounted) return;
      setState(() {
        isFailing = false;
        clicks = 0;
        progress = 0.0;
      });
      _colorController.reset();
      _shakeController.reset();
      _dramaticController.reset();
      try {
        await AudioManager().playBackground('sounds/bg_loop.mp3');
      } catch (_) {}
      if (!mounted) return;
      startLevel();
      return;
    }

    if (restart == true) {
      if (!mounted) return;
      setState(() {
        isFailing = false;
        currentQuestionIndex = checkpointIndex;
        clicks = 0;
        progress = 0.0;
      });
      questions = questionsForDifficulty(difficulty);
      _prepareQuestionsForDifficulty();
      _colorController.reset();
      _shakeController.reset();
      _dramaticController.reset();
      try {
        await AudioManager().playBackground('sounds/bg_loop.mp3');
        debugPrint('Background music restarted after failure restart');
      } catch (e, st) {
        debugPrint('Failed to restart background music: $e\n$st');
      }
      if (!mounted) return;
      startLevel();
    } else {
      if (!mounted) return;
      setState(() {
        isFailing = false;
      });
      _colorController.reset();
      _shakeController.reset();
      _dramaticController.reset();
    }
  }

  /// Determine checkpoint index based on rules in the original app.
  int getCheckpointIndex(int currentIndex) => gameLogic.getCheckpointIndex(currentIndex);

  /// Trigger the failure sequence: sounds, animations, and scheduling the
  /// game over dialog.
  void _triggerFailureAnimation() {
    if (isFailing) return; // already running
    timer?.cancel();
    setState(() => isFailing = true);

    // Store checkpoint to apply after user decision
    _pendingCheckpointIndex = gameLogic.getCheckpointIndex(currentQuestionIndex);
    _shouldShowGameOver = true;

    // Ensure not paused during failure
    _isPaused = false;

    // Count the loss for interstitial logic
    // Removed: incrementLossCount (dead code)

    // Play fail sound and stop music
    AudioManager().playSfx('fail.wav');
    try {
      AudioManager().stopBackground();
      debugPrint('Background music stopped due to failure');
    } catch (e, st) {
      debugPrint('Failed to stop background music: $e\n$st');
    }

    // Bright flash then dramatic animation
    _colorController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _shakeController.forward();
        _dramaticController.forward();
      }
    });
  }

  /// Show a simple result dialog when the player wins the full run.
  void _showResult(String msg, {bool isWin = false}) {
    timer?.cancel();
    if (isWin) {
      setState(() {
        final int finalScore = currentQuestionIndex + 1;
        if (finalScore > bestScore) bestScore = finalScore;
      });
      // Show Félicitations dialog with Next Level choice
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          backgroundColor: Colors.black,
          title: Text('Félicitations', textAlign: TextAlign.center, style: const TextStyle(color: Colors.green)),
          content: const Text('Would you like to move to the next difficulty level?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () async {
                if (!mounted) return;
                AudioManager().playSfx('click.wav');
                Navigator.pop(context);
                // determine next difficulty
                String next = 'medium';
                if (difficulty.toLowerCase() == 'easy') {
                  next = 'medium';
                } else if (difficulty.toLowerCase() == 'medium') {
                  next = 'hard';
                } else {
                  next = 'hard';
                }
                // navigate to next difficulty (reset state)
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed('/game', arguments: next);
              },
              child: const Text('Next Level'),
            ),
            TextButton(
              onPressed: () async {
                AudioManager().playSfx('click.wav');
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001100),
      // Banner ad at bottom
      bottomNavigationBar: SafeArea(child: AdsService().getBannerWidget()),
      body: SafeArea(
        child: Stack(
          children: [
            const BackgroundBeams(),
            Center(
              child: AnimatedBuilder(
                animation: _dramaticController,
                builder: (context, child) {
                  double shakeOffset = _shakeAnimation.value * 15 * sin(_shakeAnimation.value * pi * 4);
                  Color displayColor = _colorAnimation.value ?? const Color(0xFF00FF00);
                  final double dramaticScale = _dramaticScale.value;
                  final double dramaticRot = _dramaticRotate.value;
                  final double overlayOp = _dramaticOverlay.value;
                  final Matrix4 transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.001);
                  transform.multiply(Matrix4.diagonal3Values(dramaticScale, dramaticScale, 1.0));
                  transform.rotateX(dramaticRot / 4);
                  transform.rotateZ(dramaticRot);

                  return Transform(
                    transform: transform,
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(shakeOffset * (1.0 + overlayOp), 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "NODE: ${currentQuestionIndex + 1}/${questions.length}",
                            style: TextStyle(color: displayColor, letterSpacing: 2, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text("BEST: $bestScore", style: TextStyle(color: _colorWithOpacity(displayColor, 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          const SizedBox(height: 60),

                          // Main interactive circular area
                          GestureDetector(
                            onTapDown: (isFailing || _isPaused)
                                ? null
                                : (_) async {
                                    if (isFailing || _isPaused) return;
                                    AudioManager().playSfx('click.wav');
                                    _pressController.forward();
                                    setState(() => isPressed = true);
                                  },
                            onTapUp: (isFailing || _isPaused)
                                ? null
                                : (_) {
                                    _pressController.reverse();
                                    setState(() {
                                      isPressed = false;
                                      clicks++;
                                    });
                                    if (questions[currentQuestionIndex]['type'] == "wait") validate();
                                  },
                            onTapCancel: () {
                              _pressController.reverse();
                              setState(() => isPressed = false);
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: CustomPaint(
                                    painter: ImageStyleTimerPainter(progress, displayColor),
                                  ),
                                ),

                                // Bottom shadow layer
                                Transform.translate(
                                  offset: Offset(0, _pressAnimation.value / 2 + 8),
                                  child: Container(
                                    width: 190,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(40),
                                      boxShadow: [
                                          BoxShadow(color: _colorWithOpacity(Colors.black, 0.5), blurRadius: 20, spreadRadius: 2),
                                      ],
                                    ),
                                  ),
                                ),

                                // Top colored layer
                                Transform.translate(
                                  offset: Offset(0, _pressAnimation.value),
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                      border: Border.all(color: _colorWithOpacity(displayColor, 0.5), width: 4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _colorWithOpacity(displayColor, isFailing ? 0.9 : 0.4),
                                          blurRadius: isFailing ? 30 : 20,
                                          spreadRadius: isFailing ? 5 : 0,
                                        ),
                                        BoxShadow(color: _colorWithOpacity(Colors.black, 0.8), blurRadius: 20),
                                      ],
                                    ),
                                    child: Center(
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            questions[currentQuestionIndex]['q'],
                                            textAlign: TextAlign.center,
                                            maxLines: 5,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.0,
                                              shadows: [
                                                Shadow(
                                                  color: _colorWithOpacity(displayColor, isFailing ? 0.95 : 0.8),
                                                  blurRadius: isFailing ? 25 : 15,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 60),
                          Text("DATA PACKETS: $clicks", style: TextStyle(color: displayColor, fontSize: 16)),
                          const SizedBox(height: 20),
                          Text("PROGRESS: ${(progress * 100).toStringAsFixed(0)}%",
                              style: TextStyle(color: displayColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Pause button
            Positioned(
              top: 40,
              right: 20,
              child: SafeArea(
                child: FloatingActionButton.small(
                          backgroundColor: _colorWithOpacity(Colors.black, 0.6),
                  onPressed: (isFailing || _dramaticController.isAnimating) ? null : () async {
                    AudioManager().playSfx('click.wav');
                    if (_isPaused) {
                      // user is resuming
                      // Removed: incrementNavClickAndMaybeShowInterstitial (dead code)
                      setState(() {
                        _isPaused = false;
                        startLevelTimer();
                        try { if (AudioManager().musicEnabled) { AudioManager().resumeBackground(); } } catch (_) {}
                      });
                    } else {
                      setState(() {
                        _isPaused = true;
                        timer?.cancel();
                        try { AudioManager().pauseBackground(); } catch (_) {}
                      });
                    }
                  },
                  child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.redAccent),
                ),
              ),
            ),

            // Pause overlay
            if (_isPaused)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                    child: Container(
                      color: _colorWithOpacity(Colors.black, 0.45),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("PAUSED", style: TextStyle(color: _colorWithOpacity(Colors.white, 0.95), fontSize: 32, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            // Music & Sound toggles
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  children: [
                                    const Text('Music', style: TextStyle(color: Colors.white)),
                                    Switch(
                                      value: AudioManager().musicEnabled,
                                      activeThumbColor: Colors.green,
                                      inactiveThumbColor: Colors.red,
                                      onChanged: (v) async {
                                        await AudioManager().setMusicEnabled(v);
                                        // Only start music immediately if game is not paused
                                        if (v && !_isPaused) {
                                          try { await AudioManager().playBackground('sounds/bg_loop.mp3'); } catch (_) {}
                                        }
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Column(
                                  children: [
                                    const Text('Sound', style: TextStyle(color: Colors.white)),
                                    Switch(
                                      value: AudioManager().soundEnabled,
                                      activeThumbColor: Colors.green,
                                      inactiveThumbColor: Colors.red,
                                      onChanged: (v) async {
                                        await AudioManager().setSoundEnabled(v);
                                        // play a tiny click if enabling to give feedback
                                        if (v) { try { await AudioManager().playSfx('click.wav'); } catch (_) {} }
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () async {
                                AudioManager().playSfx('click.wav');
                                // Removed: incrementNavClickAndMaybeShowInterstitial (dead code)
                                setState(() {
                                  _isPaused = false;
                                  startLevelTimer();
                                  try { if (AudioManager().musicEnabled) { AudioManager().resumeBackground(); } } catch (_) {}
                                });
                              },
                              child: const Text("Resume"),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () async {
                                AudioManager().playSfx('click.wav');
                                // Removed: incrementNavClickAndMaybeShowInterstitial (dead code)
                                // Full restart from pause: reset progress and ignore checkpoints
                                timer?.cancel();
                                setState(() {
                                  _isPaused = false;
                                  isFailing = false;
                                  clicks = 0;
                                  progress = 0.0;
                                  currentQuestionIndex = 0;
                                });
                                questions = questionsForDifficulty(difficulty);
                                _prepareQuestionsForDifficulty();
                                _colorController.reset();
                                _shakeController.reset();
                                _dramaticController.reset();
                                try { if (AudioManager().musicEnabled) { AudioManager().resumeBackground(); } } catch (_) {}
                                startLevel();
                              },
                              child: const Text("Restart"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Dramatic red overlay + optional blur/vignette
            AnimatedBuilder(
              animation: _dramaticController,
              builder: (context, child) {
                final overlay = _dramaticOverlay.value;
                if (overlay <= 0) return const SizedBox.shrink();
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: overlay,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [_colorWithOpacity(Colors.red, 0.95 * overlay), _colorWithOpacity(Colors.black, 0.15 * overlay)],
                            center: Alignment.center,
                            radius: 0.9,
                          ),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6.0 * overlay, sigmaY: 6.0 * overlay),
                          child: Container(color: _colorWithOpacity(Colors.red, 0.0)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple full-screen Game Over view shown after a failure.
///
/// The 'Restart' button returns `true` to the caller so the game can
/// restart from checkpoint. The 'Menu' button returns the user to the
/// main menu route (`/`).
class GameOverScreen extends StatefulWidget {
  final int score;
  final int bestScore;
  const GameOverScreen({super.key, required this.score, required this.bestScore});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("GAME OVER", style: TextStyle(color: Colors.redAccent.shade200, fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("Score: ${widget.score}", style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text("Best: ${widget.bestScore}", style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(110, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () async {
                    AudioManager().playSfx('click.wav');
                    final nav = Navigator.of(context);
                    await AdsService().incrementLossAndMaybeShowInterstitial();
                    nav.pop(true); // restart from checkpoint
                  },
                  child: const Text("Restart", style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    minimumSize: const Size(110, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () async {
                    AudioManager().playSfx('click.wav');
                    final nav = Navigator.of(context);
                    await AdsService().incrementLossAndMaybeShowInterstitial();
                    nav.pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  child: const Text("Menu", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
