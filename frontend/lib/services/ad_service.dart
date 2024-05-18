import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  final String adUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Replace with your actual Ad Unit ID

  void initialize() {
    MobileAds.instance.initialize();
  }

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: adUnitId, // Use the provided ad unit ID
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          print('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
          print('Failed to load a rewarded ad: $error');
        },
      ),
    );
  }

  void showRewardedAd(Function onAdWatched) {
    if (_isAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          _rewardedAd = null;
          _isAdLoaded = false;
          loadRewardedAd(); // Reload the ad for future use
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Failed to show the ad: $error');
          _rewardedAd = null;
          _isAdLoaded = false;
          loadRewardedAd(); // Reload the ad for future use
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onAdWatched();
          _rewardedAd = null;
          _isAdLoaded = false;
          loadRewardedAd(); // Reload the ad for future use
        },
      );
    } else {
      print('Ad is not loaded yet');
      loadRewardedAd(); // Ensure the ad is loaded for next time
    }
  }
}
