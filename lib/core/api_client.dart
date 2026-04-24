import 'dart:convert';
import 'dart:io';

import '../models/restaurant.dart';
import '../models/restaurant_detail.dart';
import 'app_config.dart';
import 'exception_handler.dart';

class RestaurantApiClient {
  RestaurantApiClient(this.config);

  final AppConfig config;
  final HttpClient _httpClient = HttpClient();

  Future<List<Restaurant>> searchRestaurants({
    required String query,
    required int page,
    int perPage = 20,
  }) async {
    final payload = await _requestJson(
      method: 'POST',
      uri: config.searchUri(query: query, page: page, perPage: perPage),
      body: {'categoryId': ''},
    );

    final items = _extractList(payload);

    return items
        .whereType<Map<String, dynamic>>()
        .map(Restaurant.fromJson)
        .toList();
  }

  Future<RestaurantDetail> getRestaurantDetail({
    required String restaurantId,
  }) async {
    final payload = await _requestJson(
      method: 'GET',
      uri: config.detailUri(restaurantId: restaurantId),
    );

    final map = _extractMap(payload);
    return RestaurantDetail.fromJson(map);
  }

  Future<dynamic> _requestJson({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = await _httpClient.openUrl(method, uri);

      request.headers.contentType = ContentType.json;
      request.headers.set('Accept', 'application/json');
      request.headers.set('Accept-Charset', 'UTF-8');

      request.headers.set(
        'User-Agent',
        config.headers['User-Agent'] ?? 'Mozilla/5.0',
      );

      request.headers.set('auth', config.headers['auth'] ?? '');
      request.headers.set('sessiontoken', config.headers['sessiontoken'] ?? '');

      if (method == 'POST') {
        request.add(utf8.encode(jsonEncode(body ?? {})));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          _extractErrorMessage(responseBody) ??
              'Request failed with status ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }

      if (responseBody.trim().isEmpty) {
        return {};
      }

      return jsonDecode(responseBody);
    } on SocketException {
      throw const AppException('No internet connection.');
    } on HttpException catch (error) {
      throw AppException(error.message);
    } on FormatException {
      throw const AppException('Unexpected response format.');
    } catch (error) {
      throw ExceptionHandler.handle(error);
    }
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List<dynamic>) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      final candidates = [
        payload['data'],
        payload['result'],
        payload['items'],
        payload['restaurants'],
      ];

      for (final candidate in candidates) {
        if (candidate is List<dynamic>) {
          return candidate;
        }

        if (candidate is Map<String, dynamic>) {
          final nestedCandidates = [
            candidate['items'],
            candidate['restaurants'],
            candidate['data'],
            candidate['list'],
          ];

          for (final nested in nestedCandidates) {
            if (nested is List<dynamic>) {
              return nested;
            }
          }
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _extractMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) return data;

      final restaurant = payload['restaurant'];
      if (restaurant is Map<String, dynamic>) return restaurant;

      return payload;
    }

    return {};
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        final candidates = [
          decoded['message'],
          decoded['error'],
          decoded['title'],
          decoded['detail'],
        ];

        for (final candidate in candidates) {
          if (candidate is String && candidate.trim().isNotEmpty) {
            return candidate;
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
