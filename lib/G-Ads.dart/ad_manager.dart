import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  static InterstitialAd? _currentAd;
  static bool _isAdLoading = false;
  static int _currentAdIndex = 0;
  static Timer? _adTimer;
  static bool _isAdShown = false;

  // Add your 10 ad unit IDs here
  static final List<String> _adUnitIds = [
    'ca-app-pub-5561438827097019/7033953225',
    'ca-app-pub-5561438827097019/7649046801',
    'ca-app-pub-5561438827097019/6363644045',
    'ca-app-pub-5561438827097019/8443846629',
    'ca-app-pub-5561438827097019/5720871553',
    'ca-app-pub-5561438827097019/6335965133',
    'ca-app-pub-5561438827097019/5050562377',
    'ca-app-pub-5561438827097019/4504601615',
    'ca-app-pub-5561438827097019/6570084649',
    'ca-app-pub-5561438827097019/3094708210'
    // Add your remaining ad IDs here
  ];

  void initialize() {
    _startAdTimer();
    _loadNextAd();
  }

  void _startAdTimer() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 2000), (timer) {
      if (!_isAdShown && _currentAd != null) {
        _showAd();
      } else if (!_isAdShown) {
        _loadNextAd();
      }
    });
  }

  void _loadNextAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: _adUnitIds[_currentAdIndex],
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _currentAd = ad;
          _isAdLoading = false;
          _setupAdCallbacks();
          // Show ad immediately after loading
          _showAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Ad failed to load: ${error.message}');
          _isAdLoading = false;
          _tryNextAd();
        },
      ),
    );
  }

  void _setupAdCallbacks() {
    _currentAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _currentAd = null;
        _isAdShown = false;
        _tryNextAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('Ad failed to show: ${error.message}');
        ad.dispose();
        _currentAd = null;
        _isAdShown = false;
        _tryNextAd();
      },
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        _isAdShown = true;
      },
    );
  }

  void _tryNextAd() {
    _currentAdIndex = (_currentAdIndex + 1) % _adUnitIds.length;
    _loadNextAd();
  }

  void _showAd() {
    if (_currentAd != null && !_isAdShown) {
      _currentAd?.show();
    }
  }

  void dispose() {
    _adTimer?.cancel();
    _currentAd?.dispose();
  }
}
