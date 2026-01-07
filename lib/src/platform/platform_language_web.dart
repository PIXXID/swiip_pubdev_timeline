import 'package:web/web.dart' as web;

/// Returns the platform language code in the format 'language-country' (e.g., 'fr-FR', 'en-US').
///
/// For web platforms, this retrieves the language from the browser's navigator.
String platformLanguage() {
  // Exemple: "fr-FR"
  return web.window.navigator.language;
}
