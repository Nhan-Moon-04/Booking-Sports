import 'package:flutter/material.dart';
import 'package:do_an_mobile/features/auth/screens/login_screen.dart';
import 'package:do_an_mobile/features/auth/screens/register_screen.dart';
import 'package:do_an_mobile/features/home/screens/home_screen.dart';
import 'package:do_an_mobile/features/map/map_screen.dart';
import 'package:do_an_mobile/features/profile/screens/profile_screen.dart';
import 'package:do_an_mobile/features/profile/screens/profile_edit_screen.dart';
import 'package:do_an_mobile/features/booking/booking_screen.dart';
import 'package:do_an_mobile/firestore database/sport_fields.dart';
import 'package:do_an_mobile/features/booking_schedule/booking_schedule_screen.dart';
import 'package:do_an_mobile/features/home/screens/ViewAllFieldsScreen.dart';
import 'package:do_an_mobile/features/owner/ManageFieldsScreen.dart';
import 'package:do_an_mobile/features/owner/FieldDetailScreen.dart';
import 'package:do_an_mobile/features/owner/Statistics.dart';
import 'package:do_an_mobile/features/owner/ManagePendingBookingsPage.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String map = '/map';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String booking = '/booking';
  static const String schedule = '/booking_schedule';
  static const String viewAllFields = '/view_all_fields';
  static const String manage_fields = '/ManageFieldsScreen';
  static const String fieldDetail = '/field_detail';
  static const String statistics = '/owner';
  static const String manage_bookings = '/owner';
  static final Map<String, WidgetBuilder> allRoutes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    map: (context) => const MapScreen(),
    profile: (context) => const ProfileScreen(),
    profileEdit: (context) => const ProfileEditScreen(),
    schedule: (context) => const BookingScheduleScreen(),
    manage_fields: (context) => const ManageFieldsScreen(),
    statistics: (context) => const StatisticsScreen(),
    manage_bookings: (context) => const ManageBookingScreen(),

    fieldDetail: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as String;
      return FieldDetailScreen(fieldId: args);
    },
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case booking:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || args['field'] == null) {
          return _errorRoute();
        }
        return MaterialPageRoute(
          builder: (_) => BookingScreen(field: args['field'] as SportsField),
        );
      case viewAllFields:
        final args = settings.arguments as List<SportsField>?;
        if (args == null) {
          return _errorRoute();
        }
        return MaterialPageRoute(
          builder: (_) => ViewAllFieldsScreen(sportsFields: args),
        );
      default:
        return _errorRoute();
    }
  }

  static MaterialPageRoute _errorRoute() {
    return MaterialPageRoute(
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: const Text('Lỗi')),
            body: const Center(child: Text('Trang không tồn tại')),
          ),
    );
  }

  static Future<void> goTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    await Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static Future<void> replaceWith(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
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
