enum UserRole {
  akimatAdmin,
  akimatUser,
  kguZkhAdmin,
  kguZkhUser,
  landfillAdmin, // Переименовано из tooAdmin, поддерживается старое значение TOO_ADMIN
  landfillUser,
  contractorAdmin,
  contractorUser,
  driver,
  unknown,
}

extension UserRoleMapper on UserRole {
  String get label {
    switch (this) {
      case UserRole.akimatAdmin:
        return 'AKIMAT_ADMIN';
      case UserRole.akimatUser:
        return 'AKIMAT_USER';
      case UserRole.kguZkhAdmin:
        return 'KGU_ZKH_ADMIN';
      case UserRole.kguZkhUser:
        return 'KGU_ZKH_USER';
      case UserRole.landfillAdmin:
        return 'LANDFILL_ADMIN';
      case UserRole.landfillUser:
        return 'LANDFILL_USER';
      case UserRole.contractorAdmin:
        return 'CONTRACTOR_ADMIN';
      case UserRole.contractorUser:
        return 'CONTRACTOR_USER';
      case UserRole.driver:
        return 'DRIVER';
      case UserRole.unknown:
        return 'UNKNOWN';
    }
  }
}

UserRole userRoleFromString(String? role) {
  switch (role) {
    case 'AKIMAT_ADMIN':
      return UserRole.akimatAdmin;
    case 'AKIMAT_USER':
      return UserRole.akimatUser;
    case 'KGU_ZKH_ADMIN':
      return UserRole.kguZkhAdmin;
    case 'KGU_ZKH_USER':
      return UserRole.kguZkhUser;
    case 'LANDFILL_ADMIN':
      return UserRole.landfillAdmin;
    case 'TOO_ADMIN': // Поддержка старого значения для обратной совместимости
      return UserRole.landfillAdmin;
    case 'LANDFILL_USER':
      return UserRole.landfillUser;
    case 'CONTRACTOR_ADMIN':
      return UserRole.contractorAdmin;
    case 'CONTRACTOR_USER':
      return UserRole.contractorUser;
    case 'DRIVER':
      return UserRole.driver;
    default:
      return UserRole.unknown;
  }
}

