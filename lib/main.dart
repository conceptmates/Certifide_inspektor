import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/hive_constants.dart';
import '../data/inspection_storage_model.dart';
import '../providers/inspection_provider.dart';
import '../routes/routes.dart';
import '../screens/auth/auth_wrapper.dart';
import '../services/local_storage_services.dart';
import '../themes/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();
  await LocalStorageService.init();

  // Register Hive Adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(InspectionStorageModelAdapter());
  }

  // Open Hive Boxes
  await Future.wait([
    Hive.openBox<InspectionStorageModel>(HiveConstants.INSPECTION_BOX),
    Hive.openBox<InspectionStorageModel>(HiveConstants.INSPECTION_HISTORY_BOX),
  ]);

  // Handle app lifecycle
  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.detached.toString()) {
      await Hive.close();
    }
    return null;
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => InspectionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certifide Open App',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.darkTheme(),
      darkTheme: AppThemes.darkTheme(),
      themeMode: ThemeMode.dark,
      home: const AuthWrapper(),
      routes: AppRoutes.getRoutes(),
    );
  }
}
