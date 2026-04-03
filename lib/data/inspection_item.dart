// import '../constants/const.dart';
// import '../models/inspection_item.dart';

// final List<InspectionItem<String>> summary = [
//   InspectionItem(
//     id: 'summary',
//     title: 'Summary',
//     useTextField: true,
//     allowRemarks: false,
//     allowMultiImage: true,
//     allowImage: false,
//   ),
// ];

// final List<InspectionItem<String>> documents = [
//   // InspectionItem(
//   //   id: 'location',
//   //   title: 'Place of Inspection',
//   //   useTextField: true,
//   //   allowImage: false,
//   // ),
//   InspectionItem(
//     id: 'frontview',
//     title: 'Front View',
//     useTextField: true,
//   ),
//   InspectionItem(
//     id: 'rearview',
//     title: 'Rear View',
//     useTextField: true,
//   ),
//   InspectionItem(
//     id: 'leftview',
//     title: 'Left View',
//     useTextField: true,
//   ),
//   InspectionItem(
//     id: 'rightview',
//     title: 'Right View',
//     useTextField: true,
//   ),
//   InspectionItem(
//     id: 'rc',
//     title: 'RC',
//     options: CommonDropdownOptions.insurance,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'regno',
//     title: 'Reg No',
//     useTextField: true,
//     allowRemarks: true,
//     allowImage: false,
//   ),
//   InspectionItem(
//     id: 'make',
//     title: 'Make',
//     useTextField: true,
//     allowRemarks: true,
//     allowImage: false,
//   ),
//   InspectionItem(
//     id: 'model',
//     title: 'Model',
//     useTextField: true,
//     allowRemarks: true,
//     allowImage: false,
//   ),
//   InspectionItem(
//     id: 'variant',
//     title: 'Variant',
//     useTextField: true,
//     allowRemarks: true,
//     allowImage: false,
//   ),
//   InspectionItem(
//     id: 'colour',
//     title: 'Colour',
//     useTextField: true,
//     allowRemarks: true,
//     allowImage: false,
//   ),
//   InspectionItem(
//     id: 'fueltype',
//     title: 'Fuel Type',
//     options: CommonDropdownOptions.fuelType,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'transmission',
//     title: 'Transmission',
//     options: CommonDropdownOptions.transmissionType,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'manufacturingyear',
//     title: 'Manufacturing Year',
//     useTextField: true,
//     allowRemarks: true,
//     allowImage: false,
//   ),
//   InspectionItem(
//     id: 'dateofregistration',
//     title: 'Date of Registration',
//     useTextField: true,
//     allowRemarks: true,
//     allowImage: false,
//   ),
//   // InspectionItem(
//   //   id: 'seatingcapacity',
//   //   title: 'Seating Capacity',
//   //   useTextField: true,
//   //   allowRemarks: true,
//   //   allowImage: false,
//   // ),
//   InspectionItem(
//     id: 'rto',
//     title: 'RTO',
//     useTextField: true,
//     allowRemarks: true,
//     allowImage: false,
//   ),
//   InspectionItem(
//     id: 'odoreading',
//     title: 'ODO READING',
//     useTextField: true,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'INSURANCE',
//     title: 'Insurance',
//     options: CommonDropdownOptions.insurance,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'insurancetype',
//     title: 'Insurance Type',
//     options: CommonDropdownOptions.insuranceTypes,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'insuranceexpirydate',
//     title: 'Insurance Expiry Date',
//     useTextField: true,
//     allowRemarks: true,
//     allowImage: false,
//   ),
//   InspectionItem(
//     id: 'numberofownership',
//     title: 'Number of Ownership',
//     useTextField: true,
//     allowRemarks: true,
//     allowImage: false,
//   ),
//   InspectionItem(
//     id: 'hypothecation',
//     title: 'Hyphothecation',
//     options: CommonDropdownOptions.yesNo,
//     allowRemarks: true,
//   ),
//   // InspectionItem(
//   //   id: 'saleletter',
//   //   title: 'Sale Letter',
//   //   options: CommonDropdownOptions.insurance,
//   //   allowRemarks: true,
//   // ),
//   // InspectionItem(
//   //   id: 'rcownercontact',
//   //   title: 'RC OWNER CONTACT',
//   //   options: CommonDropdownOptions.available,
//   //   allowRemarks: true,
//   // ),
//   InspectionItem(
//     id: 'noc',
//     title: 'NOC',
//     options: CommonDropdownOptions.notNeeded,
//     allowRemarks: true,
//   ),
//   // InspectionItem(
//   //   id: 'parivahancheck',
//   //   title: 'PARIVAHAN CHECK',
//   //   options: CommonDropdownOptions.doneNotDoneInverted,
//   //   allowRemarks: true,
//   // ),
//   InspectionItem(
//     id: 'challan',
//     title: 'CHALLAN',
//     options: CommonDropdownOptions.ifChecked,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'blacklist',
//     title: 'BLACKLIST',
//     options: CommonDropdownOptions.ifChecked,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'vehicleservicehistory',
//     title: 'VEHICLE SERVICE HISTORY',
//     allowRemarks: true,
//     options: CommonDropdownOptions.vehicleCheck,
//     allowFileAttachment: true,
//     allowImage: false,
//   ),
//   // InspectionItem(
//   //   id: 'periodicserviceaspervsh',
//   //   title: 'PERIODIC SERVICE AS PER VSH',
//   //   options: CommonDropdownOptions.doneNotDoneInverted,
//   //   allowRemarks: true,
//   // ),
//   // InspectionItem(
//   //   id: 'accidentalrepairaspervsh',
//   //   title: 'ACCIDENTAL REPAIR AS PER VSH',
//   //   options: CommonDropdownOptions.doneNotDone,
//   //   allowRemarks: true,
//   // ),
//   // InspectionItem(
//   //   id: 'MAJORMECHANICALREPAIRINVSH',
//   //   title: 'MAJOR MECHANICAL REPAIR IN VSH',
//   //   options: CommonDropdownOptions.doneNotDone,
//   //   allowRemarks: true,
//   // ),
// ];
// final List<InspectionItem<String>> floodAffectedSigns = [
//   InspectionItem(
//     id: 'rustedbolts',
//     title: 'Rusted Bolts',
//     options: CommonDropdownOptions.floodAffected,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'underseat',
//     title: 'Under FrontSeat',
//     options: CommonDropdownOptions.floodAffected,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'insidedashboard',
//     title: 'Inside Dashboard',
//     options: CommonDropdownOptions.floodAffected,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'insideboot/dicky',
//     title: 'Inside Boot/Dicky',
//     options: CommonDropdownOptions.floodAffected,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'insideacvent',
//     title: 'Inside AC Vent',
//     options: CommonDropdownOptions.floodAffected,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'insideairfilter',
//     title: 'Inside Air Filter',
//     options: CommonDropdownOptions.floodAffected,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'insidebodypanel',
//     title: 'Inside Body Panel',
//     options: CommonDropdownOptions.floodAffected,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> afterWarmUp = [
//   InspectionItem(
//     id: 'engineoil',
//     title: 'ENGINE OIL',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'compressionleak',
//     title: 'COMPRESSION LEAK',
//     options: CommonDropdownOptions.yesNo,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'abnormalvibration',
//     title: 'ABNORMAL VIBRATION',
//     options: CommonDropdownOptions.normOrAbnorm,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'abnormalenginenoise',
//     title: 'ABNORMAL ENGINE NOISE',
//     options: CommonDropdownOptions.normOrAbnorm,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'smoke',
//     title: 'SMOKE',
//     options: CommonDropdownOptions.smoke,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'hoses',
//     title: 'HOSES',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'belts',
//     title: 'BELTS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> testDrive = [
//   InspectionItem(
//     id: 'clutchcondition',
//     title: 'CLUTCH CONDITION',
//     options: CommonDropdownOptions.smoothOkBad,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'gearshifting',
//     title: 'GEAR SHIFTING',
//     options: CommonDropdownOptions.smoothOkBad,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'abnormalnoisetrans',
//     title: 'ABNORMAL NOISE TRANS',
//     options: CommonDropdownOptions.normOrAbnorm,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'abnormalnoisefront',
//     title: 'ABNORMAL NOISE FRONT',
//     options: CommonDropdownOptions.normOrAbnorm,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'abnormalnoiserear',
//     title: 'ABNORMAL NOISE REAR',
//     options: CommonDropdownOptions.normOrAbnorm,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'suspensioncomfort',
//     title: 'SUSPENSION COMFORT',
//     options: CommonDropdownOptions.normOrAbnorm,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'alignment',
//     title: 'ALIGNMENT',
//     options: CommonDropdownOptions.normOrAbnorm,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'powersteeringcondition',
//     title: 'POWER STEERING CONDITION',
//     options: CommonDropdownOptions.smoothOkBad,
//     allowRemarks: true,
//   ),
//   InspectionItem<String>(
//     id: 'abnormalsteeringnoise',
//     title: 'ABNORMAL STEERING NOISE',
//     options: CommonDropdownOptions.normOrAbnorm,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'sidepullingonbraking',
//     title: 'SIDE PULLING ON BRAKING',
//     options: CommonDropdownOptions.yesNo,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'handbrakecondition',
//     title: 'HAND BRAKE CONDITION',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> coolant = [
//   InspectionItem<String>(
//     id: 'coolant',
//     title: 'COOLANT',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
// ];
// final List<InspectionItem<String>> brakeFluid = [
//   InspectionItem(
//     id: 'brakefluidcondition',
//     title: 'BRAKE FLUID CONDITION',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> dicky = [
//   // InspectionItem(
//   //   id: 'stepny-alloy-disc',
//   //   title: 'STEPNY (ALLOY/DISC)',
//   //   options: CommonDropdownOptions.conditions,
//   // ),
//   InspectionItem(
//     id: 'toolkit',
//     title: 'TOOL KIT',
//     options: CommonDropdownOptions.available,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'jack',
//     title: 'JACK',
//     options: CommonDropdownOptions.available,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> ac = [
//   InspectionItem(
//     id: 'airconditioningflow',
//     title: 'AIR CONDITIONING FLOW',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'airconditioningtemperature',
//     title: 'AIR CONDITIONING TEMPERATURE',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
// ];

// // final List<InspectionItem<String>> ecuScan = [
// //   InspectionItem(
// //     id: 'antilockbrakingsystem',
// //     title: 'ANTI LOCK BRAKING SYSTEM',
// //     options: CommonDropdownOptions.availability,
// //     allowRemarks: true,
// //   ),
// //   InspectionItem(
// //     id: 'fuelpump',
// //     title: 'FUEL PUMP',
// //     options: CommonDropdownOptions.conditions,
// //     allowRemarks: true,
// //   ),
// //   InspectionItem(
// //     id: 'ecuscan',
// //     title: 'ECU SCAN',
// //     options: CommonDropdownOptions.conditions,
// //     allowRemarks: true,
// //     allowFileAttachment: true,
// //     allowImage: false,
// //   ),
// //   InspectionItem(
// //     id: 'warninglamps',
// //     title: 'WARNING LAMPS',
// //     options: CommonDropdownOptions.conditions,
// //     allowRemarks: true,
// //   ),
// // ];

// final List<InspectionItem<String>> interior = [
//   InspectionItem(
//     id: 'horn',
//     title: 'HORN',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'headlamps',
//     title: 'HEAD LAMPS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'directionindicators',
//     title: 'DIRECTION INDICATORS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'brakelamps',
//     title: 'BRAKELAMPS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'wiper',
//     title: 'WIPER',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'foglamps',
//     title: 'FOG LAMPS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'powerwindow',
//     title: 'POWER WINDOW',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'sunroof',
//     title: 'SUN ROOF',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rooflamp',
//     title: 'ROOF LAMP',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'ventilations',
//     title: 'VENTILATIONS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'heating',
//     title: 'HEATING',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'insiderearviewmirror',
//     title: 'INSIDE REAR VIEW MIRROR',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'outsiderearviewmirrorrhs',
//     title: 'OUTSIDE REAR VIEW MIRROR RHS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'outsiderearviewmirrorlhs',
//     title: 'OUTSIDE REAR VIEW MIRROR LHS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'autofoldingoforvm',
//     title: 'AUTO FOLDING OF ORVM',
//     options: CommonDropdownOptions.availability,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'seats',
//     title: 'SEATS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'ventilatedseat',
//     title: 'VENTILATED SEAT',
//     options: CommonDropdownOptions.availability,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'dashboard',
//     title: 'DASHBOARD',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'doorpads',
//     title: 'DOORPADS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'roofliner',
//     title: 'ROOF LINER',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'infotainmentsystem',
//     title: 'INFOTAINMENT SYSTEM',
//     options: CommonDropdownOptions.availability,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'reverseparking',
//     title: 'REVERSE PARKING',
//     options: CommonDropdownOptions.availability,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'cruisecontrol/adas',
//     title: 'CRUISE CONTROL/ADAS',
//     options: CommonDropdownOptions.availability,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'floormats',
//     title: 'FLOOR MATS',
//     options: CommonDropdownOptions.availableNotBad,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> exterior = [
//   InspectionItem(
//     id: 'frontglassno',
//     title: 'FRONT GLASS',
//     options: CommonDropdownOptions.okNotOk,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rhsfrontdoorglassno',
//     title: 'RHS FRONT DOOR GLASS',
//     options: CommonDropdownOptions.okNotOk,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: ' rhsreardoorglassno',
//     title: ' RHS REAR DOOR GLASS',
//     options: CommonDropdownOptions.okNotOk,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rhsquarterglass',
//     title: 'RHS QUARTER GLASS',
//     options: CommonDropdownOptions.okNotOk,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: ' tailgateglassno',
//     title: 'TAIL GATE GLASS',
//     options: CommonDropdownOptions.okNotOk,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: '  quarterglass',
//     title: 'QUARTER GLASS',
//     options: CommonDropdownOptions.okNotOk,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: '  lhsrearglassno',
//     title: 'LHS REAR GLASS',
//     options: CommonDropdownOptions.okNotOk,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'lhsfrontglassno',
//     title: 'LHS FRONT GLASS',
//     options: CommonDropdownOptions.okNotOk,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'bumperfront',
//     title: 'BUMPER FRONT',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rearbumper',
//     title: 'REAR BUMPER',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rubberbeedings',
//     title: 'RUBBER BEEDINGS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'extrafittings-alterations',
//     title: 'EXTRA FITTINGS/ ALTERATIONS',
//     options: CommonDropdownOptions.doneNotDoneInverted2,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'frontrh-alloy-disc',
//     title: 'FRONT RH (ALLOY/DISC)',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rear-rh-alloy-disc',
//     title: 'REAR RH (ALLOY/DISC)',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rear-lh-alloy-disc',
//     title: 'REAR LH (ALLOY/DISC)',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'front-lh-alloy-disc',
//     title: 'FRONT LH (ALLOY/DISC)',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> tire = [
//   InspectionItem(
//     id: 'frontrh',
//     title: 'FRONT RH',
//     options: CommonDropdownOptions.tireThickness,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rearrh',
//     title: 'REAR RH',
//     options: CommonDropdownOptions.tireThickness,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'stepny',
//     title: 'STEPNY',
//     options: CommonDropdownOptions.tireThickness,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rearlh',
//     title: 'REAR LH',
//     options: CommonDropdownOptions.tireThickness,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'frontlh',
//     title: 'FRONT LH',
//     options: CommonDropdownOptions.tireThickness,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'abnormalfronttirewear',
//     title: 'ABNORMAL FRONT TIRE WEAR',
//     options: CommonDropdownOptions.normOrAbnorm,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'overalltirecondition',
//     title: 'OVERALL TIRE CONDITION',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> underHood = [
//   InspectionItem<String>(
//     id: 'radiatorcapopencheck',
//     title: 'RADIATOR CAP OPEN CHECK',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'airfilter',
//     title: 'AIR FILTER',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rhsapron',
//     title: 'RHS APRON',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'lhsapron',
//     title: 'LHS APRON',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'frontcrossmember',
//     title: 'FRONT CROSS MEMBER',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'fuseboxes',
//     title: 'FUSE BOXES',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> battery = [
//   InspectionItem(
//     id: 'batteryslnumber',
//     title: 'BATTERY SL NUMBER',
//     useTextField: true,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'batterycondition',
//     title: 'BATTERY CONDITION',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   // InspectionItem(
//   //   id: 'alternator',
//   //   title: 'ALTERNATOR',
//   //   options: CommonDropdownOptions.conditions,
//   //   allowRemarks: true,
//   // ),
//   // InspectionItem(
//   //   id: 'starter',
//   //   title: 'STARTER',
//   //   options: CommonDropdownOptions.conditions,
//   //   allowRemarks: true,
//   // ),
// ];

// final List<InspectionItem<String>> dataSet1 = [
//   InspectionItem(
//     id: 'chassisno',
//     title: 'CHASSIS NO',
//     options: CommonDropdownOptions.verifiedOrNot,
//     allowRemarks: true,
//   ),
//   InspectionItem<String>(
//     id: 'engine number',
//     title: 'ENGINE NUMBER',
//     options: CommonDropdownOptions.verifiedOrNot,
//     allowRemarks: true,
//     allowNumberRemark: true,
//   ),
//   InspectionItem<String>(
//     id: 'radiatorintercooler',
//     title: 'RADIATOR/INTERCOOLER',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem<String>(
//     id: 'leakage',
//     title: 'LEAKAGE (OIL/FUEL/COOLANT)',
//     options: CommonDropdownOptions.yesNo,
//     allowRemarks: true,
//   ),
//   InspectionItem<String>(
//     id: 'leakagegearoil',
//     title: 'LEAKAGE (GEAR OIL)',
//     options: CommonDropdownOptions.yesNo,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'frontrhshockfront',
//     title: 'FRONT RH SHOCK LEAK',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'frontlhshockfront',
//     title: 'FRONT LH SHOCK LEAK',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rearrhshockleak',
//     title: 'REAR RH SHOCK LEAK',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rearlhshockleak',
//     title: 'REAR LH SHOCK LEAK',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'powersteeringfluidleak',
//     title: ' POWER STEERING FLUID LEAK',
//     options: CommonDropdownOptions.yesNo,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'frontrhbrake',
//     title: 'FRONT RH BRAKE',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'frontlhbrake',
//     title: 'FRONT LH BRAKE',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rearrhbrake',
//     title: 'REAR RH BRAKE',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> dataSet2 = [
//   InspectionItem(
//     id: 'rearlhbrake',
//     title: 'REAR LH BRAKE',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'axleboots',
//     title: 'AXLE BOOTS',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'propshaft',
//     title: 'PROP SHAFT',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'differentialfront',
//     title: 'DIFFERENTIAL (FRONT)',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'differentialrear',
//     title: 'DIFFERENTIAL (REAR)',
//     options: CommonDropdownOptions.conditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'underbody',
//     title: 'UNDERBODY',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
// ];

// final List<InspectionItem<String>> bodyPanel = [
//   InspectionItem(
//     id: 'hood/bonnet',
//     title: 'HOOD/BONNET',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'roof',
//     title: 'ROOF',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rhsfender',
//     title: 'RHS FENDER',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rhsapillar',
//     title: 'RHS A PILLAR',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rhsfrontdoor',
//     title: 'RHS FRONT DOOR',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rhsbpillar',
//     title: 'RHS B PILLAR',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rhsreardoor',
//     title: 'RHS REAR DOOR',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rhsrunningboard',
//     title: 'RHS RUNNING BOARD',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'rhscpillar/quarterpanel',
//     title: 'RHS C PILLAR/QUARTER PANEL',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'tailgate/dicky',
//     title: 'TAIL GATE/DICKY',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'lhscpillar/quarterpanel',
//     title: 'LHS C PILLAR/QUARTER PANEL',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'lhsrunningboard',
//     title: 'LHS RUNNING BOARD',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'lhsreardoor',
//     title: 'LHS REAR DOOR',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'lhsbpillar',
//     title: 'LHS B PILLAR',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'lhsfrontdoor',
//     title: 'LHS FRONT DOOR',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'lhsapillar',
//     title: 'LHS A PILLAR',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
//   InspectionItem(
//     id: 'lhsfender',
//     title: 'LHS FENDER',
//     options: CommonDropdownOptions.bodyConditions,
//     allowRemarks: true,
//   ),
// ];
