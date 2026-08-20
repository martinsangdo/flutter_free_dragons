// Bottom-anchored adaptive banner for the game screen.
//
// Compile-time selected like AdsService: the real google_mobile_ads banner on
// mobile, and a zero-size stub on Web (ads disabled; the ad SDK depends on
// `dart:io` and must not reach a web build). Import only this file.
export 'ad_banner_stub.dart'
    if (dart.library.io) 'ad_banner_mobile.dart';
