// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/config/app_router.dart';
import 'app/config/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: TainzyApp()));
}

class TainzyApp extends ConsumerWidget {
  const TainzyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This watch will rebuild TainzyApp when auth state changes,
    // which in turn gets the new router from the provider with the correct redirect logic.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TAINZY',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}