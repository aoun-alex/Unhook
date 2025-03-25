import 'package:flutter/material.dart';

class SettingsNavigationTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool enabled;

  const SettingsNavigationTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    required this.onTap,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        enabled: enabled,
        leading: icon != null
            ? Icon(
          icon,
          color: iconColor ?? Colors.tealAccent,
        )
            : null,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle!,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        )
            : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}