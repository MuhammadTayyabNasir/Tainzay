// lib/app/config/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/doctor/screens/doctor_detail_screen.dart'; // Import new screen
import '../../features/auth/provider/auth_providers.dart';
import '../../features/auth/screen/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/doctor/screens/add_edit_doctor_screen.dart';
import '../../features/doctor/screens/doctor_list_screen.dart';
import '../../features/patient/screens/add_edit_patient_screen.dart';
import '../../features/patient/screens/patient_list_screen.dart';
import '../../features/product/screens/add_edit_product_screen.dart';
import '../../features/product/screens/product_list_screen.dart';
import '../../features/reminder/screens/reminder_list_screen.dart';
import '../../features/transaction/screens/add_transaction_screen.dart';
import '../../features/transaction/screens/transaction_list_screen.dart';
import '../shell/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;

      final loggingIn = state.uri.toString() == '/login';
      if (!isLoggedIn && !loggingIn) {
        return '/login';
      }

      if (isLoggedIn && loggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),

          GoRoute(path: '/patients', builder: (context, state) => const PatientListScreen()),
          GoRoute(path: '/add-patient', builder: (context, state) => const AddEditPatientScreen()),
          GoRoute(path: '/patient/:patientId/edit', builder: (context, state) => AddEditPatientScreen(patientId: state.pathParameters['patientId']!)),

          GoRoute(path: '/reminders', builder: (context, state) => const ReminderListScreen()),
          GoRoute(path: '/doctors', builder: (context, state) => const DoctorListScreen()),
          GoRoute(path: '/add-doctor', builder: (context, state) => const AddEditDoctorScreen()),
          GoRoute(path: '/doctor/:doctorId/edit', builder: (context, state) => AddEditDoctorScreen(doctorId: state.pathParameters['doctorId']!)),

          GoRoute(path: '/products', builder: (context, state) => const ProductListScreen()),
          GoRoute(path: '/add-product', builder: (context, state) => const AddEditProductScreen()),
          GoRoute(path: '/product/:productId/edit', builder: (context, state) => AddEditProductScreen(productId: state.pathParameters['productId']!)),

          GoRoute(path: '/transactions', builder: (context, state) => const TransactionListScreen()),
          GoRoute(path: '/add-transaction', builder: (context, state) => const AddTransactionScreen()),
          GoRoute(path: '/transaction/:transactionId/edit', builder: (context, state) => AddTransactionScreen(transactionId: state.pathParameters['transactionId']!)),
          GoRoute(
            path: '/doctor/:doctorId',
            builder: (context, state) =>
                DoctorDetailScreen(doctorId: state.pathParameters['doctorId']!),
          ),

          GoRoute(path: '/doctor/:doctorId/edit', builder: (context, state) => AddEditDoctorScreen(doctorId: state.pathParameters['doctorId']!)),
        ],
      ),
    ],
  );
});