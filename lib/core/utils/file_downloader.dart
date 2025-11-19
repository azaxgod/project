import 'dart:io' show Platform, Directory, File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Условные импорты для веба
import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart' as web_downloader;

/// Утилита для скачивания файлов (PDF, и т.д.)
class FileDownloader {
  /// Скачивает файл (PDF) и сохраняет его
  /// 
  /// [bytes] - байты файла
  /// [filename] - имя файла (без расширения, расширение добавится автоматически)
  /// [extension] - расширение файла (по умолчанию 'pdf')
  /// 
  /// Возвращает путь к сохраненному файлу (для мобильных) или null (для веба)
  static Future<String?> downloadFile({
    required List<int> bytes,
    required String filename,
    String extension = 'pdf',
  }) async {
    try {
      if (kIsWeb) {
        // Для веба используем браузерное скачивание
        return _downloadFileWeb(bytes, filename, extension);
      } else {
        // Для мобильных платформ сохраняем в Downloads или Documents
        return await _downloadFileMobile(bytes, filename, extension);
      }
    } catch (e) {
      debugPrint('FileDownloader - Error downloading file: $e');
      rethrow;
    }
  }

  /// Скачивание файла для веба
  static String? _downloadFileWeb(List<int> bytes, String filename, String extension) {
    if (!kIsWeb) return null;
    
    try {
      return web_downloader.downloadFileWeb(bytes, filename, extension);
    } catch (e) {
      debugPrint('FileDownloader - Web download error: $e');
      rethrow;
    }
  }

  /// Скачивание файла для мобильных платформ
  static Future<String> _downloadFileMobile(
    List<int> bytes,
    String filename,
    String extension,
  ) async {
    try {
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Для Android используем Downloads
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback на внешнее хранилище
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // Для iOS используем Documents
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Для других платформ используем Documents
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not determine download directory');
      }

      final filePath = '${directory.path}/$filename.$extension';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      debugPrint('FileDownloader - File saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('FileDownloader - Mobile download error: $e');
      rethrow;
    }
  }
}
