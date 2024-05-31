import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

var accentColor = const Color(0xFFFFCD03);
var mainFontColor = const Color(0xFFFFFFFF);

var appTheme = ThemeData(
  fontFamily: GoogleFonts.nunito().fontFamily,
  brightness: Brightness.dark,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 18),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontWeight: FontWeight.bold,
    ),
    titleSmall: TextStyle(
      color: Colors.grey,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w200,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      foregroundColor: Colors.white,
      backgroundColor: accentColor,
    ),
  ),
  bottomAppBarTheme: const BottomAppBarTheme(
    color: Colors.black87,
  ),
);
