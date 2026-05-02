import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../data/datasources/ad_service.dart';
import '../providers/auth_provider.dart';

class NativeAdWidget extends StatefulWidget {
  final TemplateType templateType;

  const NativeAdWidget({
    super.key,
    this.templateType = TemplateType.small,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Don't load ads if user is premium or already loaded/loading
    final isPremium = Provider.of<AuthProvider>(context, listen: false).profile?.isPremium ?? false;
    if (!isPremium && _nativeAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    final adService = Provider.of<AdService>(context, listen: false);
    
    _nativeAd = adService.loadNativeAd(
      templateType: widget.templateType,
      onAdLoaded: (ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }
        setState(() {
          _isAdLoaded = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
            _nativeAd = null; // Clear so it can try again or stay hidden
          });
        }
      },
    );

    _nativeAd?.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide ad widget for premium users
    final isPremium = Provider.of<AuthProvider>(context).profile?.isPremium ?? false;
    if (isPremium) {
      return const SizedBox.shrink();
    }

    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(
        minHeight: widget.templateType == TemplateType.small ? 90 : 320,
        maxHeight: widget.templateType == TemplateType.small ? 120 : 400,
      ),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
