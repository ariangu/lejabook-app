import 'dart:ui';
import 'package:latlong2/latlong.dart';

class Config {

  static String baseUrl = 'https://lejabook.com/';
  static int? userId;
       String clientId = '4',
        clientSecret = '2LeYWVhDvQ8vMGf6TXM0JLmyXnHvx7CxqYBNMp0I',
        copyright = '\u00a9',
        appName = 'LejaBook',
        version = 'V 1.0',
      splashScreen = '${Config.baseUrl}uploads/mobile/welcome.jpg',
      loginScreen = '${Config.baseUrl}uploads/mobile/login.jpg',
      noDataImage = '${Config.baseUrl}uploads/mobile/no_data.jpg',
      defaultBusinessImage = '${Config.baseUrl}uploads/business_default.jpg';
    final bool syncCallLog = true, showRegister = true, showFieldForce = true;

  //quantity precision       //currency precision   //call_log sync duration
  static int quantityPrecision = 0, currencyPrecision = 0, callLogSyncDuration = 10;

  //List of locale language code
  List locale = ['en', 'ar', 'de', 'fr', 'es','tr','id','my'];
  String defaultLanguage = 'en';

  //List of locales included
  List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ar', ''),
    Locale('de', ''),
    Locale('fr', ''),
    Locale('es', ''),
    Locale('tr', ''),
    Locale('id', ''),
    Locale('my', '')
  ];

  //dropdown items for changing language
  List<Map<String, dynamic>> lang = [
    {'languageCode': 'en', 'countryCode': 'US', 'name': 'English'},
    {'languageCode': 'ar', 'countryCode': '', 'name': 'العربي'},
    {'languageCode': 'de', 'countryCode': '', 'name': 'Deutsche'},
    {'languageCode': 'fr', 'countryCode': '', 'name': 'Français'},
    {'languageCode': 'es', 'countryCode': '', 'name': 'Española'},
    {'languageCode': 'tr', 'countryCode': '', 'name': 'Türkçe'},
    {'languageCode': 'id', 'countryCode': '', 'name': 'Indonesian'},
    {'languageCode': 'my', 'countryCode': '', 'name': 'မြန်မာ'}
  ];

  //final initialPosition = LatLng(20.46752985010792, 82.92005813910752);
  final String googleAPIKey = 'AIzaSyA4ogfTIWk71yyo-fWImjVBFuA13P0lApU';
}
