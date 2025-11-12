import 'package:akimat_project/services/organizations/collection/organizations_collection.dart';
import 'package:akimat_project/services/organizations/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final organizationsCollectionProvider =
    Provider<OrganizationsCollection>((ref) => OrganizationsCollection());

final organizationsServicesProvider = Provider<OrganizationsServices>((ref) {
  return OrganizationsServices(collection: ref.read(organizationsCollectionProvider));
});

