// ─────────────────────────────────────────────
// FILE: lib/Auth services/login_screen.dart
//
// PURPOSE: Handles user login via:
//   1. Email + Password
//   2. Google Sign-In
//   3. Forget Password (was BROKEN — now FIXED)
//
// WHAT CHANGED:
//   - _forgetPassword() method added
//   - _showForgetPasswordDialog() method added
//   - Forget Password button wired up (was empty)
// ─────────────────────────────────────────────

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
  // ── State ────────────────────────────────────
  bool loading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Separate controller just for the forget password
  // dialog input field — kept separate so clearing
  // it doesn't affect the main login form.
  final _resetEmailController = TextEditingController();

  final auth = FirebaseAuth.instance;

  // ── dispose ──────────────────────────────────
  // Clean up all controllers when screen closes.
  // Prevents memory leaks.
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════
  // LOGIN METHOD
  // ════════════════════════════════════════════

  // ── login ────────────────────────────────────
  // PURPOSE: Sign in using email + password.
  // Shows loading spinner while Firebase responds.
  // Navigates to Home on success, shows error toast
  // on failure.
  void login() {
    setState(() => loading = true);

    auth
        .signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    )
        .then((value) {
      setState(() => loading = false);
      Utilities().toastMessage('Login Successful');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    })
        .onError((error, stack) {
      setState(() => loading = false);
      Utilities().toastMessage(error.toString());
    });
  }

  // ════════════════════════════════════════════
  // FORGET PASSWORD — THIS WAS THE BROKEN PART
  // ════════════════════════════════════════════

  // ── _showForgetPasswordDialog ─────────────────
  // PURPOSE: Show a popup dialog where the user
  // types their email address. When they tap Send,
  // Firebase emails them a password reset link.
  //
  // WHY A DIALOG: Less disruptive than a full screen.
  // The user stays on the login page and just types
  // their email in a small popup overlay.
  //
  // ORIGINAL CODE: onPressed: () {}  ← did NOTHING
  // FIX: Opens this dialog which calls _sendResetEmail()
  void _showForgetPasswordDialog() {
    // Pre-fill the reset email field with whatever
    // the user already typed in the main email field.
    // This saves them from typing it again.
    _resetEmailController.text = emailController.text.trim();

    showDialog(
      context: context,
      // barrierDismissible: true means tapping outside
      // the dialog closes it without sending anything.
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          // ── Dialog title ───────────────────
          title: const Text(
            'Reset Password',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),

          // ── Dialog body ────────────────────
          content: Column(
            // mainAxisSize.min shrinks the dialog to
            // fit its content instead of full height
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              // Email input field inside the dialog
              TextField(
                controller: _resetEmailController,
                keyboardType: TextInputType.emailAddress,
                // autofocus pops the keyboard open
                // immediately when dialog appears
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          // ── Dialog buttons ──────────────────
          actions: [
            // Cancel — closes dialog, does nothing
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),

            // Send — triggers the actual Firebase call
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // Close the dialog first, then send email.
                // This prevents double-taps.
                Navigator.pop(context);
                _sendResetEmail(_resetEmailController.text.trim());
              },
              child: const Text(
                'Send',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── _sendResetEmail ───────────────────────────
  // PURPOSE: Call Firebase's sendPasswordResetEmail()
  // with the email the user typed.
  //
  // HOW IT WORKS:
  //   1. Validate that the email field is not empty
  //   2. Call auth.sendPasswordResetEmail(email)
  //   3. Firebase sends an email to that address
  //      with a secure link. Clicking the link opens
  //      a Firebase-hosted page to set a new password.
  //   4. Show success or error toast
  //
  // IMPORTANT: Firebase does NOT tell you if the email
  // exists or not — it silently succeeds either way.
  // This is intentional (security — prevents email
  // enumeration attacks where hackers probe which
  // emails are registered).
  Future<void> _sendResetEmail(String email) async {
    // Basic validation — don't hit Firebase with
    // an empty string
    if (email.isEmpty) {
      Utilities().toastMessage('Please enter your email address');
      return;
    }

    try {
      // This is the core Firebase method.
      // It sends a password reset link to the email.
      // The link expires after 1 hour by default
      // (configurable in Firebase console).
      await auth.sendPasswordResetEmail(email: email);

      // Success — tell the user to check their inbox
      Utilities().toastMessage(
        'Reset link sent! Check your inbox and spam folder.',
      );
    } on FirebaseAuthException catch (e) {
      // FirebaseAuthException gives us a specific
      // error code we can handle cleanly.
      //
      // Common codes:
      //   invalid-email     → email format is wrong
      //   user-not-found    → no account with this email
      //                       (older Firebase SDK only —
      //                        newer SDK silently succeeds)
      switch (e.code) {
        case 'invalid-email':
          Utilities().toastMessage('That email address is not valid.');
          break;
        case 'user-not-found':
          Utilities().toastMessage('No account found with that email.');
          break;
        default:
          Utilities().toastMessage(e.message ?? 'Something went wrong.');
      }
    } catch (e) {
      // Catch any other unexpected errors
      Utilities().toastMessage('Error: ${e.toString()}');
    }
  }

  // ════════════════════════════════════════════
  // GOOGLE SIGN-IN
  // ════════════════════════════════════════════

  // ── _signInWithGoogle ─────────────────────────
  // PURPOSE: Authenticate using a Google account.
  // After sign-in, checks if a Firestore user profile
  // exists. Creates one if this is their first login.
  Future<void> _signInWithGoogle() async {
    setState(() => loading = true);

    try {
      final userCredential = await _googleSignIn();
      setState(() => loading = false);

      if (await Apis.userExist()) {
        // Returning Google user → go straight to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      } else {
        // New Google user → create Firestore profile first
        await Apis.createUser();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      Utilities().toastMessage(e.toString());
    }
  }

  // ── _googleSignIn ─────────────────────────────
  // PURPOSE: Run the actual Google OAuth flow and
  // return a Firebase UserCredential.
  //
  // Steps:
  //   1. Open Google account picker popup
  //   2. Get the OAuth tokens (accessToken + idToken)
  //   3. Convert tokens into a Firebase credential
  //   4. Sign into Firebase with that credential
  Future<UserCredential> _googleSignIn() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Sign-in cancelled');

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 70),

                // App logo
                Image.asset(
                  'assets/images/icon.png',
                  height: 170,
                  width: 170,
                ),

                const SizedBox(height: 20),

                // ── Email field ──────────────
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter Email',
                    suffixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter email' : null,
                ),

                const SizedBox(height: 15),

                // ── Password field ───────────
                TextFormField(
                  controller: passwordController,
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

                const SizedBox(height: 15),

                // ── Login button ─────────────
                RoundButton(
                  loading: loading,
                  title: 'Login',
                  ontap: () {
                    if (_formKey.currentState!.validate()) {
                      login();
                    }
                  },
                ),

                // ── Forget Password button ────
                // ORIGINAL: onPressed: () {}  ← did nothing
                // FIX: now calls _showForgetPasswordDialog()
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgetPasswordDialog,
                    child: const Text('Forget Password?'),
                  ),
                ),

                // ── Google Sign-In button ─────
                OutlinedButton(
                  onPressed: _signInWithGoogle,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Sign in with Google'),
                  ),
                ),

                // ── Go to Signup ──────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Signup(),
                          ),
                        );
                      },
                      child: const Text('Sign Up'),
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