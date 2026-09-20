import 'package:flutter/material.dart';

import 'google_sign_in_button_io.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart';

/// Platform Google Sign-In control.
///
/// Web uses GIS `renderButton` (custom `authenticate()` is unsupported).
/// Other platforms use an outlined button that starts `authenticate()`.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return buildGoogleSignInButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}
