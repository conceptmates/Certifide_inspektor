import 'package:flutter/material.dart';
import '../models/drop_down.dart';

String logo = 'assets/images/certifide.svg';
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
    ),
    DropdownOption(
      value: 'available',
      label: 'Available',
      color: InspectionBool.no,
    ),
    DropdownOption(
      value: 'notavailable',
      label: 'Not Available',
      color: InspectionBool.yes,
    ),
    DropdownOption(
      value: 'notchecked',
      label: 'Not Checked',
      color: yellow,
    ),
  ];

  static const List<DropdownOption<String>> insuranceTypes = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'fullcover',
      label: 'Full Cover',
      color: InspectionInsuranceTypes.fullCover,
    ),
    DropdownOption(
      value: 'comprehensive',
      label: 'Comprehensive',
      color: InspectionInsuranceTypes.comprehensive,
    ),
    DropdownOption(
      value: 'thirdparty',
      label: 'Third Party',
      color: yellow,
    ),
  ];
  static const List<DropdownOption<String>> insurance = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'originalAvailable',
      label: 'Original Available',
      color: InspectionInsuranceTypes.fullCover,
    ),
    DropdownOption(
      value: 'copyavailable',
      label: 'Copy Available',
      color: yellow,
    ),
    DropdownOption(
      value: 'unavailable',
      label: 'Unavailable',
      color: Colors.red,
    ),
  ];

  static const List<DropdownOption<String>> available = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'available',
      label: 'Available',
      color: InspectionBool.yes,
    ),
    DropdownOption(
      value: 'notavailable',
      label: 'Not Available',
      color: InspectionBool.no,
    ),
  ];
  static const List<DropdownOption<String>> vehicleCheck = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'available',
      label: 'Available',
      color: InspectionBool.yes,
    ),
    DropdownOption(
      value: 'notavailable',
      label: 'Not Available',
      color: yellow,
    ),
  ];
  static const List<DropdownOption<String>> availableNotBad = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'allavailable',
      label: 'All Available',
      color: InspectionBool.yes,
    ),
    DropdownOption(
      value: 'badcondition',
      label: 'Bad Condition',
      color: red,
    ),
    DropdownOption(
      value: 'notavailable',
      label: 'Not Available',
      color: InspectionBool.no,
    ),
  ];
  static const List<DropdownOption<String>> verifiedOrNot = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'Verified',
      label: 'Verified',
      color: InspectionVerification.verified,
    ),
    DropdownOption(
      value: 'NotVerified',
      label: 'Not Verified',
      color: InspectionVerification.notVerified,
    ),
  ];

  static const List<DropdownOption<String>> floodAffected = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'VisibleSigns',
      label: 'Visible Signs',
      color: InspectionSigns.visibleSigns,
    ),
    DropdownOption(
      value: 'SuspectedSigns',
      label: 'Suspected Signs',
      color: InspectionSigns.suspectedSigns,
    ),
    DropdownOption(
      value: 'NoSigns',
      label: 'No Signs',
      color: InspectionSigns.noSign,
    ),
  ];

  static const List<DropdownOption<String>> tireThickness = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: '9mm+/Good',
      label: '9mm+/Good',
      color: InspectionTire.good,
    ),
    DropdownOption(
      value: '8mm+/75%',
      label: '8mm+/75%',
      color: InspectionTire.ok,
    ),
    DropdownOption(
      value: '6mm+/50%',
      label: '6mm+/50%',
      color: InspectionTire.average,
    ),
    DropdownOption(
      value: '4mm+/25%',
      label: '4mm+/25%',
      color: InspectionTire.poor,
    ),
    DropdownOption(
      value: '3mm-/Bad',
      label: '3mm-/Bad',
      color: InspectionTire.bad,
    ),
    DropdownOption(
      value: 'ExternalDamage',
      label: 'External Damage',
      color: InspectionTire.bad,
    ),
  ];
  static const List<DropdownOption<String>> doneNotDone = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'Done',
      label: 'Done',
      color: InspectionDone.notDone,
    ),
    DropdownOption(
      value: 'NotDone',
      label: 'Not Done',
      color: InspectionDone.done,
    ),
  ];
  static const List<DropdownOption<String>> doneNotDoneInverted = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'Done',
      label: 'Done',
      color: InspectionDone.done,
    ),
    DropdownOption(
      value: 'NotDone',
      label: 'Not Done',
      color: InspectionDone.notDone,
    ),
  ];
  static const List<DropdownOption<String>> doneNotDoneInverted2 = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'Done',
      label: 'Done',
      color: yellow,
    ),
    DropdownOption(
      value: 'NotDone',
      label: 'Not Done',
      color: Colors.green,
    ),
  ];

  static const List<DropdownOption<String>> bodyConditions = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'OK',
      label: 'OK',
      color: Colors.green,
    ),
    DropdownOption(
      value: 'Dent',
      label: 'Dent',
      color: InspectionBody.dent,
    ),
    DropdownOption(
      value: 'Crack',
      label: 'Crack',
      color: InspectionBody.crack,
    ),
    DropdownOption(
      value: 'Scratch',
      label: 'Scratch',
      color: InspectionBody.scratch,
    ),
    DropdownOption(
      value: 'Corrosion',
      label: 'Corrosion',
      color: InspectionBody.corrosion,
    ),
    DropdownOption(
      value: 'PaintDefect',
      label: 'Paint Defect',
      color: InspectionBody.paintDefect,
    ),
    DropdownOption(
      value: 'Replaced',
      label: 'Replaced',
      color: InspectionBody.replaced,
    ),
    DropdownOption(
      value: 'Repainted',
      label: 'Repainted',
      color: InspectionBody.repainted,
    ),
  ];
  static const List<DropdownOption<String>> okNotOk = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'OK',
      label: 'OK',
      color: InspectionStatus.ok,
    ),
    DropdownOption(
      value: 'replaced',
      label: 'Replaced',
      color: Colors.yellow,
    ),
    DropdownOption(
      value: 'NotOK',
      label: 'Not OK',
      color: InspectionStatus.abnormal,
    ),
  ];
  static const List<DropdownOption<String>> yesNo = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'Yes',
      label: 'Yes',
      color: Colors.red,
    ),
    DropdownOption(
      value: 'No',
      label: 'No',
      color: Colors.green,
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
    ),
    DropdownOption(
      value: 'Smooth',
      label: 'Smooth',
      color: InspectionComfort.smooth,
    ),
    DropdownOption(
      value: 'OK',
      label: 'OK',
      color: InspectionComfort.ok,
    ),
    DropdownOption(
      value: 'Tight',
      label: 'Tight',
      color: InspectionComfort.tight,
    ),
  ];

  static const List<DropdownOption<String>> conditions = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'Good',
      label: 'Good',
      color: InspectionGD.good,
    ),
    DropdownOption(
      value: 'Ok',
      label: 'OK',
      color: InspectionGD.ok,
    ),
    DropdownOption(
      value: 'Bad',
      label: 'Bad',
      color: InspectionGD.bad,
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
    ),
    DropdownOption(
      value: 'Petrol',
      label: 'Petrol',
      color: InspectionColors.normal,
    ),
    DropdownOption(
      value: 'Diesel',
      label: 'Diesel',
      color: InspectionColors.normal,
    ),
    DropdownOption(
      value: 'EV',
      label: 'EV',
      color: InspectionColors.excellent,
    ),
    DropdownOption(
      value: 'Hybrid',
      label: 'Hybrid',
      color: InspectionColors.good,
    ),
    DropdownOption(
      value: 'BiFuel',
      label: 'BiFuel',
      color: InspectionColors.good,
    ),
    DropdownOption(
      value: 'Others',
      label: 'Others',
      color: InspectionColors.normal,
    ),
  ];

  static const List<DropdownOption<String>> transmissionType = [
    DropdownOption(
      value: 'N/A',
      label: 'N/A',
      color: Colors.grey,
    ),
    DropdownOption(
      value: 'Manual',
      label: 'Manual',
      color: InspectionColors.excellent,
    ),
    DropdownOption(
      value: 'Automatic',
      label: 'Automatic',
      color: InspectionColors.good,
    ),
    DropdownOption(
      value: 'AMT',
      label: 'AMT',
      color: InspectionColors.good,
    ),
    DropdownOption(
      value: 'Others',
      label: 'others',
      color: InspectionColors.bad,
    ),
  ];

  static const List<DropdownOption<String>> basicConditions = [
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
      value: 'Normal',
      label: 'Normal',
      color: InspectionColors.normal,
    ),
    DropdownOption(
      value: 'Bad',
      label: 'Bad',
      color: InspectionColors.bad,
    ),
    DropdownOption(
      value: 'veryBad',
      label: 'Very bad',
      color: InspectionColors.veryPoor,
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
    ),
    DropdownOption(
      value: 'NotVisible',
      label: 'Not Visible',
      color: InspectionColors.excellent,
    ),
    DropdownOption(
      value: 'White',
      label: 'White',
      color: InspectionColors.veryPoor,
    ),
    DropdownOption(
      value: 'Blue',
      label: 'Blue',
      color: InspectionColors.veryPoor,
    ),
    DropdownOption(
      value: 'Black',
      label: 'Black',
      color: InspectionColors.veryPoor,
    ),
  ];
}
