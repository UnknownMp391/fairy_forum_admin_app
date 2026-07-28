import 'package:fairy_forum_admin_app/config.dart';
import 'package:fairy_forum_admin_app/providers/home_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(homeNavigationProvider);
    final navNotifier = ref.read(homeNavigationProvider.notifier);

    final destinations = navState.destinations;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= wideWidth;

        return Scaffold(
          appBar: AppBar(
            title: Text(destinations[navState.currentIndex].label),
          ),
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedIndex: navState.currentIndex,
                  onDestinationSelected: (index) {
                    navNotifier.navigateTo(index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations.map((d) {
                    return NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    );
                  }).toList(),
                ),
              Expanded(
                child: PageView(
                  controller: navState.controller,
                  onPageChanged: (i) {
                    navNotifier.updateIndexFromPageView(i);
                  },
                  children: [for (final d in destinations) d.child],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: navState.currentIndex,
                  onDestinationSelected: (index) {
                    navNotifier.navigateTo(index);
                  },
                  destinations: destinations
                      .map(
                        (e) => NavigationDestination(
                          icon: Icon(e.icon),
                          label: e.label,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}
