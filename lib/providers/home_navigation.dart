import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:fairy_forum_admin_app/routes/home/login.dart';
import 'package:fairy_forum_admin_app/routes/home/management.dart';
import 'package:fairy_forum_admin_app/routes/home/overview.dart';
import 'package:fairy_forum_admin_app/routes/home/settings.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_navigation.g.dart';

class DestinationItem {
  final String label;
  final IconData icon;
  final Widget child;

  const DestinationItem({
    required this.label,
    required this.icon,
    required this.child,
  });
}

class NavigationState {
  final int currentIndex;
  final bool isAnimating;
  final PageController controller;
  final List<DestinationItem> destinations;
  NavigationState({
    required this.destinations,
    required this.currentIndex,
    required this.isAnimating,
    required this.controller,
  });

  NavigationState copyWith({
    List<DestinationItem>? destinations,
    int? currentIndex,
    bool? isAnimating,
    PageController? controller,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      isAnimating: isAnimating ?? this.isAnimating,
      controller: controller ?? this.controller,
      destinations: destinations ?? this.destinations,
    );
  }
}

const destinationsUnlogined = [
  DestinationItem(label: '登录', icon: Icons.person, child: LoginPage()),
  DestinationItem(label: '设置', icon: Icons.settings, child: SettingsPage()),
];

const destinationsLogined = [
  DestinationItem(label: '总览', icon: Icons.home, child: OverviewPage()),
  DestinationItem(label: '管理', icon: Icons.dashboard, child: ManagementPage()),
  DestinationItem(label: '设置', icon: Icons.settings, child: SettingsPage()),
];

@Riverpod()
class HomeNavigationNotifier extends _$HomeNavigationNotifier {
  PageController? _controller;

  @override
  NavigationState build() {
    final isValid = ref.watch(isValidIdentityProvider);

    final newController = PageController();
    final oldController = _controller;
    _controller = newController;

    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!identical(_controller, oldController)) {
          oldController.dispose();
        }
      });
    }

    ref.onDispose(() {
      _controller?.dispose();
      _controller = null;
    });

    return NavigationState(
      destinations: isValid ? destinationsLogined : destinationsUnlogined,
      currentIndex: 0,
      isAnimating: false,
      controller: newController,
    );
  }

  Future<void> navigateTo(int index) async {
    if (index == state.currentIndex || state.isAnimating) return;

    state = state.copyWith(isAnimating: true);

    try {
      await state.controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );

      state = state.copyWith(currentIndex: index, isAnimating: false);
    } catch (e) {
      state = state.copyWith(isAnimating: false);
    }
  }

  void updateIndexFromPageView(int index) {
    if (!state.isAnimating) {
      state = state.copyWith(currentIndex: index);
    }
  }
}
