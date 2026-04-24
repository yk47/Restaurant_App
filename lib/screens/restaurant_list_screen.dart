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

  // observable state
  final restaurants = <Restaurant>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = RxnString();

  int _page = 1;
  String _query = '';
  int _requestToken = 0; // helps avoid outdated API responses

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

      // ignore if a newer request was triggered
      if (requestToken != _requestToken) return;

      restaurants.assignAll(results);
      hasMore.value = results.length >= apiClient.config.defaultPerPage;
    } catch (error) {
      if (requestToken != _requestToken) return;

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

      if (requestToken != _requestToken) return;

      _page = nextPage;
      restaurants.addAll(results);
      hasMore.value = results.length >= apiClient.config.defaultPerPage;
    } catch (error) {
      if (requestToken != _requestToken) return;

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

  Timer? _debounce; // debounce for search

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_handleScroll);

    _controller = Get.put(
      RestaurantListController(Get.find<RestaurantApiClient>()),
    );

    // initial load
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

    // cleanup controller
    if (Get.isRegistered<RestaurantListController>()) {
      Get.delete<RestaurantListController>(force: true);
    }

    super.dispose();
  }

  void _handleScroll() {
    // load more when near bottom
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
            return ErrorView(message: errorMessage, onRetry: _controller.retry);
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
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
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

              // pagination loader
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
                  // fixed: withValues -> withOpacity
                  color: Colors.white.withOpacity(0.22),
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
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1C),
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              actionText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A53D9),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFF8B37), Color(0xFFFF6D4D)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Flash Deal',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Up to 40% OFF\non selected restaurants',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CuisineChips extends StatelessWidget {
  const _CuisineChips();

  static const List<String> _cuisines = <String>[
    'All',
    'Italian',
    'Burger',
    'Sushi',
    'Mexican',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: _cuisines.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final bool isSelected = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? const Color(0xFF6A53D9) : Colors.white,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6A53D9)
                    : const Color(0xFFE7E6EF),
              ),
            ),
            child: Text(
              _cuisines[index],
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2E2E2E),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    Widget filterChip(String label, {bool selected = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected ? const Color(0xFFEDE9FF) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF6A53D9) : const Color(0xFFE6E6EE),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF5644C5) : const Color(0xFF454545),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: <Widget>[
          filterChip('Nearby', selected: true),
          const SizedBox(width: 8),
          filterChip('Top Rated'),
          const SizedBox(width: 8),
          filterChip('Fast Delivery'),
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
    return BottomAppBar(
      elevation: 10,
      color: Colors.white,
      height: 68,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _NavItem(icon: Icons.home_rounded, selected: true, onTap: onHomeTap),
          _NavItem(icon: Icons.explore_outlined, onTap: onDiscoverTap),
          _NavItem(icon: Icons.favorite_border_rounded, onTap: onWishlistTap),
          _NavItem(icon: Icons.chat_bubble_outline, onTap: onChatTap),
          _NavItem(icon: Icons.person_outline_rounded, onTap: onProfileTap),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: selected ? const Color(0xFF6A53D9) : const Color(0xFF8C8C96),
      ),
      tooltip: 'Navigation item',
    );
  }
}
