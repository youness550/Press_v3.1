import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pressing_under_pressure/services/game_pause.dart';

/// AdsService: initializes `MobileAds` and manages Banner, Interstitial,
/// Rewarded and AppOpen ads. Uses the ad unit IDs supplied by the user.
class AdsService {
  AdsService._private();
  static final AdsService _instance = AdsService._private();
  factory AdsService() => _instance;

  bool _initialized = false;
  bool _mobileAdsInitialized = false;

  // --- User-provided Ad Unit IDs ---
  static const String appId = 'ca-app-pub-7577507549673641~5242044075';
  static const String bannerAdUnitId = 'ca-app-pub-7577507549673641/5071389778';
  static const String interstitialAdUnitId = 'ca-app-pub-7577507549673641/7689814254';

  // --- Ad instances ---
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  // Counter for interstitial display logic
  int _lossCount = 0;
  static const _prefLossCount = 'ads_loss_count';

  bool get isBannerReady => _bannerAd != null;
  bool get isInterstitialReady => _interstitialAd != null;

  /// Initialize MobileAds. Call once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final params = ConsentRequestParameters();

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            _loadAndShowConsentFormIfRequired();
          } else {
            _checkConsentAndInitializeMobileAds();
          }
        },
        (FormError error) {
          debugPrint('ConsentInfoUpdate error: ${error.message}');
          _checkConsentAndInitializeMobileAds();
        },
      );

      // Concurrently check if we already have consent to skip the wait for returning users
      _checkConsentAndInitializeMobileAds();
    } catch (e) {
      debugPrint('AdsService UMP init error: $e');
      _checkConsentAndInitializeMobileAds();
    }
  }

  void _loadAndShowConsentFormIfRequired() {
    ConsentForm.loadAndShowConsentFormIfRequired(
      (FormError? formError) {
        if (formError != null) {
          debugPrint('ConsentForm load/show error: ${formError.message}');
        }
        _checkConsentAndInitializeMobileAds();
      },
    );
  }

  Future<void> _checkConsentAndInitializeMobileAds() async {
    if (_mobileAdsInitialized) return;

    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (canRequestAds) {
      _mobileAdsInitialized = true;
      try {
        await MobileAds.instance.initialize();
        debugPrint('AdsService: MobileAds initialized');
        
        await loadBanner();
        await loadInterstitial();
        
        try {
          final prefs = await SharedPreferences.getInstance();
          _lossCount = prefs.getInt(_prefLossCount) ?? 0;
        } catch (e) {
          debugPrint('AdsService prefs load error: $e');
        }
      } catch (e) {
        debugPrint('AdsService mobile ads init error: $e');
      }
    }
  }

  // ---------------- Banner ----------------
  Future<void> loadBanner() async {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('BannerAd loaded.'),
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: ${err.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    try {
      await _bannerAd!.load();
    } catch (e) {
      debugPrint('BannerAd load error: $e');
      _bannerAd = null;
    }
  }

  /// Returns a widget that displays the banner if loaded, or `SizedBox.shrink()`.
  /// Caller should place this in the widget tree where the banner should appear.
  Widget getBannerWidget() {
    if (_bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  // ---------------- Interstitial ----------------
  Future<void> loadInterstitial() async {
    _interstitialAd?.dispose();
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('InterstitialAd loaded');
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('Interstitial showed full screen content');
              // Pause the game/timer immediately when ad shows
              try { GamePauseNotifier.instance.pauseForAd(); } catch (_) {}
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial dismissed');
              // Resume the game/timer when ad is dismissed
              try { GamePauseNotifier.instance.resumeFromAd(); } catch (_) {}
              ad.dispose();
              _interstitialAd = null;
              // Reload for next time
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('Interstitial failed to show: ${err.message}');
              // Ensure resume if show failed
              try { GamePauseNotifier.instance.resumeFromAd(); } catch (_) {}
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd failed to load: ${err.message}');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Show the interstitial ad if loaded, pausing/resuming game as needed.
  Future<void> showInterstitialIfReady() async {
    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not ready, attempting to load');
      await loadInterstitial();
      return;
    }
    try {
      // Pause the game immediately before showing so timers stop.
      try { GamePauseNotifier.instance.pauseForAd(); } catch (_) {}
      _interstitialAd!.show();
    } catch (e) {
      // Ensure resume if show throws
      try { GamePauseNotifier.instance.resumeFromAd(); } catch (_) {}
      debugPrint('Error showing interstitial: $e');
    }
  }

  // ...existing code...

  // ...existing code...

  // ---------------- Loss Counter & Interstitial Logic ----------------
  Future<void> _saveLossCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefLossCount, _lossCount);
    } catch (_) {}
  }

  /// Call this when the player loses (after GameOver screen).
  Future<void> incrementLossAndMaybeShowInterstitial() async {
    _lossCount++;
    await _saveLossCount();
    debugPrint('AdsService: loss count=$_lossCount');
    const lossThreshold = 5;
    if (_lossCount >= lossThreshold) {
      _lossCount = 0;
      await _saveLossCount();
      await showInterstitialIfReady();
    }
  }

  // ---------------- Privacy / GDPR ----------------
  Future<void> showPrivacyOptionsForm() async {
    final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    if (status == PrivacyOptionsRequirementStatus.required) {
      ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          debugPrint('Privacy options error: ${formError.message}');
        }
      });
    }
  }

  // ---------------- Cleanup ----------------
  void dispose() {
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    try {
      _interstitialAd?.dispose();
    } catch (_) {}
    _bannerAd = null;
    _interstitialAd = null;
    debugPrint('AdsService.dispose()');
  }
}

