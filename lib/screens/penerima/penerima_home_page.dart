import 'package:flutter/material.dart';
import 'dashboard_penerima_page.dart';
import 'kebutuhan_penerima_page.dart';
import 'kelola_profil_penerima_page.dart';
import 'riwayat_donasi_penerima_page.dart';

class PenerimaHomeShell extends StatefulWidget {
  const PenerimaHomeShell({super.key});

  @override
  State<PenerimaHomeShell> createState() => _PenerimaHomeShellState();
}

class _PenerimaHomeShellState extends State<PenerimaHomeShell> {
  int _index = 0;

  late final List<Widget> _pages;
  late final List<NavigationDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardPenerimaPage(),
      const KebutuhanPenerimaPage(),
      const RiwayatDonasiPenerimaPage(),
      KelolaProfIlPenerimaPage(
        onUploadSuccess: () {
          // Set tab ke Dashboard setelah upload berhasil
          setState(() => _index = 0);
        },
      ),
    ];
    _destinations = const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.checklist_outlined),
        label: 'Kebutuhan',
      ),
      NavigationDestination(
        icon: Icon(Icons.history_outlined),
        label: 'Riwayat',
      ),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
    ];
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
