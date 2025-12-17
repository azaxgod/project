import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:flutter/material.dart';

class OrganizationsDataTable extends StatelessWidget {
  const OrganizationsDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.maxWidth = 1200,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final horizontalScrollController = ScrollController();
    final verticalScrollController = ScrollController();
    
    return Container(
      constraints: maxWidth > 0 ? BoxConstraints(maxWidth: maxWidth) : null,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: AppSize.shadowBlur,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Scrollbar(
        controller: verticalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: verticalScrollController,
          child: Scrollbar(
            controller: horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns.map((col) {
                  // Extract text from the label widget if it's a Text widget
                  Widget styledLabel = col.label;
                  if (col.label is Text) {
                    final textWidget = col.label as Text;
                    styledLabel = Text(
                      textWidget.data ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ).merge(textWidget.style),
                    );
                  }
                  return DataColumn(label: styledLabel);
                }).toList(),
                rows: rows,
                columnSpacing: AppPadding.large + 8,
                headingRowHeight: 56,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 80,
                headingRowColor: WidgetStateProperty.all(
                  AppColors.secondaryBackground,
                ),
                dividerThickness: 0.5,
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: AppColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

