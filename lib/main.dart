import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/api_client.dart';
import 'core/app_config.dart';
import 'screens/restaurant_list_screen.dart';

void main() {
  final appConfig = const AppConfig();
  final apiClient = RestaurantApiClient(appConfig);

  Get.put<AppConfig>(appConfig, permanent: true);
  Get.put<RestaurantApiClient>(apiClient, permanent: true);

  runApp(RestaurantApp(appConfig: appConfig, apiClient: apiClient));
}

class RestaurantApp extends StatefulWidget {
  const RestaurantApp({super.key, this.appConfig, this.apiClient});

  final AppConfig? appConfig;
  final RestaurantApiClient? apiClient;

  @override
  State<RestaurantApp> createState() => _RestaurantAppState();
}

class _RestaurantAppState extends State<RestaurantApp> {
  late final AppConfig _appConfig = widget.appConfig ?? const AppConfig();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<RestaurantApiClient>()) {
      Get.put<RestaurantApiClient>(
        widget.apiClient ?? RestaurantApiClient(_appConfig),
        permanent: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppConfigScope(
      config: _appConfig,
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Restaurant Explorer',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1857D6),
          scaffoldBackgroundColor: const Color(0xFFFFFBF6),
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        home: const RestaurantListScreen(),
      ),
    );
  }
}
