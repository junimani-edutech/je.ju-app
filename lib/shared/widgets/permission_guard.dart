import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../permissions/app_permission.dart';
import '../permissions/permission_provider.dart';

class PermissionGuard extends ConsumerWidget {
  final AppPermission permission; final Widget child; final Widget? fallback;
  const PermissionGuard({required this.permission, required this.child, this.fallback, super.key});
  @override Widget build(BuildContext context, WidgetRef ref) { 
    return ref.watch(canProvider(permission)) ? child : (fallback ?? const SizedBox.shrink()); 
  }
}
