class InspectionFieldExplanations {
  static const Map<String, Map<String, String>> explanations = {
    // Documents Section
    'location': {
      'title': 'Place of Inspection',
      'explanation': 'The physical location where the vehicle inspection is being conducted. This should include the complete address, city, and any relevant landmarks for future reference.'
    },
    'frontview': {
      'title': 'Front View',
      'explanation': 'A complete frontal photograph of the vehicle showing the front bumper, headlights, grille, windshield, and hood. This helps assess the overall front-end condition.'
    },
    'rearview': {
      'title': 'Rear View',
      'explanation': 'A complete rear photograph showing the rear bumper, taillights, license plate area, trunk/hatchback, and rear windshield to document the vehicle\'s rear condition.'
    },
    'leftview': {
      'title': 'Left View',
      'explanation': 'A side profile photograph from the left side of the vehicle showing doors, windows, wheels, and overall body condition on the driver side.'
    },
    'rightview': {
      'title': 'Right View',
      'explanation': 'A side profile photograph from the right side of the vehicle showing doors, windows, wheels, and overall body condition on the passenger side.'
    },
    'rc': {
      'title': 'Registration Certificate (RC)',
      'explanation': 'The Registration Certificate is a legal document that proves the vehicle is registered with the transport authority. Check if it\'s available, valid, and matches the vehicle details.'
    },
    'regno': {
      'title': 'Registration Number',
      'explanation': 'The unique alphanumeric identifier assigned to the vehicle by the RTO. It should match the number plates and RC document exactly.'
    },
    'make': {
      'title': 'Vehicle Make',
      'explanation': 'The manufacturer or brand of the vehicle (e.g., Maruti Suzuki, Hyundai, Tata, Mahindra). This should match the RC and insurance documents.'
    },
    'model': {
      'title': 'Vehicle Model',
      'explanation': 'The specific model name of the vehicle (e.g., Swift, i20, Nexon). This identifies the exact variant within the manufacturer\'s lineup.'
    },
    'variant': {
      'title': 'Vehicle Variant',
      'explanation': 'The specific trim level or configuration (e.g., LXi, VXi, ZXi for Maruti or Era, Magna, Sportz for Hyundai). This determines features and specifications.'
    },
    'colour': {
      'title': 'Vehicle Color',
      'explanation': 'The primary color of the vehicle as mentioned in the RC document. Note any color variations or dual-tone combinations if applicable.'
    },
    'fueltype': {
      'title': 'Fuel Type',
      'explanation': 'The type of fuel the vehicle uses - Petrol, Diesel, CNG, Electric, or Hybrid. This affects the vehicle\'s performance, maintenance, and resale value.'
    },
    'transmission': {
      'title': 'Transmission Type',
      'explanation': 'Whether the vehicle has Manual (stick shift) or Automatic transmission. This significantly impacts driving experience and market value.'
    },
    'manufacturingyear': {
      'title': 'Manufacturing Year',
      'explanation': 'The year when the vehicle was manufactured. This may differ from the registration year and affects depreciation calculations.'
    },
    'dateofregistration': {
      'title': 'Date of Registration',
      'explanation': 'The official date when the vehicle was first registered with the RTO. This determines the vehicle\'s age for legal and insurance purposes.'
    },
    'seatingcapacity': {
      'title': 'Seating Capacity',
      'explanation': 'The maximum number of passengers the vehicle can legally accommodate, including the driver. This should match the RC document.'
    },
    'rto': {
      'title': 'Regional Transport Office',
      'explanation': 'The RTO code that appears on the number plate, indicating which regional office registered the vehicle (e.g., MH12 for Pune).'
    },
    'odoreading': {
      'title': 'Odometer Reading',
      'explanation': 'The total distance traveled by the vehicle as shown on the odometer. Record the exact reading in kilometers for mileage verification.'
    },
    'INSURANCE': {
      'title': 'Insurance Status',
      'explanation': 'Whether the vehicle has valid insurance coverage. Insurance is mandatory for all vehicles and protects against accidents and third-party claims.'
    },
    'insurancetype': {
      'title': 'Insurance Type',
      'explanation': 'Type of insurance coverage - Comprehensive (covers own damage + third party) or Third Party (covers only third party damage). Comprehensive offers better protection.'
    },
    'insuranceexpirydate': {
      'title': 'Insurance Expiry Date',
      'explanation': 'The date when the current insurance policy expires. Driving without valid insurance is illegal and can result in penalties.'
    },
    'numberofownership': {
      'title': 'Number of Previous Owners',
      'explanation': 'How many people have owned the vehicle previously. Fewer owners generally indicate better care and higher resale value.'
    },
    'hypothecation': {
      'title': 'Hypothecation Status',
      'explanation': 'Whether the vehicle is pledged to a bank or financial institution as security for a loan. "Yes" means there\'s an active loan, "No" means it\'s loan-free.'
    },
    'saleletter': {
      'title': 'Sale Letter',
      'explanation': 'A document from the previous owner authorizing the sale of the vehicle. Required for ownership transfer and should be on stamp paper.'
    },
    'rcownercontact': {
      'title': 'RC Owner Contact',
      'explanation': 'Whether the contact details of the registered owner are available. This is important for verification and legal documentation.'
    },
    'noc': {
      'title': 'No Objection Certificate',
      'explanation': 'Required when transferring a vehicle from one state to another. "Not Needed" means it\'s an intra-state transfer.'
    },
    'parivahancheck': {
      'title': 'Parivahan Portal Check',
      'explanation': 'Verification of vehicle details through the government\'s Parivahan portal to check for any legal issues, challans, or blacklisting.'
    },
    'challan': {
      'title': 'Traffic Challan Status',
      'explanation': 'Whether there are any pending traffic violations or fines against the vehicle. Clear challan record indicates good compliance history.'
    },
    'blacklist': {
      'title': 'Blacklist Status',
      'explanation': 'Whether the vehicle is blacklisted due to involvement in accidents, insurance fraud, or other legal issues. A clean record is essential.'
    },
    'vehicleservicehistory': {
      'title': 'Vehicle Service History',
      'explanation': 'Complete maintenance records from authorized service centers. Good service history indicates proper maintenance and can increase vehicle value.'
    },
    'periodicserviceaspervsh': {
      'title': 'Periodic Service As Per VSH',
      'explanation': 'Whether regular scheduled maintenance was performed according to manufacturer recommendations. Regular servicing ensures reliability and longevity.'
    },
    'accidentalrepairaspervsh': {
      'title': 'Accidental Repair As Per VSH',
      'explanation': 'Any accident-related repairs mentioned in the service history. This helps assess the extent of previous damage and repair quality.'
    },
    'MAJORMECHANICALREPAIRINVSH': {
      'title': 'Major Mechanical Repair in VSH',
      'explanation': 'Significant engine, transmission, or other major component repairs documented in service history. These can affect reliability and value.'
    },

    // Body Panel Section
    'hood/bonnet': {
      'title': 'Hood/Bonnet',
      'explanation': 'The front cover that provides access to the engine. Check for dents, scratches, rust, paint mismatch, or accident damage that might affect engine protection.'
    },
    'roof': {
      'title': 'Roof Panel',
      'explanation': 'The top panel of the vehicle. Inspect for dents from hail, rust, paint fade, or structural damage that could lead to water leakage.'
    },
    'rhsfender': {
      'title': 'Right Hand Side Fender',
      'explanation': 'The body panel between the front door and wheel on the right side. Check for collision damage, rust, or poor repair work.'
    },
    'rhsapillar': {
      'title': 'RHS A-Pillar',
      'explanation': 'The structural support between windshield and front door on the right side. Critical for safety - check for accident damage or structural compromise.'
    },
    'rhsfrontdoor': {
      'title': 'RHS Front Door',
      'explanation': 'The right front door panel. Check for dents, scratches, door gap alignment, and proper opening/closing mechanism.'
    },
    'rhsbpillar': {
      'title': 'RHS B-Pillar',
      'explanation': 'The structural support between front and rear doors on the right side. Important for side-impact safety - inspect for damage or rust.'
    },
    'rhsreardoor': {
      'title': 'RHS Rear Door',
      'explanation': 'The right rear door panel (for 4-door vehicles). Check condition, alignment, and operation similar to front doors.'
    },
    'rhsrunningboard': {
      'title': 'RHS Running Board',
      'explanation': 'The lower side panel between wheels on the right side. Often prone to stone chips, rust, and impact damage from curbs.'
    },
    'rhscpillar/quarterpanel': {
      'title': 'RHS C-Pillar/Quarter Panel',
      'explanation': 'The rear pillar and side panel behind the rear door. Check for accident damage, rust, or structural issues affecting rear impact safety.'
    },
    'tailgate/dicky': {
      'title': 'Tailgate/Boot Lid',
      'explanation': 'The rear opening panel for cargo access. Check for proper alignment, dents, rust, and smooth opening/closing operation.'
    },
    'lhscpillar/quarterpanel': {
      'title': 'LHS C-Pillar/Quarter Panel',
      'explanation': 'The rear pillar and side panel on the left side. Mirror image of RHS - check for similar damage or structural issues.'
    },
    'lhsrunningboard': {
      'title': 'LHS Running Board',
      'explanation': 'The lower side panel on the left side. Check for damage, rust, and stone chip impacts similar to the right side.'
    },
    'lhsreardoor': {
      'title': 'LHS Rear Door',
      'explanation': 'The left rear door panel. Inspect condition, alignment, and operation to ensure proper function and safety.'
    },
    'lhsbpillar': {
      'title': 'LHS B-Pillar',
      'explanation': 'The structural support between doors on the left side. Critical for side-impact protection - check for any compromise.'
    },
    'lhsfrontdoor': {
      'title': 'LHS Front Door',
      'explanation': 'The left front door panel. Primary entry point - check for wear, damage, and proper operation of all mechanisms.'
    },
    'lhsapillar': {
      'title': 'LHS A-Pillar',
      'explanation': 'The structural support between windshield and front door on the left side. Essential for frontal crash safety.'
    },
    'lhsfender': {
      'title': 'LHS Fender',
      'explanation': 'The body panel covering the front left wheel area. Check for collision damage, rust, or misalignment.'
    },

    // Flood Affected Signs
    'rustedbolts': {
      'title': 'Rusted Bolts',
      'explanation': 'Excessive rust on bolts and fasteners can indicate flood damage. Water submersion causes rapid corrosion of metal components throughout the vehicle.'
    },
    'underseat': {
      'title': 'Under Seat Inspection',
      'explanation': 'Check under seats for mud, sand, water stains, or rust that could indicate flood exposure. Flood water often leaves debris in hidden areas.'
    },
    'insidedashboard': {
      'title': 'Inside Dashboard',
      'explanation': 'Look for water damage signs inside the dashboard - corrosion, mineral deposits, or malfunctioning electronics that indicate flood exposure.'
    },
    'insideboot/dicky': {
      'title': 'Inside Boot/Trunk',
      'explanation': 'Check the trunk area for water stains, rust, mud deposits, or unusual odors that could indicate the vehicle was submerged in flood water.'
    },
    'insideacvent': {
      'title': 'Inside AC Vent',
      'explanation': 'Inspect air conditioning vents for mud, debris, or corrosion. Flood water can enter the HVAC system leaving traces in the ventilation.'
    },
    'insideairfilter': {
      'title': 'Inside Air Filter',
      'explanation': 'Check the air filter for mud, debris, or water damage. A flood-affected vehicle often has contaminated air filtration systems.'
    },
    'insidebodypanel': {
      'title': 'Inside Body Panel',
      'explanation': 'Inspect interior body panels for water marks, rust, or corrosion that indicates flood damage. Look for signs of hasty cleaning or repainting.'
    },

    // Data Set I
    'chassisno': {
      'title': 'Chassis Number Verification',
      'explanation': 'The unique Vehicle Identification Number (VIN) stamped on the chassis. Must match RC documents exactly - any tampering indicates serious issues.'
    },
    'engine number': {
      'title': 'Engine Number Verification',
      'explanation': 'Unique identifier stamped on the engine block. Should match RC documents precisely. Mismatched numbers may indicate engine replacement or fraud.'
    },
    'radiatorintercooler': {
      'title': 'Radiator/Intercooler Condition',
      'explanation': 'Engine cooling system components. Check for leaks, damage, or clogging that could cause overheating and expensive engine damage.'
    },
    'leakage': {
      'title': 'Oil/Fuel/Coolant Leakage',
      'explanation': 'Check for any fluid leaks under the vehicle. Oil, fuel, or coolant leaks indicate wear, damage, or poor maintenance that requires immediate attention.'
    },
    'leakagegearoil': {
      'title': 'Gear Oil Leakage',
      'explanation': 'Transmission or differential oil leaks. These can cause expensive damage if not addressed and indicate potential transmission problems.'
    },
    'frontrhshockfront': {
      'title': 'Front RH Shock Absorber',
      'explanation': 'Right front shock absorber condition. Check for oil leaks, physical damage, or poor performance that affects ride comfort and handling.'
    },
    'frontlhshockfront': {
      'title': 'Front LH Shock Absorber',
      'explanation': 'Left front shock absorber condition. Should match the condition of the right side for balanced suspension performance.'
    },
    'rearrhshockleak': {
      'title': 'Rear RH Shock Absorber',
      'explanation': 'Right rear shock absorber condition. Worn shocks affect braking, cornering, and overall vehicle stability and safety.'
    },
    'rearlhshockleak': {
      'title': 'Rear LH Shock Absorber',
      'explanation': 'Left rear shock absorber condition. All four shocks should be in similar condition for optimal vehicle handling and safety.'
    },
    'powersteeringfluidleak': {
      'title': 'Power Steering Fluid Leak',
      'explanation': 'Check for hydraulic fluid leaks from the power steering system. Leaks can cause steering failure and expensive pump damage.'
    },
    'frontrhbrake': {
      'title': 'Front RH Brake System',
      'explanation': 'Right front brake condition including pads, discs, and calipers. Critical safety component - worn brakes can cause accidents.'
    },
    'frontlhbrake': {
      'title': 'Front LH Brake System',
      'explanation': 'Left front brake condition. Should match right side condition for balanced braking performance and safety.'
    },
    'rearrhbrake': {
      'title': 'Rear RH Brake System',
      'explanation': 'Right rear brake condition. All brake components must be in good condition for safe vehicle operation.'
    },

    // Data Set II
    'rearlhbrake': {
      'title': 'Rear LH Brake System',
      'explanation': 'Left rear brake condition. Complete the four-wheel brake system inspection to ensure balanced braking performance.'
    },
    'axleboots': {
      'title': 'CV Joint Boots (Axle Boots)',
      'explanation': 'Rubber covers protecting CV joints from dirt and retaining lubrication. Torn boots lead to expensive CV joint replacement.'
    },
    'propshaft': {
      'title': 'Propeller Shaft',
      'explanation': 'Drives power from transmission to differential (in RWD/4WD vehicles). Check for vibration, wear, or damage affecting power delivery.'
    },
    'differentialfront': {
      'title': 'Front Differential',
      'explanation': 'Allows wheels to rotate at different speeds during turns (in FWD/AWD). Check for leaks, noise, or operation issues.'
    },
    'differentialrear': {
      'title': 'Rear Differential',
      'explanation': 'Distributes power to rear wheels (in RWD/AWD vehicles). Critical for traction and handling - inspect for damage or leaks.'
    },
    'underbody': {
      'title': 'Underbody Condition',
      'explanation': 'Overall condition of the vehicle\'s underside including rust, damage, or modifications. Structural integrity is crucial for safety.'
    },

    // Battery Section
    'batteryslnumber': {
      'title': 'Battery Serial Number',
      'explanation': 'Unique identifier on the battery casing. Record for warranty purposes and to verify the battery age and authenticity.'
    },
    'batterycondition': {
      'title': 'Battery Physical Condition',
      'explanation': 'Check for corrosion, physical damage, leaks, or swelling. A damaged battery can fail suddenly and may be dangerous.'
    },
    'alternator': {
      'title': 'Alternator Condition',
      'explanation': 'Charges the battery while driving. A faulty alternator will drain the battery and leave you stranded.'
    },
    'starter': {
      'title': 'Starter Motor Condition',
      'explanation': 'Electric motor that starts the engine. Problems include slow cranking, clicking sounds, or complete failure to start.'
    },

    // Coolant
    'coolant': {
      'title': 'Engine Coolant',
      'explanation': 'Liquid that prevents engine overheating. Check level, color, and contamination. Old or contaminated coolant can cause expensive engine damage.'
    },

    // Under Hood
    'radiatorcapopencheck': {
      'title': 'Radiator Cap Condition',
      'explanation': 'Seals the cooling system and maintains pressure. A faulty cap can cause overheating and coolant loss.'
    },
    'airfilter': {
      'title': 'Air Filter Condition',
      'explanation': 'Filters air entering the engine. A clogged filter reduces performance and fuel efficiency, while a damaged one allows dirt into the engine.'
    },
    'rhsapron': {
      'title': 'RHS Engine Bay Apron',
      'explanation': 'Structural panel in the engine bay on the right side. Check for accident damage, rust, or poor repair work.'
    },
    'lhsapron': {
      'title': 'LHS Engine Bay Apron',
      'explanation': 'Structural panel in the engine bay on the left side. Should match the right side condition and show no signs of impact damage.'
    },
    'frontcrossmember': {
      'title': 'Front Cross Member',
      'explanation': 'Structural support beam across the front of the vehicle. Critical for crash safety - any damage compromises structural integrity.'
    },
    'fuseboxes': {
      'title': 'Fuse Boxes',
      'explanation': 'Contains electrical fuses and relays. Check for burnt fuses, corrosion, or modifications that could cause electrical problems.'
    },

    // Brake Fluid
    'brakefluidcondition': {
      'title': 'Brake Fluid Condition',
      'explanation': 'Hydraulic fluid that operates the brake system. Should be clear/light colored. Dark or contaminated fluid reduces braking efficiency.'
    },

    // Tire Section
    'frontrh': {
      'title': 'Front Right Tire',
      'explanation': 'Tread depth and condition of the front right tire. Adequate tread is crucial for grip, especially in wet conditions.'
    },
    'rearrh': {
      'title': 'Rear Right Tire',
      'explanation': 'Tread depth and condition of the rear right tire. Should match other tires for balanced handling and safety.'
    },
    'stepny': {
      'title': 'Spare Tire (Stepney)',
      'explanation': 'Emergency spare tire condition and tread depth. Must be roadworthy in case of a flat tire emergency.'
    },
    'rearlh': {
      'title': 'Rear Left Tire',
      'explanation': 'Tread depth and condition of the rear left tire. Check for even wear patterns and adequate tread depth.'
    },
    'frontlh': {
      'title': 'Front Left Tire',
      'explanation': 'Tread depth and condition of the front left tire. Front tires are crucial for steering and braking performance.'
    },
    'abnormalfronttirewear': {
      'title': 'Abnormal Front Tire Wear',
      'explanation': 'Uneven tire wear patterns indicate alignment issues, suspension problems, or improper tire pressure maintenance.'
    },
    'overalltirecondition': {
      'title': 'Overall Tire Condition',
      'explanation': 'General assessment of all tires including sidewall damage, age, brand mismatch, and overall roadworthiness.'
    },

    // Exterior Section
    'frontglassno': {
      'title': 'Front Windshield',
      'explanation': 'Windshield condition including chips, cracks, or damage. Even small damage can expand and compromise visibility and safety.'
    },
    'rhsfrontdoorglassno': {
      'title': 'RHS Front Door Glass',
      'explanation': 'Right front door window condition. Check for chips, cracks, tinting, and proper up/down operation.'
    },
    ' rhsreardoorglassno': {
      'title': 'RHS Rear Door Glass',
      'explanation': 'Right rear door window condition. Should operate smoothly and be free from damage that could affect safety.'
    },
    'rhsquarterglass': {
      'title': 'RHS Quarter Glass',
      'explanation': 'Small fixed window behind the rear door on the right side. Usually non-opening glass that improves visibility.'
    },
    ' tailgateglassno': {
      'title': 'Rear Windshield/Tailgate Glass',
      'explanation': 'Rear window condition including any heating elements, wipers, or defrosting systems. Critical for rear visibility.'
    },
    '  quarterglass': {
      'title': 'Quarter Glass',
      'explanation': 'Small side windows that improve visibility. Check for damage, proper sealing, and any modifications.'
    },
    '  lhsrearglassno': {
      'title': 'LHS Rear Door Glass',
      'explanation': 'Left rear door window condition. Should match the right side condition and operate properly.'
    },
    'lhsfrontglassno': {
      'title': 'LHS Front Door Glass',
      'explanation': 'Left front door window condition. Primary windows for driver access and visibility - must be in good condition.'
    },
    'bumperfront': {
      'title': 'Front Bumper',
      'explanation': 'Front impact protection and aerodynamic component. Check for cracks, scratches, misalignment, or accident damage.'
    },
    'rearbumper': {
      'title': 'Rear Bumper',
      'explanation': 'Rear impact protection component. Assess condition, alignment, and any signs of collision or parking damage.'
    },
    'rubberbeedings': {
      'title': 'Rubber Seals/Beadings',
      'explanation': 'Weather strips around doors and windows that prevent water and air leaks. Worn seals cause noise and water ingress.'
    },
    'extrafittings-alterations': {
      'title': 'Extra Fittings/Modifications',
      'explanation': 'Any aftermarket additions or modifications to the vehicle. Some modifications may affect insurance coverage or road legality.'
    },
    'frontrh-alloy-disc': {
      'title': 'Front RH Wheel (Alloy/Steel)',
      'explanation': 'Right front wheel condition including rim damage, corrosion, or modifications. Damaged wheels affect handling and tire wear.'
    },
    'rear-rh-alloy-disc': {
      'title': 'Rear RH Wheel (Alloy/Steel)',
      'explanation': 'Right rear wheel condition. Should be free from cracks, bends, or damage that could cause tire problems.'
    },
    'rear-lh-alloy-disc': {
      'title': 'Rear LH Wheel (Alloy/Steel)',
      'explanation': 'Left rear wheel condition. Check for matching design with other wheels and absence of structural damage.'
    },
    'front-lh-alloy-disc': {
      'title': 'Front LH Wheel (Alloy/Steel)',
      'explanation': 'Left front wheel condition. Front wheels bear steering loads and must be in excellent condition for safety.'
    },

    // A/C Section
    'airconditioningflow': {
      'title': 'AC Air Flow',
      'explanation': 'Volume and consistency of air coming from AC vents. Poor airflow indicates blocked filters, faulty blower, or ductwork issues.'
    },
    'airconditioningtemperature': {
      'title': 'AC Cooling Temperature',
      'explanation': 'How cold the air conditioning gets. Poor cooling indicates refrigerant leaks, compressor problems, or system inefficiency.'
    },

    // Interior Section
    'horn': {
      'title': 'Horn Operation',
      'explanation': 'Essential safety device for alerting other road users. Must be loud, clear, and respond immediately when pressed.'
    },
    'headlamps': {
      'title': 'Headlamps',
      'explanation': 'Primary lighting for night driving. Check high/low beam operation, alignment, and lens condition for optimal visibility.'
    },
    'directionindicators': {
      'title': 'Turn Signal Indicators',
      'explanation': 'Indicate turning intentions to other drivers. All indicator lights must flash at proper speed and be clearly visible.'
    },
    'brakelamps': {
      'title': 'Brake Lights',
      'explanation': 'Alert following vehicles when braking. Critical safety feature - all brake lights must illuminate when pedal is pressed.'
    },
    'wiper': {
      'title': 'Windshield Wipers',
      'explanation': 'Clear rain and debris from windshield. Check blade condition, motor operation, and washer fluid system.'
    },
    'foglamps': {
      'title': 'Fog Lights',
      'explanation': 'Additional lighting for poor visibility conditions. Should operate independently and provide proper beam pattern.'
    },
    'powerwindow': {
      'title': 'Power Windows',
      'explanation': 'Electric window operation. All windows should move smoothly up and down without binding or strange noises.'
    },
    'sunroof': {
      'title': 'Sunroof/Moonroof',
      'explanation': 'Opening roof panel for light and ventilation. Check for leaks, smooth operation, and proper sealing when closed.'
    },
    'rooflamp': {
      'title': 'Interior Roof Lighting',
      'explanation': 'Cabin illumination including dome lights and reading lights. All interior lights should function properly.'
    },
    'ventilations': {
      'title': 'Interior Ventilation',
      'explanation': 'Air circulation system including vents and fan speeds. Proper ventilation prevents fogging and maintains air quality.'
    },
    'heating': {
      'title': 'Cabin Heating System',
      'explanation': 'Heater operation for cold weather comfort. Should produce warm air and distribute it evenly throughout the cabin.'
    },
    'insiderearviewmirror': {
      'title': 'Interior Rearview Mirror',
      'explanation': 'Primary mirror for viewing traffic behind. Must be properly adjusted and free from cracks or silvering damage.'
    },
    'outsiderearviewmirrorrhs': {
      'title': 'RHS Exterior Mirror',
      'explanation': 'Right side exterior mirror for blind spot monitoring. Check adjustment, heating (if equipped), and glass condition.'
    },
    'outsiderearviewmirrorlhs': {
      'title': 'LHS Exterior Mirror',
      'explanation': 'Left side exterior mirror critical for safe lane changes. Must be adjustable and provide clear view of adjacent lanes.'
    },
    'autofoldingoforvm': {
      'title': 'Auto-Folding Mirrors',
      'explanation': 'Mirrors that fold automatically when parking or locking. Convenient feature that prevents damage in tight spaces.'
    },
    'seats': {
      'title': 'Seat Condition',
      'explanation': 'Overall condition of all seats including wear, tears, stains, and adjustment mechanisms. Affects comfort and resale value.'
    },
    'ventilatedseat': {
      'title': 'Ventilated Seats',
      'explanation': 'Seats with built-in ventilation for cooling. Premium feature that improves comfort in hot weather conditions.'
    },
    'dashboard': {
      'title': 'Dashboard Condition',
      'explanation': 'Instrument panel condition including cracks, fade, or damage. Houses critical controls and displays for vehicle operation.'
    },
    'doorpads': {
      'title': 'Door Panel Trim',
      'explanation': 'Interior door panel condition including upholstery, switches, and storage compartments. Affects interior aesthetics and function.'
    },
    'roofliner': {
      'title': 'Roof Lining/Headliner',
      'explanation': 'Interior roof covering condition. Check for sagging, stains, or damage that affects appearance and may indicate water ingress.'
    },
    'infotainmentsystem': {
      'title': 'Infotainment System',
      'explanation': 'Audio, navigation, and connectivity system. Test all functions including radio, Bluetooth, USB, and touchscreen operation.'
    },
    'reverseparking': {
      'title': 'Reverse Parking Aid',
      'explanation': 'Sensors or camera system to assist with parking. Check sensor cleanliness, camera clarity, and warning system operation.'
    },
    'cruisecontrol/adas': {
      'title': 'Cruise Control/ADAS',
      'explanation': 'Advanced driver assistance systems including cruise control, lane keep assist, and collision avoidance. Test all functions.'
    },
    'floormats': {
      'title': 'Floor Mats',
      'explanation': 'Protective mats for vehicle floor. Check condition, fit, and cleanliness. Quality mats protect carpet and add value.'
    },

    // Dicky/Boot Section
    'stepny-alloy-disc': {
      'title': 'Spare Wheel Condition',
      'explanation': 'Spare tire mounting and wheel condition. Must be properly secured and in good condition for emergency use.'
    },
    'toolkit': {
      'title': 'Vehicle Tool Kit',
      'explanation': 'Basic tools for emergency repairs and tire changes. Should include wheel wrench, jack handle, and other essential tools.'
    },
    'jack': {
      'title': 'Vehicle Jack',
      'explanation': 'Equipment for lifting vehicle to change tires. Must be complete, functional, and appropriate for the vehicle weight.'
    },

    // Test Drive Section
    'clutchcondition': {
      'title': 'Clutch Performance',
      'explanation': 'Clutch engagement, disengagement, and slip characteristics. Worn clutch causes poor acceleration and expensive replacement costs.'
    },
    'gearshifting': {
      'title': 'Gear Shifting Quality',
      'explanation': 'Smoothness and precision of gear changes. Poor shifting indicates transmission wear, linkage problems, or clutch issues.'
    },
    'abnormalnoisetrans': {
      'title': 'Transmission Noise',
      'explanation': 'Unusual sounds from the transmission during driving. Grinding, whining, or clunking noises indicate serious mechanical problems.'
    },
    'abnormalnoisefront': {
      'title': 'Front End Noise',
      'explanation': 'Unusual sounds from front suspension, steering, or drivetrain. May indicate worn components that affect safety and handling.'
    },
    'abnormalnoiserear': {
      'title': 'Rear End Noise',
      'explanation': 'Unusual sounds from rear suspension or differential. Can indicate worn bushings, shocks, or differential problems.'
    },
    'suspensioncomfort': {
      'title': 'Suspension Comfort',
      'explanation': 'Ride quality and handling characteristics. Harsh ride or excessive body roll indicates worn suspension components.'
    },
    'alignment': {
      'title': 'Wheel Alignment',
      'explanation': 'Vehicle tracking straight without steering input. Poor alignment causes tire wear, pulling, and handling problems.'
    },
    'powersteeringcondition': {
      'title': 'Power Steering Performance',
      'explanation': 'Ease of steering operation and response. Heavy steering or wandering indicates power steering system problems.'
    },
    'abnormalsteeringnoise': {
      'title': 'Steering System Noise',
      'explanation': 'Unusual sounds when turning the steering wheel. May indicate worn components, low fluid, or pump problems.'
    },
    'sidepullingonbraking': {
      'title': 'Brake Pull Tendency',
      'explanation': 'Vehicle pulling to one side when braking. Indicates uneven brake performance, alignment issues, or tire problems.'
    },
    'handbrakecondition': {
      'title': 'Handbrake/Parking Brake',
      'explanation': 'Parking brake holding ability and adjustment. Must hold vehicle securely on slopes and release completely when disengaged.'
    },

    // After Warm-Up Section
    'engineoil': {
      'title': 'Engine Oil Condition',
      'explanation': 'Oil color, consistency, and level after engine reaches operating temperature. Clean oil indicates good maintenance practices.'
    },
    'compressionleak': {
      'title': 'Engine Compression Issues',
      'explanation': 'Signs of compression loss like rough idling, power loss, or excessive exhaust smoke. Indicates internal engine wear.'
    },
    'abnormalvibration': {
      'title': 'Engine Vibration',
      'explanation': 'Unusual vibrations felt through the vehicle when engine is running. May indicate engine mount problems or internal issues.'
    },
    'abnormalenginenoise': {
      'title': 'Engine Noise Levels',
      'explanation': 'Unusual sounds from the engine like knocking, ticking, or grinding. These can indicate serious internal engine problems.'
    },
    'smoke': {
      'title': 'Exhaust Smoke',
      'explanation': 'Color and quantity of exhaust smoke. Blue smoke indicates oil burning, white smoke suggests coolant issues, black smoke shows fuel problems.'
    },
    'hoses': {
      'title': 'Engine Hoses',
      'explanation': 'Condition of rubber hoses for coolant, vacuum, and other fluids. Cracked or soft hoses can fail and cause expensive damage.'
    },
    'belts': {
      'title': 'Engine Belts',
      'explanation': 'Drive belts for alternator, AC, and other accessories. Worn belts can break and leave you stranded or damage components.'
    },

    // Summary
    'summary': {
      'title': 'Inspection Summary',
      'explanation': 'Overall assessment of the vehicle condition, highlighting major issues, recommendations, and final evaluation. Include multiple photos showing the vehicle\'s general condition.'
    },
  };

  static Map<String, String>? getExplanation(String fieldId) {
    return explanations[fieldId];
  }

  static String getTitle(String fieldId) {
    return explanations[fieldId]?['title'] ?? fieldId;
  }

  static String getExplanationText(String fieldId) {
    return explanations[fieldId]?['explanation'] ?? 'No explanation available for this field.';
  }
}