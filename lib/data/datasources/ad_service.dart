import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;

  // ── Production Ad Unit IDs (PhoneGuard) ──────────────────────
  // App ID: ca-app-pub-7846790707867237~5281854677 (set in AndroidManifest.xml)

  // Banner — defined but not currently used in the app UI
  String get bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-7846790707867237/8185018486' // reuse native unit if needed
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS test (no iOS build)

  // Native Advanced — used across Dashboard, Settings, FAQ, Activity Logs,
  // Trusted Numbers, Command Guide screens
  String get nativeAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-7846790707867237/8185018486'
      : 'ca-app-pub-3940256099942544/3986624511'; // iOS test (no iOS build)

  // Rewarded — used in ProtectionStatusCard for +4h protection extension
  String get rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-7846790707867237/3758688310'
      : 'ca-app-pub-3940256099942544/1712485313'; // iOS test (no iOS build)

  Future<void> init() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  void loadRewardedAd({
    required Function(RewardedAd) onAdLoaded,
    required VoidCallback onAdFailedToLoad,
  }) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          onAdFailedToLoad();
        },
      ),
    );
  }

  void showRewardedAd({
    required RewardedAd ad,
    required OnUserEarnedRewardCallback onUserEarnedReward,
    required VoidCallback onAdDismissed,
  }) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onAdDismissed();
      },
    );

    ad.show(onUserEarnedReward: onUserEarnedReward);
  }

  // Helper for Native Ads
  NativeAd loadNativeAd({
    required TemplateType templateType,
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: 'adFactoryExample', // This requires native side setup if using custom factory
      // Using standard templates (small/medium) is easier for pure flutter
      listener: NativeAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailedToLoad(ad, error);
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: templateType,
        mainBackgroundColor: const Color(0xFF1E1E1E),
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF121212),
          backgroundColor: const Color(0xFF00E5FF),
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFFFFFFF),
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFB0B0B0),
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFB0B0B0),
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    );
  }
}
