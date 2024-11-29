import 'dart:async';
import 'dart:io';
// import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'dart:typed_data';
import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
        }

      },

      onFaceDetected: (Face? face) {

        _detectedFace = face;

        _faceDetected = face != null;

        if (_faceDetected) {
          // Debugging: Log bounding boxes and face center
           faceBox = face!.boundingBox;
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

  void _defineBox() {
    // Example box (centered on screen)
    double boxWidth = 300.w; // Box width
    double boxHeight = 450.h; // Box height
    double boxLeft = 30.w; // X-coordinate
    double boxTop = 150.h; // Y-coordinate

    _definedBox = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);
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


  bool isFaceWithinBox(Rect faceBox) {
    if (_definedBox == null) return false;

    // Check if the entire face bounding box is inside the defined box
    return _definedBox!.contains(Offset(faceBox.left, faceBox.top)) &&
        _definedBox!.contains(Offset(faceBox.right, faceBox.bottom));
  }


  bool _isCapturing = false;

  DateTime? _lastCaptureTime; // Track the time of the last capture

  void _captureIfReady() async {
    if (_isCapturing) return; // Prevent re-entry during an active capture

    final now = DateTime.now();
    if (_lastCaptureTime != null &&
        now.difference(_lastCaptureTime!).inSeconds < 6) {
      return; // Skip if last capture was within the cooldown period
    }

    if (_faceDetected && isFaceWithinBox(_detectedFace!.boundingBox)) {
      _isCapturing = true;
      _lastCaptureTime = now; // Update the last capture time
      notifyListeners();

      try {
        // Delay for user interaction (5 seconds)
        await Future.delayed(const Duration(seconds: 5));

        // Capture the image
        controller.captureImage();

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
