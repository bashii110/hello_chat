import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello_chat/Auth%20services/login_screen.dart';
import 'package:hello_chat/utils/utilities.dart';
import '../components/roundbutton.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final emailControllor = TextEditingController();
  final passwordControllor = TextEditingController();
  bool loading = false;
  bool _obscurePassword = true;

  final FirebaseAuth auth = FirebaseAuth.instance;

  // void dispose() async {
  //   emailControllor.dispose();
  //   passwordControllor.dispose();
  // }

  void signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailControllor.text.trim(),
        password: passwordControllor.text.trim(),
      );

      await userCredential.user!.sendEmailVerification();

      setState(() => loading = false);

      Utilities().toastMessage(
          "Verification email sent! Check your inbox and spam folder.");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);
      Utilities().toastMessage(e.message ?? "Auth error");
    } catch (e) {
      setState(() => loading = false);
      Utilities().toastMessage("Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Sign Up Please",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    Image.asset(
                      "assets/images/icon.png",
                      height: 170,
                      width: 170,
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: emailControllor,
                  decoration: InputDecoration(
                    hintText: "Enter Email",
                    suffixIcon: Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  validator: (value) {
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
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter password' : null,
                ),
                SizedBox(
                  height: 15,
                ),
                RoundButton(
                    title: "Sign Up",
                    loading: loading,
                    ontap: () {
                      if (_formKey.currentState!.validate()) {
                        signUp();
                      }
                    }),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                      onPressed: () {}, child: Text("Forget Password")),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()));
                      },
                      child: Text("Login"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
