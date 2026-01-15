import 'package:flutter/material.dart';

import '../models/donasi_model.dart';

class DonasiCard extends StatelessWidget {
  const DonasiCard({super.key, required this.data, this.onTap});

  final DonasiModel data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: const Icon(Icons.volunteer_activism),
        ),
        title: Text(data.namaDonasi ?? 'Unknown'),
        subtitle: Text(
          '${data.kategori} • ${data.jumlah} item • ${data.status}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
