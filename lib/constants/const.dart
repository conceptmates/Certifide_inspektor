import 'package:flutter/material.dart';
import '../models/drop_down.dart';

String logo = 'assets/images/certifide.svg';
String carSpyHeritageVault = 'assets/images/carspy_heritage_vault.png';
String carSpyHeroSection = 'assets/images/carspyHero.png';
const Color yellow = Color(0xffffe5a0);
const Color red = Color(0xffffc8aa);

class InspectionColors {
  static const Color excellent = Colors.green;
  static const Color good = Colors.lightGreen;
  static const Color normal = Color(0xffe5b499);
  static const Color bad = Colors.orange;
  static const Color veryPoor = Colors.red;
}

class InspectionBool {
  static const Color yes = Colors.green;
  static const Color no = Colors.red;
}

class InspectionSign {
  static const Color noSign = Colors.green;
  static const Color visible = Colors.red;
  static const Color suspected = Color(0xffffe5a0);
}

class InspectionTire {
  static const Color good = Colors.green;
  static const Color ok = Colors.lightGreen;
  static const Color average = Colors.yellow;
  static const Color poor = Color(0xffe5b499);
  static const Color bad = Colors.red;
}

class InspectionVerification {
  static const Color verified = Colors.green;
  static const Color notVerified = Colors.red;
}

class InspectionDone {
  static const Color done = Colors.green;
  static const Color notDone = Colors.red;
}

class InspectionGD {
  static const Color good = Colors.green;
  static const Color ok = Color(0xffe5b499);
  static const Color bad = Colors.red;
}

class InspectionComfort {
  static const Color smooth = Colors.green;
  static const Color ok = Color(0xffe5b499);
  static const Color tight = Colors.red;
}

class InspectionStatus {
  static const Color normal = Colors.green;
  static const Color ok = Colors.lightGreen;
  static const Color abnormal = Colors.red;
}

class InspectionBody {
  static const Color ok = Colors.green;
  static const Color repainted = Colors.red;
  static const Color dent = Colors.red;
  static const Color crack = Colors.red;
  static const Color scratch = Color(0xffe5b499);
  static const Color corrosion = Colors.red;
  static const Color paintDefect = Colors.red;
  static const Color replaced = Colors.red;
}

class InspectionSigns {
  static const Color noSign = Colors.green;
  static const Color suspectedSigns = Color(0xffe5b499);
  static const Color visibleSigns = Colors.red;
}

class InspectionTaskStats {
  static const Color done = Colors.green;
  static const Color notDone = Colors.red;
}

class InspectionInsuranceTypes {
  static const Color fullCover = Colors.green;
  static const Color comprehensive = Colors.lightGreen;
  static const Color noInsurance = yellow;
}

class InspectionInsurance {
  static const Color originalAvailable = Colors.green;
  static const Color copyAvailable = Color(0xffe5b499);
  static const Color unavailable = Colors.red;
}

class CommonDropdownOptions {
  static const List<DropdownOption<String>> ifChecked = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'available',
      label: 'Available',
      color: InspectionBool.no,
      icon: Icons.check_circle,
    ),
    DropdownOption(
      value: 'notavailable',
      label: 'Not Available',
      color: InspectionBool.yes,
      icon: Icons.cancel,
    ),
    DropdownOption(
      value: 'notchecked',
      label: 'Not Checked',
      color: yellow,
      icon: Icons.schedule,
    ),
  ];

  static const List<DropdownOption<String>> insuranceTypes = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'fullcover',
      label: 'Full Cover',
      color: InspectionInsuranceTypes.fullCover,
      icon: Icons.security,
    ),
    DropdownOption(
      value: 'comprehensive',
      label: 'Comprehensive',
      color: InspectionInsuranceTypes.comprehensive,
      icon: Icons.verified_user,
    ),
    DropdownOption(
      value: 'thirdparty',
      label: 'Third Party',
      color: yellow,
      icon: Icons.shield,
    ),
  ];
  static const List<DropdownOption<String>> insurance = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'originalAvailable',
      label: 'Original Available',
      color: InspectionInsuranceTypes.fullCover,
      icon: Icons.verified,
    ),
    DropdownOption(
      value: 'copyavailable',
      label: 'Copy Available',
      color: yellow,
      icon: Icons.content_copy,
    ),
    DropdownOption(
      value: 'unavailable',
      label: 'Unavailable',
      color: Colors.red,
      icon: Icons.dangerous,
    ),
  ];

  static const List<DropdownOption<String>> available = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'available',
      label: 'Available',
      color: InspectionBool.yes,
      icon: Icons.check_circle,
    ),
    DropdownOption(
      value: 'notavailable',
      label: 'Not Available',
      color: InspectionBool.no,
      icon: Icons.cancel,
    ),
  ];
  static const List<DropdownOption<String>> vehicleCheck = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'available',
      label: 'Available',
      color: InspectionBool.yes,
      icon: Icons.check_circle,
    ),
    DropdownOption(
      value: 'notavailable',
      label: 'Not Available',
      color: yellow,
      icon: Icons.warning,
    ),
  ];
  static const List<DropdownOption<String>> availableNotBad = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'allavailable',
      label: 'All Available',
      color: InspectionBool.yes,
      icon: Icons.done_all,
    ),
    DropdownOption(
      value: 'badcondition',
      label: 'Bad Condition',
      color: red,
      icon: Icons.report_problem,
    ),
    DropdownOption(
      value: 'notavailable',
      label: 'Not Available',
      color: InspectionBool.no,
      icon: Icons.cancel,
    ),
  ];
  static const List<DropdownOption<String>> verifiedOrNot = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'Verified',
      label: 'Verified',
      color: InspectionVerification.verified,
      icon: Icons.verified,
    ),
    DropdownOption(
      value: 'NotVerified',
      label: 'Not Verified',
      color: InspectionVerification.notVerified,
      icon: Icons.error,
    ),
  ];

  static const List<DropdownOption<String>> floodAffected = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'VisibleSigns',
      label: 'Visible Signs',
      color: InspectionSigns.visibleSigns,
      icon: Icons.water_damage,
    ),
    DropdownOption(
      value: 'SuspectedSigns',
      label: 'Suspected Signs',
      color: InspectionSigns.suspectedSigns,
      icon: Icons.warning_amber,
    ),
    DropdownOption(
      value: 'NoSigns',
      label: 'No Signs',
      color: InspectionSigns.noSign,
      icon: Icons.check_circle,
    ),
  ];

  static const List<DropdownOption<String>> tireThickness = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: '9mm+/Good',
      label: '9mm+/Good',
      color: InspectionTire.good,
      icon: Icons.tire_repair,
    ),
    DropdownOption(
      value: '8mm+/75%',
      label: '8mm+/75%',
      color: InspectionTire.ok,
      icon: Icons.circle,
    ),
    DropdownOption(
      value: '6mm+/50%',
      label: '6mm+/50%',
      color: InspectionTire.average,
      icon: Icons.adjust,
    ),
    DropdownOption(
      value: '4mm+/25%',
      label: '4mm+/25%',
      color: InspectionTire.poor,
      icon: Icons.warning,
    ),
    DropdownOption(
      value: '3mm-/Bad',
      label: '3mm-/Bad',
      color: InspectionTire.bad,
      icon: Icons.dangerous,
    ),
    DropdownOption(
      value: 'ExternalDamage',
      label: 'External Damage',
      color: InspectionTire.bad,
      icon: Icons.report_problem,
    ),
  ];
  static const List<DropdownOption<String>> doneNotDone = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'Done',
      label: 'Done',
      color: InspectionDone.notDone,
      icon: Icons.done,
    ),
    DropdownOption(
      value: 'NotDone',
      label: 'Not Done',
      color: InspectionDone.done,
      icon: Icons.close,
    ),
  ];
  static const List<DropdownOption<String>> doneNotDoneInverted = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'Done',
      label: 'Done',
      color: InspectionDone.done,
      icon: Icons.done,
    ),
    DropdownOption(
      value: 'NotDone',
      label: 'Not Done',
      color: InspectionDone.notDone,
      icon: Icons.close,
    ),
  ];
  static const List<DropdownOption<String>> doneNotDoneInverted2 = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'Done',
      label: 'Done',
      color: yellow,
      icon: Icons.done,
    ),
    DropdownOption(
      value: 'NotDone',
      label: 'Not Done',
      color: Colors.green,
      icon: Icons.close,
    ),
  ];

  static const List<DropdownOption<String>> bodyConditions = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'OK',
      label: 'OK',
      color: Colors.green,
      icon: Icons.check_circle,
    ),
    DropdownOption(
      value: 'Dent',
      label: 'Dent',
      color: InspectionBody.dent,
      icon: Icons.push_pin,
    ),
    DropdownOption(
      value: 'Crack',
      label: 'Crack',
      color: InspectionBody.crack,
      icon: Icons.broken_image,
    ),
    DropdownOption(
      value: 'Scratch',
      label: 'Scratch',
      color: InspectionBody.scratch,
      icon: Icons.gesture,
    ),
    DropdownOption(
      value: 'Corrosion',
      label: 'Corrosion',
      color: InspectionBody.corrosion,
      icon: Icons.scatter_plot,
    ),
    DropdownOption(
      value: 'PaintDefect',
      label: 'Paint Defect',
      color: InspectionBody.paintDefect,
      icon: Icons.palette,
    ),
    DropdownOption(
      value: 'Replaced',
      label: 'Replaced',
      color: InspectionBody.replaced,
      icon: Icons.swap_horiz,
    ),
    DropdownOption(
      value: 'Repainted',
      label: 'Repainted',
      color: InspectionBody.repainted,
      icon: Icons.brush,
    ),
  ];
  static const List<DropdownOption<String>> okNotOk = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'OK',
      label: 'OK',
      color: InspectionStatus.ok,
      icon: Icons.check,
    ),
    DropdownOption(
      value: 'replaced',
      label: 'Replaced',
      color: Colors.yellow,
      icon: Icons.swap_horiz,
    ),
    DropdownOption(
      value: 'NotOK',
      label: 'Not OK',
      color: InspectionStatus.abnormal,
      icon: Icons.close,
    ),
  ];
  static const List<DropdownOption<String>> yesNo = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'Yes',
      label: 'Yes',
      color: Colors.red,
      icon: Icons.check,
    ),
    DropdownOption(
      value: 'No',
      label: 'No',
      color: Colors.green,
      icon: Icons.close,
    ),
  ];

  static const List<DropdownOption<String>> normOrAbnorm = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'Normal',
      label: 'Normal',
      color: InspectionStatus.normal,
    ),
    DropdownOption(
      value: 'OK',
      label: 'OK',
      color: InspectionStatus.ok,
    ),
    DropdownOption(
      value: 'Abnormal',
      label: 'Abnormal',
      color: InspectionStatus.abnormal,
    ),
  ];
  static const List<DropdownOption<String>> smoothOkBad = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'Smooth',
      label: 'Smooth',
      color: InspectionComfort.smooth,
      icon: Icons.thumb_up,
    ),
    DropdownOption(
      value: 'OK',
      label: 'OK',
      color: InspectionComfort.ok,
      icon: Icons.thumbs_up_down,
    ),
    DropdownOption(
      value: 'Tight',
      label: 'Tight',
      color: InspectionComfort.tight,
      icon: Icons.thumb_down,
    ),
  ];

  static const List<DropdownOption<String>> conditions = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'Good',
      label: 'Good',
      color: InspectionGD.good,
      icon: Icons.thumb_up,
    ),
    DropdownOption(
      value: 'Ok',
      label: 'OK',
      color: InspectionGD.ok,
      icon: Icons.thumbs_up_down,
    ),
    DropdownOption(
      value: 'Bad',
      label: 'Bad',
      color: InspectionGD.bad,
      icon: Icons.thumb_down,
    ),
  ];

  static const List<DropdownOption<String>> notNeeded = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'available',
      label: 'Available',
      color: InspectionDone.done,
    ),
    DropdownOption(
      value: 'Not Available',
      label: 'Not Available',
      color: InspectionDone.notDone,
    ),
    DropdownOption(
      value: 'NotNeeded',
      label: 'Not Needed',
      color: InspectionDone.done,
    ),
  ];

  //availability

  static const List<DropdownOption<String>> availability = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'AvailableWorking',
      label: 'Available Working',
      color: InspectionColors.excellent,
    ),
    DropdownOption(
      value: 'AvailableNotWorking',
      label: 'Available Not Working',
      color: InspectionColors.normal,
    ),
    DropdownOption(
      value: 'NotAvailable',
      label: 'Not Available',
      color: InspectionColors.veryPoor,
    ),
  ];

  static const List<DropdownOption<String>> fuelType = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'Petrol',
      label: 'Petrol',
      color: InspectionColors.normal,
      icon: Icons.local_gas_station,
    ),
    DropdownOption(
      value: 'Diesel',
      label: 'Diesel',
      color: InspectionColors.normal,
      icon: Icons.oil_barrel,
    ),
    DropdownOption(
      value: 'EV',
      label: 'EV',
      color: InspectionColors.excellent,
      icon: Icons.electric_car,
    ),
    DropdownOption(
      value: 'Hybrid',
      label: 'Hybrid',
      color: InspectionColors.good,
      icon: Icons.power,
    ),
    DropdownOption(
      value: 'BiFuel',
      label: 'BiFuel',
      color: InspectionColors.good,
      icon: Icons.commute,
    ),
    DropdownOption(
      value: 'Others',
      label: 'Others',
      color: InspectionColors.normal,
      icon: Icons.more_horiz,
    ),
  ];

  static const List<DropdownOption<String>> transmissionType = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'Manual',
      label: 'Manual',
      color: InspectionColors.excellent,
      icon: Icons.precision_manufacturing,
    ),
    DropdownOption(
      value: 'Automatic',
      label: 'Automatic',
      color: InspectionColors.good,
      icon: Icons.settings,
    ),
    DropdownOption(
      value: 'AMT',
      label: 'AMT',
      color: InspectionColors.good,
      icon: Icons.tune,
    ),
    DropdownOption(
      value: 'Others',
      label: 'others',
      color: InspectionColors.bad,
      icon: Icons.more_horiz,
    ),
  ];

  static const List<DropdownOption<String>> basicConditions = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'Excellent',
      label: 'Excellent',
      color: InspectionColors.excellent,
      icon: Icons.star,
    ),
    DropdownOption(
      value: 'Good',
      label: 'Good',
      color: InspectionColors.good,
      icon: Icons.thumb_up,
    ),
    DropdownOption(
      value: 'Normal',
      label: 'Normal',
      color: InspectionColors.normal,
      icon: Icons.thumbs_up_down,
    ),
    DropdownOption(
      value: 'Bad',
      label: 'Bad',
      color: InspectionColors.bad,
      icon: Icons.thumb_down,
    ),
    DropdownOption(
      value: 'veryBad',
      label: 'Very bad',
      color: InspectionColors.veryPoor,
      icon: Icons.warning,
    ),
  ];

  static const List<DropdownOption<String>> secondaryCondition = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'Excellent',
      label: 'Excellent',
      color: InspectionColors.excellent,
    ),
    DropdownOption(
      value: 'Good',
      label: 'Good',
      color: InspectionColors.good,
    ),
    DropdownOption(
      value: 'NeedsService',
      label: 'Needs Service',
      color: InspectionColors.veryPoor,
    ),
  ];

  static const List<DropdownOption<String>> smoke = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
      icon: Icons.help_outline,
    ),
    DropdownOption(
      value: 'NotVisible',
      label: 'Not Visible',
      color: InspectionColors.excellent,
      icon: Icons.check_circle,
    ),
    DropdownOption(
      value: 'White',
      label: 'White',
      color: InspectionColors.veryPoor,
      icon: Icons.cloud,
    ),
    DropdownOption(
      value: 'Blue',
      label: 'Blue',
      color: InspectionColors.veryPoor,
      icon: Icons.cloud_queue,
    ),
    DropdownOption(
      value: 'Black',
      label: 'Black',
      color: InspectionColors.veryPoor,
      icon: Icons.cloud_off,
    ),
  ];
}
