import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:terax_ai_app/providers/auth_provider.dart';
import 'package:terax_ai_app/utils/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Check authentication status after animation
    Future.delayed(const Duration(seconds: 2), () {
      print('🔍 [SplashScreen] Starting auth check after 2 second delay');
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    print('🔍 EMERGENCY FIX [SplashScreen] _checkAuthStatus started - Testing Immediate Navigation');

    // EMERGENCY FIX: Try immediate navigation first to test if navigation works
    if (mounted) {
      print('🔍 EMERGENCY FIX [SplashScreen] Attempting immediate navigation to /main');
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go('/main');
          print('🔍 EMERGENCY FIX [SplashScreen] Immediate navigation succeeded');
          return; // Exit after successful immediate navigation
        }
      } catch (e) {
        print('🔍 EMERGENCY FIX [SplashScreen] Immediate navigation failed: $e - trying original logic');
      }
    }

    // If immediate navigation fails, use original logic as fallback
    print('🔍 [SplashScreen] _checkAuthStatus started - Original Logic');

    try {
      // Get the auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Wait for the auth provider to complete initialization
      await authProvider.waitForInitialization();

      if (!mounted) return;

      print(
          '🔍 [SplashScreen] Auth initialization complete. Logged in: ${authProvider.isLoggedIn}');

      // Navigate based on authentication state
      if (authProvider.isLoggedIn) {
        print('🔍 [SplashScreen] User is logged in, navigating to main screen');
        context.go('/main');
      } else {
        print(
            '🔍 [SplashScreen] User is not logged in, navigating to signin screen');
        context.go('/signin');
      }
    } catch (e, stackTrace) {
      print('❌ [SplashScreen] Error during auth check: $e');
      print('❌ [SplashScreen] Stack trace: $stackTrace');

      // On error, direct to signin for safety
      if (mounted) {
        print('🔍 [SplashScreen] Error occurred, defaulting to signin screen');
        context.go('/signin');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRed
                                .withAlpha((255 * 0.3).round()),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shield,
                        size: 80,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Name
                    Text(
                      'Terax AI',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Personal Safety',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.lightTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                    const SizedBox(height: 48),

                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Loading text
                    Text(
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
