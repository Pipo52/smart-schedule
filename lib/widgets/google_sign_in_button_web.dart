import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_sign_in_web;

Widget buildGoogleSignInButton({
  required String label,
  VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return SizedBox(
    height: 52,
    child: google_sign_in_web.renderButton(
      configuration: google_sign_in_web.GSIButtonConfiguration(
        type: google_sign_in_web.GSIButtonType.standard,
        theme: google_sign_in_web.GSIButtonTheme.outline,
        size: google_sign_in_web.GSIButtonSize.large,
        text: google_sign_in_web.GSIButtonText.signinWith,
        shape: google_sign_in_web.GSIButtonShape.pill,
        minimumWidth: 320,
      ),
    ),
  );
}
