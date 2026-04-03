import 'package:flutter/material.dart';

import '../../../models/public_cars_models.dart';
import 'widgets/public_car_listing_detail_page.dart';

/// Thin alias for [PublicCarListingDetailPage] (new-inventory flows).
/// Prefer importing [PublicCarListingDetailPage] directly for used cars or shared UI.
class NewCarDetailPage extends StatelessWidget {
  const NewCarDetailPage({super.key, required this.listing});

  final PublicCarListing listing;

  @override
  Widget build(BuildContext context) {
    return PublicCarListingDetailPage(listing: listing);
  }
}
