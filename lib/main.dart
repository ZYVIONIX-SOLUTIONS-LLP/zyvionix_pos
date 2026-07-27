import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/provider/navbar/navbar_provider.dart';
import 'package:zyvionix_pos/views/auth/login_screen.dart';
import 'constants/app_theme.dart';
import 'database/hive_boxes.dart';
import 'controllers/product_controller.dart';
import 'controllers/bill_controller.dart';
import 'controllers/theme_controller.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HiveBoxes.initHiveAndOpenBoxes();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => BillController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => BottomNavbarProvider()),
      ],
      child: const ZyvionixPosApp(),
    ),
  );
}

class ZyvionixPosApp extends StatelessWidget {
  const ZyvionixPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return MaterialApp(
          title: 'Zyvionix POS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
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
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
