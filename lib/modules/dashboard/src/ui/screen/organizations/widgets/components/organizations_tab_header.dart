import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/core/ui/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class OrganizationsTabHeader extends StatelessWidget {
  const OrganizationsTabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.title2,
              ),
              const SizedBox(height: AppPadding.xs),
              Text(
                subtitle,
                style: AppTextStyles.footnote,
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          PrimaryButton(
            label: actionLabel!,
            onPressed: onAction,
            icon: Icons.add,
            useBlackText: true,
          ),
      ],
    );
  }
}

