import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/locale/language_switcher.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/generated/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/organizations_tabs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationsPage extends ConsumerWidget {
  const OrganizationsPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale to ensure rebuild when language changes
    ref.watch(localeProvider);
    final s = S.of(context);
    final state = ref.watch(organizationsControllerProvider);
    final controller = ref.watch(organizationsControllerProvider.notifier);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.role_management),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: NavbarWidgetsProvider.combineMobileWidgets(
                context,
                mobileNavbarWidgets,
              ),
            ),
      body: Column(
        children: [
          if (kIsWeb)
            HeaderNavbar(
              webWidgets: webNavbarWidgets,
            ),
          Expanded(
            child: state.data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => OrganizationsErrorState(
                message: s.failed_to_load_data(error),
                onRetry: controller.refresh,
              ),
              data: (data) {
                if (state.role == UserRole.driver || state.role == UserRole.tooAdmin) {
                  return _ForbiddenOrganizationsPage(
                    scaffoldKey: scaffoldKey,
                    webNavbarWidgets: webNavbarWidgets,
                    mobileNavbarWidgets: mobileNavbarWidgets,
                  );
                }

                return OrganizationsTabs(
                  config: config,
                  state: state,
                  data: data,
                  controller: controller,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ForbiddenOrganizationsPage extends StatelessWidget {
  const _ForbiddenOrganizationsPage({
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      key: scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.insufficient_permissions),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: NavbarWidgetsProvider.combineMobileWidgets(
                context,
                mobileNavbarWidgets,
              ),
            ),
      body: Column(
        children: [
          if (kIsWeb)
            HeaderNavbar(
              webWidgets: webNavbarWidgets,
            ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    s.insufficient_permissions,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.insufficient_permissions_message,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

