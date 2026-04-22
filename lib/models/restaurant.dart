class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.raw,
    this.description = '',
    this.imageUrl = '',
    this.subtitle = '',
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String subtitle;
  final Map<String, dynamic> raw;

  String get heroTag => 'restaurant-image-$id';

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id:
          _stringValue(json, const <String>[
            'id',
            'restaurantId',
            'restaurant_id',
            '_id',
            'rid',
          ]) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name:
          _stringValue(json, const <String>[
            'name',
            'restaurantName',
            'title',
            'branchName',
          ]) ??
          'Restaurant',
      description:
          _stringValue(json, const <String>[
            'description',
            'shortDescription',
            'details',
            'summary',
          ]) ??
          '',
      imageUrl:
          _stringValue(json, const <String>[
            'image',
            'imageUrl',
            'coverImage',
            'thumbnail',
            'photo',
            'logo',
          ]) ??
          '',
      subtitle:
          _stringValue(json, const <String>[
            'categoryName',
            'cuisineName',
            'type',
            'subtitle',
          ]) ??
          '',
      raw: json,
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
