import 'package:face_camera/face_camera.dart';
import 'package:ruadmission/view_model/camera_page_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../utils/utils.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // File? _capturedImage;
  //
  // late FaceCameraController controller;
  // bool _faceDetected = false;
  //
  // @override
  // void initState() {
  //   controller = FaceCameraController(
  //     autoCapture: true,
  //     defaultCameraLens: CameraLens.front,
  //     onCapture: (File? image) {
  //       setState(() => _capturedImage = image);
  //     },
  //     onFaceDetected: (Face? face) {
  //       print('Face detected: ${face}');
  //       setState(() {
  //         _faceDetected = face != null;
  //       });
  //     },
  //
  //   );
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {


    final cameraProvider = Provider.of<CameraPageViewModel>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          backgroundColor: Colors.deepPurple.shade50,
          appBar: AppBar(
            backgroundColor: Colors.deepPurple.shade100,
            centerTitle: true,
            title: const Text('Rajshahi University Admission face recognition',
              style: TextStyle(fontSize: 15,fontWeight: FontWeight.normal),maxLines: 2,softWrap: true,),
          ),
          body: SafeArea(
            child: Builder(builder: (context) {
              if (cameraProvider.capturedImage != null) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                    //  alignment: Alignment.bottomCenter,
                      children: [
                        Center(
                          child: Transform.scale(
                            scale: 0.9,
                            child: Image.file(
                              cameraProvider.capturedImage!,
                            //  width: double.maxFinite,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            const SizedBox(width: 5,),
                            Expanded(
                              child: ElevatedButton(
                                  onPressed: ()  {
                                    cameraProvider.startImageStream();
                                  },
                                  child:  Text(
                                    'Capture Again',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14.sp, fontWeight: FontWeight.w700),
                                  ),),
                            ),

                            const SizedBox(width: 10,),
                         //   if(cameraProvider.canSubmit==true)
                            Expanded(
                              child: ElevatedButton(
                                  onPressed: ()  {
                                    Utils(context: context).snack(message: "No API to Submit", backgroundColor: Colors.red);

                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: const Text(
                                    'Submit',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700,color: Colors.white),
                                  )),
                            ),
                            const SizedBox(width: 5,),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }
              return Stack(
                children: [
                  SmartFaceCamera(
                      showCaptureControl: false,
                      controller: cameraProvider.controller,
                      messageBuilder: (context, face) {
                        // if (face == null) {
                        //   return _message('Place your face in the camera');
                        // }
                        if (face == null || !face.wellPositioned || !cameraProvider.isFaceWithinBox(cameraProvider.faceBox!)) {
                          return _message('Center your face in the square and hold the camera for 5 seconds');
                        }
                        return _message("Hold the camera for 5 seconds, Capturing...");
                      }),
                  if (cameraProvider.definedBox != null)
                    Positioned(
                      left: cameraProvider.definedBox!.left,
                      top: cameraProvider.definedBox!.top,
                      child: Container(
                        width: cameraProvider.definedBox!.width,
                        height: cameraProvider.definedBox!.height,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                      ),
                    ),
                ],
              );
            }),
          )),
    );
  }

  Widget _message(String msg) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
    child: Text(msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red,
            fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
  );

  // @override
  // void dispose() {
  //   controller.dispose();
  //   super.dispose();
  // }
}