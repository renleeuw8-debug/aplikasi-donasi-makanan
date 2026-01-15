import 'package:flutter/material.dart';
import 'map_page.dart';
import 'profil_page.dart';
import 'beranda_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.peran = 'donatur'});

  final String peran; // 'donatur', 'petugas', or 'admin'

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget> _pages;
  late final List<NavigationDestination> _destinations;

  @override
  void initState() {
    super.initState();
    if (widget.peran == 'donatur') {
      _pages = const [BerandaPage(), DonasiMapScreen(), ProfileScreen()];
      _destinations = const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          label: 'Lokasi',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ];
    } else if (widget.peran == 'petugas') {
      _pages = const [
        BerandaPage(), // Placeholder - gunakan web admin untuk petugas
        DonasiMapScreen(),
        ProfileScreen(),
      ];
      _destinations = const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          label: 'Lokasi',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ];
    } else if (widget.peran == 'admin') {
      _pages = const [
        BerandaPage(), // Placeholder - gunakan web admin dari folder web/pages
        ProfileScreen(),
      ];
      _destinations = const [
        NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ];
    } else {
      // Default to donatur pages
      _pages = const [BerandaPage(), DonasiMapScreen(), ProfileScreen()];
      _destinations = const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          label: 'Lokasi',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Keluar Aplikasi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Apakah Anda yakin ingin keluar dari aplikasi?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Tidak'),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Ya, Keluar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        return result ?? false;
      },
      child: Scaffold(
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: _destinations,
          onDestinationSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
