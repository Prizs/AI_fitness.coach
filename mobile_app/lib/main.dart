import 'package:flutter/material.dart';
import 'package:mobile_app/screens/auth/login_screen.dart';
import 'package:mobile_app/screens/trainer/trainer_shell.dart';
import 'package:mobile_app/screens/auth/register_screen.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/screens/nutrition_screen.dart';
import 'package:mobile_app/screens/progress_screen.dart';
import 'package:mobile_app/screens/client_trainer_tab.dart';
import 'package:mobile_app/screens/workouts_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/widgets/app_update.dart';
import 'package:mobile_app/widgets/top_notification_banner.dart';
import 'package:mobile_app/services/chat_notification_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AuthService.instance.loadServerConfig().then((_) {
    runApp(const AiFitnessCoachApp());
  });
}

class AiFitnessCoachApp extends StatelessWidget {
  const AiFitnessCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Fitness Coach',
      navigatorKey: appNavigatorKey,
      builder: (context, child) => TopNotificationBannerWrapper(
        key: TopNotificationBanner.bannerKey,
        child: child!,
      ),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1FAE87),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showLogin = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    AuthService.instance.restoreSession().then((restored) {
      if (mounted && restored) {
        setState(() => _isAuthenticated = true);
      }
    });
    // Busca actualizaciones al abrir la app, sin molestar si ya esta al dia.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkForUpdatesOnStart(context);
    });
  }

  void _handleLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _handleRegisterSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService.instance.loggedInUser != null || _isAuthenticated) {
      // FORCE ROUTE FOR TRAINER ACCOUNT (Bypass server cache)
      if (AuthService.instance.loggedInUser?.role == 'trainer' || 
          AuthService.instance.loggedInUser?.cedula == '29977666') {
        return const TrainerShell();
      }
      return const AppShell();
    }

    if (_showLogin) {
      return LoginScreen(
        onLoginSuccess: _handleLoginSuccess,
        onGoToRegister: () {
          setState(() {
            _showLogin = false;
          });
        },
      );
    }

    return RegisterScreen(
      onRegisterSuccess: _handleRegisterSuccess,
      onBackToLogin: () {
        setState(() {
          _showLogin = true;
        });
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Se pide la semana una sola vez al entrar, para que Rutinas y Nutricion
    // abran de inmediato en lugar de esperar a la IA cada vez que se tocan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WeeklyPlanService.instance
          .ensureLoaded(AuthService.instance.loggedInUser);
      ChatNotificationService.instance.startPolling(
        appNavigatorKey,
        onNavigateTab: (index) {
          if (mounted) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      );
    });
  }

  @override
  void dispose() {
    ChatNotificationService.instance.stopPolling();
    super.dispose();
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    ClientTrainerTab(),
    WorkoutsScreen(),
    NutritionScreen(),
    ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_currentIndex == 1 && index != 1) {
            ChatNotificationService.instance.clearAllActiveChats();
          }
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_rounded),
            label: 'Rutinas',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_rounded),
            label: 'Nutrición',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            label: 'Progreso',
          ),
        ],
      ),
    );
  }
}

