import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
// import '../app_text_styles.dart';
// import '../app_sizes.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const SecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.buttonHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.cardRadius),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: AppTextStyles.button.copyWith(color: AppColors.primary)),
      ),
    );
  }
}
