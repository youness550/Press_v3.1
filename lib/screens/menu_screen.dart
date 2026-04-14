// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pressing_under_pressure/services/audio_manager.dart';
import 'package:pressing_under_pressure/ui/components/loading_bar.dart';
import 'package:pressing_under_pressure/ui/components/background_beams.dart';
import 'package:pressing_under_pressure/ui/components/neon_text.dart';
import 'package:pressing_under_pressure/ui/components/glass_card.dart';
import 'package:pressing_under_pressure/services/progress_service.dart';

// Local helper to avoid deprecated `withOpacity` usage.
Color _colorWithOpacity(Color c, double opacity) => Color.fromRGBO(c.red, c.green, c.blue, opacity);

/// Main menu screen with premium glassmorphism difficulty cards,
/// animated glitch title, and particle background.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  bool _ready = false;
  static const String _storeUrl = 'https://apps.apple.com/us/developer/imad-hamidi/id1781018469';

  // Staggered entrance animations
  late AnimationController _entranceController;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _cardsFade;
  late Animation<Offset> _titleSlide;
  late Animation<Offset> _subtitleSlide;

  // Subtitle pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isMasterUnlocked = false;
  bool _isExtremeUnlocked = false;

  @override
  void initState() {
    super.initState();

    // Loading bar animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() => _ready = true);
      });
    _loadingController.forward();

    // Entrance stagger
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 0.55, curve: Curves.easeOut)),
    );
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 0.55, curve: Curves.easeOut)),
    );
    _cardsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _entranceController.forward();

    // Subtitle pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initAudioSettings();

    _isMasterUnlocked = ProgressService().isMasterUnlocked();
    _isExtremeUnlocked = ProgressService().isExtremeUnlocked();
  }

  Future<void> _initAudioSettings() async {
    await AudioManager().init();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Open the developer store page in an external browser/app.
  Future<void> _openStore() async {
    final Uri uri = Uri.parse(_storeUrl);
    try {
      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open store link')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open store link')));
    }
  }

  Future<void> _showUnlockDialog(String title, String message, String proceedText, String difficulty) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xEE0a0a0a),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: difficulty == 'extreme' ? const Color(0xFFCC0033) : const Color(0xFFFF8C00),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: difficulty == 'extreme' ? const Color(0xFFFF2244) : const Color(0xFFFFAA00),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Courier',
            shadows: [
              Shadow(
                color: difficulty == 'extreme'
                    ? _colorWithOpacity(const Color(0xFFFF0033), 0.6)
                    : _colorWithOpacity(const Color(0xFFFF8C00), 0.6),
                blurRadius: 12,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: TextStyle(
            color: _colorWithOpacity(Colors.white, 0.85),
            fontSize: 14,
            fontFamily: 'Courier',
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              AudioManager().playSfx('click.wav');
              AudioManager().hapticSelection();
              Navigator.pop(c, false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: _colorWithOpacity(Colors.white, 0.4), fontFamily: 'Courier'),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: difficulty == 'extreme' ? const Color(0xFFCC0033) : const Color(0xFFFF8C00),
                width: 1,
              ),
            ),
            child: TextButton(
              onPressed: () {
                AudioManager().playSfx('click.wav');
                AudioManager().hapticSelection();
                Navigator.pop(c, true);
              },
              child: Text(
                proceedText,
                style: TextStyle(
                  color: difficulty == 'extreme' ? const Color(0xFFFF2244) : const Color(0xFFFFAA00),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (res == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/game', arguments: difficulty);
    }
  }

  void _onDifficultyTap(String difficulty) {
    if (!_ready) return;
    AudioManager().playSfx('click.wav');
    AudioManager().hapticSelection();
    if (!mounted) return;

    if (difficulty == 'master') {
      if (!_isMasterUnlocked) return;
      _showUnlockDialog(
        "🏆 MASTER LEVEL",
        "You think you're ready?\nThis level shows no mercy.\nOne life. No second chances.",
        "I'm Ready",
        "master",
      );
      return;
    }
    if (difficulty == 'extreme') {
      if (!_isExtremeUnlocked) return;
      _showUnlockDialog(
        "☠️ EXTREME MODE",
        "Warning: This mode is for players\nwho mastered everything.\nNo power-ups. Instant death.\nGood luck.",
        "ENTER",
        "extreme",
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed('/game', arguments: difficulty);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double cardWidth = (size.width * 0.85).clamp(0, 400);

    return Scaffold(
      backgroundColor: const Color(0xFF000a00),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (low layer)
          Positioned.fill(
            child: Image.asset(
              'assets/images/menu.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.15),
            ),
          ),
          // Particle background
          const Positioned.fill(
            child: BackgroundBeams(baseColor: Color(0xFF00FF66)),
          ),
          // Dark overlay
          Container(color: _colorWithOpacity(Colors.black, 0.25)),

          // Store button (top-right)
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _colorWithOpacity(const Color(0xFF00FF66), 0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: _colorWithOpacity(const Color(0xFF00FF66), 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.storefront_rounded, color: Color(0xFF00FF66), size: 24),
                  onPressed: () {
                    AudioManager().playSfx('click.wav');
                    AudioManager().hapticSelection();
                    _openStore();
                  },
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),

                    // Title with glitch
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: const NeonText(
                          text: 'PRESSING\nUNDER\nPRESSURE',
                          fontSize: 32,
                          color: Color(0xFF00FF66),
                          enableFlicker: true,
                          enableGlitch: true,
                          glowIntensity: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Subtitle with pulse
                    SlideTransition(
                      position: _subtitleSlide,
                      child: FadeTransition(
                        opacity: _subtitleFade,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, _) {
                            return Text(
                              '◆ SELECT DIFFICULTY ◆',
                              style: TextStyle(
                                color: _colorWithOpacity(
                                  const Color(0xFF00FF66),
                                  _pulseAnimation.value,
                                ),
                                fontSize: 13,
                                letterSpacing: 4,
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Loading bar
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: LoadingBar(
                        animation: _loadingAnimation,
                        width: cardWidth,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Difficulty cards
                    FadeTransition(
                      opacity: _cardsFade,
                      child: SizedBox(
                        width: cardWidth,
                        child: Column(
                          children: [
                            _buildDifficultyCard(
                              title: 'EASY',
                              subtitle: '20 nodes • Generous time',
                              icon: Icons.shield_outlined,
                              color: const Color(0xFF00CC44),
                              difficulty: 'easy',
                              locked: false,
                              bestScore: ProgressService().getBestScore('easy'),
                            ),
                            const SizedBox(height: 10),
                            _buildDifficultyCard(
                              title: 'MEDIUM',
                              subtitle: '53 nodes • Standard pressure',
                              icon: Icons.flash_on_rounded,
                              color: const Color(0xFFFF9900),
                              difficulty: 'medium',
                              locked: false,
                              bestScore: ProgressService().getBestScore('medium'),
                            ),
                            const SizedBox(height: 10),
                            _buildDifficultyCard(
                              title: 'HARD',
                              subtitle: '50 nodes • No room for error',
                              icon: Icons.local_fire_department_rounded,
                              color: const Color(0xFFFF3344),
                              difficulty: 'hard',
                              locked: false,
                              bestScore: ProgressService().getBestScore('hard'),
                            ),
                            const SizedBox(height: 10),
                            _buildDifficultyCard(
                              title: 'MASTER',
                              subtitle: '50 nodes • 40% less time',
                              icon: Icons.emoji_events_rounded,
                              color: const Color(0xFFFF8C00),
                              difficulty: 'master',
                              locked: !_isMasterUnlocked,
                              bestScore: ProgressService().getBestScore('master'),
                            ),
                            const SizedBox(height: 10),
                            _buildDifficultyCard(
                              title: 'EXTREME',
                              subtitle: 'Instant death • No mercy',
                              icon: Icons.dangerous_rounded,
                              color: const Color(0xFFCC0033),
                              difficulty: 'extreme',
                              locked: !_isExtremeUnlocked,
                              bestScore: ProgressService().getBestScore('extreme'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    FadeTransition(
                      opacity: _cardsFade,
                      child: SizedBox(
                        width: cardWidth,
                        child: GlassCard(
                          borderColor: _colorWithOpacity(const Color(0xFF00FF66), 0.28),
                          backgroundColor: _colorWithOpacity(const Color(0xFF00FF66), 0.05),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Wrap(
                            alignment: WrapAlignment.spaceAround,
                            runSpacing: 8,
                            children: [
                              _buildQuickToggle(
                                label: 'MUSIC',
                                value: AudioManager().musicEnabled,
                                onChanged: (v) async {
                                  await AudioManager().setMusicEnabled(v);
                                  if (v) {
                                    try {
                                      await AudioManager().playBackground('sounds/bg_loop.mp3');
                                    } catch (_) {}
                                  }
                                  if (!mounted) return;
                                  setState(() {});
                                },
                              ),
                              _buildQuickToggle(
                                label: 'SOUND',
                                value: AudioManager().soundEnabled,
                                onChanged: (v) async {
                                  await AudioManager().setSoundEnabled(v);
                                  if (v) {
                                    try {
                                      await AudioManager().playSfx('click.wav');
                                    } catch (_) {}
                                  }
                                  if (!mounted) return;
                                  setState(() {});
                                },
                              ),
                              _buildQuickToggle(
                                label: 'VIBRATION',
                                value: AudioManager().vibrationEnabled,
                                onChanged: (v) async {
                                  await AudioManager().setVibrationEnabled(v);
                                  if (!mounted) return;
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Version
                    FadeTransition(
                      opacity: _cardsFade,
                      child: Text(
                        'v1.3.0',
                        style: TextStyle(
                          color: _colorWithOpacity(const Color(0xFF00FF66), 0.25),
                          fontSize: 11,
                          fontFamily: 'Courier',
                          letterSpacing: 2,
                        ),
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

  Widget _buildDifficultyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String difficulty,
    required bool locked,
    required int bestScore,
  }) {
    final opacityFactor = locked ? 0.35 : 1.0;

    return GlassCard(
      borderColor: _colorWithOpacity(color, locked ? 0.2 : 0.6),
      backgroundColor: _colorWithOpacity(color, locked ? 0.03 : 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      borderWidth: locked ? 1 : 1.5,
      blurAmount: 8,
      onTap: locked ? null : () => _onDifficultyTap(difficulty),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _colorWithOpacity(color, locked ? 0.08 : 0.15),
              border: Border.all(
                color: _colorWithOpacity(color, locked ? 0.15 : 0.4),
                width: 1.5,
              ),
              boxShadow: locked
                  ? []
                  : [
                      BoxShadow(
                        color: _colorWithOpacity(color, 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: Icon(
              locked ? Icons.lock_rounded : icon,
              color: _colorWithOpacity(color, opacityFactor),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _colorWithOpacity(color, opacityFactor),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    letterSpacing: 3,
                    shadows: locked
                        ? []
                        : [
                            Shadow(
                              color: _colorWithOpacity(color, 0.5),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  locked ? 'Complete ${difficulty == "extreme" ? "Master" : "Hard"} to unlock' : subtitle,
                  style: TextStyle(
                    color: _colorWithOpacity(Colors.white, locked ? 0.25 : 0.5),
                    fontSize: 11,
                    fontFamily: 'Courier',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Best score badge
          if (!locked && bestScore > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _colorWithOpacity(color, 0.15),
                border: Border.all(
                  color: _colorWithOpacity(color, 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '★ $bestScore',
                style: TextStyle(
                  color: _colorWithOpacity(color, 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ),

          // Arrow for unlocked
          if (!locked) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: _colorWithOpacity(color, 0.5),
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _colorWithOpacity(const Color(0xFF00FF66), 0.82),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Courier',
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 6),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00FF66),
        ),
      ],
    );
  }
}
