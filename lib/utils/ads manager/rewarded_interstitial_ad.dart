import 'package:certifide_openapp/constants/ad_constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedInterstitialAdManager {
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoaded = false;

  static const String _adUnitId = rewardedAdUnitId;

  /// Load a rewarded interstitial ad
  Future<void> loadRewardedInterstitialAd() async {
    try {
      await RewardedInterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (RewardedInterstitialAd ad) {
            print('Rewarded interstitial ad loaded successfully');
            _rewardedInterstitialAd = ad;
            _isAdLoaded = true;
            _setFullScreenContentCallback();
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('Failed to load rewarded interstitial ad: $error');
            _rewardedInterstitialAd = null;
            _isAdLoaded = false;
          },
        ),
      );
    } catch (e) {
      print('Error loading rewarded interstitial ad: $e');
    }
  }

  /// Set up full screen content callbacks
  void _setFullScreenContentCallback() {
    _rewardedInterstitialAd?.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedInterstitialAd ad) {
        print('Rewarded interstitial ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        print('Rewarded interstitial ad dismissed');
        ad.dispose();
        _rewardedInterstitialAd = null;
        _isAdLoaded = false;
        // Preload the next ad
        loadRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent:
          (RewardedInterstitialAd ad, AdError error) {
        print('Failed to show rewarded interstitial ad: $error');
        ad.dispose();
        _rewardedInterstitialAd = null;
        _isAdLoaded = false;
        // Try to load a new ad
        loadRewardedInterstitialAd();
      },
    );
  }

  /// Show the rewarded interstitial ad
  Future<void> showRewardedInterstitialAd({
    required Function(AdWithoutView, RewardItem) onUserEarnedReward,
    Function()? onAdClosed,
    Function()? onAdFailedToShow,
  }) async {
    if (_rewardedInterstitialAd == null || !_isAdLoaded) {
      print('Rewarded interstitial ad is not ready yet');
      onAdFailedToShow?.call();
      return;
    }

    try {
      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
          print('User earned reward: ${rewardItem.amount} ${rewardItem.type}');
          onUserEarnedReward(ad, rewardItem);
        },
      );
    } catch (e) {
      print('Error showing rewarded interstitial ad: $e');
      onAdFailedToShow?.call();
    }
  }

  /// Check if ad is loaded and ready to show
  bool get isAdLoaded => _isAdLoaded;

  /// Get the current ad instance (for advanced usage)
  RewardedInterstitialAd? get currentAd => _rewardedInterstitialAd;

  /// Manually dispose of the current ad without loading a new one
  void disposeCurrentAd() {
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
    _isAdLoaded = false;
  }

  /// Dispose of the ad manager completely
  void dispose() {
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
    _isAdLoaded = false;
  }

  /// Set custom ad unit ID (useful for different ad placements)
  Future<void> loadWithCustomAdUnit(String customAdUnitId) async {
    try {
      await RewardedInterstitialAd.load(
        adUnitId: customAdUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (RewardedInterstitialAd ad) {
            print('Custom rewarded interstitial ad loaded successfully');
            _rewardedInterstitialAd = ad;
            _isAdLoaded = true;
            _setFullScreenContentCallback();
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('Failed to load custom rewarded interstitial ad: $error');
            _rewardedInterstitialAd = null;
            _isAdLoaded = false;
          },
        ),
      );
    } catch (e) {
      print('Error loading custom rewarded interstitial ad: $e');
    }
  }
}
