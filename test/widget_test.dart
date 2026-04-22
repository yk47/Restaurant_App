import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:restaurant_app/core/api_client.dart';
import 'package:restaurant_app/core/app_config.dart';
import 'package:restaurant_app/main.dart';
import 'package:restaurant_app/models/restaurant.dart';
import 'package:restaurant_app/models/restaurant_detail.dart';

class FakeRestaurantApiClient extends RestaurantApiClient {
  FakeRestaurantApiClient(super.config);

  @override
  Future<List<Restaurant>> searchRestaurants({
    required String query,
    required int page,
    int perPage = 20,
  }) async {
    return <Restaurant>[
      Restaurant(
        id: '1',
        name: 'Saffron Kitchen',
        description: 'Mediterranean and grilled favorites.',
        imageUrl: '',
        subtitle: 'Mediterranean',
        raw: const <String, dynamic>{},
      ),
    ];
  }

  @override
  Future<RestaurantDetail> getRestaurantDetail({
    required String restaurantId,
  }) async {
    return RestaurantDetail(
      id: restaurantId,
      name: 'Saffron Kitchen',
      description: 'Mediterranean and grilled favorites.',
      imageUrl: '',
      images: const <String>[],
      address: 'Kuwait City',
      phone: '+965 12345678',
      subtitle: 'Mediterranean',
      raw: const <String, dynamic>{},
    );
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('renders restaurant search screen', (WidgetTester tester) async {
    final config = const AppConfig();
    final client = FakeRestaurantApiClient(config);

    await tester.pumpWidget(
      RestaurantApp(appConfig: config, apiClient: client),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Special Offers'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Special Offers'), findsOneWidget);
  });
}
