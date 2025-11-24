import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет для отображения роли пользователя на вебе
class UserRoleBadge extends ConsumerWidget {
  const UserRoleBadge({super.key});

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.akimatAdmin:
        return 'Акимат';
      case UserRole.akimatUser:
        return 'Акимат (пользователь)';
      case UserRole.kguZkhAdmin:
        return 'KGU ZKH';
      case UserRole.kguZkhUser:
        return 'KGU ZKH (пользователь)';
      case UserRole.landfillAdmin:
        return 'LANDFILL';
      case UserRole.landfillUser:
        return 'LANDFILL (пользователь)';
      case UserRole.contractorAdmin:
        return 'Подрядчик';
      case UserRole.contractorUser:
        return 'Подрядчик (пользователь)';
      case UserRole.driver:
        return 'Водитель';
      case UserRole.unknown:
        return 'Неизвестно';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.akimatAdmin:
      case UserRole.akimatUser:
        return Colors.blue;
      case UserRole.kguZkhAdmin:
      case UserRole.kguZkhUser:
        return Colors.green;
      case UserRole.landfillAdmin:
      case UserRole.landfillUser:
        return Colors.orange;
      case UserRole.contractorAdmin:
      case UserRole.contractorUser:
        return Colors.purple;
      case UserRole.driver:
        return Colors.teal;
      case UserRole.unknown:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.akimatAdmin:
      case UserRole.akimatUser:
        return Icons.admin_panel_settings;
      case UserRole.kguZkhAdmin:
      case UserRole.kguZkhUser:
        return Icons.business;
      case UserRole.landfillAdmin:
      case UserRole.landfillUser:
        return Icons.engineering;
      case UserRole.contractorAdmin:
      case UserRole.contractorUser:
        return Icons.business_center;
      case UserRole.driver:
        return Icons.drive_eta;
      case UserRole.unknown:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    
    if (user == null) {
      return const SizedBox.shrink();
    }

    final role = userRoleFromString(user.role);
    final roleLabel = _getRoleLabel(role);
    final roleColor = _getRoleColor(role);
    final roleIcon = _getRoleIcon(role);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.normal,
        vertical: AppPadding.small,
      ),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSize.buttonRadius),
        border: Border.all(
          color: roleColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roleIcon,
            size: 18,
            color: roleColor,
          ),
          const SizedBox(width: AppPadding.small),
          Text(
            roleLabel,
            style: TextStyle(
              color: roleColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

