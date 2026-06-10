import 'package:flutter/material.dart';

import '../services/splash_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SplashServices splashServices=SplashServices();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    splashServices.isLogin(context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Container(
                height: 180,
                  width: 180,
                  child: Image.asset("assets/images/icon.png"),
              ),

              Text("BuxhiiTech",
                style:  TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w400,
                    color:  Colors.purple.shade400,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
