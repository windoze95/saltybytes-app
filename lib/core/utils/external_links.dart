import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Outbound URLs the app links to (legal pages, store management) and a helper
/// to open them in the platform browser.
class ExternalLinks {
  ExternalLinks._();

  static const String privacyPolicy = 'https://saltybytes.ai/privacy';

  /// Apple's standard EULA. App Store review (guideline 3.1.2) requires the
  /// paywall to link a Terms of Use; this is Apple's default when the app has
  /// no custom agreement.
  static const String termsOfUse =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// The App Store's subscription-management page.
  static const String appleManageSubscriptions =
      'https://apps.apple.com/account/subscriptions';

  /// Google Play's management page for a specific subscription product.
  static String playManageSubscription(String productId) =>
      'https://play.google.com/store/account/subscriptions'
      '?sku=$productId&package=codes.julian.saltybytes';
}

/// Opens [url] in the platform browser. Returns whether it launched; a malformed
/// or unlaunchable URL is swallowed so a dead link never crashes the screen.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (error) {
    debugPrint('openExternalUrl failed for $url: $error');
    return false;
  }
}
