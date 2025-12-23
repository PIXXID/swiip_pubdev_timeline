// FONCTIONS PARTAGÉES DE L'APPLICATION
import 'package:flutter/material.dart';

Color? formatStringToColor(String? color) {
  if (color == null || color.isEmpty) {
    return null; // Si la chaîne est nulle ou vide, on retourne null
  }

  // On enlève le # si présent
  String cleanedColor = color.replaceAll('#', '');

  // Si la chaîne a 6 caractères, on ajoute 'FF' pour une opacité maximale
  if (cleanedColor.length == 6) {
    cleanedColor = 'FF$cleanedColor';
  }

  try {
    // Conversion de la chaîne en entier et retour de la couleur
    return Color(int.parse(cleanedColor, radix: 16));
  } catch (e) {
    // En cas d'erreur de parsing, retourne null
    return null;
  }
}