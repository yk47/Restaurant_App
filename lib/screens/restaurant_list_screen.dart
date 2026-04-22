import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/exception_handler.dart';
import '../models/restaurant.dart';
import '../widgets/error_fallback.dart';
import '../widgets/restaurant_card.dart';
import 'restaurant_detail_screen.dart';

class RestaurantListController extends GetxController {
  RestaurantListController(this.apiClient);

  final RestaurantApiClient apiClient;
  final restaurants = <Restaurant>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = RxnString();

  int _page = 1;
  String _query = '';
  int _requestToken = 0;

  Future<void> loadRestaurants({required String query}) async {
    _query = query;
    _page = 1;
    hasMore.value = true;
    errorMessage.value = null;
    restaurants.clear();
    isLoading.value = true;

    final int requestToken = ++_requestToken;

    try {
      final results = await apiClient.searchRestaurants(
        query: query,
        page: _page,
        perPage: apiClient.config.defaultPerPage,
      );
      if (requestToken != _requestToken) {
        return;
      }
      restaurants.assignAll(results);
      hasMore.value = results.length >= apiClient.config.defaultPerPage;
    } catch (error) {
      if (requestToken != _requestToken) {
        return;
      }
      errorMessage.value = ExceptionHandler.handle(error).message;
      hasMore.value = false;
    } finally {
      if (requestToken == _requestToken) {
        isLoading.value = false;
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) {
      return;
    }

    isLoadingMore.value = true;
    final int requestToken = _requestToken;

    try {
      final nextPage = _page + 1;
      final results = await apiClient.searchRestaurants(
        query: _query,
        page: nextPage,
        perPage: apiClient.config.defaultPerPage,
      );
      if (requestToken != _requestToken) {
        return;
      }
      _page = nextPage;
      restaurants.addAll(results);
      hasMore.value = results.length >= apiClient.config.defaultPerPage;
    } catch (error) {
      if (requestToken != _requestToken) {
        return;
      }
      errorMessage.value = ExceptionHandler.handle(error).message;
    } finally {
      if (requestToken == _requestToken) {
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> retry() => loadRestaurants(query: _query);
}

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late final RestaurantListController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _controller = Get.put(
      RestaurantListController(Get.find<RestaurantApiClient>()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadRestaurants(query: '');
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    if (Get.isRegistered<RestaurantListController>()) {
      Get.delete<RestaurantListController>(force: true);
    }
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      _controller.loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller.loadRestaurants(query: value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfigScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(190),
        child: SafeArea(
          bottom: false,
          top: false,
          child: _TopHeader(
            controller: _searchController,
            storeCode: config.storeCode,
            onSearchChanged: _onSearchChanged,
            onSearchSubmitted: (value) {
              _controller.loadRestaurants(query: value.trim());
            },
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        onHomeTap: () {},
        onDiscoverTap: () {},
        onWishlistTap: () {},
        onChatTap: () {},
        onProfileTap: () {},
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final errorMessage = _controller.errorMessage.value;
          final restaurants = _controller.restaurants;

          if (_controller.isLoading.value && restaurants.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null && restaurants.isEmpty) {
            return ErrorFallbackWidget(
              message: errorMessage,
              onRetry: _controller.retry,
            );
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              const SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Special Offers',
                  actionText: 'See All',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: _OfferCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(
                child: _SectionHeader(title: 'Cuisines', actionText: 'See All'),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              const SliverToBoxAdapter(child: _CuisineChips()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Popular Restaurants',
                  actionText: 'See All',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              const SliverToBoxAdapter(child: _FilterRow()),
              if (restaurants.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text('No restaurants found. Try another search.'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  sliver: SliverList.separated(
                    itemCount: restaurants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: RestaurantCard(
                          restaurant: restaurant,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => RestaurantDetailScreen(
                                  restaurantId: restaurant.id,
                                  heroTag: restaurant.heroTag,
                                  previewRestaurant: restaurant,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              SliverToBoxAdapter(
                child: AnimatedOpacity(
                  opacity: _controller.isLoadingMore.value ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          );
        }),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.controller,
    required this.storeCode,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
  });

  final TextEditingController controller;
  final String storeCode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF6A53D9), Color(0xFF5A48C8)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x2A4A3EB5),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 44),
          Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Location',
                      style: TextStyle(color: Color(0xFFCFC8FF), fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xFFFF8B37),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'New York, USA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFFCFC8FF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                  tooltip: 'Notifications',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  textField: true,
                  label: 'Search restaurants in $storeCode',
                  child: TextField(
                    controller: controller,
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {},
                  tooltip: 'Filter',
                  icon: const Icon(Icons.tune, color: Color(0xFF6751D6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionText});

  final String title;
  final String actionText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 28 / 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              actionText,
              style: const TextStyle(
                color: Color(0xFF7D70C8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 176),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Weekend Offers',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Get Special Offer',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22 / 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: 'Up to ',
                          style: TextStyle(color: Color(0xFF6D6D79)),
                        ),
                        TextSpan(
                          text: '30% OFF',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6551D5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Book Now'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 116,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: const Color(0xFFFFEFE7),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              size: 58,
              color: Color(0xFFFF8B37),
            ),
          ),
        ],
      ),
    );
  }
}

class _CuisineChips extends StatelessWidget {
  const _CuisineChips();

  @override
  Widget build(BuildContext context) {
    const cuisines = <String>[
      'Italian',
      'Mexican',
      'Chinese',
      'Indian',
      'Arabic',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF24222C),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              cuisines[index],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: cuisines.length,
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        children: const <Widget>[
          _FilterChip(label: 'Cuisins', selected: false, hasArrow: true),
          SizedBox(width: 8),
          _FilterChip(label: 'Nearest', selected: true),
          SizedBox(width: 8),
          _FilterChip(label: 'Great Offers', selected: true),
          SizedBox(width: 8),
          _FilterChip(label: 'Ratings 4.5+', selected: false),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.hasArrow = false,
  });

  final String label;
  final bool selected;
  final bool hasArrow;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF6551D5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF33313B),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasArrow) ...const <Widget>[
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF33313B)),
          ],
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.onHomeTap,
    required this.onDiscoverTap,
    required this.onWishlistTap,
    required this.onChatTap,
    required this.onProfileTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onDiscoverTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onChatTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _BottomItem(
              icon: Icons.home,
              label: 'Home',
              active: true,
              onTap: onHomeTap,
            ),
            _BottomItem(
              icon: Icons.explore_outlined,
              label: 'Discover',
              active: false,
              onTap: onDiscoverTap,
            ),
            _BottomItem(
              icon: Icons.favorite_border,
              label: 'Wishlist',
              active: false,
              onTap: onWishlistTap,
            ),
            _BottomItem(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              active: false,
              onTap: onChatTap,
            ),
            _BottomItem(
              icon: Icons.person_outline,
              label: 'Profile',
              active: false,
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              color: active ? const Color(0xFF6551D5) : const Color(0xFF9797A3),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active
                    ? const Color(0xFF6551D5)
                    : const Color(0xFF9797A3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
