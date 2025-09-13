// lib/app/shell/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'app_shell_sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _getCurrentTitle(String location) {
    if (location.startsWith('/patients')) return 'Patients';
    if (location.startsWith('/doctors')) return 'Doctors';
    if (location.startsWith('/products')) return 'Products';
    if (location.startsWith('/transactions')) return 'Transactions';
    if (location.startsWith('/reminders')) return 'Schedules';
    return 'Dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final String title = _getCurrentTitle(location);

    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        final bool isMobile = sizingInfo.isMobile;

        // --- MOBILE LAYOUT using standard Drawer ---
        if (isMobile) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(title),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            drawer: const AppShellSidebar(),
            body: widget.child,
            floatingActionButton: _buildFab(context),
          );
        }

        // --- DESKTOP / TABLET LAYOUT ---
        return Scaffold(
          key: _scaffoldKey,
          body: Row(
            children: [
              const AppShellSidebar(),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: widget.child,
              ),
            ],
          ),
          floatingActionButton: _buildFab(context),
        );
      },
    );
  }

  Widget? _buildFab(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    String? goRoute;
    IconData icon = Icons.add;

    if (location.startsWith('/patients')) goRoute = '/add-patient';
    else if (location.startsWith('/doctors')) goRoute = '/add-doctor';
    else if (location.startsWith('/products')) goRoute = '/add-product';
    else if (location.startsWith('/transactions')) goRoute = '/add-transaction';

    if (goRoute != null) {
      return FloatingActionButton(
        onPressed: () => context.go(goRoute!),
        child: Icon(icon),
      );
    }
    return null;
  }
}