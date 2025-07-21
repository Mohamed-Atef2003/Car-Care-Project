import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth/login_screen.dart';
import 'constants/colors.dart';
import 'payment/deep_link_handler.dart';

import 'providers/user_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/store_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';

import 'splash_screen.dart';

// Firebase configuration options
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Configuration for car care project
    return const FirebaseOptions(
      apiKey: 'AIzaSyAwwtacepuuKo2Q8OGNupZpTj2AAWbtOMc',
      projectId: 'car-care-97882',
      messagingSenderId: '638722588860',
      appId: '1:638722588860:android:38ea870b5ec415a26bd0b9',
      // Optional values
      authDomain: 'car-care-97882.firebaseapp.com',
      storageBucket: 'car-care-97882.firebasestorage.app',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("Dotenv loaded successfully.");
  } catch (e) {
    print("Error loading .env file: $e");
  }
  
  // Initialize date formatting for English language
  await initializeDateFormatting('en', null);
  
  // Initialize Firebase with options only if not already initialized
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully.");
    } else {
      print("Firebase was already initialized");
      Firebase.app(); // Get the default app instance without re-initializing
    }
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Dispose deep link handler
    DeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Car Care',
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
        },
        // Set English as the default language
        locale: const Locale('en'),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.black),
            titleTextStyle: TextStyle(
              color: AppColors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            hintStyle: TextStyle(color: AppColors.grey),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        builder: (context, child) {
          // Initialize deep link handling after the app is built
          Future.delayed(Duration.zero, () {
            if (context.mounted) {
              DeepLinkHandler.initUniLinks(context);
            }
          });
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
