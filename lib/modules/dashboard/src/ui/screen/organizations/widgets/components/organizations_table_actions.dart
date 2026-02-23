import 'package:flutter/material.dart';

class OrganizationsTableAction {
  const OrganizationsTableAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
}

class OrganizationsTableActions extends StatelessWidget {
  const OrganizationsTableActions({super.key, required this.actions});

  final List<OrganizationsTableAction> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions
          .map(
            (action) => OutlinedButton(
              style: action.isDestructive
                  ? OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    )
                  : null,
              onPressed: action.onPressed,
              child: Text(action.label),
            ),
          )
          .toList(),
    );
  }
}

