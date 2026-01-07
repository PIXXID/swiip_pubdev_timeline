import 'package:flutter/widgets.dart';

/// Returns the platform language code in the format 'language-country' (e.g., 'fr-FR', 'en-US').
///
/// For IO platforms (mobile, desktop), this retrieves the locale from the platform dispatcher.
/// If no country code is available, returns only the language code (e.g., 'fr').
String platformLanguage() {
  // Exemple: "fr_FR" -> on convertit en "fr-FR" si tu veux le même format
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final lang = locale.languageCode;
  final country = locale.countryCode;
  return (country == null || country.isEmpty) ? lang : '$lang-$country';
}
