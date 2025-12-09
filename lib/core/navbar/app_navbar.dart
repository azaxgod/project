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
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surface,
              gradient: LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.surface.withOpacity(0.98),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.separator,
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: AppSize.shadowBlur,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 12 : config.padding),
            child: Row(
              children: [
                // Логотип с версией
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.snowing,
                          color: Colors.white,
                          size: isVeryCompact ? 18 : 22,
                        ),
                      ),
                      if (!isVeryCompact) ...[
                        const SizedBox(width: AppPadding.small),
                        Text(
                          'SnowOps',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 18 : 22,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withOpacity(0.1),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const AppVersionBadge(),
                      ],
                    ],
                  ),
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.snowing,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppPadding.small),
            Text(
              'SnowOps',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.separator,
                  Colors.transparent,
                ],
              ),
            ),
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