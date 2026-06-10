import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello_chat/screens/home.dart';
import 'package:hello_chat/utils/utilities.dart';

class VerifyEmail extends StatefulWidget {
  const VerifyEmail({super.key});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  bool isEmailVerified=false;
  Timer? timer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isEmailVerified= FirebaseAuth.instance.currentUser!.emailVerified;
    if(!isEmailVerified){
      sendVerificationEmail();
      Timer.periodic(
          Duration(seconds: 3),
              (_){
            checkEmailVerified();
              },
      );
    }
  }


  // For checking if user Verified
  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();

    setState(() {
      isEmailVerified= FirebaseAuth.instance.currentUser!.emailVerified;

    });

    if(isEmailVerified){
      timer!.cancel();

    }
  }

  @override
  void dispose(){
    timer?.cancel();
    super.dispose();
  }



  Future sendVerificationEmail() async{
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
    } catch (e){
      Utilities().toastMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return isEmailVerified ? Home() : Scaffold(
      appBar: AppBar(
        title: Text("Please Verify"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Text(
            "Verification email has been sent to you. Please Verify!",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
