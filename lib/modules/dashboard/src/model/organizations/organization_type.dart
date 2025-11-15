enum OrganizationType { akimat, kguZkh, too, contractor }

extension OrganizationTypeX on OrganizationType {
  String get label {
    switch (this) {
      case OrganizationType.akimat:
        return 'AKIMAT';
      case OrganizationType.kguZkh:
        return 'KGU_ZKH';
      case OrganizationType.too:
        return 'TOO';
      case OrganizationType.contractor:
        return 'CONTRACTOR';
    }
  }
}

