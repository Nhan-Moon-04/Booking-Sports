import 'package:flutter/material.dart';
import 'package:do_an_mobile/features/auth/screens/login_screen.dart';
import 'package:do_an_mobile/features/auth/screens/register_screen.dart';
import 'package:do_an_mobile/features/home/screens/home_screen.dart';
import 'package:do_an_mobile/features/map/map_screen.dart'; // Import MapScreen
import 'package:do_an_mobile/features/profile/screens/profile_screen.dart';
import 'package:do_an_mobile/features/profile/screens/profile_edit_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String map = '/map'; // Add map route
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';

  static final Map<String, WidgetBuilder> allRoutes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    map: (context) => const MapScreen(), // Add MapScreen to routes
    profile: (context) => const ProfileScreen(),
    profileEdit: (context) => const ProfileEditScreen(),
  };

  // Helper methods
  static Future<void> goTo(BuildContext context, String routeName, {Object? arguments}) async {
    await Navigator.pushNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static Future<void> replaceWith(BuildContext context, String routeName, {Object? arguments}) async {
    await Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static void pop(BuildContext context) {
    Navigator.pop(context);
  }
}