import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class BannerAdWidget extends StatefulWidget {
  final int index;

  const BannerAdWidget({Key? key, required this.index}) : super(key: key);

  @override
  _BannerAdWidgetState createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  late BannerAd _bannerAd;
  final List<String> _adUnitIds = [
    'ca-app-pub-5561438827097019/2466400091', // Banner Ad Unit ID 1
    // 'ca-app-pub-3940256099942544/9214589741',
    // 'ca-app-pub-3940256099942544/9214589741',
    // 'ca-app-pub-3940256099942544/9214589741',
    // 'ca-app-pub-3940256099942544/9214589741',
    // 'ca-app-pub-3940256099942544/9214589741',
    // 'ca-app-pub-3940256099942544/9214589741',

    'ca-app-pub-5561438827097019/5644410976', // Banner Ad Unit ID 2
    'ca-app-pub-5561438827097019/9392084296', // Banner Ad Unit ID 3
    'ca-app-pub-5561438827097019/7516482574', // Banner Ad Unit ID 4
    'ca-app-pub-5561438827097019/3664867478', // Banner Ad Unit ID 5
    // 'ca-app-pub-5561438827097019/4313989766',
    'ca-app-pub-5561438827097019/2152475253', // Banner Ad Unit ID 6
  ];

  @override
  void initState() {
    super.initState();
    _bannerAd = _createBannerAd();
    _loadAd();
  }

  BannerAd _createBannerAd() {
    return BannerAd(
      adUnitId: _adUnitIds[widget.index],
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {});
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
        onAdOpened: (Ad ad) {},
        onAdClosed: (Ad ad) {},
        onAdImpression: (Ad ad) {},
      ),
    );
  }

  void _loadAd() {
    _bannerAd.load();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _bannerAd.size.width.toDouble(),
        height: _bannerAd.size.height.toDouble(),
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: AdWidget(ad: _bannerAd),
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }
}
