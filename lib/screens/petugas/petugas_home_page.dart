import 'package:flutter/material.dart';
import 'petugas_dashboard_page.dart';
import 'verifikasi_tab_page.dart';
import 'profil_petugas_page.dart';
import 'daftar_penerima_page.dart';
import 'laporan_penanganan_page.dart';

class PetugasHomeShell extends StatefulWidget {
  final String? namaPetugas;

  const PetugasHomeShell({super.key, this.namaPetugas});

  @override
  State<PetugasHomeShell> createState() => _PetugasHomeShellState();
}

class _PetugasHomeShellState extends State<PetugasHomeShell> {
  int _index = 0;

  late final List<Widget> _pages;
  late final List<NavigationDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _pages = [
      PetugasDashboardPage(namaPetugas: widget.namaPetugas),
      const VerifikasiTabPage(),
      const DaftarPenerimaPage(),
      const LaporanPenangananPage(),
      ProfilPetugasPage(),
    ];
    _destinations = const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.verified_outlined),
        label: 'Verifikasi',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline),
        label: 'Penerima',
      ),
      NavigationDestination(
        icon: Icon(Icons.description_outlined),
        label: 'Laporan',
      ),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: color.surface,
        selectedIndex: _index,
        onDestinationSelected: (index) {
          setState(() => _index = index);
        },
        destinations: _destinations,
      ),
    );
  }
}
