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
import 'package:akimat_project/modules/violations/src/controller/violations_controller.dart';
import 'package:akimat_project/modules/violations/src/controller/violations_providers.dart';
import 'package:akimat_project/services/violations/model/violation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ViolationDetailPage extends ConsumerStatefulWidget {
  const ViolationDetailPage({
    super.key,
    required this.violationId,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final String violationId;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<ViolationDetailPage> createState() => _ViolationDetailPageState();
}

class _ViolationDetailPageState extends ConsumerState<ViolationDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(violationsControllerProvider.notifier).loadViolationDetail(widget.violationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final state = ref.watch(violationsControllerProvider);
    final controller = ref.read(violationsControllerProvider.notifier);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.violations),
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
            child: state.violationDetail?.when(
              data: (data) => _buildViolationDetail(data, controller),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка загрузки данных: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadViolationDetail(widget.violationId),
                      child: const Text('Повторить'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Назад'),
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

  Widget _buildViolationDetail(data, ViolationsController controller) {
    final violation = data.violation.violation;
    final appeals = data.appeals;

    return SingleChildScrollView(
      padding: EdgeInsets.all(PlatformConfig.instance.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопкой назад
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  'Детали нарушения',
                  style: AppTextStyles.title1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.large),
          
          // Информация о нарушении
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          violation.type.value,
                          style: AppTextStyles.title2,
                        ),
                      ),
                      _buildStatusChip(violation.status),
                    ],
                  ),
                  const SizedBox(height: AppPadding.normal),
                  _buildInfoRow('ID', violation.id),
                  _buildInfoRow('Рейс', data.violation.violation.tripId),
                  _buildInfoRow('Тип', violation.type.value),
                  _buildInfoRow('Серьезность', violation.severity.value),
                  _buildInfoRow('Обнаружено', violation.detectedBy.value),
                  _buildInfoRow('Статус', violation.status.value),
                  if (violation.description != null)
                    _buildInfoRow('Описание', violation.description!),
                  if (data.violation.driver != null)
                    _buildInfoRow('Водитель', data.violation.driver!.fullName),
                  if (data.violation.vehicle != null)
                    _buildInfoRow('Машина', data.violation.vehicle!.plateNumber),
                  if (data.violation.contractor != null)
                    _buildInfoRow('Подрядчик', data.violation.contractor!.name),
                  _buildInfoRow('Создано', _formatDateTime(violation.createdAt)),
                  _buildInfoRow('Обновлено', _formatDateTime(violation.updatedAt)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppPadding.large),
          
          // Апелляции
          Text(
            'Апелляции (${appeals.length})',
            style: AppTextStyles.title2,
          ),
          const SizedBox(height: AppPadding.normal),
          
          if (appeals.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.large),
                child: Center(
                  child: Text(
                    'Апелляций нет',
                    style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ),
            )
          else
            ...appeals.map((appeal) => _buildAppealCard(appeal)),
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
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
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

  Widget _buildStatusChip(ViolationStatus status) {
    Color color;
    switch (status.value) {
      case 'OPEN':
        color = Colors.orange;
        break;
      case 'CANCELED':
        color = Colors.green;
        break;
      case 'FIXED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.normal,
        vertical: AppPadding.small,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSize.buttonRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAppealCard(appeal) {
    final appealData = appeal.appeal;
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.normal),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Апелляция #${appealData.id.substring(0, 8)}',
                  style: AppTextStyles.title3,
                ),
                _buildAppealStatusChip(appealData.status),
              ],
            ),
            const SizedBox(height: AppPadding.small),
            Text(
              'Причина: ${appealData.reasonCode.value}',
              style: AppTextStyles.body,
            ),
            if (appealData.reasonText.isNotEmpty) ...[
              const SizedBox(height: AppPadding.small),
              Text(
                appealData.reasonText,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppPadding.small),
            Text(
              'Создано: ${_formatDateTime(appealData.createdAt)}',
              style: AppTextStyles.caption,
            ),
            if (appeal.comments.isNotEmpty) ...[
              const SizedBox(height: AppPadding.normal),
              Text(
                'Комментарии (${appeal.comments.length})',
                style: AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppPadding.small),
              ...appeal.comments.map((comment) => Padding(
                    padding: const EdgeInsets.only(bottom: AppPadding.small),
                    child: Container(
                      padding: const EdgeInsets.all(AppPadding.small),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${comment.authorRole}: ${_formatDateTime(comment.createdAt)}',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.message,
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppealStatusChip(appealStatus) {
    Color color;
    switch (appealStatus.value) {
      case 'SUBMITTED':
        color = Colors.blue;
        break;
      case 'UNDER_REVIEW':
        color = Colors.orange;
        break;
      case 'NEED_INFO':
        color = Colors.yellow.shade700;
        break;
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      case 'CLOSED':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        appealStatus.value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}








