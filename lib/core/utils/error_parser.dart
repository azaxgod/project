import 'package:dio/dio.dart';

/// Утилита для парсинга ошибок и получения понятных сообщений для пользователя
class ErrorParser {
  /// Получить понятное сообщение об ошибке из любого типа исключения
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _parseDioError(error);
    } else if (error is Exception) {
      return _parseGenericError(error);
    } else if (error is String) {
      return error;
    } else {
      return error.toString();
    }
  }

  /// Парсинг ошибок Dio (сетевые ошибки, HTTP ошибки)
  static String _parseDioError(DioException error) {
    // Если есть ответ от сервера, извлекаем сообщение об ошибке
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final errorData = error.response!.data;
      
      String serverMessage = '';
      if (errorData is Map) {
        if (errorData.containsKey('error')) {
          serverMessage = errorData['error'] is String 
              ? errorData['error'] as String
              : errorData['error'].toString();
        } else if (errorData.containsKey('message')) {
          serverMessage = errorData['message'] is String
              ? errorData['message'] as String
              : errorData['message'].toString();
        }
      } else if (errorData is String) {
        serverMessage = errorData;
      }

      // Если есть сообщение от сервера, используем его
      if (serverMessage.isNotEmpty) {
        return _formatServerError(statusCode!, serverMessage);
      }

      // Иначе формируем сообщение по статус коду
      return _formatHttpError(statusCode!);
    }

    // Обработка сетевых ошибок (без ответа от сервера)
    return _parseNetworkError(error);
  }

  /// Форматирование ошибок сервера с учетом статус кода
  static String _formatServerError(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return 'Некорректный запрос: $message';
      case 401:
        return 'Ошибка авторизации. Пожалуйста, войдите заново.';
      case 403:
        return 'Доступ запрещен: $message';
      case 404:
        return 'Ресурс не найден: $message';
      case 409:
        return 'Конфликт данных: $message';
      case 422:
        return 'Ошибка валидации: $message';
      case 429:
        return 'Слишком много запросов. Пожалуйста, подождите немного.';
      case 500:
        return 'Ошибка сервера. Пожалуйста, попробуйте позже или обратитесь к администратору.';
      case 502:
        return 'Сервер временно недоступен. Пожалуйста, попробуйте позже.';
      case 503:
        return 'Сервис временно недоступен. Пожалуйста, попробуйте позже.';
      default:
        return message.isNotEmpty ? message : 'Ошибка сервера (код $statusCode)';
    }
  }

  /// Форматирование HTTP ошибок по статус коду
  static String _formatHttpError(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Некорректный запрос. Проверьте введенные данные.';
      case 401:
        return 'Ошибка авторизации. Пожалуйста, войдите заново.';
      case 403:
        return 'Доступ запрещен. У вас нет прав для выполнения этого действия.';
      case 404:
        return 'Ресурс не найден.';
      case 409:
        return 'Конфликт данных. Возможно, такая запись уже существует.';
      case 422:
        return 'Ошибка валидации данных. Проверьте правильность заполнения полей.';
      case 429:
        return 'Слишком много запросов. Пожалуйста, подождите немного.';
      case 500:
        return 'Внутренняя ошибка сервера. Пожалуйста, попробуйте позже или обратитесь к администратору.';
      case 502:
        return 'Сервер временно недоступен. Пожалуйста, попробуйте позже.';
      case 503:
        return 'Сервис временно недоступен. Пожалуйста, попробуйте позже.';
      default:
        return 'Ошибка сервера (код $statusCode). Пожалуйста, попробуйте позже.';
    }
  }

  /// Парсинг сетевых ошибок (timeout, connection error и т.д.)
  static String _parseNetworkError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Время ожидания соединения истекло. Проверьте подключение к интернету и попробуйте снова.';
      
      case DioExceptionType.sendTimeout:
        return 'Время отправки данных истекло. Проверьте подключение к интернету и попробуйте снова.';
      
      case DioExceptionType.receiveTimeout:
        return 'Время получения данных истекло. Проверьте подключение к интернету и попробуйте снова.';
      
      case DioExceptionType.badCertificate:
        return 'Ошибка сертификата безопасности. Пожалуйста, обратитесь к администратору.';
      
      case DioExceptionType.badResponse:
        return 'Неверный ответ от сервера. Пожалуйста, попробуйте позже.';
      
      case DioExceptionType.cancel:
        return 'Запрос был отменен.';
      
      case DioExceptionType.connectionError:
        return 'Ошибка подключения. Проверьте подключение к интернету и попробуйте снова.';
      
      case DioExceptionType.unknown:
      default:
        final message = error.message ?? '';
        if (message.contains('Failed host lookup') || 
            message.contains('failed host lookup') ||
            message.contains('getaddrinfo failed') ||
            message.contains('SocketException')) {
          return 'Не удается подключиться к серверу. Проверьте подключение к интернету и попробуйте снова.';
        } else if (message.contains('Network is unreachable') ||
                   message.contains('network is unreachable')) {
          return 'Сеть недоступна. Проверьте подключение к интернету.';
        } else if (message.isNotEmpty) {
          return 'Ошибка подключения: $message';
        } else {
          return 'Неизвестная ошибка сети. Проверьте подключение к интернету и попробуйте снова.';
        }
    }
  }

  /// Парсинг общих ошибок
  static String _parseGenericError(Exception error) {
    final errorString = error.toString().toLowerCase();
    
    // Обработка специфических типов ошибок
    if (errorString.contains('auth') || errorString.contains('unauthorized')) {
      return 'Ошибка авторизации. Пожалуйста, войдите заново.';
    } else if (errorString.contains('permission') || errorString.contains('forbidden')) {
      return 'У вас нет прав для выполнения этого действия.';
    } else if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Ресурс не найден.';
    } else if (errorString.contains('timeout')) {
      return 'Время ожидания истекло. Попробуйте снова.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Ошибка подключения. Проверьте интернет соединение.';
    }
    
    // Возвращаем оригинальное сообщение, если не удалось распознать
    return error.toString().replaceFirst('Exception: ', '');
  }
}

