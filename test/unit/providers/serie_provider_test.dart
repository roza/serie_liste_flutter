import 'package:flutter_test/flutter_test.dart';
import 'package:serie_liste/providers/serie_provider.dart';
import 'package:serie_liste/services/serie_api_service.dart';
import '../../helpers/test_data.dart';
import '../../mocks/mock_http_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SerieProvider', () {
    test('état initial : liste vide, pas de chargement', () {
      final provider = SerieProvider();

      expect(provider.series, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('fetchSeries charge les séries depuis le service', () async {
      final provider = SerieProvider(
        apiService: SerieApiService(client: MockHttpClient(body: mockSeriesJson)),
      );

      await provider.fetchSeries();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.series.length, 2);
      expect(provider.series[0].nom, 'Breaking Bad');
      expect(provider.error, isNull);
    });

    test('fetchSeries utilise le fallback mock en cas d\'erreur réseau', () async {
      final provider = SerieProvider(
        apiService: SerieApiService(client: MockHttpClientError()),
      );

      await provider.fetchSeries();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.series, isNotEmpty);
      expect(provider.error, isNotNull);
    });

    test('notifie les listeners après fetchSeries', () async {
      final provider = SerieProvider(
        apiService: SerieApiService(client: MockHttpClient(body: mockSeriesJson)),
      );
      var notified = false;
      provider.addListener(() => notified = true);

      await provider.fetchSeries();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notified, isTrue);
    });
  });
}
