import 'dart:io';

import 'package:ruadmission/view/camera_page.dart';
import 'package:ruadmission/view/otp_sending_page.dart';
import 'package:ruadmission/view_model/camera_page_view_model.dart';
import 'package:flutter/material.dart';

import 'package:face_camera/face_camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ruadmission/view_model/otp_sending_page_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  await SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
  ]);
  await FaceCamera.initialize();

  runApp( MyApp());
}

class MyApp extends StatelessWidget{

  @override
  Widget build(BuildContext context){
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return MultiProvider(
      providers:[
        ChangeNotifierProvider(
            create: (context)=> CameraPageViewModel() ),


        ChangeNotifierProvider(
            create: (context)=> OtpSendingPageViewModel() ),
      ],
      child: ScreenUtilInit(
        designSize: Size(deviceWidth,deviceHeight),
        minTextAdapt: true,
          splitScreenMode: false,
        builder:(context,child){
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title:"RU Admission",
            home: OtpSendingPage(),
            //CameraPage()
          );
        },
      )
    );
  }

}

