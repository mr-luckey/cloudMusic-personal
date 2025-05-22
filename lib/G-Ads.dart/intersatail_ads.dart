// // import 'package:google_mobile_ads/google_mobile_ads.dart';
// // // import 'dart:io';

// // // ignore: avoid_classes_with_only_static_members
// // class AdManager {
// //   static InterstitialAd? _interstitialAd1;
// //   static InterstitialAd? _interstitialAd2;
// //   static final List<String> _adUnitIds = [
// //     // '	ca-app-pub-3940256099942544/1033173712',
// //     // '	ca-app-pub-3940256099942544/1033173712',

// //     'ca-app-pub-5561438827097019/7678519709', // Ad Unit ID 1
// //     'ca-app-pub-5561438827097019/4741209644', // Ad Unit ID 2
// //   ];

//   // static int _currentAdIndex = 0;

// //   static void initialize() {
// //     _loadInterstitialAd(_currentAdIndex);
// //   }

// //   static void _loadInterstitialAd(int index) {
// //     InterstitialAd.load(
// //       adUnitId: _adUnitIds[index],
// //       request: const AdRequest(),
// //       adLoadCallback: InterstitialAdLoadCallback(
// //         onAdLoaded: (InterstitialAd ad) {
// //           if (index == 0) {
// //             _interstitialAd1 = ad;
// //           } else {
// //             _interstitialAd2 = ad;
// //           }
// //         },
// //         onAdFailedToLoad: (LoadAdError error) {
// //           print('InterstitialAd failed to load: $error');
// //           // If the first ad fails to load, try loading the second one
// //           if (index == 0) {
// //             _loadInterstitialAd(1);
// //           }
// //         },
// //       ),
// //     );
// //   }

// //   static void showInterstitialAd() {
// //     InterstitialAd? currentAd =
// //         _currentAdIndex == 0 ? _interstitialAd1 : _interstitialAd2;

// //     if (currentAd != null) {
// //       currentAd.fullScreenContentCallback = FullScreenContentCallback(
// //         onAdDismissedFullScreenContent: (InterstitialAd ad) {
// //           ad.dispose();
// //           _currentAdIndex = (_currentAdIndex + 1) % 2; // Switch to the other ad
// //           initialize(); // Load the next ad
// //         },
// //       );
// //       currentAd.show();
// //     } else {
// //       print('InterstitialAd is not ready yet.');
// //     }
// //   }
// // }
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ignore: avoid_classes_with_only_static_members
class AdManager {
  static InterstitialAd? _googleInterstitialAd1;
  static InterstitialAd? _googleInterstitialAd2;
  static bool _isFacebookAdLoaded = false;

  static final List<String> _googleAdUnitIds = [
    'ca-app-pub-5561438827097019/5438640841', // Ad Unit ID 1
    'ca-app-pub-5561438827097019/4741209644',

    // Ad Unit ID 2
  ];

  // static final List<String> _facebookAdUnitIds = [
  //   'Y1284769629160789_1285855045718914', // Replace with your Facebook Ad Unit ID 1
  //   '1284769629160789_1285855219052230', // Replace with your Facebook Ad Unit ID 2
  // ];

  static int _currentAdIndex = 0;

  static void initialize() {
    _loadGoogleInterstitialAd(_currentAdIndex);
  }

  static void _loadGoogleInterstitialAd(int index) {
    InterstitialAd.load(
      adUnitId: _googleAdUnitIds[index],
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (index == 0) {
            _googleInterstitialAd1 = ad;
          } else {
            _googleInterstitialAd2 = ad;
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Google InterstitialAd failed to load: $error');
          _loadGoogleInterstitialAd(index);
          // _loadFacebookAd(index); // Try loading Facebook Ad
        },
      ),
    );
  }

  // static void _loadFacebookAd(int index) {
  //   FacebookInterstitialAd.loadInterstitialAd(
  //     placementId: _facebookAdUnitIds[index],
  //     listener: (result, value) {
  //       if (result == InterstitialAdResult.LOADED) {
  //         _isFacebookAdLoaded = true;
  //       } else if (result == InterstitialAdResult.ERROR) {
  //         print('Facebook InterstitialAd failed to load: $value');
  //         _loadGoogleInterstitialAd(index); // Retry loading Google Ad
  //       }
  //     },
  //   );
  // }

  static void showInterstitialAd() {
    InterstitialAd? currentGoogleAd =
        _currentAdIndex == 0 ? _googleInterstitialAd1 : _googleInterstitialAd2;

    if (currentGoogleAd != null) {
      currentGoogleAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _currentAdIndex = (_currentAdIndex + 1) % 2; // Switch to the other ad
          initialize(); // Load the next ad
        },
      );
      currentGoogleAd.show();
    } else if (_isFacebookAdLoaded) {
      FacebookInterstitialAd.showInterstitialAd();
      _isFacebookAdLoaded = false;
    } else {
      print('InterstitialAd is not ready yet.');
    }
  }
}
