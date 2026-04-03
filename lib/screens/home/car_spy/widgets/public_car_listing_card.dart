import 'package:flutter/material.dart';

import '../../../../models/public_cars_models.dart';
import '../car_spy_data.dart';

/// List row card for a dealer listing (new or used). Supply a formatted [priceLabel]
/// from the parent (e.g. `NumberFormat.currency`) so callers control locale/symbol.
class PublicCarListingCard extends StatelessWidget {
  const PublicCarListingCard({
    super.key,
    required this.listing,
    required this.priceLabel,
    required this.onTap,
  });

  final PublicCarListing listing;
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.primaryImageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: CarSpyColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CarSpyColors.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HERO IMAGE ---
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

              // --- CONTENT SECTION (Compact) ---
              Padding(
                // Reduced overall padding from 16 to 12
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15, // Reduced from 17
                        fontWeight: FontWeight.w700,
                        color: CarSpyColors.onSurface,
                        height: 1.2,
                      ),
                    ),

                    // Subtitle
                    if (listing.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4), // Reduced from 6
                      Text(
                        listing.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12, // Reduced from 13
                          color: CarSpyColors.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10), // Reduced from 14

                    // Specs (Badges)
                    Wrap(
                      spacing: 6, // Reduced from 8
                      runSpacing: 6, // Reduced from 8
                      children: [
                        if (listing.year != null)
                          _buildSpecBadge(
                            Icons.calendar_today_outlined,
                            '${listing.year}',
                          ),
                        if (listing.transmission != null)
                          _buildSpecBadge(
                            Icons.settings_suggest_outlined,
                            listing.transmission!,
                          ),
                        if (listing.fuelType != null)
                          _buildSpecBadge(
                            Icons.local_gas_station_outlined,
                            listing.fuelType!,
                          ),
                      ],
                    ),

                    const SizedBox(height: 12), // Reduced from 16
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 12), // Reduced from 16

                    // Price & Call to Action
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            priceLabel,
                            style: const TextStyle(
                              fontSize: 17, // Reduced from 19
                              fontWeight: FontWeight.w800,
                              color: CarSpyColors.primary,
                            ),
                          ),
                        ),
                        // Call to Action Arrow
                        Container(
                          padding: const EdgeInsets.all(5), // Slightly smaller
                          decoration: BoxDecoration(
                            color: CarSpyColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12, // Reduced from 14
                            color: CarSpyColors.primary,
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
    );
  }

  // Helper method to build consistent spec tags (Compact)
  Widget _buildSpecBadge(IconData icon, String label) {
    return Container(
      // Reduced padding inside the badge
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey.shade600), // Smaller icon
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11, // Reduced from 12
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
