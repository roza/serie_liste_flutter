import 'package:flutter/material.dart';
import '../models/serie.dart';
import '../services/serie_api_service.dart';

class SerieProvider with ChangeNotifier {
  final SerieApiService _apiService;

  List<Serie> _series = [];
  bool _isLoading = false;
  String? _error;

  List<Serie> get series => _series;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SerieProvider({SerieApiService? apiService})
      : _apiService = apiService ?? SerieApiService();

  Future<void> fetchSeries() async {
    _isLoading = true;
    _error = null;

    try {
      _series = await _apiService.fetchSeries();
    } catch (e) {
      _error = 'Impossible de charger les séries.';
      _series = _apiService.getMockSeries();
    } finally {
      _isLoading = false;
      // fetchSeries() est async : quand on arrive ici, le build est terminé.
      // notifyListeners() peut donc être appelé.
      notifyListeners();
    }
  }

  Future<Serie> fetchSerieById(int id) async {
    return _apiService.fetchSerieById(id);
  }
}
