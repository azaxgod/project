import 'dart:async';
import 'package:flutter/material.dart';
import 'package:akimat_project/core/ui/app_colors.dart';

/// Тип уведомления
enum NotificationType {
  success,
  error,
  warning,
  info,
}

/// Модель уведомления
class NotificationModel {
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onTap;

  const NotificationModel({
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 4),
    this.onTap,
  });
}

/// Глобальный контроллер для управления уведомлениями
class NotificationController {
  final _notifications = <NotificationModel>[];
  final _controller = StreamController<List<NotificationModel>>.broadcast();

  Stream<List<NotificationModel>> get stream => _controller.stream;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  /// Показать уведомление
  void show(NotificationModel notification) {
    _notifications.add(notification);
    _controller.add(_notifications);
    
    // Автоматически удаляем уведомление после указанной длительности
    Timer(notification.duration, () {
      remove(notification);
    });
  }

  /// Показать успешное уведомление
  void showSuccess(String message, {Duration? duration}) {
    show(NotificationModel(
      message: message,
      type: NotificationType.success,
      duration: duration ?? const Duration(seconds: 4),
    ));
  }

  /// Показать ошибку
  void showError(String message, {Duration? duration}) {
    show(NotificationModel(
      message: message,
      type: NotificationType.error,
      duration: duration ?? const Duration(seconds: 4),
    ));
  }

  /// Показать предупреждение
  void showWarning(String message, {Duration? duration}) {
    show(NotificationModel(
      message: message,
      type: NotificationType.warning,
      duration: duration ?? const Duration(seconds: 4),
    ));
  }

  /// Показать информацию
  void showInfo(String message, {Duration? duration}) {
    show(NotificationModel(
      message: message,
      type: NotificationType.info,
      duration: duration ?? const Duration(seconds: 4),
    ));
  }

  /// Удалить уведомление
  void remove(NotificationModel notification) {
    _notifications.remove(notification);
    _controller.add(_notifications);
  }

  /// Очистить все уведомления
  void clear() {
    _notifications.clear();
    _controller.add(_notifications);
  }

  void dispose() {
    _controller.close();
  }
}

/// Виджет для отображения уведомлений
class NotificationOverlay extends StatefulWidget {
  final NotificationController controller;
  final Widget child;

  const NotificationOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  /// Получить контроллер из контекста
  static NotificationController? maybeOf(BuildContext context) {
    final overlay = context.findAncestorStateOfType<_NotificationOverlayState>();
    return overlay?.widget.controller;
  }

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          StreamBuilder<List<NotificationModel>>(
            stream: widget.controller.stream,
            initialData: widget.controller.notifications,
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              
              if (notifications.isEmpty) {
                return const SizedBox.shrink();
              }

              // Используем MediaQuery.maybeOf для безопасного доступа к MediaQuery
              final mediaQuery = MediaQuery.maybeOf(context);
              final topPadding = (mediaQuery?.padding.top ?? 0) + 16;

              return Positioned(
                top: topPadding,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: notifications.map((notification) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NotificationItem(
                        notification: notification,
                        onDismiss: () => widget.controller.remove(notification),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Отдельный виджет для каждого уведомления с анимацией
class _NotificationItem extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Начинаем справа за экраном
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // Запускаем анимацию появления
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    // Анимация исчезновения
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: colors.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Градиентная полоса слева
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: colors.gradient,
                        ),
                      ),
                    ),
                    // Контент
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Иконка
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.iconBackgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              colors.icon,
                              color: colors.iconColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Текст
                          Flexible(
                            child: Text(
                              widget.notification.message,
                              style: TextStyle(
                                color: colors.textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Кнопка закрытия
                          GestureDetector(
                            onTap: _dismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.closeButtonColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: colors.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _NotificationColors _getColors() {
    switch (widget.notification.type) {
      case NotificationType.success:
        return _NotificationColors(
          backgroundColor: Colors.white,
          textColor: AppColors.textPrimary,
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          iconBackgroundColor: AppColors.successLight.withOpacity(0.2),
          gradient: AppColors.successGradient,
          shadowColor: AppColors.success,
          closeButtonColor: AppColors.background,
        );
      case NotificationType.error:
        return _NotificationColors(
          backgroundColor: Colors.white,
          textColor: AppColors.textPrimary,
          icon: Icons.error_rounded,
          iconColor: AppColors.error,
          iconBackgroundColor: AppColors.errorLight.withOpacity(0.2),
          gradient: LinearGradient(
            colors: [AppColors.error, AppColors.errorLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shadowColor: AppColors.error,
          closeButtonColor: AppColors.background,
        );
      case NotificationType.warning:
        return _NotificationColors(
          backgroundColor: Colors.white,
          textColor: AppColors.textPrimary,
          icon: Icons.warning_rounded,
          iconColor: AppColors.warning,
          iconBackgroundColor: AppColors.warningLight.withOpacity(0.2),
          gradient: LinearGradient(
            colors: [AppColors.warning, AppColors.warningLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shadowColor: AppColors.warning,
          closeButtonColor: AppColors.background,
        );
      case NotificationType.info:
        return _NotificationColors(
          backgroundColor: Colors.white,
          textColor: AppColors.textPrimary,
          icon: Icons.info_rounded,
          iconColor: AppColors.primary,
          iconBackgroundColor: AppColors.primaryLight.withOpacity(0.2),
          gradient: AppColors.primaryGradient,
          shadowColor: AppColors.primary,
          closeButtonColor: AppColors.background,
        );
    }
  }
}

class _NotificationColors {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Gradient gradient;
  final Color shadowColor;
  final Color closeButtonColor;

  const _NotificationColors({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.gradient,
    required this.shadowColor,
    required this.closeButtonColor,
  });
}

