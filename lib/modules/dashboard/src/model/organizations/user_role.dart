enum UserRole {
  akimatAdmin,
  kguZkhAdmin,
  tooAdmin,
  contractorAdmin,
  driver,
  unknown,
}

extension UserRoleMapper on UserRole {
  String get label {
    switch (this) {
      case UserRole.akimatAdmin:
        return 'AKIMAT_ADMIN';
      case UserRole.kguZkhAdmin:
        return 'KGU_ZKH_ADMIN';
      case UserRole.tooAdmin:
        return 'TOO_ADMIN';
      case UserRole.contractorAdmin:
        return 'CONTRACTOR_ADMIN';
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
    case 'KGU_ZKH_ADMIN':
      return UserRole.kguZkhAdmin;
    case 'TOO_ADMIN':
      return UserRole.tooAdmin;
    case 'CONTRACTOR_ADMIN':
      return UserRole.contractorAdmin;
    case 'DRIVER':
      return UserRole.driver;
    default:
      return UserRole.unknown;
  }
}

