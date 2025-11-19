import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_controller.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class AnalyticsTripDetailPage extends ConsumerStatefulWidget {
  const AnalyticsTripDetailPage({
    super.key,
    required this.tripId,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final String tripId;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<AnalyticsTripDetailPage> createState() => _AnalyticsTripDetailPageState();
}

class _AnalyticsTripDetailPageState extends ConsumerState<AnalyticsTripDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsControllerProvider.notifier).loadTripDetail(widget.tripId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final state = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: const Text('Детали рейса'),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: NavbarWidgetsProvider.combineMobileWidgets(
                context,
                widget.mobileNavbarWidgets,
              ),
            ),
      body: Column(
        children: [
          if (kIsWeb)
            HeaderNavbar(
              webWidgets: widget.webNavbarWidgets,
            ),
          Expanded(
            child: state.tripDetail?.when(
              data: (data) => _buildContent(data, config),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка загрузки данных: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadTripDetail(widget.tripId),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ) ?? const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TripDetailResponse data, PlatformConfig config) {
    final trip = data.data;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return SingleChildScrollView(
      padding: EdgeInsets.all(config.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Основная информация
          _buildInfoSection(trip, dateFormat),
          
          const SizedBox(height: AppPadding.large),
          
          // GPS-трек
          if (trip.gpsTrack != null && trip.gpsTrack!.isNotEmpty)
            _buildGpsTrack(trip.gpsTrack!),
          
          const SizedBox(height: AppPadding.large),
          
          // Фотографии
          if (trip.lprInUrl != null || trip.volumeInUrl != null || 
              trip.lprOutUrl != null || trip.volumeOutUrl != null)
            _buildPhotosSection(trip),
          
          const SizedBox(height: AppPadding.large),
          
          // Нарушения
          if (trip.violations != null && trip.violations!.isNotEmpty)
            _buildViolationsSection(trip.violations!),
        ],
      ),
    );
  }

  Widget _buildInfoSection(TripDetailData trip, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Информация о рейсе', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          _buildInfoRow('Водитель', trip.driverName ?? '—'),
          _buildInfoRow('Подрядчик', trip.contractorName ?? '—'),
          _buildInfoRow('Транспорт', trip.vehicleName ?? '—'),
          if (trip.startTime != null)
            _buildInfoRow('Время старта', dateFormat.format(trip.startTime!)),
          if (trip.polygonArrivalTime != null)
            _buildInfoRow('Прибытие на полигон', dateFormat.format(trip.polygonArrivalTime!)),
          if (trip.polygonExitTime != null)
            _buildInfoRow('Выезд с полигона', dateFormat.format(trip.polygonExitTime!)),
          _buildInfoRow('Статус', trip.status ?? '—'),
          if (trip.ticketId != null)
            _buildInfoRow('Тикет', trip.ticketId!),
          if (trip.contractId != null)
            _buildInfoRow('Контракт', trip.contractId!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsTrack(List<Map<String, dynamic>> gpsTrack) {
    // Парсим GPS точки
    final points = gpsTrack.map((point) {
      final lat = point['latitude'] as num? ?? point['lat'] as num?;
      final lng = point['longitude'] as num? ?? point['lng'] as num? ?? point['lon'] as num?;
      if (lat != null && lng != null) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
      return null;
    }).whereType<LatLng>().toList();

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final center = points[points.length ~/ 2];

    return Container(
      height: 400,
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GPS-трек', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.akimat.project',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: points.first,
                      width: 20,
                      height: 20,
                      child: const Icon(Icons.play_arrow, color: Colors.green, size: 20),
                    ),
                    Marker(
                      point: points.last,
                      width: 20,
                      height: 20,
                      child: const Icon(Icons.stop, color: Colors.red, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(TripDetailData trip) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Фотографии', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          Wrap(
            spacing: AppPadding.normal,
            runSpacing: AppPadding.normal,
            children: [
              if (trip.lprInUrl != null)
                _buildPhotoCard('LPR Въезд', trip.lprInUrl!),
              if (trip.volumeInUrl != null)
                _buildPhotoCard('Volume Въезд', trip.volumeInUrl!),
              if (trip.lprOutUrl != null)
                _buildPhotoCard('LPR Выезд', trip.lprOutUrl!),
              if (trip.volumeOutUrl != null)
                _buildPhotoCard('Volume Выезд', trip.volumeOutUrl!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(String label, String url) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, size: 48),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildViolationsSection(List<String> violations) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Нарушения', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          ...violations.map((violation) => Container(
            margin: const EdgeInsets.only(bottom: AppPadding.small),
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    violation,
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

