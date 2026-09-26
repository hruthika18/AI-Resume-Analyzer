import 'package:flutter/material.dart';

import 'app_sidebar.dart';

/// Shared page chrome used by every authenticated screen.
///
/// On wide windows (desktop/tablet) it shows the sidebar permanently next
/// to the page content, matching the original design. On narrow windows
/// (phones) it moves the sidebar into a Drawer behind a top app bar, so
/// the app stays usable on common Android screen sizes.
class AppScaffold extends StatelessWidget {
  final String selectedItem;
  final Widget body;
  final Color backgroundColor;

  static const double _wideBreakpoint = 900;

  const AppScaffold({
    super.key,
    required this.selectedItem,
    required this.body,
    this.backgroundColor = const Color(0xFFF7F9FF),
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _wideBreakpoint;

    if (isWide) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            AppSidebar(selectedItem: selectedItem),
            Expanded(child: SafeArea(child: body)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF102752),
        foregroundColor: Colors.white,
        title: Text(selectedItem),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF102752),
        child: AppSidebar(selectedItem: selectedItem),
      ),
      body: SafeArea(child: body),
    );
  }
}
