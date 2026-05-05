import 'package:flutter/material.dart';
import '../models/serie.dart';
import '../services/preferences_service.dart';

class FavorisProvider with ChangeNotifier {
  final PreferencesService _prefsService;

  List<Serie> _favoris = [];

  List<Serie> get favoris => _favoris;

  FavorisProvider({PreferencesService? prefsService})
      : _prefsService = prefsService ?? PreferencesService() {
    _chargerFavoris();
  }

  Future<void> _chargerFavoris() async {
    _favoris = await _prefsService.getFavoris();
    notifyListeners();
  }

  Future<void> toggleFavori(Serie serie) async {
    if (_favoris.any((s) => s.id == serie.id)) {
      _favoris.removeWhere((s) => s.id == serie.id);
    } else {
      _favoris.add(serie);
    }
    await _prefsService.saveFavoris(_favoris);
    notifyListeners();
  }

  bool estFavori(int serieId) => _favoris.any((s) => s.id == serieId);
}
