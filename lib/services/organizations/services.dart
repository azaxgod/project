import 'package:akimat_project/services/organizations/collection/organizations_collection.dart';
import 'package:akimat_project/services/organizations/collection/roles_collection.dart';

class OrganizationsServices {
  const OrganizationsServices({
    required this.collection,
    required this.rolesCollection,
  });

  final OrganizationsCollection collection;
  final RolesCollection rolesCollection;
}

