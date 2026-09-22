import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/provider/navbar/navbar_provider.dart';
import 'package:zyvionix_pos/provider/auth_provider.dart';
import 'package:zyvionix_pos/views/auth/login_screen.dart';
import 'package:zyvionix_pos/views/navbar/navbar_screen.dart';
import 'constants/app_theme.dart';
import 'database/hive_boxes.dart';
import 'controllers/language_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/bill_controller.dart';
import 'controllers/theme_controller.dart';
import 'views/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/firebase/firebase_service.dart';
import 'views/firebase/local_notification_service.dart';
import 'services/maintenance_service.dart';
import 'services/socket_service.dart';
import 'services/network_service.dart';
import 'widgets/offline_overlay.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await LocalNotificationService.init();
    await FCMService().initialize();

    print('✅ Firebase & FCM initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  await Hive.initFlutter();
  await HiveBoxes.initHiveAndOpenBoxes();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkController()),
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => BillController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => LanguageController()),
        ChangeNotifierProvider(create: (_) => BottomNavbarProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const ZyvionixPosApp(),
    ),
  );
}

class ZyvionixPosApp extends StatefulWidget {
  const ZyvionixPosApp({super.key});

  @override
  State<ZyvionixPosApp> createState() => _ZyvionixPosAppState();
}

class _ZyvionixPosAppState extends State<ZyvionixPosApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Background handling logic if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeController, LanguageController>(
      builder: (context, themeController, languageController, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: languageController.tr('app_title'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (context, child) => OfflineOverlayWrapper(child: child!),
          home: const AppStartupHandler(),
        );
      },
    );
  }
}

class AppStartupHandler extends StatefulWidget {
  const AppStartupHandler({super.key});

  @override
  State<AppStartupHandler> createState() => _AppStartupHandlerState();
}

class _AppStartupHandlerState extends State<AppStartupHandler> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    MaintenanceService().initSocket();
    await MaintenanceService().checkInitialMaintenanceStatus();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final box = HiveBoxes.getSettingsBox();
      final token = box.get('auth_token');

      if (token != null && token.isNotEmpty) {
        final userId = box.get('user_id');
        if (userId != null) {
          await HiveBoxes.openUserBoxes(userId);
        }

        SocketService().initSocket();

        if (mounted) {
          context.read<ProductController>().init();
          context.read<BillController>().init();
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NavbarScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
