import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_store_plus/media_store_plus.dart';

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

  // Hive.initFlutter() is performed once inside LocalStorageService.init().
  await LocalStorageService.init();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(InspectionStorageModelAdapter());
  }

  // INSPECTION_BOX / INSPECTION_HISTORY_BOX are opened lazily on first access
  // (every reader guards with isBoxOpen), so we don't block the first frame on
  // deserializing them here.

  // MediaStore is only needed when saving captured media (well after launch),
  // so initialize it after the first frame instead of on the critical path.
  if (Platform.isAndroid) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MediaStore.ensureInitialized();
    });
  }

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
