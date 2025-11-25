import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:flutter/material.dart';

class LandfillCamerasPage extends StatelessWidget {
  const LandfillCamerasPage({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final config = PlatformConfig.instance;

    return Container(
      margin: EdgeInsets.all(config.padding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppPadding.normal),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                    ),
                    child: Icon(
                      Icons.videocam,
                      color: AppColors.primary,
                      size: AppSize.iconSizeLarge,
                    ),
                  ),
                  const SizedBox(width: AppPadding.normal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Камеры',
                          style: AppTextStyles.title1,
                        ),
                        const SizedBox(height: AppPadding.xs),
                        Text(
                          'Управление камерами на полигонах',
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      // TODO: Открыть диалог добавления камеры
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить камеру'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.large),
            // TODO: Добавить таблицу со списком камер организации
            Container(
              padding: const EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Text(
                'Здесь будет список камер, привязанных к полигонам этой организации. Можно перемещать камеры по карте, менять параметры, отключать/включать.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

