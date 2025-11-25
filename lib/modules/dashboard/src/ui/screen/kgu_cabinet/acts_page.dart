import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActsPage extends ConsumerStatefulWidget {
  const ActsPage({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  ConsumerState<ActsPage> createState() => _ActsPageState();
}

class _ActsPageState extends ConsumerState<ActsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final config = PlatformConfig.instance;

    return Container(
      margin: EdgeInsets.all(config.padding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(AppPadding.large),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppPadding.normal),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSize.smallRadius),
                  ),
                  child: Icon(
                    Icons.description,
                    color: AppColors.primary,
                    size: AppSize.iconSizeLarge,
                  ),
                ),
                const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Акты',
                        style: AppTextStyles.title1,
                      ),
                      const SizedBox(height: AppPadding.xs),
                      Text(
                        'Управление актами с подрядчиками и организациями приёма снега',
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Вкладки
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.local_shipping),
                  text: 'Подрядчики',
                ),
                Tab(
                  icon: Icon(Icons.delete_outline),
                  text: 'Приём снега (LANDFILL)',
                ),
              ],
            ),
          ),
          // Контент вкладок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Вкладка "Подрядчики"
                _ActsContractorsTab(),
                // Вкладка "Приём снега (LANDFILL)"
                _ActsLandfillsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActsContractorsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final s = S.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Акты с подрядчиками',
                  style: AppTextStyles.title2,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  // TODO: Открыть диалог создания акта с подрядчиком
                },
                icon: const Icon(Icons.add),
                label: const Text('Создать акт'),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.large),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
              child: Center(
                child: Text(
                  'Здесь будет список актов КГУ ↔ подрядчики:\nподрядчик, номер акта, период, объём, сумма, статус',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActsLandfillsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final s = S.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Акты с организациями приёма снега',
                  style: AppTextStyles.title2,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  // TODO: Открыть диалог создания акта с LANDFILL
                },
                icon: const Icon(Icons.add),
                label: const Text('Создать акт'),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.large),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
              child: Center(
                child: Text(
                  'Здесь будет список актов КГУ ↔ операторы полигонов:\nLANDFILL, номер акта, период, общий объём м³, сумма, статус',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
