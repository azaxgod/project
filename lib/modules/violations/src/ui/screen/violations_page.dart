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
import 'package:akimat_project/modules/violations/src/ui/screen/violation_detail_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ViolationsPage extends ConsumerStatefulWidget {
  const ViolationsPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<ViolationsPage> createState() => _ViolationsPageState();
}

class _ViolationsPageState extends ConsumerState<ViolationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(violationsControllerProvider.notifier).loadViolations();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final state = ref.watch(violationsControllerProvider);
    final controller = ref.read(violationsControllerProvider.notifier);

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
            child: state.violations?.when(
              data: (data) => _buildViolationsList(data, controller),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка загрузки данных: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadViolations(),
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

  Widget _buildViolationsList(data, ViolationsController controller) {
    final violations = data.data;
    
    if (violations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Нарушений не найдено',
              style: AppTextStyles.title2.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(PlatformConfig.instance.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Нарушения',
            style: AppTextStyles.title1,
          ),
          const SizedBox(height: AppPadding.normal),
          ...violations.map((record) => _buildViolationCard(context, record)),
        ],
      ),
    );
  }

  Widget _buildViolationCard(BuildContext context, record) {
    final violation = record.violation;
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.normal),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
      ),
      child: InkWell(
        onTap: () {
          // Переход на детальную страницу нарушения
          context.push('/violations/${violation.id}');
        },
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
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
            const SizedBox(height: AppPadding.small),
            if (violation.description != null) ...[
              Text(
                violation.description!,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppPadding.small),
            ],
            Row(
              children: [
                _buildInfoChip('Серьезность', violation.severity.value),
                const SizedBox(width: AppPadding.small),
                _buildInfoChip('Обнаружено', violation.detectedBy.value),
              ],
            ),
            if (record.driver != null || record.vehicle != null) ...[
              const SizedBox(height: AppPadding.small),
              Row(
                children: [
                  if (record.driver != null)
                    Text(
                      'Водитель: ${record.driver!.fullName}',
                      style: AppTextStyles.caption,
                    ),
                  if (record.vehicle != null) ...[
                    const SizedBox(width: AppPadding.normal),
                    Text(
                      'Машина: ${record.vehicle!.plateNumber}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            ],
            if (record.hasActiveAppeal) ...[
              const SizedBox(height: AppPadding.small),
              Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gavel, size: 16, color: Colors.blue),
                    const SizedBox(width: AppPadding.small),
                    Text(
                      'Есть активная апелляция',
                      style: AppTextStyles.caption.copyWith(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(status) {
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

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption,
      ),
    );
  }
}

