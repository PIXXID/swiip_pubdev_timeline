import 'package:flutter/widgets.dart';

String platformLanguage() {
  // Exemple: "fr_FR" -> on convertit en "fr-FR" si tu veux le même format
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final lang = locale.languageCode;
  final country = locale.countryCode;
  return (country == null || country.isEmpty) ? lang : '$lang-$country';
}
