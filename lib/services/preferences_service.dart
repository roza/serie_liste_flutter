import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/serie.dart';

class PreferencesService {
  static const _favorisKey = 'favoris';

  Future<List<Serie>> getFavoris() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_favorisKey);
    if (jsonStr == null) return [];

    final List<dynamic> data = jsonDecode(jsonStr);
    return data.map((j) => Serie.fromJson(j)).toList();
  }

  Future<void> saveFavoris(List<Serie> favoris) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(favoris.map((s) => s.toJson()).toList());
    await prefs.setString(_favorisKey, jsonStr);
  }
}
