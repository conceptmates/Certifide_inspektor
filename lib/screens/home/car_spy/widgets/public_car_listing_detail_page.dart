import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../models/public_cars_models.dart';
import '../car_spy_data.dart';

class PublicCarListingDetailPage extends StatefulWidget {
  const PublicCarListingDetailPage({
    super.key,
    required this.listing,
    this.appBarTitle,
  });

  final PublicCarListing listing;
  final String? appBarTitle;

  @override
  State<PublicCarListingDetailPage> createState() =>
      _PublicCarListingDetailPageState();
}

class _PublicCarListingDetailPageState
    extends State<PublicCarListingDetailPage> {
  late final PageController _photoController =
      PageController(viewportFraction: 0.88);
  int _photoIndex = 0;
  bool _isFavorite = false;
  bool _showSpecsExpanded = false;

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  String? _fmtMoney(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null) return raw;
    return _inr.format(v);
  }

  void _toggleFavorite() {
    HapticFeedback.mediumImpact();
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _shareListing() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing is not available'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _callDealer() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact information not available'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _whatsAppDealer() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WhatsApp contact not available'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final barTitle = widget.appBarTitle ?? l.title;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CarSpyColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Text(
          barTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _shareListing,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
          ),
          IconButton(
            onPressed: _toggleFavorite,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(_isFavorite),
                color: _isFavorite ? Colors.red : null,
              ),
            ),
            tooltip: 'Favorite',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGallery(l),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- TITLE & PRICE ---
                        Text(
                          l.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: CarSpyColors.onSurface,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _fmtMoney(l.price) ?? 'Price on request',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: CarSpyColors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- QUICK GLANCE SPECS ---
                        _AnimatedExpandableSpecs(
                          isExpanded: _showSpecsExpanded,
                          onToggle: () => setState(
                              () => _showSpecsExpanded = !_showSpecsExpanded),
                          year: l.year,
                          transmission: l.transmission,
                          fuelType: l.fuelType,
                          mileageKm: l.mileageKm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- DEALER CARD ---
            if (l.user != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _DealerCard(
                  dealer: l.user!,
                  onCall: _callDealer,
                  onWhatsApp: _whatsAppDealer,
                ),
              ),

            // --- DETAILED SECTIONS ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (l.description != null &&
                      l.description!.trim().isNotEmpty) ...[
                    _buildSectionCard(
                      'Overview',
                      [
                        Text(
                          l.description!.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: CarSpyColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildSectionCard(
                    'Listing Details',
                    [
                      _kv('Registration', l.registrationNumber),
                      _kv('Dealer Name', l.user?.name),
                      _kv('Warranty', l.warranty),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionCard(
                    'Pricing & Costs',
                    [
                      _kv('Ex-showroom', _fmtMoney(l.price)),
                      _kv('On-road price', _fmtMoney(l.onRoadPrice)),
                      _kv('Maintenance', l.maintenanceCost),
                      _kv('Insurance', _fmtMoney(l.insuranceCost)),
                      _kv('Resale value', _fmtMoney(l.resaleValue)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionCard(
                    'Technical Specifications',
                    [
                      _kv('Engine (cc)', l.engineCapacityCc),
                      _kv('Efficiency', l.mileageFuelEfficiency),
                      _kv('Drivetrain', l.drivetrain),
                      _kv('Body type', l.bodyType),
                      _kv('Seating', l.seatingCapacity),
                      _kv('Boot space', l.bootSpace),
                      _kv('Ground clearance', l.groundClearance),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionCard(
                    'Safety & Features',
                    [
                      _kv('Safety (NCAP)', l.safetyRatingNcap),
                      _kv('Airbags', l.airbagsCount),
                      _kv('ABS / ESC', l.absEsc),
                      _kv('Infotainment', l.infotainmentFeatures),
                    ],
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActionBar(
        priceLabel: _fmtMoney(l.price) ?? 'Price on request',
        onContact: _callDealer,
        onWhatsApp: _whatsAppDealer,
        onShare: _shareListing,
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget?> children) {
    final validChildren = children.whereType<Widget>().toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: CarSpyColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...validChildren,
        ],
      ),
    );
  }

  Widget? _kv(String label, Object? value) {
    final s = (value?.toString() ?? '').trim();
    if (s.isEmpty || s == 'null') return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: SelectableText(
              s,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CarSpyColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEnlargedPhotos(PublicCarListing l, int initialIndex) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenPhotoViewer(
            photos: l.photos,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildGallery(PublicCarListing l) {
    if (l.photos.isEmpty) {
      return Container(
        height: 240,
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(
            Icons.directions_car_filled_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _photoController,
            padEnds: true,
            itemCount: l.photos.length,
            onPageChanged: (i) => setState(() => _photoIndex = i),
            itemBuilder: (context, i) {
              final url = l.photos[i].url;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openEnlargedPhotos(l, i),
                    borderRadius: BorderRadius.circular(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return ColoredBox(
                                color: Colors.grey.shade100,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in_rounded,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tap to zoom',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Photo counter badge
                          if (l.photos.length > 1)
                            Positioned(
                              left: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.photo_library_outlined,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${i + 1}/${l.photos.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (l.photos.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              l.photos.length,
              (i) => GestureDetector(
                onTap: () => _photoController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: i == _photoIndex ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i == _photoIndex
                        ? CarSpyColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnimatedExpandableSpecs extends StatelessWidget {
  const _AnimatedExpandableSpecs({
    required this.isExpanded,
    required this.onToggle,
    this.year,
    this.transmission,
    this.fuelType,
    this.mileageKm,
  });

  final bool isExpanded;
  final VoidCallback onToggle;
  final int? year;
  final String? transmission;
  final String? fuelType;
  final int? mileageKm;

  @override
  Widget build(BuildContext context) {
    final allSpecs = <(IconData, String, String?)>[
      (Icons.calendar_today_outlined, 'Year', year?.toString()),
      (Icons.settings_suggest_outlined, 'Transmission', transmission),
      (Icons.local_gas_station_outlined, 'Fuel', fuelType),
      (Icons.speed_outlined, 'Mileage', mileageKm != null ? '$mileageKm km' : null),
    ];

    final visibleSpecs = isExpanded ? allSpecs : allSpecs.take(3).toList();
    final hasMore = allSpecs.length > 3;

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...visibleSpecs.where((s) => s.$3 != null).map(
                  (s) => _SpecChip(icon: s.$1, label: s.$3!),
                ),
            if (hasMore)
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: CarSpyColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CarSpyColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        size: 14,
                        color: CarSpyColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpanded ? 'Less' : '${allSpecs.length - 3} more',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CarSpyColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DealerCard extends StatelessWidget {
  const _DealerCard({
    required this.dealer,
    required this.onCall,
    required this.onWhatsApp,
  });

  final PublicCarListingUser dealer;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [CarSpyColors.primary, Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                dealer.name.isNotEmpty
                    ? dealer.name[0].toUpperCase()
                    : 'D',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dealer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CarSpyColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Certified Dealer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _ActionIconButton(
                icon: Icons.phone_outlined,
                color: const Color(0xFF10B981),
                onTap: onCall,
                tooltip: 'Call',
              ),
              const SizedBox(width: 10),
              _ActionIconButton(
                icon: Icons.chat_bubble_outline,
                color: const Color(0xFF25D366),
                onTap: onWhatsApp,
                tooltip: 'WhatsApp',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.priceLabel,
    required this.onContact,
    required this.onWhatsApp,
    required this.onShare,
  });

  final String priceLabel;
  final VoidCallback onContact;
  final VoidCallback onWhatsApp;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  priceLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: CarSpyColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: onShare,
                  icon: Icon(Icons.share_outlined,
                      color: Colors.grey.shade700, size: 22),
                  tooltip: 'Share',
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onContact,
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('Contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CarSpyColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: CarSpyColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FullScreenPhotoViewer extends StatefulWidget {
  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  final List<PublicCarPhoto> photos;
  final int initialIndex;

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = photos[i].url;
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: Colors.grey.shade800,
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white54),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            Positioned(
              top: 8,
              left: 8,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  if (photos.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_index + 1} / ${photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
