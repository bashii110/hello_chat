import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello_chat/Auth%20services/signup_screen.dart';
import 'package:hello_chat/components/roundbutton.dart';
import 'package:hello_chat/helper/apis_help.dart';
import 'package:hello_chat/screens/home.dart';
import 'package:hello_chat/utils/utilities.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading= false;
  final _formKey = GlobalKey<FormState>();
  final emailControllor = TextEditingController();
  final passwordControllor = TextEditingController();
  final auth = FirebaseAuth.instance;


  void login (){
    setState(() {
      loading=true;
    });

    auth.signInWithEmailAndPassword(
        email: emailControllor.text,
        password: passwordControllor.text,
    ).then((value){
      setState(() {
        loading=false;
      });
      Utilities().toastMessage("Login Successful");
      Navigator.push(context, MaterialPageRoute(builder: (context)=> Home()));
    }).onError((error, stack){
      setState(() {
        loading=false;
      });
      Utilities().toastMessage(error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Login Please"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                SizedBox(
                  height: 70,
                ),

                Stack(
                  children: [
                    Image.asset("assets/images/icon.png", height: 170, width: 170,)
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: emailControllor,
                  decoration: InputDecoration(
                    hintText: "Enter Email",
                    suffixIcon: Icon(Icons.email_outlined,),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    ),
                  validator: (value){
                    if (value!.isEmpty) {
                      return "Empty field";
                    }
                    return null;
                  },
                  ),

                SizedBox(
                  height: 15,
                ),

                TextFormField(
                  controller: passwordControllor,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Enter Password",
                    suffixIcon: Icon(Icons.remove_red_eye_outlined,),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  validator: (value){
                    if (value!.isEmpty) {
                      return "Empty field";
                    }
                    return null;
                  },
                ),

                SizedBox(
                  height: 15,
                ),

                RoundButton(
                  loading: loading,
                  title: "Login", ontap: (){
                  if(_formKey.currentState!.validate()){
                    login();
                  }
                },),


                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                      onPressed: (){
                      },
                      child: Text("Forget Password")),
                ),

                OutlinedButton(

                    onPressed: (){
                      _signInWithGoogle();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Text("Sign in with Google",),
                    )),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Signup()));
                      },
                      child: Text("Sign Up"),),


                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }


  _signInWithGoogle(){
    setState(() {
      loading=true;
    });
    signInWithGoogle().then((user) async {
      setState(() {
        loading=false;
      });
      if(await Apis.userExist()){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> Home()));
      } else {

        await Apis.createUser().then((value){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> Home()));
        });
      }

    }).onError((erro, stack){
      Utilities().toastMessage(erro.toString());
      setState(() {
        loading=false;
      });
    });
  }



  Future<UserCredential> signInWithGoogle() async {
    // Create an instance
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Start the sign-in flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Sign-in aborted by user");
      }

      // Get authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credentials
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      return await FirebaseAuth.instance.signInWithCredential(credential);


  }


}


