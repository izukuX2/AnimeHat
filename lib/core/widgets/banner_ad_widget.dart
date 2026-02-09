import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> with RouteAware {
  Key _key = UniqueKey();
  bool _isVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AdService.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    AdService.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    // When another route is pushed on top of this one
    debugPrint('BannerAdWidget: Hidden (didPushNext)');
    setState(() => _isVisible = false);
  }

  @override
  void didPopNext() {
    // When the top route is popped and this one becomes visible again
    debugPrint('BannerAdWidget: Visible (didPopNext)');
    setState(() {
      _isVisible = true;
      _key = UniqueKey(); // Refresh on return
    });
  }

  void _reloadAd() {
    if (!mounted) return;
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.adsEnabled || !_isVisible) {
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
          debugPrint('Banner loaded: $placementId');
        },
        onClick: (placementId) => debugPrint('Banner clicked: $placementId'),
        onFailed: (placementId, error, message) {
          debugPrint('Banner ad failed: $placementId $error $message');
          // Retry after delay
          if (_isVisible) {
            Future.delayed(const Duration(seconds: 30), () {
              debugPrint('Retrying Banner Load...');
              _reloadAd();
            });
          }
        },
      ),
    );
  }
}
