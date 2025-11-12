import 'package:flutter/material.dart';

class OrganizationsDataTable extends StatelessWidget {
  const OrganizationsDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns,
          rows: rows,
          columnSpacing: 24,
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.surfaceVariant,
          ),
        ),
      ),
    );
  }
}

