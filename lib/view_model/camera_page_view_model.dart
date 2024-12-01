import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:ruadmission/models/image_send_model.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;

class CameraPageViewModel with ChangeNotifier {
  File? _capturedImage;
  File? get capturedImage => _capturedImage;
  File? _croppedImage;

  late FaceCameraController controller;
  bool _faceDetected = false;
  Face? _detectedFace;

bool _canSubmit = true;
bool get canSubmit => _canSubmit;

  Rect? _definedBox; // The box where the face should be positioned
  Rect? get definedBox => _definedBox; // Expose the box for UI drawing
  Rect? faceBox;

  bool isImageSent = false;



  Future<void> sendImage( String? mobile, String? token) async {
    try{

      var img = json.encode({
        "image":base64Image.toString(),
        "mobile":mobile.toString(),
        "token" : token.toString(),
      });
      print(img);
      final response = await http.post(
          Uri.parse('https://aad.ru.ac.bd/api/save-selfie'),
          headers: {
            'Content-Type': 'application/json', // Specify JSON content
            'Authorization': 'Bearer NO7pAwK1Fl',
            'Accept':'*/*'
          },
          body: img
      );

      if(response.statusCode == 200){
        var jsonResponse = json.decode(response.body);
        print("Response after sending image: ${response.body.toString()}");
        ImageSendModel imageSendModel = ImageSendModel.fromJson(jsonResponse);
        if(imageSendModel.statusCode == 200){
          isImageSent = true;
        }


      }

    }catch(error){
      print(error);
    }

  }

  String? base64Image;
  void convertToBase64()async{
    final File photoFile = File(_capturedImage!.path);
    // Convert to Base64
    final List<int> imageBytes = await photoFile.readAsBytes();
     base64Image = base64Encode(imageBytes);
  }

  CameraPageViewModel() {
    _clearCacheOnStartup();
    controller = FaceCameraController(
      autoCapture: false,
      defaultCameraLens: CameraLens.front,
      onCapture: (File? image) async {
        if(image!=null && _detectedFace != null){
          // Remove previously captured image
          if (_capturedImage != null && _capturedImage!.existsSync()) {
            _capturedImage!.deleteSync();
          }
          File? croppedImage = await _cropFace(image, _detectedFace!.boundingBox);
          _croppedImage = croppedImage;
          _capturedImage = _croppedImage;
          notifyListeners();
          convertToBase64();

        }

      },

      onFaceDetected: (Face? face) {

        _detectedFace = face;

        _faceDetected = face != null;

        if (_faceDetected) {
          // Debugging: Log bounding boxes and face center
           faceBox = face?.boundingBox;
          Offset faceCenter = Offset(
            faceBox!.left + faceBox!.width / 2,
            faceBox!.top + faceBox!.height / 2,
          );

          print("Face Box: $faceBox");
          print("Defined Box: $_definedBox");
          print("Face Center: $faceCenter");

          if (isFaceWithinBox(faceBox!)) {
            print("Face is within the box. Attempting to capture.");

            if(_isCapturing){
              return;
            }
            _captureIfReady();
          } else {
            print("Face is outside the defined box.");
          }
        }


        notifyListeners();


      },
    );

    _defineBox();
  }

  Future<void> _clearCacheOnStartup() async {
    await clearAppCache();
  }

  void releaseMemory() {
    _capturedImage = null;
    _croppedImage = null;
    notifyListeners();
  }

  Future<void> clearAppCache() async {
    final cacheDir = await getTemporaryDirectory();
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
  }

  Rect _adjustBoundingBox(Rect faceBox, Size cameraSize, Size screenSize) {
    // Calculate scaling factors
    double scaleX = screenSize.width / cameraSize.width;
    double scaleY = screenSize.height / cameraSize.height;

    // Adjust the face box to the screen size
    double left = faceBox.left * scaleX;
    double top = faceBox.top * scaleY;
    double width = faceBox.width * scaleX;
    double height = faceBox.height * scaleY;

    return Rect.fromLTWH(left, top, width, height);
  }

  void _defineBox() {
    // Example box (centered on screen)
    double boxWidth = 350.w; // Box width
    double boxHeight = 450.h; // Box height
    double boxLeft = 5.w; // X-coordinate
    double boxTop = 150.h; // Y-coordinate

    _definedBox = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);
  }

  // Size calculateImageSize(Size widgetSize, double aspectRatio) {
  //   // Match the shorter dimension to maintain aspect ratio
  //   double imageWidth = widgetSize.width;
  //   double imageHeight = imageWidth / aspectRatio;
  //
  //   if (imageHeight > widgetSize.height) {
  //     imageHeight = widgetSize.height;
  //     imageWidth = imageHeight * aspectRatio;
  //   }
  //
  //   return Size(imageWidth, imageHeight);
  // }

  // Offset calculateImageOffset(Size widgetSize, Size imageSize) {
  //   double offsetX = (widgetSize.width - imageSize.width) / 2;
  //   double offsetY = (widgetSize.height - imageSize.height) / 2;
  //   return Offset(offsetX, offsetY);
  // }
  // Offset calculateImageOffset(Size widgetSize, Size imageSize) {
  //   double offsetX = (widgetSize.width - imageSize.width) / 2;
  //   double offsetY = (widgetSize.height - imageSize.height) / 2;
  //   return Offset(offsetX, offsetY);
  // }
  // Offset calculateImageOffset(Size cameraSize, Size widgetSize) {
  //   double offsetX = (widgetSize.width - cameraSize.width * calculateScaleFactors(cameraSize, widgetSize).width) / 2;
  //   double offsetY = (widgetSize.height - cameraSize.height * calculateScaleFactors(cameraSize, widgetSize).height) / 2;
  //   return Offset(offsetX, offsetY);
  // }
  Offset calculateImageOffset(Size cameraSize, Size widgetSize, Size scaleFactors) {
    double offsetX = (widgetSize.width - cameraSize.width * scaleFactors.width) / 2;
    double offsetY = (widgetSize.height - cameraSize.height * scaleFactors.height) / 2;
    return Offset(offsetX, offsetY);
  }



  // Size calculateImageSize(Size widgetSize, double aspectRatio) {
  //   double imageWidth = widgetSize.width;
  //   double imageHeight = imageWidth / aspectRatio;
  //
  //   if (imageHeight > widgetSize.height) {
  //     imageHeight = widgetSize.height;
  //     imageWidth = imageHeight * aspectRatio;
  //   }
  //
  //   return Size(imageWidth, imageHeight);
  // }



  // Rect transformBoundingBox(Rect boundingBox, Size imageSize, Size widgetSize, Offset imageOffset) {
  //   double scaleX = imageSize.width / widgetSize.width;
  //   double scaleY = imageSize.height / widgetSize.height;
  //
  //   return Rect.fromLTRB(
  //     (boundingBox.left * scaleX) + imageOffset.dx,
  //     (boundingBox.top * scaleY) + imageOffset.dy,
  //     (boundingBox.right * scaleX) + imageOffset.dx,
  //     (boundingBox.bottom * scaleY) + imageOffset.dy,
  //   );
  // }

  // Rect transformBoundingBox(Rect boundingBox, Size imageSize, Size widgetSize, Offset imageOffset) {
  //   // Calculate the scaling factors for both X and Y directions
  //   double scaleX = imageSize.width / widgetSize.width;
  //   double scaleY = imageSize.height / widgetSize.height;
  //
  //   // Transform the coordinates
  //   double left = (boundingBox.left * scaleX) + imageOffset.dx;
  //   double top = (boundingBox.top * scaleY) + imageOffset.dy;
  //   double right = (boundingBox.right * scaleX) + imageOffset.dx;
  //   double bottom = (boundingBox.bottom * scaleY) + imageOffset.dy;
  //
  //   return Rect.fromLTRB(left, top, right, bottom);
  // }
  // Rect transformBoundingBox(Rect faceBox, Size scaleFactors, Offset imageOffset) {
  //   double left = faceBox.left * scaleFactors.width + imageOffset.dx;
  //   double top = faceBox.top * scaleFactors.height + imageOffset.dy;
  //   double right = faceBox.right * scaleFactors.width + imageOffset.dx;
  //   double bottom = faceBox.bottom * scaleFactors.height + imageOffset.dy;
  //
  //   return Rect.fromLTRB(left, top, right, bottom);
  // }







  // Size calculateScaleFactors(Size cameraSize, Size widgetSize) {
  //   double scaleX = widgetSize.width / cameraSize.width;
  //   double scaleY = widgetSize.height / cameraSize.height;
  //   return Size(scaleX, scaleY);
  // }

  bool isFaceWithinBox(Rect faceBox) {
    if (_definedBox == null || _detectedFace == null) return false;


    // Size imageSize = calculateImageSize(Size(360.0, 788.0), 16/9);
    // print("Assumed Image Size: $imageSize");
    // Size scaleFactors = calculateScaleFactors(imageSize, Size(360.0,788.0));
    // Offset imageOffset = calculateImageOffset(Size(360.0,788.0), imageSize, scaleFactors);
    // print("Image Offset: $imageOffset");

    // Example usage
  //  Rect transformedBox = transformBoundingBox(faceBox, imageSize, Size(360.0,788.0), imageOffset);


  //  Rect transformedFaceBox = transformBoundingBox(faceBox, scaleFactors, imageOffset);

   // print("Transformed Face Box: $transformedBox");
    // Check if the face is fully within the defined box
    // bool allCornersInside = _definedBox!.contains(Offset(transformedBox.left, transformedBox.top)) &&
    //     _definedBox!.contains(Offset(transformedBox.right, transformedBox.top)) &&
    //     _definedBox!.contains(Offset(transformedBox.left, transformedBox.bottom)) &&
    //     _definedBox!.contains(Offset(transformedBox.right, transformedBox.bottom));
    // Check if all corners of the transformed face bounding box are inside the defined box
    // bool allCornersInside = _definedBox!.contains(Offset(transformedFaceBox.left, transformedFaceBox.top)) &&
    //     _definedBox!.contains(Offset(transformedFaceBox.right, transformedFaceBox.top)) &&
    //     _definedBox!.contains(Offset(transformedFaceBox.left, transformedFaceBox.bottom)) &&
    //     _definedBox!.contains(Offset(transformedFaceBox.right, transformedFaceBox.bottom));

    // Debugging: Log the transformed face box and defined box information
    // print("Transformed Face Box: $transformedFaceBox");
    // print("Defined Box: $_definedBox");
    //
    // if (allCornersInside) {
    //   print("Face is fully inside the defined box after transforming.");
    // } else {
    //   print("After calculate: ");
    //   //  print("Face Box is not fully inside the Defined Box.");
    //     print("Face Box: $faceBox");
    //     print("Defined Box: $_definedBox!");
    //     print("Top-Left Inside: ${_definedBox!.contains(Offset(faceBox.left, faceBox.top))}");
    //     print("Top-Right Inside: ${_definedBox!.contains(Offset(faceBox.right, faceBox.top))}");
    //     print("Bottom-Left Inside: ${_definedBox!.contains(Offset(faceBox.left, faceBox.bottom))}");
    //     print("Bottom-Right Inside: ${_definedBox!.contains(Offset(faceBox.right, faceBox.bottom))}");
    //   print("Face is NOT fully inside the defined box transforming.");
    // }









    // Calculate the center of the face bounding box
    Offset faceCenter = Offset(
      faceBox.left + faceBox.width / 2,
      faceBox.top + faceBox.height / 2,
    );
    bool isCenterInsideBox = _definedBox!.contains(faceCenter);

    if (isCenterInsideBox) {
      print("Face center is inside the defined box.");
    } else {
      print("Face center is not inside the defined box.");
    }

    double margin = 8.0;

  //  Rect? expandedBox
    // Expand the defined box by a margin
    //  expandedBox = Rect.fromLTRB(
    //   _definedBox!.left - margin,
    //   _definedBox!.top - margin,
    //   _definedBox!.right + margin,
    //   _definedBox!.bottom + margin,
    // );
    // Check if all corners of the face bounding box are inside the expanded box
    bool allCornersInside = _definedBox!.contains(Offset(faceBox.left, faceBox.top)) &&
        _definedBox!.contains(Offset(faceBox.right, faceBox.top)) &&
        _definedBox!.contains(Offset(faceBox.left, faceBox.bottom)) &&
        _definedBox!.contains(Offset(faceBox.right, faceBox.bottom));

    // // Debugging: Log the results
    if (!allCornersInside) {
      print("Face Box is not fully inside the Defined Box.");
      print("Face Box: $faceBox");
      print("Defined Box: $_definedBox!");
      print("Top-Left Inside: ${_definedBox!.contains(Offset(faceBox.left, faceBox.top))}");
      print("Top-Right Inside: ${_definedBox!.contains(Offset(faceBox.right, faceBox.top))}");
      print("Bottom-Left Inside: ${_definedBox!.contains(Offset(faceBox.left, faceBox.bottom))}");
      print("Bottom-Right Inside: ${_definedBox!.contains(Offset(faceBox.right, faceBox.bottom))}");
    }

    // Check if the face center is within the defined box
    bool isInsideBox = _definedBox!.contains(Offset(faceBox.left, faceBox.top)) &&
        _definedBox!.contains(Offset(faceBox.right, faceBox.bottom));




  //  final double margin = 5.0;
    // bool isFaceFullyInsideBox =
    //     faceBox.left >= _definedBox!.left  &&
    //         faceBox.top >= _definedBox!.top  &&
    //         faceBox.right <= _definedBox!.right  &&
    //         faceBox.bottom <= _definedBox!.bottom ;
    //
    // if (isFaceFullyInsideBox) {
    //   print("Face is fully inside the defined box.");
    // } else {
    //   print("Face is NOT fully inside the defined box.");
    // }

    if(isInsideBox){
      print("face is in the defined box.");
      print("Defined Box: $_definedBox");
      print("Face Box: $faceBox");
    }
    else{
      print("face is not in the defined box.");
      print("Defined Box: $_definedBox");
      print("Face Box: $faceBox");
    }


    // Validate face orientation
    double yaw = _detectedFace!.headEulerAngleY ?? 0.0; // Yaw (side-to-side)
    double roll = _detectedFace!.headEulerAngleZ ?? 0.0; // Roll (tilt)

    bool isProperlyOriented = yaw.abs() < 15 && roll.abs() < 15; // Allow small deviation

    if(isProperlyOriented){
      print("Ready to capture");
    }
    else{
      print("Not ready to capture");
    }
    return isInsideBox && isProperlyOriented;
  }



  // bool isFaceWithinBox(Rect faceBox) {
  //   if (_definedBox == null) return false;
  //
  //   // Check if the entire face bounding box is inside the defined box
  //   return _definedBox!.contains(Offset(faceBox.left, faceBox.top)) &&
  //       _definedBox!.contains(Offset(faceBox.right, faceBox.bottom));
  // }


  bool _isCapturing = false;

  DateTime? _lastCaptureTime; // Track the time of the last capture

  void _captureIfReady() async {
    if (_isCapturing) return; // Prevent re-entry during an active capture

    final now = DateTime.now();
    if (_lastCaptureTime != null &&
        now.difference(_lastCaptureTime!).inSeconds < 3) {
      return; // Skip if last capture was within the cooldown period
    }

    if (_faceDetected && isFaceWithinBox(_detectedFace!.boundingBox)) {
      _isCapturing = true;
      _lastCaptureTime = now; // Update the last capture time
      notifyListeners();

      try {
        // Delay for user interaction (5 seconds)
        await Future.delayed(const Duration(seconds: 1));

        // Re-check face position before capturing
        if (_faceDetected && isFaceWithinBox(_detectedFace!.boundingBox)) {
          controller.captureImage(); // Capture only if face is still in the box
          print("Image captured successfully.");
        } else {
          print("Capture aborted - Face moved outside the box.");
        }

        // Capture the image
      //  controller.captureImage();

        // Log face data for debugging
        print("Left eye: ${_detectedFace!.leftEyeOpenProbability}");
        print("Tracking ID: ${_detectedFace!.trackingId}");
      } catch (e) {
        print("Error during capture: $e");
      } finally {
        // Ensure lock is released after capture
        _isCapturing = false;
        notifyListeners();
      }
    }
  }



  // void canSubmitToApi(){
  //   if(_detectedFace!=null){
  //     double leftEyeOpen = _detectedFace!.leftEyeOpenProbability ?? 0.0;
  //     double rightEyeOpen = _detectedFace!.rightEyeOpenProbability ?? 0.0;
  //     // Define a threshold to determine if an eye is considered "open"
  //     print("Left eye : ${_detectedFace!.leftEyeOpenProbability}");
  //     print("Right eye : ${_detectedFace!.rightEyeOpenProbability}");
  //     double openThreshold = 0.1; // Adjust this threshold as needed
  //     if(leftEyeOpen < openThreshold || rightEyeOpen < openThreshold){
  //       _canSubmit = false;
  //       notifyListeners();
  //     }
  //     else{
  //       _canSubmit = true;
  //       notifyListeners();
  //     }
  //   }
  //   else {
  //     // If no face is detected, cannot submit
  //     _canSubmit = false;
  //     notifyListeners();
  //   }
  // }




  //Croping the captured image by detecting the face area in the image
  Future<File?> _cropFace(File originalImage, Rect boundingBox) async {
    try {

      print("Bounding Box: Left=${boundingBox.left}, Top=${boundingBox.top}, Width=${boundingBox.width}, Height=${boundingBox.height}");


      // Load the image as a Uint8List
      Uint8List imageBytes = (await originalImage.readAsBytes());

      // Decode the image using the `image` package
      img.Image? decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) return null;

      // // Scale the bounding box to match the actual image resolution
      // int cropX = (boundingBox.left * decodedImage.width).toInt();
      // int cropY = (boundingBox.top * decodedImage.height).toInt();
      // int cropWidth = (boundingBox.width * decodedImage.width).toInt();
      // int cropHeight = (boundingBox.height * decodedImage.height).toInt();

      // Ensure the cropping dimensions are within the image boundaries
      // cropX = cropX.clamp(0, decodedImage.width - 1);
      // cropY = cropY.clamp(0, decodedImage.height - 1);
      // cropWidth = cropWidth.clamp(0, decodedImage.width - cropX);
      // cropHeight = cropHeight.clamp(0, decodedImage.height - cropY);
//
//       // Define the extra space above the hair (e.g., 20% of the bounding box height)
//       double paddingPercentage = 0.8;
//       int extraPadding = (boundingBox.height * paddingPercentage).toInt();
//
//       int cropX = boundingBox.left.toInt();
// // Adjust the cropY to move upwards
//       int cropY = (boundingBox.top - extraPadding).toInt();
//
// // Clamp cropY to ensure it stays within the image bounds
//       cropY = cropY.clamp(0, decodedImage.height - 1);
//
//       int cropWidth = boundingBox.width.toInt();
// // Optionally increase the cropHeight to include the extra space
//       int cropHeight = (boundingBox.height + extraPadding).toInt();
//
// // Clamp cropHeight to ensure it does not exceed image boundaries
//       cropHeight = cropHeight.clamp(1, decodedImage.height - cropY);
//
//
//       // Fallback if bounding box dimensions are invalid
//       if (cropWidth < 10 || cropHeight < 10) {
//         print("Warning: Bounding box too small, using fallback crop.");
//         cropX = (decodedImage.width * 0.25).toInt();
//         cropY = (decodedImage.height * 0.25).toInt();
//         cropWidth = (decodedImage.width * 0.5).toInt();
//         cropHeight = (decodedImage.height * 0.5).toInt();
//       }




//       // Define the extra space above the hair (e.g., 80% of the bounding box height)
//       double paddingPercentage = 0.8;
//       int extraPadding = (boundingBox.height * paddingPercentage).toInt();
//
//       int cropX = boundingBox.left.toInt();
// // Move upwards to include extra space above the head
//       int cropY = (boundingBox.top - extraPadding).toInt();
//
// // Add horizontal padding symmetrically to ensure balance
//       int horizontalPadding = (boundingBox.width * 0.2).toInt(); // 20% of the width
//       cropX = (cropX - horizontalPadding).clamp(0, decodedImage.width - 1);
//
// // Adjust cropWidth and cropHeight to include the extra space
//       int cropWidth = (boundingBox.width + 2 * horizontalPadding).toInt();
//       int cropHeight = (boundingBox.height + extraPadding).toInt();
//
// // Ensure cropHeight does not exceed image boundaries
//       cropY = cropY.clamp(0, decodedImage.height - 1);
//       cropHeight = cropHeight.clamp(1, decodedImage.height - cropY);
//
// // Ensure cropWidth does not exceed image boundaries
//       cropWidth = cropWidth.clamp(1, decodedImage.width - cropX);
//
// // Fallback if bounding box dimensions are invalid
//       if (cropWidth < 10 || cropHeight < 10) {
//         print("Warning: Bounding box too small, using fallback crop.");
//         cropX = (decodedImage.width * 0.25).toInt();
//         cropY = (decodedImage.height * 0.25).toInt();
//         cropWidth = (decodedImage.width * 0.5).toInt();
//         cropHeight = (decodedImage.height * 0.5).toInt();
//       }
//
// // Debugging: Print final crop values
//       print("Final Crop X: $cropX, Crop Y: $cropY, Crop Width: $cropWidth, Crop Height: $cropHeight");
//       print("Image Width: ${decodedImage.width}, Image Height: ${decodedImage.height}");
//
//       // Debugging: Print final crop values
//       print("Final Crop X: $cropX, Crop Y: $cropY, Crop Width: $cropWidth, Crop Height: $cropHeight");
//       print("Crop X: $cropX, Crop Y: $cropY, Crop Width: $cropWidth, Crop Height: $cropHeight");
//       print("Image Width: ${decodedImage.width}, Image Height: ${decodedImage.height}");
//
//
//       print("Left eye : ${_detectedFace!.leftEyeOpenProbability}");
//       print("Right eye : ${_detectedFace!.rightEyeOpenProbability}");
//
//       // Crop the image
//       img.Image croppedImage = img.copyCrop(decodedImage,
//           x: cropX, y: cropY, width: cropWidth, height: cropHeight);

      // Fixed crop dimensions
      const int targetWidth = 450;
      const int targetHeight = 550;

// Calculate the center of the face bounding box
      int faceCenterX = (boundingBox.left + boundingBox.width / 2).toInt();
      int faceTopY = boundingBox.top.toInt();

// Adjust cropY to include more space above the face
      int cropX = (faceCenterX - targetWidth / 2).toInt();
      int cropY = (faceTopY - (targetHeight * 0.3).toInt()).toInt(); // Shift up by 30% of the crop height

// Clamp cropY to ensure it stays within image bounds
      cropX = cropX.clamp(0, decodedImage.width - targetWidth);
      cropY = cropY.clamp(0, decodedImage.height - targetHeight);

// Ensure the crop dimensions stay fixed
      int cropWidth = targetWidth.clamp(1, decodedImage.width - cropX);
      int cropHeight = targetHeight.clamp(1, decodedImage.height - cropY);

// Debugging: Print final crop values
      print("Final Crop X: $cropX, Crop Y: $cropY, Crop Width: $cropWidth, Crop Height: $cropHeight");
      print("Image Width: ${decodedImage.width}, Image Height: ${decodedImage.height}");

// Crop the image
      img.Image croppedImage = img.copyCrop(decodedImage,
          x: cropX, y: cropY, width: cropWidth, height: cropHeight);


      // Encode the cropped image back to a file
      Uint8List croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImage));

      // Save the cropped image to a file
      String croppedPath =
          '${originalImage.parent.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      File croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(croppedBytes);


      if (!croppedFile.existsSync() || await croppedFile.length() == 0) {
        print("Error: Cropped file is invalid");
        return null;
      }


      return croppedFile;
    } catch (e) {
      print("Error cropping image: $e");
      return null;
    }
  }


  void startImageStream()async{
    await controller.startImageStream();
     _capturedImage = null;
     notifyListeners();
  }


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }


}
