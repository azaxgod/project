import 'package:flutter/material.dart';
// import '../model/kpi_card.dart';

class KpiCardWidget extends StatelessWidget {
  // final KpiCardModel data;
  final VoidCallback? onTap;

  const KpiCardWidget({super.key,  this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                // data.title,
                'a',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                // data.value,
                'a',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
