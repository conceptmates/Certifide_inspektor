import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_store_plus/media_store_plus.dart';

import 'constants/hive_constants.dart';
import 'data/inspection_storage_model.dart';
import 'routes/routes.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/local_storage_services.dart';
import 'themes/app_scroll_behavior.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  await LocalStorageService.init();

  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
  }

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(InspectionStorageModelAdapter());
  }

  await Future.wait([
    Hive.openBox<InspectionStorageModel>(HiveConstants.INSPECTION_BOX),
    Hive.openBox<InspectionStorageModel>(HiveConstants.INSPECTION_HISTORY_BOX),
  ]);

  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.detached.toString()) {
      await Hive.close();
    }
    return null;
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certifide Inspektor',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.darkTheme(),
      themeMode: ThemeMode.dark,
      scrollBehavior: const AppScrollBehavior(),
      home: const AuthWrapper(),
      routes: AppRoutes.getRoutes(),
    );
  }
}
