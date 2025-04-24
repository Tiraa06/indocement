import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:indocement_apk/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indocement_apk/pages/master.dart';
import 'package:indocement_apk/pages/login.dart';
import 'package:indocement_apk/pages/register.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Indocement_Apk",
        theme: ThemeData(
          scaffoldBackgroundColor: Constants.scaffoldBackgroundColor,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const SplashScreen(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}

Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case "/master":
      return MaterialPageRoute(builder: (BuildContext context) {
        return const MasterScreen();
      });
    case "/login":
      return MaterialPageRoute(builder: (BuildContext context) {
        return const Login();
      });
    case "/register":
      return MaterialPageRoute(builder: (BuildContext context) {
        return const Register();
      });
    default:
      return MaterialPageRoute(builder: (BuildContext context) {
        return const Login(); // Default ke Login untuk keamanan
      });
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Fade Animation (0 to 1 opacity over 1 second)
    _fadeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Scale Animation (1.0 to 1.2 scale over 0.5 seconds)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOut,
      ),
    );

    // Start the fade animation
    _fadeController.forward().then((_) {
      // After fade completes, start the scale animation
      _scaleController.forward().then((_) {
        // After scale completes, wait 1 second then navigate
        Future.delayed(const Duration(seconds: 1), () {
          _checkLoginStatus();
        });
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getInt('idEmployee') != null;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/master');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/logo_animasi.png',
              width: 200.w, // Adjusted for ScreenUtil
              height: 200.h,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}