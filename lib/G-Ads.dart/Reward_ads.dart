// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// class RewardedAdManager {
//   RewardedAd? _rewardedAd;

//   void loadRewardedAd() {
//     RewardedAd.load(
//       adUnitId: '	ca-app-pub-3940256099942544/5354046379',
//       request: AdRequest(),
//       rewardedAdLoadCallback: RewardedAdLoadCallback(
//         onAdLoaded: (RewardedAd ad) {
//           _rewardedAd = ad;
//           print('Rewarded Ad loaded.');
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           print('Rewarded Ad failed to load: $error');
//         },
//       ),
//     );
//   }

//   void showRewardedAd(BuildContext context, Function onAdCompleted) {
//     if (_rewardedAd != null) {
//       _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
//         onAdShowedFullScreenContent: (RewardedAd ad) => print('Ad showed.'),
//         onAdDismissedFullScreenContent: (RewardedAd ad) {
//           print('Ad dismissed.');
//           ad.dispose();
//           onAdCompleted();
//         },
//         onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
//           print('Ad failed to show: $error');
//           ad.dispose();
//         },
//       );

//       _rewardedAd!.show(
//         onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
//           print('User earned reward: ${reward.amount} ${reward.type}');
//         },
//       );
//     } else {
//       print('Rewarded Ad is not loaded yet.');
//     }
//   }
// }
