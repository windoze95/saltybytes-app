import 'package:flutter_test/flutter_test.dart';
import 'package:saltybytes_app/core/iap/store_platform.dart';

void main() {
  group('storePlatformFrom', () {
    test('modern iOS can purchase and maps to the apple API platform', () {
      final p = storePlatformFrom(
        isIOS: true,
        isAndroid: false,
        osVersion: 'Version 17.5 (Build 21F79)',
      );
      expect(p.kind, StoreKind.apple);
      expect(p.canPurchase, isTrue);
      expect(p.apiPlatform, 'apple');
      expect(p.blockedReason, isNull);
    });

    test('iOS 15 exactly is supported (StoreKit 2 boundary)', () {
      final p = storePlatformFrom(
        isIOS: true,
        isAndroid: false,
        osVersion: 'Version 15.0 (Build 19A340)',
      );
      expect(p.canPurchase, isTrue);
    });

    test('iOS 14 is blocked with an explanatory reason but is still apple', () {
      final p = storePlatformFrom(
        isIOS: true,
        isAndroid: false,
        osVersion: 'Version 14.4 (Build 18D52)',
      );
      expect(p.kind, StoreKind.apple);
      expect(p.canPurchase, isFalse);
      expect(p.blockedReason, contains('iOS 15'));
      // Still reports apple so any restored SK1 receipt is at least attributed.
      expect(p.apiPlatform, 'apple');
    });

    test('an unparseable iOS version assumes support (runtime gate still runs)',
        () {
      final p = storePlatformFrom(
        isIOS: true,
        isAndroid: false,
        osVersion: 'Version unknown',
      );
      expect(p.canPurchase, isTrue);
    });

    test('Android can purchase and maps to the google API platform', () {
      final p = storePlatformFrom(
        isIOS: false,
        isAndroid: true,
        osVersion: '13',
      );
      expect(p.kind, StoreKind.google);
      expect(p.canPurchase, isTrue);
      expect(p.apiPlatform, 'google');
    });

    test('non-store platforms cannot purchase and have no API platform', () {
      final p = storePlatformFrom(
        isIOS: false,
        isAndroid: false,
        osVersion: 'macOS 14.5',
      );
      expect(p.kind, StoreKind.none);
      expect(p.canPurchase, isFalse);
      expect(p.apiPlatform, isNull);
    });
  });
}
