import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'community_feed_screen.dart';
import 'settings_screen.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const CommunityFeedScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Required for the body to draw behind the BottomNavigationBar, enabling the BackdropFilter blur to work!
      body: Stack(
        children: [
          // Dynamic Mesh Gradient Background
          Positioned.fill(
             child: Container(color: AppColors.background),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Foreground Content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        // Removed BoxShadow as shadows behind a highly transparent glassmorphic container
        // actually bleed *through* the container and create muddy visual artifacts.
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6), // This ensures the background color is applied OVER the blur, rather than the BottomNav bar trying to do it
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  useMaterial3: false, // Force disable the Material 3 pill indicator entirely
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                  HapticFeedback.selectionClick();
                  if (index == _currentIndex) {
                      HapticFeedback.lightImpact();
                  }
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: Colors.transparent, // Must be completely transparent here so the Container color shows through
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textSecondary,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded, size: 28),
                label: 'Scanner',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                activeIcon: Icon(Icons.history_rounded, size: 28),
                label: 'My Garden',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                activeIcon: Icon(Icons.people_alt_rounded, size: 28),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                activeIcon: Icon(Icons.settings_rounded, size: 28),
                label: 'Profile',
              ),
            ],
          ),
          ),
          ),
          ),
        ),
      ),
    );
  }
}
