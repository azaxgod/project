import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/widgets/app_footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';

class AppNavbar extends StatelessWidget {
  final List<Widget> webWidgets;
  final List<Widget> mobileWidgets;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const AppNavbar({
    super.key,
    this.scaffoldKey,
    this.webWidgets = const [],
    this.mobileWidgets = const [],
  });

  @override
  Widget build(BuildContext context) {
    final config = PlatformConfig.instance;

    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Определяем режим отображения по ширине экрана
          final isCompact = constraints.maxWidth < 1100;
          final isVeryCompact = constraints.maxWidth < 900;
          
          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.separator,
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: AppSize.shadowBlur,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 12 : config.padding),
            child: Row(
              children: [
                // Логотип с версией
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.snowing,
                      color: AppColors.primary,
                      size: isVeryCompact ? 20 : AppSize.iconSize,
                    ),
                    if (!isVeryCompact) ...[
                      const SizedBox(width: AppPadding.small),
                      Text(
                        'SnowOps',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 16 : 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const AppVersionBadge(),
                    ],
                  ],
                ),
                const SizedBox(width: 8),
                // Навигационные кнопки с прокруткой
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: webWidgets.map((widget) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 4),
                        child: _wrapWidgetForCompact(widget, isCompact, isVeryCompact),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(
              Icons.snowing,
              color: AppColors.primary,
              size: AppSize.iconSize,
            ),
            const SizedBox(width: AppPadding.small),
            Text(
              'SnowOps',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: mobileWidgets,
        leading: IconButton(
          icon: Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () {
            if (scaffoldKey?.currentState != null) {
              scaffoldKey!.currentState!.openDrawer();
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: AppColors.separator,
            height: 0.5,
          ),
        ),
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  /// Обертка для компактного режима
  Widget _wrapWidgetForCompact(Widget widget, bool isCompact, bool isVeryCompact) {
    // Пропускаем SizedBox без изменений
    if (widget is SizedBox) {
      return SizedBox(width: isVeryCompact ? 4 : (isCompact ? 6 : 8));
    }
    return widget;
  }
}