// lib/routes/routes.dart

import 'dart:developer';

import 'package:flutter/material.dart';
import '../models/inspection_template_model.dart';
import '../screens/auth/login_page.dart';
import '../screens/credits/add_credit_page.dart';
import '../screens/history/history_page.dart';
import '../screens/home/inspection_page.dart';
import '../screens/home/vehicle_details_form.dart';
import '../screens/users/add_user_page.dart';
import '../screens/profile/profile.dart';
import '../screens/main_screen.dart';

class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String addUser = '/add-user';
  static const String addCredits = '/add-credits';
  static const String profile = '/profile';
  static const String inspection = '/inspection';
  static const String vehicleDetails = '/vehicle-details';
  static const String history = '/history';
}

class AppRoutes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      Routes.login: (context) => LoginPage(),
      Routes.home: (context) => const MainScreen(),
      Routes.addUser: (context) => const AddUserPage(),
      Routes.addCredits: (context) => const AddCreditsPage(),
      Routes.profile: (context) => const ProfilePage(),
      Routes.history: (context) => HistoryPage(),
      Routes.inspection: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        final inspectionIdValue = args?['inspectionId'];
        final inspectionId = inspectionIdValue is int
            ? inspectionIdValue
            : inspectionIdValue is String
                ? int.tryParse(inspectionIdValue)
                : null;

        // Parse inspectionTemplate from arguments
        dynamic templateData = args?['inspectionTemplate'];
        InspectionInitializationResponse? inspectionTemplate;
        
        if (templateData != null) {
          if (templateData is InspectionInitializationResponse) {
            inspectionTemplate = templateData;
          } else if (templateData is Map<String, dynamic>) {
            try {
              inspectionTemplate = InspectionInitializationResponse.fromJson(templateData);
            } catch (e) {
              log('Error parsing inspection template in routes: $e');
            }
          }
        }

        return InspectionScreen(
          isNewInspection: args?['isNew'] ?? false,
          vehicleDetails: args?['vehicleDetails'],
          inspectionId: inspectionId,
          inspectionTemplate: inspectionTemplate,
        );
      },
      Routes.vehicleDetails: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        return VehicleDetailsForm(isNewInspection: args?['isNew'] ?? true);
      },
    };
  }
}
