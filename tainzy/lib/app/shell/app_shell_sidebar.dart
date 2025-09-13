// lib/app/shell/app_shell_sidebar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/provider/auth_providers.dart';
import '../repositories/auth_repository.dart';

class AppShellSidebar extends ConsumerWidget {
  const AppShellSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final String location = GoRouterState.of(context).uri.toString();

    return Drawer(
      elevation: 0,
      width: 250,
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(theme),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _SidebarItem(
            title: 'Dashboard', icon: Icons.dashboard_outlined,
            isSelected: _isSelected('/', location),
            onTap: () => _onItemTapped(context, '/'),
          ),
          _SidebarItem(
            title: 'Patients', icon: Icons.people_alt_outlined,
            isSelected: _isSelected('/patients', location),
            onTap: () => _onItemTapped(context, '/patients'),
          ),
          _SidebarItem(
            title: 'Doctors', icon: Icons.medical_services_outlined,
            isSelected: _isSelected('/doctors', location),
            onTap: () => _onItemTapped(context, '/doctors'),
          ),
          _SidebarItem(
            title: 'Products', icon: Icons.medication_outlined,
            isSelected: _isSelected('/products', location),
            onTap: () => _onItemTapped(context, '/products'),
          ),
          _SidebarItem(
            title: 'Transactions', icon: Icons.receipt_long_outlined,
            isSelected: _isSelected('/transactions', location),
            onTap: () => _onItemTapped(context, '/transactions'),
          ),
          _SidebarItem(
            title: 'Schedules', icon: Icons.schedule_outlined,
            isSelected: _isSelected('/reminders', location),
            onTap: () => _onItemTapped(context, '/reminders'),
          ),
          const Spacer(),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _SidebarItem(
            title: 'Logout', icon: Icons.logout,
            isSelected: false,
            onTap: () async {
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return SizedBox(
      height: 61, // Match header height + 1 for divider
      child: Center(
        child: Text(
          'TAINZY',
          style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              letterSpacing: 2),
        ),
      ),
    );
  }

  bool _isSelected(String route, String currentLocation) {
    return currentLocation.startsWith(route) && (route != '/' || currentLocation == '/');
  }

  void _onItemTapped(BuildContext context, String route) {
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
    context.go(route);
  }
}

class _SidebarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem(
      {required this.title,
        required this.icon,
        required this.isSelected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.primaryColor : theme.iconTheme.color?.withOpacity(0.7);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: isSelected ? theme.primaryColor : Colors.transparent, width: 4))
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, color: color, size: 22,),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: color,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}