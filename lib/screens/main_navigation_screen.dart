
import 'package:flutter/material.dart';
import 'package:teachly/core/localization/app_localization.dart';
import 'package:teachly/core/localization/language_controller.dart';
import 'package:teachly/screens/setting_screen.dart';
import 'package:teachly/screens/splash_screen.dart';

import 'home_screen.dart';
import 'schedule_screen.dart';
import 'student_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final LanguageController languageController;

  const MainNavigationScreen({
    super.key,
    required this.languageController,
  });

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  int currentIndex = 0;

  late final List<Widget> screens = [
    const HomeScreen(),
    const ScheduleScreen(),
    const StudentListScreen(),

    SettingsScreen(
      onBack: () {
        changeTab(0);
      },
      onLogout: _handleLogout,
      languageController: widget.languageController,
    ),
  ];

  void changeTab(int index) {
    if (index < 0 || index >= screens.length) {
      return;
    }

    setState(() {
      currentIndex = index;
    });
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SplashScreen(
          languageController: widget.languageController,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeachlyNavigation(
      currentIndex: currentIndex,
      onTabChanged: changeTab,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1FFF3),
        extendBody: true,

        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),

        bottomNavigationBar: currentIndex == 3
            ? const TeachlyBottomNavigation()
            : null,
      ),
    );
  }
}

class TeachlyNavigation extends InheritedWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const TeachlyNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required super.child,
  });

  static TeachlyNavigation of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<TeachlyNavigation>();

    assert(
      result != null,
      'TeachlyNavigation was not found in the widget tree.',
    );

    return result!;
  }

  @override
  bool updateShouldNotify(
    TeachlyNavigation oldWidget,
  ) {
    return currentIndex != oldWidget.currentIndex;
  }
}

class TeachlyBottomNavigation extends StatelessWidget {
  const TeachlyBottomNavigation({super.key});

  static const Color primaryGreen =
      Color(0xFF2F8F57);

  @override
  Widget build(BuildContext context) {
    final navigation =
        TeachlyNavigation.of(context);

    final l10n = AppLocalizations.of(context);

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFEAEAEA),
            width: 0.7,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home_rounded,
            label: l10n.home,
            selected:
                navigation.currentIndex == 0,
            onTap: () {
              navigation.onTabChanged(0);
            },
          ),
          _BottomNavItem(
            icon: Icons.calendar_month_outlined,
            label: l10n.schedule,
            selected:
                navigation.currentIndex == 1,
            onTap: () {
              navigation.onTabChanged(1);
            },
          ),
          _BottomNavItem(
            icon: Icons.groups_outlined,
            label: l10n.studentList,
            selected:
                navigation.currentIndex == 2,
            onTap: () {
              navigation.onTabChanged(2);
            },
          ),
          _BottomNavItem(
            icon: Icons.settings_outlined,
            label: l10n.settings,
            selected:
                navigation.currentIndex == 3,
            onTap: () {
              navigation.onTabChanged(3);
            },
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color primaryGreen =
      Color(0xFF2F8F57);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 78,
        height: 68,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? primaryGreen
                  : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: selected
                    ? primaryGreen
                    : Colors.grey,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

