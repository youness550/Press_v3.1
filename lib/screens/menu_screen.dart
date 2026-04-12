// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pressing_under_pressure/services/audio_manager.dart';
// import removed: AdsService not used
import 'package:pressing_under_pressure/ui/components/loading_bar.dart';
import 'package:pressing_under_pressure/services/progress_service.dart';

// Local helper to avoid deprecated `withOpacity` usage.
Color _colorWithOpacity(Color c, double opacity) => Color.fromRGBO(c.red, c.green, c.blue, opacity);

/// Main menu screen with a large START button and a subtle loading bar.
///
/// This widget displays the game's entry screen and navigates to the
/// game screen via a named route (`/game`). It plays short SFX when
/// buttons are pressed and shows a store icon that opens an external URL.
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

  // START button press animation (3D effect)
  late AnimationController _startPressController;
  
  late AnimationController _extremePulseController;
  late Animation<double> _extremePulseAnimation;

  bool _isMasterUnlocked = false;
  bool _isExtremeUnlocked = false;


  @override
  void initState() {
    super.initState();
    // Loading bar animation: when completed, mark menu as ready.
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() => _ready = true);
      });
    _loadingController.forward();

    // Start button press animation controller
    _startPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _startPressController.addListener(() => setState(() {}));

    _extremePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _extremePulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _extremePulseController, curve: Curves.easeInOut));
    _extremePulseController.addListener(() => setState(() {}));

    _isMasterUnlocked = ProgressService().isMasterUnlocked();
    _isExtremeUnlocked = ProgressService().isExtremeUnlocked();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _extremePulseController.dispose();
    try {
      _startPressController.dispose();
    } catch (_) {}
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
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(side: BorderSide(color: difficulty == 'extreme' ? Colors.red : Colors.orange), borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: difficulty == 'extreme' ? Colors.redAccent : Colors.orangeAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text(message, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () { AudioManager().playSfx('click.wav'); Navigator.pop(c, false); }, child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () { AudioManager().playSfx('click.wav'); Navigator.pop(c, true); }, child: Text(proceedText, style: TextStyle(color: difficulty == 'extreme' ? Colors.red : Colors.orange, fontWeight: FontWeight.bold))),
        ],
      )
    );
    if (res == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/game', arguments: difficulty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.7;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
            // Background image (fills entire screen)
            Positioned.fill(
              child: Image.asset(
                'assets/images/menu.png',
                fit: BoxFit.cover,
              ),
            ),
            // Subtle dark overlay so foreground controls remain readable
            Container(color: _colorWithOpacity(Colors.black, 0.35)),

          // Store icon (top-right)
          Positioned(
            top: 18,
            right: 18,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.store, color: Colors.white70, size: 28),
                onPressed: () {
                  AudioManager().playSfx('click.wav');
                  _openStore();
                },
              ),
            ),
          ),

          // Center content with loading bar and START button
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),

                  // Neon loading bar — shows progress until ready
                  LoadingBar(animation: _loadingAnimation, width: width),

                  const SizedBox(height: 28),

                  // Difficulty selection buttons
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorWithOpacity(Colors.green, 0.75),
                          minimumSize: const Size(100, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            side: BorderSide(color: _colorWithOpacity(Colors.greenAccent, 0.9), width: 2),
                          ),
                          elevation: 6,
                        ),
                        onPressed: _ready
                            ? () async {
                                AudioManager().playSfx('click.wav');
                                if (!mounted) return;
                                Navigator.of(context).pushReplacementNamed('/game', arguments: 'easy');
                              }
                            : null,
                        child: const Text('Easy', style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorWithOpacity(Colors.orange, 0.78),
                          minimumSize: const Size(100, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            side: BorderSide(color: _colorWithOpacity(Colors.orangeAccent, 0.9), width: 2),
                          ),
                          elevation: 6,
                        ),
                        onPressed: _ready
                            ? () async {
                                AudioManager().playSfx('click.wav');
                                if (!mounted) return;
                                Navigator.of(context).pushReplacementNamed('/game', arguments: 'medium');
                              }
                            : null,
                        child: const Text('Medium', style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorWithOpacity(Colors.redAccent, 0.78),
                          minimumSize: const Size(100, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            side: BorderSide(color: _colorWithOpacity(Colors.redAccent, 0.9), width: 2),
                          ),
                          elevation: 6,
                        ),
                        onPressed: _ready
                            ? () async {
                                AudioManager().playSfx('click.wav');
                                if (!mounted) return;
                                Navigator.of(context).pushReplacementNamed('/game', arguments: 'hard');
                              }
                            : null,
                        child: const Text('Hard', style: TextStyle(color: Colors.white)),
                      ),
                      // MASTER Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorWithOpacity(const Color(0xFFFF8C00), _isMasterUnlocked ? 0.9 : 0.3),
                          minimumSize: const Size(100, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            side: BorderSide(color: _colorWithOpacity(const Color(0xFFFF8C00), 0.9), width: 2),
                          ),
                          elevation: _isMasterUnlocked ? 6 : 0,
                        ),
                        onPressed: (_ready && _isMasterUnlocked)
                            ? () async {
                                AudioManager().playSfx('click.wav');
                                _showUnlockDialog("🏆 MASTER LEVEL", "You think you're ready?\nThis level shows no mercy.\nOne life. No second chances.", "I'm Ready", "master");
                              }
                            : null,
                        icon: _isMasterUnlocked ? const Icon(Icons.emoji_events, size: 18, color: Colors.white) : const Icon(Icons.lock, size: 18, color: Colors.white54),
                        label: Text('Master', style: TextStyle(color: _isMasterUnlocked ? Colors.white : Colors.white54)),
                      ),
                      // EXTREME Button
                      Container(
                        decoration: _isExtremeUnlocked ? BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFCC0033).withOpacity(_extremePulseAnimation.value * 0.8), blurRadius: 15, spreadRadius: 2 * _extremePulseAnimation.value),
                          ]
                        ) : null,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _colorWithOpacity(const Color(0xFFCC0033), _isExtremeUnlocked ? 0.9 : 0.3),
                            minimumSize: const Size(100, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              side: BorderSide(color: _colorWithOpacity(const Color(0xFFCC0033), 0.9), width: 2),
                            ),
                            elevation: _isExtremeUnlocked ? 6 : 0,
                          ),
                          onPressed: (_ready && _isExtremeUnlocked)
                              ? () async {
                                  AudioManager().playSfx('click.wav');
                                  _showUnlockDialog("☠️ EXTREME MODE", "Warning: This mode is for players who mastered everything.\nNo power-ups. Instant death.\nGood luck.", "ENTER", "extreme");
                                }
                              : null,
                          icon: _isExtremeUnlocked ? const Icon(Icons.dangerous, size: 18, color: Colors.white) : const Icon(Icons.lock, size: 18, color: Colors.white54),
                          label: Text('Extreme', style: TextStyle(color: _isExtremeUnlocked ? Colors.white : Colors.white54)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
