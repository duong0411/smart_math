import 'package:flutter/material.dart';

abstract final class AppToast {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static void error(String message) => _show(
        message,
        backgroundColor: const Color(0xFFB3261E),
      );

  static void success(String message) => _show(
        message,
        backgroundColor: const Color(0xFF0F766E),
      );

  static void info(String message) => _show(
        message,
        backgroundColor: const Color(0xFF334155),
      );

  static void _show(String message, {required Color backgroundColor}) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
