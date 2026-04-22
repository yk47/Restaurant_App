import 'package:flutter/widgets.dart';

class AppConfig {
  const AppConfig({
    this.baseUri = 'https://dev-api.livelongfit.com',
    this.lang = 'en',
    this.storeCode = 'KW',
    this.currencyCode = 'KD',
    this.userId = '1f60cddc-ae03-4430-b8d7-deb6bf63846c',
    this.latLng = '29.3800453,47.9744896',
    this.authToken =
        'Y8FyZBClwGhrOYaq1sOi5Kr+vqgI9ZUlRWuqzVaqljqSzejGXrxD158TZ0fSbJWbugCpYXu8w6PeRSpZjgZJ+Vur1B0ktJDByxpgVdweAJ+4CO1YQ5DltkgFjk+TmgmTmFNc/IwFAVGBtu2kCeWVZUf7t5A/dKkQUdCBdfkJaVkYHQRbM+ekxvpVLWsrBp8wLsM12O2UJiy01EMd7MlUUyErdT9K9+047LTgMTZXs5fiKkPP1GJKx7BjAjMIIF7Mf3k1Z6BQZ0bv/+orMLaGYbpoRvClPdEpRV23pZfeTqE=',
    this.sessionToken = '',
    this.defaultPerPage = 20,
  });

  final String baseUri;
  final String lang;
  final String storeCode;
  final String currencyCode;
  final String userId;
  final String latLng;
  final String authToken;
  final String sessionToken;
  final int defaultPerPage;

  Uri searchUri({
    required String query,
    required int page,
    required int perPage,
  }) {
    return Uri.parse('$baseUri/api/v2/restaurant/search').replace(
      queryParameters: <String, String>{
        'lang': lang,
        'storeCode': storeCode,
        'page': page.toString(),
        'perPage': perPage.toString(),
        'q': query,
        'categoryId': '',
        'macroCategoryId': '',
        'nearBy': '',
        'sortBy': '1',
        'homeManagementId': '',
        'latlng': latLng,
        'userId': userId,
        'calories': '',
        'carbs': '',
        'proteins': '',
        'fats': '',
        'isCheat': '0',
      },
    );
  }

  Uri detailUri({required String restaurantId}) {
    return Uri.parse('$baseUri/api/v2/restaurant/details').replace(
      queryParameters: <String, String>{
        'lang': lang,
        'storeCode': storeCode,
        'currencyCode': currencyCode,
        'restaurantId': restaurantId,
        'userId': userId,
        'latlng': latLng,
      },
    );
  }

  Map<String, String> get headers => <String, String>{
    'Accept': 'application/json',
    'Accept-Charset': 'UTF-8',
    'Content-Type': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:127.0) Gecko/20100101 Firefox/127.0',
    'auth': authToken,
    'sessiontoken': sessionToken,
  };
}

class AppConfigScope extends InheritedWidget {
  const AppConfigScope({super.key, required this.config, required super.child});

  final AppConfig config;

  static AppConfig of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppConfigScope>();
    assert(scope != null, 'AppConfigScope not found in widget tree.');
    return scope!.config;
  }

  @override
  bool updateShouldNotify(AppConfigScope oldWidget) {
    return oldWidget.config != config;
  }
}
