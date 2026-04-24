class RestaurantDetail {
  const RestaurantDetail({
    required this.id,
    required this.name,
    required this.raw,
    this.description = '',
    this.imageUrl = '',
    this.images = const [],
    this.address = '',
    this.phone = '',
    this.supportPhone = '',
    this.subtitle = '',
    this.restaurantCategories = '',
    this.rating = 0,
    this.items = const [],
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> images;
  final String address;
  final String phone;
  final String supportPhone;
  final String subtitle;
  final String restaurantCategories;
  final double rating;
  final List<RestaurantMenuItem> items;
  final Map<String, dynamic> raw;

  factory RestaurantDetail.fromJson(Map<String, dynamic> json) {
    final rawImages = [
      _stringValue(json, const [
            'image',
            'imageUrl',
            'coverImage',
            'thumbnail',
            'photo',
            'logo',
          ]) ??
          '',
    ];

    rawImages.addAll(
      _stringListValue(json, const [
        'images',
        'gallery',
        'photos',
        'imageUrls',
      ]),
    );

    final filteredImages = rawImages
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);

    return RestaurantDetail(
      id:
          _stringValue(json, const [
            'id',
            'restaurantId',
            'restaurant_id',
            '_id',
            'rid',
          ]) ??
          '0',

      name:
          _stringValue(json, const [
            'name',
            'restaurantName',
            'title',
            'branchName',
          ]) ??
          'Restaurant',

      description:
          _stringValue(json, const [
            'description',
            'longDescription',
            'details',
            'summary',
          ]) ??
          '',

      imageUrl: filteredImages.isNotEmpty ? filteredImages.first : '',
      images: filteredImages,

      address: _addressValue(json) ?? '',

      phone:
          _stringValue(json, const ['phone', 'phoneNumber', 'telephone']) ?? '',

      supportPhone:
          _stringValue(json, const [
            'supportPhone',
            'support_phone',
            'supportNumber',
            'supportNo',
            'customerSupportPhone',
          ]) ??
          '',

      subtitle:
          _stringValue(json, const [
            'categoryName',
            'cuisineName',
            'type',
            'subtitle',
          ]) ??
          '',

      restaurantCategories:
          _categoriesValue(json, const [
            'restaurantCategories',
            'categories',
            'cuisines',
            'categoryName',
            'cuisineName',
          ]) ??
          '',

      rating:
          _doubleValue(json, const ['rating', 'avgRating', 'averageRating']) ??
          0,

      items: _menuItemsValue(json, const ['itemList', 'items', 'menuItems']),

      raw: json,
    );
  }
}

class RestaurantMenuItem {
  const RestaurantMenuItem({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.categoryName = '',
    this.description = '',
    this.finalPrice = 0,
    this.regularPrice = 0,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final double regularPrice;
  final String categoryName;
  final double finalPrice;

  factory RestaurantMenuItem.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuItem(
      id: _stringValue(json, const ['id', 'itemId', '_id']) ?? '0',

      name:
          _stringValue(json, const ['name', 'itemName', 'title']) ??
          'Menu Item',

      imageUrl:
          _stringValue(json, const ['defaultImage', 'image', 'imageUrl']) ??
          _firstImageFromList(json['images']) ??
          '',

      categoryName:
          _stringValue(json, const ['categoryName', 'category']) ?? '',

      description:
          _stringValue(json, const ['shortDescription', 'description']) ?? '',

      finalPrice:
          _doubleValue(json, const ['finalPrice', 'price', 'regularPrice']) ??
          0,

      regularPrice: _doubleValue(json, const ['regularPrice', 'price']) ?? 0,
    );
  }
}

String? _stringValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is num) {
      return value.toString();
    }
  }
  return null;
}

List<String> _stringListValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];

    if (value is List) {
      return value
          .whereType<String>()
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);
    }
  }
  return const [];
}

double? _doubleValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];

    if (value is num) return value.toDouble();

    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

String? _categoriesValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is List) {
      final labels = <String>[];

      for (final item in value) {
        if (item is String && item.trim().isNotEmpty) {
          labels.add(item.trim());
          continue;
        }

        if (item is Map<String, dynamic>) {
          final label = _stringValue(item, const [
            'name',
            'title',
            'label',
            'categoryName',
          ]);

          if (label != null && label.isNotEmpty) {
            labels.add(label);
          }
        }
      }

      if (labels.isNotEmpty) {
        return labels.join(', ');
      }
    }
  }
  return null;
}

String? _addressValue(Map<String, dynamic> json) {
  final directAddress = _stringValue(json, const [
    'address',
    'location',
    'branchAddress',
  ]);

  if (directAddress != null && directAddress.isNotEmpty) {
    return directAddress;
  }

  final address = json['address'];

  if (address is Map<String, dynamic>) {
    final parts = <String>[];

    final areaName = _stringValue(address, const ['areaName']);
    final block = _stringValue(address, const ['block']);
    final street = _stringValue(address, const ['street']);
    final building = _stringValue(address, const ['building']);
    final floor = _stringValue(address, const ['floor']);
    final stateName = _stringValue(address, const ['stateName']);

    if (areaName != null) parts.add(areaName);
    if (block != null) parts.add('Block $block');
    if (street != null) parts.add('Street $street');
    if (building != null) parts.add('Building $building');

    if (floor != null && floor.trim().isNotEmpty) {
      parts.add('Floor $floor');
    }

    if (stateName != null) parts.add(stateName);

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
  }

  return null;
}

List<RestaurantMenuItem> _menuItemsValue(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];

    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(RestaurantMenuItem.fromJson)
          .toList(growable: false);
    }
  }
  return const [];
}

String? _firstImageFromList(dynamic value) {
  if (value is List && value.isNotEmpty) {
    for (final item in value) {
      if (item is String && item.trim().isNotEmpty) {
        return item.trim();
      }

      if (item is Map<String, dynamic>) {
        final image = _stringValue(item, const ['image', 'url', 'imageUrl']);

        if (image != null && image.isNotEmpty) {
          return image;
        }
      }
    }
  }

  return null;
}
