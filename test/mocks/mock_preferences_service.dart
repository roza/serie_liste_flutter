import 'package:serie_liste/models/serie.dart';
import 'package:serie_liste/services/preferences_service.dart';

class MockPreferencesService extends PreferencesService {
  List<Serie> _favoris = [];

  @override
  Future<List<Serie>> getFavoris() async => List.from(_favoris);

  @override
  Future<void> saveFavoris(List<Serie> favoris) async {
    _favoris = List.from(favoris);
  }
}
