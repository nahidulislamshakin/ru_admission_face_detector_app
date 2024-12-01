import 'package:flutter/material.dart';
import 'package:face_camera/face_camera.dart';
import 'package:provider/provider.dart';
import 'package:ruadmission/view_model/camera_page_view_model.dart';


class GetWidgetDimensionPage extends StatelessWidget{
  Size? cameraWidgetSize;


  @override
  Widget build(BuildContext context) {

    final cameraProvider = Provider.of<CameraPageViewModel>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        cameraWidgetSize = Size(constraints.maxWidth, constraints.maxHeight);
        print("Camera Widget Size: $cameraWidgetSize");
return SmartFaceCamera(controller: cameraProvider.controller);
      //  return FaceCameraPreview();
      },
    );
  }

}