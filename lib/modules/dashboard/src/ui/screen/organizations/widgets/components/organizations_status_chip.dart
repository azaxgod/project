import 'package:flutter/material.dart';

class OrganizationsStatusChip extends StatelessWidget {
  const OrganizationsStatusChip({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green.shade600 : Colors.red.shade600;
    return Chip(
      backgroundColor: color,
      label: Text(
        isActive ? 'Активен' : 'Заблокировано',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

