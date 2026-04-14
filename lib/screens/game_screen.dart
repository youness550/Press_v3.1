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
import 'package:pressing_under_pressure/ui/components/neon_text.dart';
import 'package:pressing_under_pressure/ui/components/glass_card.dart';
import 'package:pressing_under_pressure/ui/components/animated_counter.dart';
import 'package:pressing_under_pressure/services/progress_service.dart';

// Helper to create a color with explicit opacity without using deprecated
// `withOpacity` to avoid precision-loss deprecation warnings.
Color _colorWithOpacity(Color c, double opacity) =>
  Color.fromRGBO(c.red, c.green, c.blue, opacity);

/// Color palette for each difficulty.
Color _difficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return const Color(0xFF00CC44);
    case 'medium':
      return const Color(0xFF00FF66);
    case 'hard':
      return const Color(0xFFFF3344);
    case 'master':
      return const Color(0xFFFF8C00);
    case 'extreme':
      return const Color(0xFFCC0033);
    default:
      return const Color(0xFF00FF66);
  }
}

String _difficultyLabel(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return 'EASY';
    case 'medium':
      return 'MEDIUM';
    case 'hard':
      return 'HARD';
    case 'master':
      return 'MASTER';
    case 'extreme':
      return 'EXTREME';
    default:
      return difficulty.toUpperCase();
  }
}

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

  // Pulsing glow on the center button
  late AnimationController _pulseGlowController;
  late Animation<double> _pulseGlow;

  // Node transition animation
  late AnimationController _nodeTransitionController;
  late Animation<double> _nodeScale;

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
    bestScore = ProgressService().getBestScore(difficulty);
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
      begin: _difficultyColor(difficulty),
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

    // Pulse glow
    _pulseGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseGlow = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseGlowController, curve: Curves.easeInOut),
    );
    _pulseGlowController.addListener(() => setState(() {}));

    // Node transition
    _nodeTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _nodeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _nodeTransitionController, curve: Curves.easeInOut));
    _nodeTransitionController.addListener(() => setState(() {}));

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
    _pulseGlowController.dispose();
    _nodeTransitionController.dispose();
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
        AudioManager().playSfx('ping.wav');
        AudioManager().hapticMedium();
        _nodeTransitionController.forward(from: 0);
        startLevel();
      } else {
        _showResult("SYSTEM FULLY COMPROMISED 🎉", isWin: true);
      }
    } else {
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
      if (finalScore > bestScore) {
        bestScore = finalScore;
        ProgressService().saveBestScore(difficulty, bestScore);
      }
    });

    dynamic restart;
    try {
      // Show GameOver screen, ad logic handled inside GameOverScreen
      final navigator = Navigator.of(context);
      restart = await navigator.push<dynamic>(MaterialPageRoute(
        builder: (c) => GameOverScreen(
          score: finalScore,
          bestScore: bestScore,
          difficulty: difficulty,
        ),
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
  int getCheckpointIndex(int currentIndex) => gameLogic.getCheckpointIndex(currentIndex, difficulty);

  /// Trigger the failure sequence: sounds, animations, and scheduling the
  /// game over dialog.
  void _triggerFailureAnimation() {
    if (isFailing) return; // already running
    timer?.cancel();
    setState(() => isFailing = true);

    // Store checkpoint to apply after user decision
    _pendingCheckpointIndex = gameLogic.getCheckpointIndex(currentQuestionIndex, difficulty);
    _shouldShowGameOver = true;

    // Ensure not paused during failure
    _isPaused = false;

    // Play fail sound and stop music
    AudioManager().playSfx('fail.wav');
    AudioManager().hapticHeavy();
    // Repeated vibration burst for dramatic failure feel
    Future.delayed(const Duration(milliseconds: 100), () => AudioManager().hapticHeavy());
    Future.delayed(const Duration(milliseconds: 200), () => AudioManager().hapticHeavy());
    Future.delayed(const Duration(milliseconds: 350), () => AudioManager().hapticVibrate());
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
      if (difficulty == 'hard') ProgressService().markHardCompleted();
      if (difficulty == 'master') ProgressService().markMasterCompleted();
      
      setState(() {
        final int finalScore = currentQuestionIndex + 1;
        if (finalScore > bestScore) {
          bestScore = finalScore;
          ProgressService().saveBestScore(difficulty, bestScore);
        }
      });

      final diffColor = _difficultyColor(difficulty);

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xF0050505),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _colorWithOpacity(diffColor, 0.8), width: 2.5),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeonText(
                text: '◆ SYSTEM COMPROMISED ◆',
                fontSize: 20,
                color: diffColor,
                enableFlicker: true,
                enableGlitch: false,
              ),
              const SizedBox(height: 8),
              Container(
                height: 2,
                width: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _colorWithOpacity(diffColor, 0),
                      _colorWithOpacity(diffColor, 1),
                      _colorWithOpacity(diffColor, 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '▸ ALL NODES BREACHED ▸',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: diffColor,
                  fontFamily: 'Courier',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Security protocols overwhelmed. System access gained.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _colorWithOpacity(Colors.white, 0.7),
                  fontFamily: 'Courier',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select your next action:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _colorWithOpacity(Colors.white, 0.6),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            _buildDialogButton(
              'NEXT LEVEL',
              diffColor,
              () async {
                if (!mounted) return;
                AudioManager().playSfx('click.wav');
                AudioManager().hapticSelection();
                Navigator.of(c).pop();
                String next = 'medium';
                switch (difficulty.toLowerCase()) {
                  case 'easy':
                    next = 'medium';
                    break;
                  case 'medium':
                    next = 'hard';
                    break;
                  case 'hard':
                    next = 'master';
                    break;
                  case 'master':
                    next = 'extreme';
                    break;
                  default:
                    next = difficulty;
                }
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed('/game', arguments: next);
              },
            ),
            const SizedBox(width: 8),
            _buildDialogButton(
              'RETRY LEVEL',
              _colorWithOpacity(Colors.white, 0.5),
              () async {
                AudioManager().playSfx('click.wav');
                AudioManager().hapticSelection();
                Navigator.of(c).pop();
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed('/game', arguments: difficulty);
              },
            ),
            const SizedBox(width: 8),
            _buildDialogButton(
              'BACK TO MENU',
              _colorWithOpacity(Colors.white, 0.35),
              () {
                AudioManager().playSfx('click.wav');
                AudioManager().hapticSelection();
                Navigator.of(c).pop();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDialogButton(String label, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorWithOpacity(color, 0.5), width: 1),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(difficulty);
    final displayColor = _colorAnimation.value ?? diffColor;

    return Scaffold(
      backgroundColor: const Color(0xFF000a00),
      // Banner ad at bottom
      bottomNavigationBar: SafeArea(child: AdsService().getBannerWidget()),
      body: SafeArea(
        child: Stack(
          children: [
            // Particle background (colored per difficulty)
            BackgroundBeams(
              baseColor: isFailing ? const Color(0xFFFF0000) : diffColor,
              intensified: isFailing || difficulty == 'extreme',
            ),

            // Main game content
            Center(
              child: AnimatedBuilder(
                animation: _dramaticController,
                builder: (context, child) {
                  double shakeOffset = _shakeAnimation.value * 15 * sin(_shakeAnimation.value * pi * 4);
                  if (difficulty == 'extreme' && !isFailing) {
                    shakeOffset += sin(DateTime.now().millisecondsSinceEpoch / 40.0) * 3.0;
                  }
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
                      child: Transform.scale(
                        scale: _nodeScale.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(height: 20),

                            // Main interactive circular area
                            GestureDetector(
                              onTapDown: (isFailing || _isPaused)
                                  ? null
                                  : (_) async {
                                      if (isFailing || _isPaused) return;
                                      AudioManager().playSfx('click.wav');
                                      AudioManager().hapticLight();
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
                                  // Timer ring
                                  SizedBox(
                                    width: 300,
                                    height: 300,
                                    child: CustomPaint(
                                      painter: ImageStyleTimerPainter(progress, displayColor),
                                    ),
                                  ),

                                  // Pulsing outer glow
                                  Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _colorWithOpacity(
                                            displayColor,
                                            _pulseGlow.value * (isFailing ? 0.8 : 0.25),
                                          ),
                                          blurRadius: 40,
                                          spreadRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Bottom shadow layer
                                  Transform.translate(
                                    offset: Offset(0, _pressAnimation.value / 2 + 8),
                                    child: Container(
                                      width: 190,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _colorWithOpacity(Colors.black, 0.6),
                                        borderRadius: BorderRadius.circular(40),
                                        boxShadow: [
                                            BoxShadow(color: _colorWithOpacity(Colors.black, 0.5), blurRadius: 20, spreadRadius: 2),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Top colored layer (main button)
                                  Transform.translate(
                                    offset: Offset(0, _pressAnimation.value),
                                    child: Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            _colorWithOpacity(displayColor, 0.08),
                                            const Color(0xFF050505),
                                          ],
                                          stops: const [0.0, 0.85],
                                        ),
                                        border: Border.all(
                                          color: _colorWithOpacity(displayColor, isFailing ? 0.8 : 0.5),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _colorWithOpacity(displayColor, isFailing ? 0.9 : 0.35),
                                            blurRadius: isFailing ? 35 : 20,
                                            spreadRadius: isFailing ? 6 : 1,
                                          ),
                                          // Inner highlight
                                          BoxShadow(
                                            color: _colorWithOpacity(displayColor, 0.1),
                                            blurRadius: 60,
                                            spreadRadius: -10,
                                          ),
                                          BoxShadow(color: _colorWithOpacity(Colors.black, 0.8), blurRadius: 20),
                                        ],
                                      ),
                                      child: Center(
                                        child: SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.all(14.0),
                                            child: Text(
                                              questions[currentQuestionIndex]['q'],
                                              textAlign: TextAlign.center,
                                              maxLines: 5,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.0,
                                                fontFamily: 'Courier',
                                                height: 1.4,
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

                            const SizedBox(height: 30),

                            // Click counter with animated bounce
                            AnimatedCounter(
                              value: clicks,
                              prefix: '⬡ DATA PACKETS: ',
                              color: displayColor,
                              fontSize: 15,
                            ),

                            const SizedBox(height: 14),

                            // Progress gauge bar
                            SizedBox(
                              width: 200,
                              child: Column(
                                children: [
                                  // Progress bar
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: _colorWithOpacity(displayColor, 0.1),
                                      border: Border.all(
                                        color: _colorWithOpacity(displayColor, 0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: FractionallySizedBox(
                                        widthFactor: progress.clamp(0.0, 1.0),
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: progress > 0.8
                                                  ? [const Color(0xFFFF4400), const Color(0xFFFF0000)]
                                                  : [displayColor, _colorWithOpacity(displayColor, 0.7)],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _colorWithOpacity(
                                                  progress > 0.8 ? const Color(0xFFFF0000) : displayColor,
                                                  0.5,
                                                ),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${(progress * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: _colorWithOpacity(
                                        progress > 0.8 ? const Color(0xFFFF4400) : displayColor,
                                        0.7,
                                      ),
                                      fontSize: 11,
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // HUD Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _colorWithOpacity(Colors.black, 0.4),
                      border: Border(
                        bottom: BorderSide(
                          color: _colorWithOpacity(diffColor, 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Difficulty badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _colorWithOpacity(diffColor, 0.15),
                            border: Border.all(
                              color: _colorWithOpacity(diffColor, 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _difficultyLabel(difficulty),
                            style: TextStyle(
                              color: diffColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Node counter
                        Expanded(
                          child: Text(
                            'NODE ${currentQuestionIndex + 1}/${questions.length}',
                            style: TextStyle(
                              color: _colorWithOpacity(diffColor, 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier',
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: _colorWithOpacity(diffColor, 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Best score
                        Text(
                          '★ BEST: $bestScore',
                          style: TextStyle(
                            color: _colorWithOpacity(const Color(0xFFFFD700), 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Courier',
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Pause button
            Positioned(
              top: 48,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _colorWithOpacity(diffColor, 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _colorWithOpacity(diffColor, 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: FloatingActionButton.small(
                  backgroundColor: _colorWithOpacity(Colors.black, 0.7),
                  onPressed: (isFailing || _dramaticController.isAnimating) ? null : () async {
                    AudioManager().playSfx('click.wav');
                    AudioManager().hapticSelection();
                    if (_isPaused) {
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
                  child: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: diffColor,
                    size: 22,
                  ),
                ),
              ),
            ),

            // Pause overlay
            if (_isPaused)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      color: _colorWithOpacity(Colors.black, 0.6),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NeonText(
                              text: '◇ PAUSED ◇',
                              fontSize: 28,
                              color: diffColor,
                              enableFlicker: true,
                              enableGlitch: false,
                              glowIntensity: 0.8,
                            ),
                            const SizedBox(height: 30),

                            // Music & Sound toggles
                            GlassCard(
                              borderColor: _colorWithOpacity(diffColor, 0.3),
                              backgroundColor: _colorWithOpacity(diffColor, 0.05),
                              padding: const EdgeInsets.all(20),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 24,
                                runSpacing: 16,
                                children: [
                                  _buildToggle('MUSIC', AudioManager().musicEnabled, diffColor, (v) async {
                                    await AudioManager().setMusicEnabled(v);
                                    if (v && !_isPaused) {
                                      try { await AudioManager().playBackground('sounds/bg_loop.mp3'); } catch (_) {}
                                    }
                                    setState(() {});
                                  }),
                                  _buildToggle('SOUND', AudioManager().soundEnabled, diffColor, (v) async {
                                    await AudioManager().setSoundEnabled(v);
                                    if (v) { try { await AudioManager().playSfx('click.wav'); } catch (_) {} }
                                    setState(() {});
                                  }),
                                  _buildToggle('VIBRATION', AudioManager().vibrationEnabled, diffColor, (v) async {
                                    await AudioManager().setVibrationEnabled(v);
                                    setState(() {});
                                  }),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Resume button
                            _buildPauseButton(
                              'RESUME',
                              diffColor,
                              Icons.play_arrow_rounded,
                              () async {
                                AudioManager().playSfx('click.wav');
                                AudioManager().hapticSelection();
                                setState(() {
                                  _isPaused = false;
                                  startLevelTimer();
                                  try { if (AudioManager().musicEnabled) { AudioManager().resumeBackground(); } } catch (_) {}
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // Restart button
                            _buildPauseButton(
                              'RESTART',
                              const Color(0xFFFF4444),
                              Icons.refresh_rounded,
                              () async {
                                AudioManager().playSfx('click.wav');
                                AudioManager().hapticSelection();
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

            if (difficulty == 'extreme')
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: _colorWithOpacity(Colors.redAccent, 0.12),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Color color, ValueChanged<bool> onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _colorWithOpacity(Colors.white, 0.7),
            fontSize: 11,
            fontFamily: 'Courier',
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Switch(
          value: value,
          activeThumbColor: color,
          activeTrackColor: _colorWithOpacity(color, 0.3),
          inactiveThumbColor: _colorWithOpacity(Colors.red, 0.7),
          inactiveTrackColor: _colorWithOpacity(Colors.red, 0.15),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPauseButton(String label, Color color, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      child: GlassCard(
        borderColor: _colorWithOpacity(color, 0.5),
        backgroundColor: _colorWithOpacity(color, 0.08),
        padding: EdgeInsets.zero,
        borderRadius: 14,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cinematic Game Over screen with glitch effect, animated score,
/// and glassmorphism action cards.
class GameOverScreen extends StatefulWidget {
  final int score;
  final int bestScore;
  final String difficulty;
  const GameOverScreen({
    super.key,
    required this.score,
    required this.bestScore,
    this.difficulty = 'medium',
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _titleFade;
  late Animation<double> _scoreFade;
  late Animation<double> _buttonsFade;
  late Animation<double> _titleScale;

  // Score counter animation
  late AnimationController _scoreCountController;
  int _displayedScore = 0;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );
    _titleScale = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack)),
    );
    _scoreFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.25, 0.55, curve: Curves.easeOut)),
    );
    _buttonsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
    _entranceController.forward();

    // Animate score counting up
    _scoreCountController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.score * 60).clamp(300, 2000)),
    );
    _scoreCountController.addListener(() {
      setState(() {
        _displayedScore = (widget.score * _scoreCountController.value).round();
      });
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _scoreCountController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _scoreCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(widget.difficulty);

    return Scaffold(
      backgroundColor: const Color(0xFF050000),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Red particle background
          const BackgroundBeams(
            baseColor: Color(0xFFFF2222),
            intensified: true,
          ),

          // Dark overlay
          Container(color: _colorWithOpacity(Colors.black, 0.5)),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SYSTEM FAILURE title
                    FadeTransition(
                      opacity: _titleFade,
                      child: ScaleTransition(
                        scale: _titleScale,
                        child: const NeonText(
                          text: 'SYSTEM\nFAILURE',
                          fontSize: 36,
                          color: Color(0xFFFF2222),
                          enableFlicker: true,
                          enableGlitch: true,
                          glowIntensity: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    FadeTransition(
                      opacity: _titleFade,
                      child: Text(
                        '◆ CONNECTION TERMINATED ◆',
                        style: TextStyle(
                          color: _colorWithOpacity(const Color(0xFFFF4444), 0.6),
                          fontSize: 11,
                          fontFamily: 'Courier',
                          letterSpacing: 3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Score card
                    FadeTransition(
                      opacity: _scoreFade,
                      child: GlassCard(
                        borderColor: _colorWithOpacity(const Color(0xFFFF2222), 0.4),
                        backgroundColor: _colorWithOpacity(const Color(0xFFFF2222), 0.05),
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                        child: Column(
                          children: [
                            Text(
                              'NODES BREACHED',
                              style: TextStyle(
                                color: _colorWithOpacity(Colors.white, 0.5),
                                fontSize: 11,
                                fontFamily: 'Courier',
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_displayedScore',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                                shadows: [
                                  Shadow(
                                    color: _colorWithOpacity(const Color(0xFFFF2222), 0.8),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: _colorWithOpacity(const Color(0xFFFF2222), 0.2),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: _colorWithOpacity(const Color(0xFFFFD700), 0.7),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'BEST: ${widget.bestScore}',
                                  style: TextStyle(
                                    color: _colorWithOpacity(const Color(0xFFFFD700), 0.7),
                                    fontSize: 14,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Action buttons
                    FadeTransition(
                      opacity: _buttonsFade,
                      child: Column(
                        children: [
                          // Restart button
                          SizedBox(
                            width: 220,
                            child: GlassCard(
                              borderColor: _colorWithOpacity(diffColor, 0.6),
                              backgroundColor: _colorWithOpacity(diffColor, 0.1),
                              padding: EdgeInsets.zero,
                              borderRadius: 14,
                              onTap: () async {
                                AudioManager().playSfx('click.wav');
                                AudioManager().hapticSelection();
                                final nav = Navigator.of(context);
                                await AdsService().incrementLossAndMaybeShowInterstitial();
                                nav.pop(true); // restart from checkpoint
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh_rounded, color: diffColor, size: 22),
                                    const SizedBox(width: 10),
                                    Text(
                                      'RESTART',
                                      style: TextStyle(
                                        color: diffColor,
                                        fontFamily: 'Courier',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        letterSpacing: 3,
                                        shadows: [
                                          Shadow(
                                            color: _colorWithOpacity(diffColor, 0.5),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Menu button
                          SizedBox(
                            width: 220,
                            child: GlassCard(
                              borderColor: _colorWithOpacity(Colors.white, 0.2),
                              backgroundColor: _colorWithOpacity(Colors.white, 0.03),
                              padding: EdgeInsets.zero,
                              borderRadius: 14,
                              onTap: () async {
                                AudioManager().playSfx('click.wav');
                                AudioManager().hapticSelection();
                                final nav = Navigator.of(context);
                                await AdsService().incrementLossAndMaybeShowInterstitial();
                                nav.pushNamedAndRemoveUntil('/', (route) => false);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.home_rounded, color: _colorWithOpacity(Colors.white, 0.5), size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'MENU',
                                      style: TextStyle(
                                        color: _colorWithOpacity(Colors.white, 0.5),
                                        fontFamily: 'Courier',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
