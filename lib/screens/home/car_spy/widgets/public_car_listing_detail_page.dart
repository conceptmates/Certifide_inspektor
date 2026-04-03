import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/public_cars_models.dart';
import '../car_spy_data.dart';

/// Full detail view for a [PublicCarListing] (new or used inventory).
///
/// Optional [appBarTitle] overrides the app bar label; body still shows [listing.title].
class PublicCarListingDetailPage extends StatefulWidget {
  const PublicCarListingDetailPage({
    super.key,
    required this.listing,
    this.appBarTitle,
  });

  final PublicCarListing listing;

  /// Defaults to [listing.title] when null.
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

  String _fmtMoney(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final v = double.tryParse(raw);
    if (v == null) return raw;
    return _inr.format(v);
  }

  String _str(Object? v) {
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final barTitle = widget.appBarTitle ?? l.title;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CarSpyColors.onSurface,
        elevation: 0,
        title: Text(
          barTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGallery(l),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    _fmtMoney(l.price),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: CarSpyColors.primary,
                    ),
                  ),
                  if (l.description != null && l.description!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        l.description!,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: CarSpyColors.onSurface,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _sectionTitle('Listing'),
                  _kv('Year', _str(l.year)),
                  _kv('Mileage (km)', _str(l.mileageKm)),
                  _kv('Registration number', _str(l.registrationNumber)),
                  // _kv('Chassis number', _str(l.chassisNumber)),
                  const SizedBox(height: 20),
                  _sectionTitle('Seller'),
                  // _kv('Dealer ID', _str(l.user?.id)),
                  _kv('Dealer name', _str(l.user?.name)),
                  const SizedBox(height: 20),
                  _sectionTitle('Pricing & costs'),
                  _kv('Ex-showroom / list price', _fmtMoney(l.price)),
                  _kv('On-road price', _fmtMoney(l.onRoadPrice)),
                  _kv('Maintenance cost', _str(l.maintenanceCost)),
                  _kv('Insurance cost', _fmtMoney(l.insuranceCost)),
                  _kv('Resale value', _fmtMoney(l.resaleValue)),
                  _kv('Warranty', _str(l.warranty)),
                  const SizedBox(height: 20),
                  _sectionTitle('Specifications'),
                  _kv('Transmission', _str(l.transmission)),
                  _kv('Fuel type', _str(l.fuelType)),
                  _kv('Engine (cc)', _str(l.engineCapacityCc)),
                  _kv('Mileage / efficiency', _str(l.mileageFuelEfficiency)),
                  _kv('Drivetrain', _str(l.drivetrain)),
                  _kv('Body type', _str(l.bodyType)),
                  _kv('Seating capacity', _str(l.seatingCapacity)),
                  _kv('Boot space', _str(l.bootSpace)),
                  _kv('Ground clearance', _str(l.groundClearance)),
                  const SizedBox(height: 20),
                  _sectionTitle('Safety & features'),
                  _kv('Safety (NCAP)', _str(l.safetyRatingNcap)),
                  _kv('Airbags', _str(l.airbagsCount)),
                  _kv('ABS / ESC', _str(l.absEsc)),
                  _kv('Infotainment', _str(l.infotainmentFeatures)),
                ],
              ),
            ),
          ],
        ),
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
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.directions_car_filled_outlined,
            size: 64,
            color: Colors.grey.shade400,
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
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openEnlargedPhotos(l, i),
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: Colors.grey.shade300,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return ColoredBox(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.zoom_in_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_photoIndex + 1} / ${l.photos.length}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                l.photos.length,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _photoIndex ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _photoIndex
                          ? CarSpyColors.primary
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: CarSpyColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CarSpyColors.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen zoomable gallery (pinch / pan via [InteractiveViewer]).
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
                  minScale: 0.5,
                  maxScale: 5,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: Colors.grey.shade600,
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator.adaptive(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (photos.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Text(
                  '${_index + 1} / ${photos.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
