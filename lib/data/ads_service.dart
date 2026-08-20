// Public entry point for AdMob.
//
// The implementation is chosen at compile time: the real google_mobile_ads
// service on mobile (where `dart:io` exists), and a no-op stub on Web. Ads are
// disabled on Web per the game spec, and the ad SDK depends on `dart:io`, so it
// must never be imported into a web build — this conditional export guarantees
// that. Everything else in the app imports only this file.
export 'ads_service_stub.dart'
    if (dart.library.io) 'ads_service_mobile.dart';
