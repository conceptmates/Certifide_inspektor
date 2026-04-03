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
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            );
                          },
                        )
                      : _listingImagePlaceholder(),
                ),
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
        ),
      ),
    );
  }

  Widget _listingImagePlaceholder() {
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
