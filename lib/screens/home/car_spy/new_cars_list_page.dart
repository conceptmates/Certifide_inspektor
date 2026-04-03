import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/public_cars_models.dart';
import '../../../services/api_services.dart';
import 'car_spy_data.dart';

class NewCarsListPage extends StatefulWidget {
  const NewCarsListPage({super.key});

  @override
  State<NewCarsListPage> createState() => _NewCarsListPageState();
}

class _NewCarsListPageState extends State<NewCarsListPage> {
  final List<PublicCarListing> _cars = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  final ScrollController _scrollController = ScrollController();

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _loading || _page >= _lastPage) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 280) {
      _loadMore();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _cars.clear();
      });
    }

    final result = await ApiService.getNewCars(
      page: _page,
      perPage: 15,
      sort: 'newest',
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final list = result['cars'] as List<PublicCarListing>;
      final meta = result['meta'];
      setState(() {
        _cars.addAll(list);
        _lastPage = meta.lastPage;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } else {
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = result['message']?.toString() ?? 'Failed to load listings';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_page >= _lastPage || _loadingMore) return;
    setState(() => _loadingMore = true);
    _page += 1;
    final result = await ApiService.getNewCars(
      page: _page,
      perPage: 15,
      sort: 'newest',
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final list = result['cars'] as List<PublicCarListing>;
      final meta = result['meta'];
      setState(() {
        _cars.addAll(list);
        _lastPage = meta.lastPage;
        _loadingMore = false;
      });
    } else {
      _page -= 1;
      setState(() => _loadingMore = false);
    }
  }

  String _formatPrice(String raw) {
    final v = double.tryParse(raw);
    if (v == null) return raw;
    return _inr.format(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CarSpyColors.onSurface,
        elevation: 0,
        title: const Text(
          'New cars',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: CarSpyColors.primary,
        onRefresh: () => _load(reset: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _cars.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null && _cars.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => _load(reset: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: CarSpyColors.primary,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: _cars.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _cars.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        final car = _cars[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _NewCarCard(
            listing: car,
            priceLabel: _formatPrice(car.price),
          ),
        );
      },
    );
  }
}

class _NewCarCard extends StatelessWidget {
  const _NewCarCard({
    required this.listing,
    required this.priceLabel,
  });

  final PublicCarListing listing;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.primaryImageUrl;
    return Container(
      decoration: BoxDecoration(
        color: CarSpyColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CarSpyColors.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    },
                  )
                : _placeholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CarSpyColors.onSurface,
                  ),
                ),
                if (listing.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    listing.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CarSpyColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: CarSpyColors.primary,
                      ),
                    ),
                    if (listing.year != null) ...[
                      const Spacer(),
                      Text(
                        '${listing.year}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (listing.transmission != null ||
                    listing.fuelType != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (listing.transmission != null)
                        listing.transmission,
                      if (listing.fuelType != null) listing.fuelType,
                    ].whereType<String>().join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.directions_car_filled_outlined,
          size: 48,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
