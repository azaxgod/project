import 'package:akimat_project/core/ui/widgets/card_item.dart';
import 'package:flutter/material.dart';
// import '../../../core/ui/widgets/primary_button.dart';
// import '../../../core/ui/widgets/card_item.dart';

class AkimatHome extends StatelessWidget {
  const AkimatHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Левая панель навигации
          NavigationRail(
            selectedIndex: 0,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard), label: Text('Дашборд')),
              NavigationRailDestination(
                  icon: Icon(Icons.business), label: Text('Организации')),
              NavigationRailDestination(
                  icon: Icon(Icons.map), label: Text('Участки')),
              NavigationRailDestination(
                  icon: Icon(Icons.assignment), label: Text('Тикеты')),
              NavigationRailDestination(
                  icon: Icon(Icons.local_shipping), label: Text('Рейсы')),
              NavigationRailDestination(
                  icon: Icon(Icons.report), label: Text('Отчеты')),
            ],
            selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Основной контент
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Главная панель', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // KPI блок
              SizedBox(
  height: 120,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: [
      AppCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Активные участки', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('12', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      const SizedBox(width: 16),
      AppCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Активные тикеты', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('8', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      const SizedBox(width: 16),
      AppCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Всего рейсов', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('25', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      const SizedBox(width: 16),
      AppCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Нарушения', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('3', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ],
  ),
),

                  const SizedBox(height: 16),
                  // Карта (placeholder)
                  Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Center(child: Text('Здесь будет карта OSM с полигонами')),
                  ),
                  const SizedBox(height: 16),
                  // Таблица последних рейсов (placeholder)
                  const Text('Последние рейсы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DataTable(columns: const [
                    DataColumn(label: Text('Время')),
                    DataColumn(label: Text('Подрядчик')),
                    DataColumn(label: Text('Госномер')),
                    DataColumn(label: Text('Участок')),
                    DataColumn(label: Text('Полигон')),
                    DataColumn(label: Text('Объем')),
                    DataColumn(label: Text('Статус')),
                  ], rows: const [
                    DataRow(cells: [
                      DataCell(Text('08:00')),
                      DataCell(Text('ТОО А')),
                      DataCell(Text('KZ1234AB')),
                      DataCell(Text('Участок 1')),
                      DataCell(Text('Полигон 1')),
                      DataCell(Text('5 м³')),
                      DataCell(Text('CONFIRMED')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('09:00')),
                      DataCell(Text('Подрядчик Б')),
                      DataCell(Text('KZ5678CD')),
                      DataCell(Text('Участок 2')),
                      DataCell(Text('Полигон 3')),
                      DataCell(Text('8 м³')),
                      DataCell(Text('ROUTE_VIOLATION')),
                    ]),
                  ])
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
