import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_size.dart';

/// Декоративные элементы для фона и украшения интерфейса
class DecorativeElements {
  /// Премиум градиентный фон с тематическими элементами
  static Widget themedBackground({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Stack(
        children: [
          // Большой декоративный круг справа вверху
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.primary.withOpacity(0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Средний декоративный круг слева внизу
          Positioned(
            bottom: -180,
            left: -180,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Маленький декоративный круг в центре
          Positioned(
            top: 250,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// Премиум декоративный паттерн для карточек
  static Widget cardPattern({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        gradient: AppColors.surfaceGradient,
      ),
      child: Stack(
        children: [
          // Тонкий паттерн с улучшенной прозрачностью
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(),
            ),
          ),
          // Легкий градиентный оверлей
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// Иконка мусоровоза для декора
  static Widget truckIcon({
    double size = 80,
    Color? color,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TruckPainter(color: color ?? AppColors.primary),
    );
  }

  /// Иконка полигона для декора
  static Widget polygonIcon({
    double size = 80,
    Color? color,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PolygonPainter(color: color ?? AppColors.secondary),
    );
  }

  /// Иконка карты для декора
  static Widget mapIcon({
    double size = 80,
    Color? color,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MapPainter(color: color ?? AppColors.info),
    );
  }

  /// Декоративная волна
  static Widget waveDecoration({
    Color? color,
    double height = 100,
  }) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _WavePainter(color: color ?? AppColors.primary.withOpacity(0.1)),
    );
  }

  /// Декоративные точки (pattern dots)
  static Widget dotPattern({
    Color? color,
    double spacing = 20,
  }) {
    return CustomPaint(
      painter: _DotPatternPainter(
        color: color ?? AppColors.textTertiary.withOpacity(0.3),
        spacing: spacing,
      ),
    );
  }
}

/// Художник для рисования премиум паттерна
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Более тонкий и элегантный паттерн
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Рисуем сетку с большим шагом для элегантности
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Добавляем тонкие диагональные линии для глубины
    final diagonalPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.01)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    const diagonalStep = 40.0;
    for (double i = -size.height; i < size.width; i += diagonalStep) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        diagonalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Художник для рисования мусоровоза
class _TruckPainter extends CustomPainter {
  final Color color;

  _TruckPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // Кабина
    final cabRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.3, size.height * 0.4),
      const Radius.circular(4),
    );
    canvas.drawRRect(cabRect, paint);

    // Кузов
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.4, size.height * 0.25, size.width * 0.5, size.height * 0.5),
      const Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, paint);

    // Колеса
    final wheelPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.75),
      size.width * 0.08,
      wheelPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.75),
      size.width * 0.08,
      wheelPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Художник для рисования полигона
class _PolygonPainter extends CustomPainter {
  final Color color;

  _PolygonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Рисуем шестиугольник (полигон)
    for (int i = 0; i < 6; i++) {
      final angle = (i * 2 * math.pi) / 6 - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Внутренний круг
    final innerPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Художник для рисования карты
class _MapPainter extends CustomPainter {
  final Color color;

  _MapPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Контур карты
    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.1);
    path.lineTo(size.width * 0.8, size.height * 0.15);
    path.lineTo(size.width * 0.85, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height * 0.85);
    path.lineTo(size.width * 0.15, size.height * 0.6);
    path.close();
    canvas.drawPath(path, paint);

    // Маркеры на карте
    final markerPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.4), 4, markerPaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.5), 4, markerPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.65), 4, markerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Художник для рисования волны
class _WavePainter extends CustomPainter {
  final Color color;

  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double x = 0; x < size.width; x += 20) {
      final y = size.height * 0.5 + math.sin(x / 20) * 10;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Художник для рисования точечного паттерна
class _DotPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;

  _DotPatternPainter({
    required this.color,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



