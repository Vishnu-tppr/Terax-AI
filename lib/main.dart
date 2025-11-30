import 'package:flutter/material.dart';
import 'dart:async';
import 'package:terax_ai_app/screens/auth/biometric_auth_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:terax_ai_app/providers/safe_zones_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/incidents_provider.dart';
import 'providers/safety_provider.dart';
import 'providers/location_provider.dart';
import 'providers/voice_provider.dart';
import 'screens/auth/sign_in_screen.dart';
import 'services/emergency_contacts_service.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'config/api_config.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    if (kDebugMode) {
      print('Initializing TeraxAI App...');
    }

    // Initialize API key for immediate use (non-blocking)
    try {
      await ApiConfig.initializeWithApiKey().timeout(const Duration(seconds: 15));
      if (kDebugMode) {
        print('API configuration initialized successfully');
      }
    } on TimeoutException catch (apiError) {
      if (kDebugMode) {
        print('API initialization timeout, continuing with app startup: $apiError');
        print('NOTE: Gemini API key validation failed - app will work with limited features.');
      }
    } catch (apiError) {
      if (kDebugMode) {
        print('API initialization failed, continuing with app startup: $apiError');
        print('NOTE: Gemini API key may not be configured. This is OK for basic app functionality.');
      }
    }

    runApp(const TeraxAIApp());
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ FATAL ERROR during app startup: $e');
      print('📋 STACK TRACE: $stackTrace');
    }

    // Run a minimal error app in debug mode to show the error on screen
    if (kDebugMode) {
      runApp(const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: ErrorDisplayWidget(),
          ),
        ),
      ));
    }
  }
}

class TeraxAIApp extends StatelessWidget {
  const TeraxAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Building TeraxAIApp with providers...');
    }

    return MultiProvider(
      providers: [
        // Core authentication provider (modified for better error handling)
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            print('Creating AuthProvider...');
          }
          return AuthProvider();
        }),

        // Settings provider (essential for theme and basic settings)
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            print('Creating SettingsProvider...');
          }
          return SettingsProvider();
        }),

        // Start with basic providers first, then add others later
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            print('Creating ContactsProvider...');
          }
          return ContactsProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            print('Creating IncidentsProvider...');
          }
          return IncidentsProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            print('Creating SafetyProvider...');
          }
          return SafetyProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            print('Creating LocationProvider...');
          }
          return LocationProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            print('Creating VoiceProvider...');
          }
          return VoiceProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          if (kDebugMode) {
            print('Creating SafeZonesProvider...');
          }
          return SafeZonesProvider();
        }),
        Provider(create: (_) {
          if (kDebugMode) {
            print('Creating EmergencyContactsService...');
          }
          return EmergencyContactsService();
        }),
      ],
      child: const TeraxAIAppView(),
    );
  }
}

class TeraxAIAppView extends StatelessWidget {
  const TeraxAIAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp.router(
          title: 'Terax AI - Personal Safety',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsProvider.settings.themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: kDebugMode,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        if (kDebugMode) {
          print('🔍 [Router] Building SplashScreen for path: /');
        }
        return const SplashScreen();
      }
    ),
    GoRoute(
      path: '/biometric',
      builder: (context, state) {
        if (kDebugMode) {
          print('🔍 [Router] Building BiometricAuthScreen for path: /biometric');
        }
        return const BiometricAuthScreen();
      }
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) {
        if (kDebugMode) {
          print('🔍 [Router] Building SignInScreen for path: /signin');
        }
        return const SignInScreen();
      }
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) {
        if (kDebugMode) {
          print('🔍 [Router] Building SignUpScreen for path: /signup');
        }
        return const SignUpScreen();
      }
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) {
        if (kDebugMode) {
          print('🔍 [Router] Building MainScreen for path: /main');
        }
        return const MainScreen();
      }
    ),
  ],
);

/// Error display widget for startup failures
class ErrorDisplayWidget extends StatefulWidget {
  const ErrorDisplayWidget({super.key});

  static String? _lastError;

  static void setLastError(String error) {
    _lastError = error;
  }

  @override
  State<ErrorDisplayWidget> createState() => _ErrorDisplayWidgetState();
}

class _ErrorDisplayWidgetState extends State<ErrorDisplayWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'App Startup Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              ErrorDisplayWidget._lastError ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => runApp(const TeraxAIApp()),
            child: const Text('Retry Startup'),
          ),
        ],
      ),
    );
  }
}
