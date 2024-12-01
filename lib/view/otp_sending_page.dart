import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ruadmission/view/camera_page.dart';
import 'package:ruadmission/view_model/otp_sending_page_view_model.dart';

class OtpSendingPage extends StatefulWidget{

  @override
  State<OtpSendingPage> createState() => _OtpSendingPageState();
}

class _OtpSendingPageState extends State<OtpSendingPage> {

  late final TextEditingController numberController;
  late final TextEditingController otpController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    numberController = TextEditingController();
    otpController = TextEditingController();
  }
  @override
  void dispose() {
    numberController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final otpProvider = Provider.of<OtpSendingPageViewModel>(context);
  final deviceHeight = MediaQuery.of(context).size.height;
  final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body:SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: SizedBox(
            width: deviceWidth,
            height: deviceHeight,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 15,
                  ),
                   Center(child: Text("Enter your number to get OTP",style: TextStyle(fontSize: 22.sp,color: Colors.black),),),
                const SizedBox(height: 15,),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: numberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "01XXXXXXXXX",
                            labelText: "Enter your mobile number",
                            prefixIcon: Icon(Icons
                                .phone_android_rounded), // Using prefixIcon parameter
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "Please enter your mobile number";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15,),
                        if(otpProvider.isOtpSent)
                        TextFormField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "01XXXXXXXXX",
                            labelText: "Enter your otp",
                            prefixIcon: Icon(Icons
                                .phone_android_rounded), // Using prefixIcon parameter
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "Please enter your mobile number";
                            }
                            return null;
                          },
                        )
                      ],
                    ),
                  ),
                  if(!otpProvider.isOtpSent)
                    Column(
                      children: [
                        const SizedBox(height: 15,),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlueAccent
                            ),
                            onPressed: ()async{
                              //   await otpProvider.sendOTP(numberController.text, "2450");
                              print("sending mobile number");

                              await otpProvider.sendNumber(numberController.text.toString());
                              print("is otp sent : ${otpProvider.isOtpSent}");
                              if( otpProvider.isOtpSent ==true){
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP Sent Successful"),backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),));
                              }
                              else{
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wrong Number"),backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),));
                              }
                            },
                            child: Text("Send Number",style: TextStyle(color: Colors.white),),),
                        )
                      ],
                    ),
                  if(otpProvider.isOtpSent)
                    Column(
                      children: [
                        const SizedBox(height: 15,),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlueAccent
                            ),
                            onPressed: ()async{
                                 await otpProvider.sendOTP(numberController.text, otpController.text);
                           //   await otpProvider.sendNumber(numberController.text.toString());
                              if( otpProvider.isOtpReceived ==true){
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP Sent Successful"),backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),));
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>CameraPage(mobile: otpProvider.mobilNumber,token: otpProvider.token,)));
                              }
                              else{
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wrong Number"),backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),));
                              }
                            },
                            child: Text("Send Otp",style: TextStyle(color: Colors.white),),),
                        ),
                        const SizedBox(height: 20,),
                        TextButton(
                            onPressed: (){
                              otpProvider.sendOtpAgain();
                            },
                            child: Text("Send OTP Again",style:TextStyle(fontSize: 18.sp,fontWeight: FontWeight.bold,color: Colors.lightBlueAccent)))
                      ],
                    ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}