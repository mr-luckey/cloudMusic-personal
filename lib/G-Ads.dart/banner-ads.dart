// // // /// The BannerAdWidget class in Dart is used to display banner ads in a Flutter application using Google
// // // /// Mobile Ads.
// // // // import 'package:flutter/material.dart';
// // // // import 'package:google_mobile_ads/google_mobile_ads.dart';
// // // // import 'dart:io';

// // // // class BannerAdWidget extends StatefulWidget {
// // // //   final int index;

// // // //   const BannerAdWidget({Key? key, required this.index}) : super(key: key);

// // // //   @override
// // // //   _BannerAdWidgetState createState() => _BannerAdWidgetState();
// // // // }

// // // // class _BannerAdWidgetState extends State<BannerAdWidget> {
// // // //   late BannerAd _bannerAd;
// // // //   final List<String> _adUnitIds = [
// // // //     //test ADS implemented replace with your ID
// // // //    // Banner Ad Unit ID 1
// // // //     'ca-app-pub-3940256099942544/9214589741',
// // // //     'ca-app-pub-3940256099942544/9214589741',
// // // //     'ca-app-pub-3940256099942544/9214589741',
// // // //     'ca-app-pub-3940256099942544/9214589741',
// // // //     'ca-app-pub-3940256099942544/9214589741',
// // // //     'ca-app-pub-3940256099942544/9214589741',

// // // //     // Banner Ad Unit ID 5

// // // //   // Banner Ad Unit ID 6
// // // //   ];

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _bannerAd = _createBannerAd();
// // // //     _loadAd();
// // // //   }

// // // //   BannerAd _createBannerAd() {
// // // //     return BannerAd(
// // // //       adUnitId: _adUnitIds[widget.index],
// // // //       request: const AdRequest(),
// // // //       size: AdSize.banner,
// // // //       listener: BannerAdListener(
// // // //         onAdLoaded: (ad) {
// // // //           setState(() {});
// // // //         },
// // // //         onAdFailedToLoad: (ad, err) {
// // // //           ad.dispose();
// // // //         },
// // // //         onAdOpened: (Ad ad) {},
// // // //         onAdClosed: (Ad ad) {},
// // // //         onAdImpression: (Ad ad) {},
// // // //       ),
// // // //     );
// // // //   }

// // // //   void _loadAd() {
// // // //     _bannerAd.load();
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Center(
// // // //       child: Container(
// // // //         width: _bannerAd.size.width.toDouble(),
// // // //         height: _bannerAd.size.height.toDouble(),
// // // //         margin: EdgeInsets.symmetric(vertical: 10.0),
// // // //         child: AdWidget(ad: _bannerAd),
// // // //       ),
// // // //     );
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _bannerAd.dispose();
// // // //     super.dispose();
// // // //   }
// // // // }
// // // import 'package:flutter/material.dart';
// // // import 'package:google_mobile_ads/google_mobile_ads.dart';
// // // import 'package:facebook_audience_network/facebook_audience_network.dart';
// // // import 'dart:io';

// // // class BannerAdWidget extends StatefulWidget {
// // //   final int index;

// // //   const BannerAdWidget({Key? key, required this.index}) : super(key: key);

// // //   @override
// // //   _BannerAdWidgetState createState() => _BannerAdWidgetState();
// // // }

// // // class _BannerAdWidgetState extends State<BannerAdWidget> {
// // //   late BannerAd _bannerAd;
// // //   late FacebookBannerAd _facebookBannerAd;
// // //   bool _isAdLoaded = false;
// // //   final List<String> _adUnitIds = [
// // //     // Replace with your Ad Unit IDs
// // //     'ca-app-pub-5561438827097019/2466400091',
// // //     'ca-app-pub-5561438827097019/5644410976',
// // //     'ca-app-pub-5561438827097019/9392084296',
// // //     'ca-app-pub-5561438827097019/7516482574',
// // //     'ca-app-pub-5561438827097019/3664867478',
// // //     'ca-app-pub-5561438827097019/4313989766',
// // //   ];

// // //   final List<String> _facebookAdUnitIds = [
// // //     // Replace with your Facebook Ad Unit IDs
// // //     '1284769629160789_1285822015722217',
// // //     '1284769629160789_1285821532388932',
// // //     '1284769629160789_1285821619055590',
// // //     '1284769629160789_1285821792388906',
// // //     '1284769629160789_1285821875722231',
// // //     '1284769629160789_1285821935722225',
// // //   ];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     //   FacebookAudienceNetwork.init(
// // //     //   // testingId: "a77955ee-3304-4635-be65-81029b0f5201",
// // //     //   // iOSAdvertiserTrackingEnabled: true,
// // //     // );
// // //     _bannerAd = _createBannerAd();
// // //     _facebookBannerAd = _createFacebookBannerAd();
// // //     _loadAd();
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _bannerAd.dispose();
// // //     super.dispose();
// // //   }

// // //   BannerAd _createBannerAd() {
// // //     return BannerAd(
// // //       adUnitId: _adUnitIds[widget.index],
// // //       request: const AdRequest(),
// // //       size: AdSize.banner,
// // //       listener: BannerAdListener(
// // //         onAdLoaded: (ad) {
// // //           setState(() {
// // //             _isAdLoaded = true;
// // //           });
// // //         },
// // //         onAdFailedToLoad: (ad, err) {
// // //           ad.dispose();
// // //           setState(() {
// // //             _isAdLoaded = false;
// // //           });
// // //           _loadFacebookAd();
// // //         },
// // //         onAdOpened: (Ad ad) {},
// // //         onAdClosed: (Ad ad) {},
// // //         onAdImpression: (Ad ad) {},
// // //       ),
// // //     );
// // //   }

// // //   FacebookBannerAd _createFacebookBannerAd() {
// // //     return FacebookBannerAd(
// // //       placementId: _facebookAdUnitIds[widget.index],
// // //       bannerSize: BannerSize.STANDARD,
// // //       listener: (result, value) {
// // //         switch (result) {
// // //           case BannerAdResult.ERROR:
// // //             print("Error: $value");
// // //             _loadAd(); // Retry loading Google Ad
// // //             break;
// // //           case BannerAdResult.LOADED:
// // //             setState(() {
// // //               _isAdLoaded = true;
// // //             });
// // //             break;
// // //           case BannerAdResult.CLICKED:
// // //             print("Clicked: $value");
// // //             break;
// // //           case BannerAdResult.LOGGING_IMPRESSION:
// // //             print("Logging Impression: $value");
// // //             break;
// // //         }
// // //       },
// // //     );
// // //   }

// // //   void _loadAd() {
// // //     _bannerAd.load();
// // //   }

// // //   void _loadFacebookAd() {
// // //     setState(() {});
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Center(
// // //       child: _isAdLoaded
// // //           ? Container(
// // //               width: _bannerAd.size.width.toDouble(),
// // //               height: _bannerAd.size.height.toDouble(),
// // //               margin: EdgeInsets.symmetric(vertical: 10.0),
// // //               child: AdWidget(ad: _bannerAd),
// // //             )
// // //           : Container(
// // //               margin: EdgeInsets.symmetric(vertical: 10.0),
// // //               child: _facebookBannerAd,
// // //             ),
// // //     );
// // //   }
// // // }
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:facebook_audience_network/facebook_audience_network.dart';

// class BannerAdWidget extends StatefulWidget {
//   final int index;

//   const BannerAdWidget({Key? key, required this.index}) : super(key: key);

//   @override
//   _BannerAdWidgetState createState() => _BannerAdWidgetState();
// }

// class _BannerAdWidgetState extends State<BannerAdWidget> {
//   BannerAd? _bannerAd;
//   bool _isGoogleAdLoaded = false;
//   bool _isFacebookAdLoaded = false;

//   final List<String> _adUnitIds = [
//     'ca-app-pub-5561438827097019/2466400091',
//     'ca-app-pub-5561438827097019/5644410976',
//     'ca-app-pub-5561438827097019/9392084296',
//     'ca-app-pub-5561438827097019/7516482574',
//     'ca-app-pub-5561438827097019/3664867478',
//     'ca-app-pub-5561438827097019/4313989766',
//   ];

//   // final List<String> _facebookAdUnitIds = [
//   //   // '1284769629160789_1285822015722217',
//   //   // '1284769629160789_1285821532388932',
//   //   // '1284769629160789_1285821619055590',
//   //   // '1284769629160789_1285821792388906',
//   //   // '1284769629160789_1285821875722231',
//   //   // '1284769629160789_1285821935722225',
//   // ];

//   @override
//   void initState() {
//     super.initState();
//     _loadGoogleAd();
//   }

//   @override
//   void dispose() {
//     _bannerAd?.dispose();
//     super.dispose();
//   }

//   void _loadGoogleAd() {
//     _bannerAd = BannerAd(
//       adUnitId: _adUnitIds[widget.index],
//       request: const AdRequest(),
//       size: AdSize.banner,
//       listener: BannerAdListener(
//         onAdLoaded: (ad) {
//           setState(() {
//             _isGoogleAdLoaded = true;
//           });
//         },
//         onAdFailedToLoad: (ad, err) {
//           ad.dispose();
//           setState(() {
//             _isGoogleAdLoaded = false;
//           });
//           _loadFacebookAd();
//         },
//       ),
//     );
//     _bannerAd?.load();
//   }

//   void _loadFacebookAd() {
//     setState(() {
//       _isFacebookAdLoaded = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: _isGoogleAdLoaded
//           ? Container(
//               width: _bannerAd!.size.width.toDouble(),
//               height: _bannerAd!.size.height.toDouble(),
//               margin: const EdgeInsets.symmetric(vertical: 10.0),
//               child: AdWidget(ad: _bannerAd!),
//             )
//           : _isGoogleAdLoaded
//               ? Container(
//                   width: _bannerAd!.size.width.toDouble(),
//                   height: _bannerAd!.size.height.toDouble(),
//                   margin: const EdgeInsets.symmetric(vertical: 10.0),
//                   child: AdWidget(ad: _bannerAd!),
//                 )
//               //  _isFacebookAdLoaded
//               //     ? FacebookBannerAd(
//               //         placementId: _facebookAdUnitIds[widget.index],
//               //         bannerSize: BannerSize.STANDARD,
//               //         listener: (result, value) {
//               //           if (result == BannerAdResult.LOADED) {
//               //             setState(() {
//               //               _isFacebookAdLoaded = true;
//               //             });
//               //           }
//               //         },
//               //       )
//               : const SizedBox.shrink(),
//     );
//   }
// }
// // //banner Ads logic completed
