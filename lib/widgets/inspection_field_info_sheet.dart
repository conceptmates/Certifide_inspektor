import 'package:flutter/material.dart';

import '../constants/inspection_field_explanations.dart';
import 'inspection_field_info/components/field_info_content_card.dart';
import 'inspection_field_info/components/field_info_sheet_header.dart';
import 'inspection_field_info/components/reference_media_section.dart';
export 'inspection_field_info/components/reference_media_section.dart';

class InspectionFieldInfoSheet {
  static void show({
    required BuildContext context,
    required String fieldId,
    String? customTitle,
    String? customExplanation,
    List<Map<String, dynamic>> referenceMedia = const [],
  }) {
    final explanation = InspectionFieldExplanations.getExplanation(fieldId);
    final title = customTitle ?? explanation?['title'] ?? fieldId;
    final explanationText = customExplanation ??
        explanation?['explanation'] ??
        'No explanation available for this field.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FieldInfoSheetHeader(
                title: title,
                onClose: () => Navigator.of(context).pop(),
              ),
              Divider(
                color: Theme.of(context).dividerColor.withAlpha(128),
                thickness: 1,
                height: 1,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (referenceMedia.isNotEmpty) ...[
                        ReferenceMediaSectionView(mediaList: referenceMedia),
                        const SizedBox(height: 24),
                      ],
                      FieldInfoContentCard(
                        icon: Icons.search_outlined,
                        title: 'What to inspect',
                        text: explanationText,
                        accentColor: const Color(0xFF667eea),
                      ),
                      const SizedBox(height: 24),
                      FieldInfoContentCard(
                        icon: Icons.location_on_outlined,
                        title: 'Where to find this',
                        text: _getLocationGuide(fieldId),
                        accentColor: Colors.orange,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _getLocationGuide(String fieldId) {
    switch (fieldId.toLowerCase()) {
      case 'location':
        return 'Record the complete address where the inspection is taking place - building name/number, street, area, city, and pincode.';
      case 'frontview':
        return 'Stand 3-4 feet in front of the vehicle, center yourself with the front grille, and capture the entire front including bumper to hood.';
      case 'rearview':
        return 'Position yourself 3-4 feet behind the vehicle, center with the rear license plate, and capture from bumper to roof line.';
      case 'leftview':
        return 'Stand on the driver\'s side, about 6-8 feet away, and capture the full profile from front wheel to rear wheel.';
      case 'rightview':
        return 'Stand on the passenger side, about 6-8 feet away, and capture the complete side profile of the vehicle.';
      case 'rc':
        return 'Physical document - usually kept in the vehicle\'s document holder or with the owner. Check the front and back pages.';
      case 'regno':
        return 'Front and rear number plates of the vehicle. Also printed on the RC document and insurance papers.';
      case 'odoreading':
        return 'Digital display on the instrument cluster behind the steering wheel. Turn on ignition to see the reading.';
      case 'hood/bonnet':
        return 'The front panel that opens upward to access the engine. Check from outside and also open to inspect hinges.';
      case 'roof':
        return 'Top panel of the vehicle. Best viewed from slightly elevated position or by walking around the vehicle.';
      case 'rhsfender':
        return 'Body panel between the front wheel and door on the right side (passenger side) of the vehicle.';
      case 'lhsfender':
        return 'Body panel between the front wheel and door on the left side (driver\'s side) of the vehicle.';
      case 'rhsfrontdoor':
        return 'Right side (passenger) front door. Check both exterior panel and interior door frame.';
      case 'lhsfrontdoor':
        return 'Left side (driver) front door. Inspect exterior panel, edges, and door frame alignment.';
      case 'rhsreardoor':
        return 'Right side (passenger) rear door. Available only on 4-door vehicles and SUVs.';
      case 'lhsreardoor':
        return 'Left side (driver) rear door. Check for dents, scratches, and proper closing alignment.';
      case 'tailgate/dicky':
        return 'Rear opening panel - trunk lid on sedans, tailgate on hatchbacks/SUVs. Check opening mechanism and seals.';
      case 'batteryslnumber':
        return 'Open the hood/bonnet. Battery is usually a rectangular black box with terminals on top, typically on one side of engine bay.';
      case 'batterycondition':
        return 'Same location as battery - check the plastic casing, terminals (metal connectors), and mounting bracket.';
      case 'alternator':
        return 'Engine bay - circular component with pulley, usually on the right side of engine, connected to drive belt.';
      case 'starter':
        return 'Engine bay - cylindrical component mounted on the engine block, typically near the transmission bellhousing.';
      case 'airfilter':
        return 'Engine bay - inside a rectangular or round plastic housing, usually on top or side of engine.';
      case 'fuseboxes':
        return 'Engine bay - rectangular black boxes with removable covers, usually near the battery or on firewall.';
      case 'chassisno':
        return 'Vehicle identification number stamped on chassis - typically on firewall in engine bay or under driver seat area.';
      case 'engine number':
        return 'Stamped on engine block - usually on the side or front of engine, may require torch light to see clearly.';
      case 'frontrhbrake':
        return 'Right front wheel - visible through wheel spokes. Look at brake disc (shiny metal disc) and brake pads.';
      case 'frontlhbrake':
        return 'Left front wheel - brake components visible through wheel openings when wheel is turned or removed.';
      case 'rearrhbrake':
        return 'Right rear wheel - brake disc or drum visible through wheel spokes. May be disc or drum type.';
      case 'rearlhbrake':
        return 'Left rear wheel - inspect brake components through wheel openings or when wheel is removed.';
      case 'frontrh':
        return 'Right front wheel tire - check tread depth on inner, center, and outer edges of tire surface.';
      case 'frontlh':
        return 'Left front wheel tire - inspect all areas of tire tread and sidewall for wear and damage.';
      case 'rearrh':
        return 'Right rear wheel tire - examine tread pattern and depth across entire tire width.';
      case 'rearlh':
        return 'Left rear wheel tire - check for even wear and adequate tread depth across tire surface.';
      case 'stepny':
        return 'Spare tire - usually located in boot/trunk area, under cargo floor, or mounted under vehicle rear.';
      case 'headlamps':
        return 'Front of vehicle - main lighting units on either side of grille. Test both high and low beam functions.';
      case 'brakelamps':
        return 'Rear of vehicle - red lights that illuminate when brake pedal is pressed. Usually 2-3 on each side.';
      case 'directionindicators':
        return 'Orange/amber lights on all four corners of vehicle - front, rear, and sometimes on side mirrors.';
      case 'foglamps':
        return 'Lower front bumper area - additional lights below headlamps, and sometimes rear fog lamps.';
      case 'dashboard':
        return 'Inside cabin - the panel in front of driver containing gauges, controls, and instrument cluster.';
      case 'seats':
        return 'Inside cabin - all passenger seating including front seats, rear bench/individual seats.';
      case 'doorpads':
        return 'Interior door panels - fabric/plastic panels on inside of all doors with window controls and handles.';
      case 'roofliner':
        return 'Interior ceiling - fabric covering on inside roof, check for sagging or water stains.';
      case 'frontglassno':
        return 'Front windshield - large glass panel in front of driver, check both inside and outside surfaces.';
      case 'rhsfrontdoorglassno':
        return 'Right front door window - roll window up and down to check entire glass surface.';
      case 'lhsfrontglassno':
        return 'Left front door window - driver side window, check for chips, cracks, or damage.';
      case ' tailgateglassno':
        return 'Rear windshield - back glass of vehicle, may have defogger lines and wiper.';
      case 'coolant':
        return 'Engine bay - coolant reservoir (translucent plastic tank) or radiator cap when engine is cold.';
      case 'brakefluidcondition':
        return 'Engine bay - brake fluid reservoir near firewall, usually has a transparent or semi-transparent container.';
      case 'engineoil':
        return 'Engine bay - check oil dipstick (yellow/orange handle) or oil filler cap on top of engine.';
      case 'horn':
        return 'Test by pressing horn button on steering wheel. Horn units located behind front grille or bumper.';
      case 'powerwindow':
        return 'Test all window switches inside cabin - each door should have up/down controls.';
      case 'infotainmentsystem':
        return 'Center dashboard - touchscreen or display unit between driver and passenger seats.';
      default:
        return 'Refer to the vehicle manual or ask the inspection supervisor for the exact location of this component.';
    }
  }
}

class InspectionInfoButton extends StatelessWidget {
  final String fieldId;
  final String? customTitle;
  final String? customExplanation;
  final List<Map<String, dynamic>> referenceMedia;
  final double size;
  final Color? color;

  const InspectionInfoButton({
    super.key,
    required this.fieldId,
    this.customTitle,
    this.customExplanation,
    this.referenceMedia = const [],
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4FC3F7),
            Color(0xFF29B6F6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF29B6F6).withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            InspectionFieldInfoSheet.show(
              context: context,
              fieldId: fieldId,
              customTitle: customTitle,
              customExplanation: customExplanation,
              referenceMedia: referenceMedia,
            );
          },
          child: const Center(
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
