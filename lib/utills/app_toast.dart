import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'app_font.dart';

class Utils{
  void showToast({
    required BuildContext context,
    required String title,
    required String message,
    bool isSuccess = true,
  }) {
    toastification.show(
      context: context,

      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: FontFamily.montserratBold,
        ),
      ),

      description: Text(
        message,
        style: TextStyle(
          color: Colors.black,
          fontFamily: FontFamily.montserratSemiBold,
        ),
      ),

      type: isSuccess
          ? ToastificationType.success
          : ToastificationType.error,

      style: ToastificationStyle.flatColored,

      autoCloseDuration: const Duration(seconds: 3),

      icon: Icon(
        isSuccess
            ? Icons.check_circle_outline
            : Icons.error_outline,
        color: Colors.black,
      ),

      showIcon: true,
      showProgressBar: false,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      borderRadius: BorderRadius.circular(12),
    );
  }
}