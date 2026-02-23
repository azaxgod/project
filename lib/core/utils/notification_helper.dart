import 'package:flutter/material.dart';
import 'package:akimat_project/core/ui/widgets/notification_overlay.dart';
import 'package:akimat_project/core/utils/error_parser.dart';

/// Расширение для BuildContext для удобного показа уведомлений
extension NotificationExtension on BuildContext {
  /// Получить контроллер уведомлений
  NotificationController? get notificationController {
    return NotificationOverlay.maybeOf(this) ?? NotificationHelper.controller;
  }

  /// Показать успешное уведомление
  void showSuccessNotification(String message, {Duration? duration}) {
    final controller = notificationController;
    if (controller != null) {
      controller.showSuccess(message, duration: duration);
    }
  }

  /// Показать ошибку
  void showErrorNotification(String message, {Duration? duration}) {
    final controller = notificationController;
    if (controller != null) {
      controller.showError(message, duration: duration);
    }
  }

  /// Показать ошибку из исключения (автоматически парсит)
  void showErrorNotificationFromException(dynamic error, {Duration? duration}) {
    final message = ErrorParser.getErrorMessage(error);
    showErrorNotification(message, duration: duration);
  }

  /// Показать предупреждение
  void showWarningNotification(String message, {Duration? duration}) {
    final controller = notificationController;
    if (controller != null) {
      controller.showWarning(message, duration: duration);
    }
  }

  /// Показать информационное уведомление
  void showInfoNotification(String message, {Duration? duration}) {
    final controller = notificationController;
    if (controller != null) {
      controller.showInfo(message, duration: duration);
    }
  }

  /// Показать уведомление с задержкой перед перезагрузкой страницы
  /// 
  /// [message] - сообщение об успехе
  /// [onComplete] - колбэк для перезагрузки/обновления данных (может быть async)
  /// [delay] - задержка перед вызовом onComplete (по умолчанию 4 секунды)
  Future<void> showSuccessWithReload(
    String message,
    Future<void> Function()? onComplete, {
    Duration? delay,
  }) async {
    showSuccessNotification(message);
    await Future.delayed(delay ?? const Duration(seconds: 4));
    // Вызываем колбэк для перезагрузки данных и ждем его завершения
    if (onComplete != null) {
      await onComplete();
    }
  }
}

/// Вспомогательный класс для работы с уведомлениями
class NotificationHelper {
  static NotificationController? _globalController;

  /// Инициализировать глобальный контроллер
  static void init(NotificationController controller) {
    _globalController = controller;
  }

  /// Получить глобальный контроллер
  static NotificationController? get controller => _globalController;

  /// Показать успешное уведомление
  static void showSuccess(String message, {Duration? duration}) {
    _globalController?.showSuccess(message, duration: duration);
  }

  /// Показать ошибку
  static void showError(String message, {Duration? duration}) {
    _globalController?.showError(message, duration: duration);
  }

  /// Показать ошибку из исключения
  static void showErrorFromException(dynamic error, {Duration? duration}) {
    final message = ErrorParser.getErrorMessage(error);
    showError(message, duration: duration);
  }

  /// Показать предупреждение
  static void showWarning(String message, {Duration? duration}) {
    _globalController?.showWarning(message, duration: duration);
  }

  /// Показать информацию
  static void showInfo(String message, {Duration? duration}) {
    _globalController?.showInfo(message, duration: duration);
  }

  /// Показать уведомление с задержкой перед перезагрузкой
  static Future<void> showSuccessWithReload(
    String message,
    VoidCallback onComplete, {
    Duration? delay,
  }) async {
    showSuccess(message);
    await Future.delayed(delay ?? const Duration(seconds: 4));
    onComplete();
  }
}

