import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({
  required String label,
  VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return OutlinedButton.icon(
    onPressed: isLoading ? null : onPressed,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    icon: isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : const Icon(Icons.g_mobiledata_rounded, size: 28),
    label: Text(label),
  );
}
