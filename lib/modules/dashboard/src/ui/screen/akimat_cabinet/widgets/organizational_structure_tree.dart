import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_details_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationalStructureTree extends ConsumerWidget {
  const OrganizationalStructureTree({
    super.key,
    required this.data,
    required this.isSuperAdmin,
  });

  final OrganizationsData data;
  final bool isSuperAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Пытаемся найти организацию Акимата
    Organization? akimatOrg;
    try {
      akimatOrg = data.organizations.firstWhere(
        (org) => org.type == OrganizationType.akimat,
      );
    } catch (e) {
      // Акимат не найден - это нормально для KGU_ZKH_ADMIN
      akimatOrg = null;
    }

    // Если Акимат найден, строим дерево от него
    if (akimatOrg != null) {
      // Находим KGU_ZKH (дочерние организации Акимата)
      final kguOrgs = data.organizations.where(
        (org) => org.type == OrganizationType.kguZkh &&
            org.parentOrgId == akimatOrg!.id,
      ).toList();

      return SingleChildScrollView(
        child: _TreeNode(
          organization: akimatOrg!,
          level: 0,
          children: kguOrgs.map((kgu) => _buildKguNode(kgu, 1)).toList(),
          isSuperAdmin: isSuperAdmin,
        ),
      );
    }

    // Если Акимат не найден (для KGU_ZKH_ADMIN), строим дерево от KGU_ZKH
    final allKguOrgs = data.organizations.where(
      (org) => org.type == OrganizationType.kguZkh,
    ).toList();

    if (allKguOrgs.isEmpty) {
      return Center(
        child: Text(
          'Организации не найдены',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Если только одна KGU_ZKH, показываем её как корень
    if (allKguOrgs.length == 1) {
      return SingleChildScrollView(
        child: _buildKguNode(allKguOrgs.first, 0),
      );
    }

    // Если несколько KGU_ZKH, показываем их все
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: allKguOrgs.map((kgu) => _buildKguNode(kgu, 0)).toList(),
      ),
    );
  }

  _TreeNode _buildKguNode(Organization kgu, int kguLevel) {
    // Находим подрядчиков для этого KGU
    final contractors = data.organizations.where(
      (org) => org.type == OrganizationType.contractor &&
          org.parentOrgId == kgu.id,
    ).toList();

    // Находим полигоны для этого KGU
    final landfills = data.organizations.where(
      (org) => org.type == OrganizationType.too &&
          org.parentOrgId == kgu.id,
    ).toList();

    return _TreeNode(
      organization: kgu,
      level: kguLevel,
      children: [
        ...contractors.map((contractor) => _TreeNode(
              organization: contractor,
              level: kguLevel + 1,
              children: [],
              isSuperAdmin: isSuperAdmin,
            )),
        ...landfills.map((landfill) => _TreeNode(
              organization: landfill,
              level: kguLevel + 1,
              children: [],
              isSuperAdmin: isSuperAdmin,
            )),
      ],
      isSuperAdmin: isSuperAdmin,
    );
  }
}

class _TreeNode extends ConsumerWidget {
  const _TreeNode({
    required this.organization,
    required this.level,
    required this.children,
    this.isSuperAdmin = false,
  });

  final Organization organization;
  final int level;
  final List<_TreeNode> children;
  final bool isSuperAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasChildren = children.isNotEmpty;
    final indent = level * 32.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: indent),
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.normal,
            vertical: AppPadding.small,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSize.smallRadius),
            border: Border.all(
              color: AppColors.divider,
              width: 0.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              if (organization.type == OrganizationType.kguZkh && isSuperAdmin) {
                OrganizationsDetailsDialogs.showOrganizationDetails(
                  context: context,
                  organization: organization,
                  data: ref.read(organizationsControllerProvider).data.value!,
                );
              }
            },
            child: Row(
              children: [
                if (hasChildren)
                  Icon(
                    Icons.folder,
                    size: AppSize.iconSize,
                    color: AppColors.primary,
                  )
                else
                  Icon(
                    _getIconForType(organization.type),
                    size: AppSize.iconSize,
                    color: AppColors.textSecondary,
                  ),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        organization.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (organization.type == OrganizationType.kguZkh &&
                          isSuperAdmin)
                        Text(
                          'Нажмите для просмотра карточки',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasChildren)
                  Icon(
                    Icons.chevron_right,
                    size: AppSize.iconSize,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
        if (hasChildren) ...[
          const SizedBox(height: AppPadding.small),
          ...children,
        ],
      ],
    );
  }

  IconData _getIconForType(OrganizationType type) {
    switch (type) {
      case OrganizationType.akimat:
        return Icons.account_balance;
      case OrganizationType.kguZkh:
        return Icons.business;
      case OrganizationType.contractor:
        return Icons.local_shipping;
      case OrganizationType.too:
        return Icons.delete_outline;
    }
  }
}

