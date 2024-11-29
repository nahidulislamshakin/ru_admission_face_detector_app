import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Utils {
  BuildContext context;
  Utils({required this.context});

  void snack({required String message, required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12.sp,
                color: Colors.white
            ),
            maxLines: 2,
            softWrap: true,
          ),
        ),

        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 2),
        elevation: 10,
        showCloseIcon: true,
        behavior: SnackBarBehavior.floating,
        width: 300.w,

      ),
    );
  }
}
