import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hello_chat/screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
// ...
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hello Chat',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          titleTextStyle: TextStyle(fontSize: 20,fontWeight: FontWeight.w500, color:  Colors.white),
          backgroundColor: Colors.purple.shade400,

        ),

        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

