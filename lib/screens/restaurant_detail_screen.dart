import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api_client.dart';
import '../core/exception_handler.dart';
import '../models/restaurant.dart';
import '../models/restaurant_detail.dart';
import '../widgets/error_fallback.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
    required this.heroTag,
    this.previewRestaurant,
  });

  final String restaurantId;
  final String heroTag;
  final Restaurant? previewRestaurant;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  late Future<RestaurantDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDetail();
  }

  Future<RestaurantDetail> _loadDetail() {
    return Get.find<RestaurantApiClient>().getRestaurantDetail(
      restaurantId: widget.restaurantId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      extendBodyBehindAppBar: true,
      body: FutureBuilder<RestaurantDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorFallbackWidget(
              title: 'Could not load restaurant',
              message: ExceptionHandler.handle(
                snapshot.error ?? 'Unknown error',
              ).message,
              onRetry: () {
                setState(() {
                  _future = _loadDetail();
                });
              },
            );
          }

          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('Restaurant details unavailable.'));
          }

          return _RestaurantDetailContent(
            detail: detail,
            heroTag: widget.heroTag,
            previewRestaurant: widget.previewRestaurant,
            onBack: () => Navigator.pop(context),
          );
        },
      ),
    );
  }
}

class _RestaurantDetailContent extends StatefulWidget {
  const _RestaurantDetailContent({
    required this.detail,
    required this.heroTag,
    required this.previewRestaurant,
    required this.onBack,
  });

  final RestaurantDetail detail;
  final String heroTag;
  final Restaurant? previewRestaurant;
  final VoidCallback onBack;

  @override
  State<_RestaurantDetailContent> createState() =>
      _RestaurantDetailContentState();
}

class _RestaurantDetailContentState extends State<_RestaurantDetailContent> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final gallery = <String>{
      if (detail.imageUrl.isNotEmpty) detail.imageUrl,
      ...detail.images,
    }.toList(growable: false);

    final menuItems = detail.items;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;

        return Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: wide ? 920 : double.infinity,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _HeroTopSection(
                        heroTag: widget.heroTag,
                        imageUrl: detail.imageUrl,
                        title: detail.name,
                        onBack: widget.onBack,
                        gallery: gallery,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -22),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7F7FA),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(26),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE7FFF1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        children: <Widget>[
                                          Icon(
                                            Icons.local_offer,
                                            size: 14,
                                            color: Color(0xFF1EAF62),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            '10% OFF',
                                            style: TextStyle(
                                              color: Color(0xFF1EAF62),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Color(0xFFF0A21D),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      detail.rating > 0
                                          ? detail.rating.toStringAsFixed(1)
                                          : 'N/A',
                                      style: const TextStyle(
                                        color: Color(0xFF7E7E88),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  detail.name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    const _MetaItem(
                                      icon: Icons.watch_later_outlined,
                                      text: '15 min',
                                    ),
                                    const _MetaItem(
                                      icon: Icons.attach_money,
                                      text: 'KD 5.00',
                                    ),
                                    _MetaItem(
                                      icon: Icons.lunch_dining_outlined,
                                      text:
                                          detail.restaurantCategories.isNotEmpty
                                          ? detail.restaurantCategories
                                          : (detail.subtitle.isNotEmpty
                                                ? detail.subtitle
                                                : 'Italian'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _MetaItem(
                                  icon: Icons.location_on_outlined,
                                  text: detail.address.isNotEmpty
                                      ? 'Location: ${detail.address}'
                                      : 'Location: 1012 Ocean avenue, New york, USA',
                                ),
                                if (detail.supportPhone.isNotEmpty ||
                                    detail.phone.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 6),
                                  _MetaItem(
                                    icon: Icons.phone_outlined,
                                    text: detail.supportPhone.isNotEmpty
                                        ? detail.supportPhone
                                        : detail.phone,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                _TabsRow(
                                  selectedIndex: selectedTab,
                                  onChange: (index) {
                                    setState(() {
                                      selectedTab = index;
                                    });
                                  },
                                ),
                                const SizedBox(height: 14),
                                if (selectedTab == 1)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      detail.description.isNotEmpty
                                          ? detail.description
                                          : 'No description available for this restaurant.',
                                      style: const TextStyle(
                                        color: Color(0xFF4B4B56),
                                        height: 1.45,
                                      ),
                                    ),
                                  )
                                else ...<Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        'Menu (${menuItems.length} items)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Text(
                                        'View Full Menu',
                                        style: TextStyle(
                                          color: Color(0xFF7A6ED2),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Search items',
                                        prefixIcon: Icon(Icons.search),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const _MenuFilterChips(),
                                  const SizedBox(height: 14),
                                  if (menuItems.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Text(
                                        'No menu items available.',
                                        style: TextStyle(
                                          color: Color(0xFF7A7A85),
                                        ),
                                      ),
                                    )
                                  else
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: menuItems.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: wide ? 3 : 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.95,
                                          ),
                                      itemBuilder: (context, index) {
                                        return _MenuCard(
                                          item: menuItems[index],
                                        );
                                      },
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6751D5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Book a Table',
                      style: TextStyle(
                        fontSize: 24 / 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroTopSection extends StatelessWidget {
  const _HeroTopSection({
    required this.heroTag,
    required this.imageUrl,
    required this.title,
    required this.onBack,
    required this.gallery,
  });

  final String heroTag;
  final String imageUrl;
  final String title;
  final VoidCallback onBack;
  final List<String> gallery;

  @override
  Widget build(BuildContext context) {
    final resolvedGallery = gallery.isNotEmpty
        ? gallery
        : <String>[if (imageUrl.isNotEmpty) imageUrl];

    return SizedBox(
      height: 326,
      child: Stack(
        children: <Widget>[
          Hero(
            tag: heroTag,
            child: SizedBox.expand(
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _heroPlaceholder(),
                    )
                  : _heroPlaceholder(),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x44000000), Color(0x99000000)],
              ),
            ),
            child: SizedBox.expand(),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 14,
            right: 14,
            child: Row(
              children: <Widget>[
                _RoundIconButton(icon: Icons.arrow_back, onPressed: onBack),
                const Spacer(),
                _RoundIconButton(icon: Icons.share, onPressed: () {}),
                const SizedBox(width: 10),
                _RoundIconButton(icon: Icons.favorite_border, onPressed: () {}),
              ],
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: Color(0xCC202020),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
          if (resolvedGallery.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: resolvedGallery.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final url = resolvedGallery[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 74,
                        color: Colors.white,
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: url.isEmpty
                              ? _thumbPlaceholder()
                              : Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _thumbPlaceholder(),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: const Color(0xFF323232),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: const Color(0xFFE7E7EC),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Color(0xFF9F9FA8)),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: const Color(0xFF2A2A2E), size: 22),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFF7669CC)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF74747F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TabsRow extends StatelessWidget {
  const _TabsRow({required this.selectedIndex, required this.onChange});

  final int selectedIndex;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    const tabs = <String>['Menu', 'About', 'Gallery', 'Review'];
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7EE))),
      ),
      child: Row(
        children: List<Widget>.generate(tabs.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChange(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: selected
                      ? const Border(
                          bottom: BorderSide(
                            color: Color(0xFF6751D5),
                            width: 3,
                          ),
                        )
                      : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF6751D5)
                        : const Color(0xFF73737E),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MenuFilterChips extends StatelessWidget {
  const _MenuFilterChips();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const <Widget>[
          _SmallTag(
            label: 'Veg',
            icon: Icons.eco_outlined,
            bg: Color(0xFFF2FFF3),
            fg: Color(0xFF2EA852),
          ),
          SizedBox(width: 8),
          _SmallTag(
            label: 'Spicy',
            icon: Icons.local_fire_department_outlined,
            bg: Color(0xFFFFF1F1),
            fg: Color(0xFFE46262),
          ),
          SizedBox(width: 8),
          _SmallTag(
            label: 'Bestseller Items',
            bg: Colors.white,
            fg: Color(0xFF5E5E69),
          ),
          SizedBox(width: 8),
          _SmallTag(
            label: 'Top rated Item',
            bg: Colors.white,
            fg: Color(0xFF5E5E69),
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8E8EF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});

  final RestaurantMenuItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (item.categoryName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC23232A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'KD ${item.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F2F38),
                        ),
                      ),
                      if (item.regularPrice > item.finalPrice) ...<Widget>[
                        const SizedBox(width: 6),
                        Text(
                          'KD ${item.regularPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8B8B96),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x00000000), Color(0xAA000000)],
                ),
              ),
              child: Text(
                item.description.isNotEmpty
                    ? '${item.name}\n${item.description}'
                    : item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE6E6EB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_outlined,
        size: 32,
        color: Color(0xFF90909A),
      ),
    );
  }
}
