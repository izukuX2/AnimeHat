import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  Key _key = UniqueKey();

  void _reloadAd() {
    if (!mounted) return;
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.adsEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      height: 50, // Standard banner height
      child: UnityBannerAd(
        key: _key,
        placementId: AdService.bannerPlacementId,
        size: BannerSize.standard,
        onLoad: (placementId) {
          print('Banner loaded: $placementId');
        },
        onClick: (placementId) => print('Banner clicked: $placementId'),
        onFailed: (placementId, error, message) {
          print('Banner ad failed: $placementId $error $message');
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), () {
            print('Retrying Banner Load...');
            _reloadAd();
          });
        },
      ),
    );
  }
}
