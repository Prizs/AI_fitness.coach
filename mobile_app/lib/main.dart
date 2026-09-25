import 'package:flutter/material.dart';
import 'package:mobile_app/screens/auth/login_screen.dart';
import 'package:mobile_app/screens/auth/register_screen.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/screens/nutrition_screen.dart';
import 'package:mobile_app/screens/progress_screen.dart';
import 'package:mobile_app/screens/workouts_screen.dart';
import 'package:mobile_app/services/auth_service.dart';

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
  }

  void _handleLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _handleRegisterSuccess() {
    setState(() {
      _showLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService.instance.loggedInUser != null || _isAuthenticated) {
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

  final List<Widget> _screens = const [
    HomeScreen(),
    CoachScreen(),
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
            icon: Icon(Icons.smart_toy_rounded),
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
