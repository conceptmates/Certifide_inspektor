import 'dart:developer';

import 'package:certifide_openapp/constants/ad_constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool isAdReady = false;

  void loadAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          isAdReady = true;

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              isAdReady = false;
              loadAd(); // Load the next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              isAdReady = false;
              loadAd(); // Try loading another ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          isAdReady = false;
          // Try loading another ad after a delay
          Future.delayed(const Duration(minutes: 2), loadAd);
        },
      ),
    );
  }

  void showAdIfReady() {
    if (_interstitialAd != null && isAdReady) {
      _interstitialAd!.show();
    } else {
      log('Interstitial ad not ready yet');
      // Optionally reload the ad
      loadAd();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
