import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ruadmission/models/number_response_model.dart';

import '../models/otp_sent_response_model.dart';


class OtpSendingPageViewModel extends ChangeNotifier{

  bool isOtpSent = false;
  bool isOtpReceived = false;

  String? mobilNumber;
  String? token;

  void sendOtpAgain(){
    isOtpSent = false;
    notifyListeners();
  }

  Future<void> sendNumber(String number) async {
    try{

      var mobile = json.encode({
        "mobile":number.toString()
      });
      final response = await http.post(
        Uri.parse('https://aad.ru.ac.bd/api/user-query'),
        headers: {
          'Content-Type': 'application/json', // Specify JSON content
          'Authorization': 'Bearer NO7pAwK1Fl',
          'Accept':'*/*'
        },
        body: mobile
      );

      if(response.statusCode == 200){
        var jsonResponse = json.decode(response.body);
        NumberResponseModel numberResponse = NumberResponseModel.fromJson(jsonResponse);
        if(numberResponse.statusCode==200){
          print(numberResponse.toString());
          isOtpSent = true;
          notifyListeners();

        }
        else{
          print(numberResponse.toString());
          isOtpSent = false;
          notifyListeners();
        }


      }

    }catch(error){
      print(error);
    }

  }

  Future<void> sendOTP(String number, String code) async {
    try{

      var otp = json.encode({
        "mobile":number.toString(),
        "code":code.toString(),
      });
      print(otp);
      final response = await http.post(
          Uri.parse('https://aad.ru.ac.bd/api/otp-verification'),
          headers: {
            'Content-Type': 'application/json', // Specify JSON content
            'Authorization': 'Bearer NO7pAwK1Fl',
            'Accept':'*/*'
          },
          body: otp
      );

      if(response.statusCode == 200){
        var jsonResponse = json.decode(response.body);
        OtpSentResponseModel otpResponse = OtpSentResponseModel.fromJson(jsonResponse);
        if(otpResponse.statusCode==200){
          print(otpResponse.toString());
          mobilNumber = number;
          token = otpResponse.token;
          isOtpReceived = true;
          notifyListeners();

        }
        else{
          print(otpResponse.toString());
          isOtpSent = false;
          notifyListeners();
        }


      }

    }catch(error){
      print(error);
    }

  }

}