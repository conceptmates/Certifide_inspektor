import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/public_cars_models.dart';
import '../car_spy_data.dart';

class PublicCarListingCard extends StatefulWidget {
  const PublicCarListingCard({
    super.key,
    required this.listing,
    required this.priceLabel,
    required this.onTap,
    this.onFavoriteToggle,
    this.onShare,
    this.isFavorite = false,
  });

  final PublicCarListing listing;
  final String priceLabel;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onShare;
  final bool isFavorite;

  @override
  State<PublicCarListingCard> createState() => _PublicCarListingCardState();
}

class _PublicCarListingCardState extends State<PublicCarListingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScaleAnimation;
  bool _isPressed = false;
  bool _showQuickActions = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _heartController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _onFavoriteTap() {
    HapticFeedback.mediumImpact();
    _heartController.forward().then((_) => _heartController.reverse());
    widget.onFavoriteToggle?.call();
  }

  void _onShareTap() {
    HapticFeedback.lightImpact();
    widget.onShare?.call();
  }

  void _toggleQuickActions() {
    setState(() {
      _showQuickActions = !_showQuickActions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.listing.primaryImageUrl;

    return GestureDetector(
      onLongPress: _toggleQuickActions,
      onTapUp: (_) {
        if (_showQuickActions) {
          setState(() => _showQuickActions = false);
        } else {
          widget.onTap();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: CarSpyColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isPressed
                ? CarSpyColors.primary.withValues(alpha: 0.5)
                : CarSpyColors.outlineVariant.withValues(alpha: 0.6),
            width: _isPressed ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? CarSpyColors.primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: _isPressed ? 16 : 12,
              offset: Offset(0, _isPressed ? 6 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            splashColor: CarSpyColors.primary.withValues(alpha: 0.08),
            highlightColor: CarSpyColors.primary.withValues(alpha: 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HERO IMAGE ---
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _listingImagePlaceholder(),
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : _listingImagePlaceholder(),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 10,
                      right: 10,
                      child: AnimatedBuilder(
                        animation: _heartScaleAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _heartScaleAnimation.value,
                          child: child,
                        ),
                        child: GestureDetector(
                          onTap: _onFavoriteTap,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: widget.isFavorite
                                  ? Colors.red
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Quick action buttons (shown on long press)
                    if (_showQuickActions)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Row(
                          children: [
                            _QuickActionButton(
                              icon: Icons.share_outlined,
                              onTap: _onShareTap,
                              color: CarSpyColors.primary,
                            ),
                            const SizedBox(width: 8),
                            _QuickActionButton(
                              icon: Icons.open_in_full_rounded,
                              onTap: widget.onTap,
                              color: CarSpyColors.onSurface,
                            ),
                          ],
                        ),
                      ),
                    // Listing type badge
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.listing.type == 'new'
                              ? CarSpyColors.primary.withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.listing.type == 'new'
                                  ? Icons.new_releases_outlined
                                  : Icons.verified_outlined,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.listing.type == 'new' ? 'New' : 'Used',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // --- CONTENT SECTION ---
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CarSpyColors.onSurface,
                          height: 1.2,
                        ),
                      ),

                      // Subtitle
                      if (widget.listing.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.listing.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CarSpyColors.onSurfaceVariant,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Specs (Badges)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (widget.listing.year != null)
                            _buildSpecBadge(
                              Icons.calendar_today_outlined,
                              '${widget.listing.year}',
                            ),
                          if (widget.listing.transmission != null)
                            _buildSpecBadge(
                              Icons.settings_suggest_outlined,
                              widget.listing.transmission!,
                            ),
                          if (widget.listing.fuelType != null)
                            _buildSpecBadge(
                              Icons.local_gas_station_outlined,
                              widget.listing.fuelType!,
                            ),
                          if (widget.listing.mileageKm != null)
                            _buildSpecBadge(
                              Icons.speed_outlined,
                              '${widget.listing.mileageKm} km',
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      Divider(color: Colors.grey.shade200, height: 1),
                      const SizedBox(height: 14),

                      // Price & Call to Action
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.priceLabel,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: CarSpyColors.primary,
                                  ),
                                ),
                                if (widget.listing.onRoadPrice != null)
                                  Text(
                                    'On-road price',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isPressed
                                  ? CarSpyColors.primary
                                  : CarSpyColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: _isPressed
                                  ? Colors.white
                                  : CarSpyColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listingImagePlaceholder() {
    return ColoredBox(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.directions_car_filled_outlined,
          size: 48,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
