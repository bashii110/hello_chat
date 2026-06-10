

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hello_chat/models/chat_user.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class Apis {
  static final auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore= FirebaseFirestore.instance;

  // For storing self data
  static late ChatUser me;

  // get user
  static User get user => auth.currentUser!;



  // To check if user Exist or not
  static Future<bool> userExist()async{
    return (await firestore.collection("users").doc(user.uid).get()).exists;
  }

  //For getting current user info
  static Future<void> selfInfo()async{
     firestore.collection("users").doc(user.uid).get().then((user) async{

       if(user.exists){
         me = ChatUser.fromJson(user.data()!);
       } else {
          await createUser().then((value)=> selfInfo());
       }
     });
  }



  // To create a new user
  static Future<void> createUser()async{

    // format current time
    final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Creating user
    final chatUser= ChatUser(
      name: user.displayName.toString(),
      id: user.uid,
      email: user.email.toString(),
      image: user.photoURL.toString(),
      lastActive: formatted,
      about: 'Hey! Whats Up',
    );

    return await firestore.collection("users").doc(user.uid).set(chatUser.toJson());
  }


  // For getting all user data from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>>  getAllUsers(){
    return  firestore.collection("users").where("id", isNotEqualTo: Apis.user.uid).snapshots();
  }

  static Future<void> updateUserInfo() async{
    await firestore.collection("users").doc(user.uid).update({
      "name" : me.name,
      "about" : me.about,
      "image" : me.image,
    });
  }

}