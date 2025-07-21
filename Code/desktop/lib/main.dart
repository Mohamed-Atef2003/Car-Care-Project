import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:car_care/pages/welcome_page.dart';
import 'package:car_care/theme/app_colors.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/loading_provider.dart';


import 'authentication/login_page.dart';
import 'authentication/register_page.dart';
import 'authentication/terms_page.dart';
import 'authentication/forgot_password_page.dart';
import 'package:car_care/utils/connectivity_manager.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:car_care/services/firebase_firestore_fix.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Firestore to properly handle threading
  FirestoreThreadFix.configureFirestore();
  
  // Configure window for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1280, 720),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'Car Care',
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('Error initializing window: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => app_auth.AuthProvider(),
        ),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityManager()),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindow();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initWindow() async {
    try {
      HardwareKeyboard.instance.addHandler((event) {
        final result = _handleKeyPress(event);
        return result == KeyEventResult.handled;
      });
    } catch (e) {
      debugPrint('Error initializing keyboard handlers: $e');
    }
  }

  KeyEventResult _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      _toggleFullScreen();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _toggleFullScreen() async {
    _isFullScreen = !_isFullScreen;
    await windowManager.setFullScreen(_isFullScreen);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoadingProvider>(
          create: (_) => LoadingProvider(),
        ),
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<AuthService>(
          create: (context) => AuthService(
            context.read<ApiService>(),
            context.read<StorageService>(),
          ),
        ),
        
      ],
      child: Consumer2<LoadingProvider, ConnectivityManager>(
        builder: (context, loadingProvider, connectivityManager, child) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                MaterialApp(
                  title: 'Car Care',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    primarySwatch: AppColors.primarySwatch,
                    scaffoldBackgroundColor: AppColors.background,
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary,
                      secondary: AppColors.secondary,
                      surface: AppColors.white,
                      onPrimary: AppColors.white,
                      onSecondary: AppColors.textPrimary,
                      onSurface: AppColors.textPrimary,
                    ),
                    textTheme: TextTheme(
                      bodyLarge: TextStyle(color: AppColors.textPrimary),
                      bodyMedium: TextStyle(color: AppColors.textPrimary),
                      titleLarge: TextStyle(color: AppColors.textPrimary),
                      titleMedium: TextStyle(color: AppColors.textPrimary),
                      titleSmall: TextStyle(color: AppColors.gray),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ),
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(1.0)),
                      child: Stack(
                        children: [
                          child!,
                          if (!connectivityManager.isConnected)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Material(
                                child: Container(
                                  color: Colors.red,
                                  padding: const EdgeInsets.all(8),
                                  child: const Text(
                                    'No internet connection',
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  home: const WelcomePage(),
                  routes: {
                    '/login': (ctx) => const LoginPage(),
                    '/register': (ctx) => const RegisterPage(),
                    '/terms': (ctx) => const TermsPage(),
                    '/forgot-password': (ctx) => const ForgotPasswordPage(),
                  },
                  initialRoute: AppRoutes.initial,
                  onGenerateRoute: AppRoutes.onGenerateRoute,
                  onUnknownRoute: (settings) => MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Center(
                        child: Text('Route not found!'),
                      ),
                    ),
                  ),
                ),
                if (loadingProvider.isLoading)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              if (loadingProvider.loadingMessage.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(loadingProvider.loadingMessage),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<app_auth.AuthProvider>(context, listen: false).tryAutoLogin(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Consumer<app_auth.AuthProvider>(
          builder: (ctx, auth, _) {
            if (auth.isAuth) {
              return const WelcomePage();
            }
            return const LoginPage();
          },
        );
      },
    );
  }
}
