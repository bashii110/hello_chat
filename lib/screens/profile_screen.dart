import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hello_chat/Auth%20services/login_screen.dart';
import 'package:hello_chat/helper/apis_help.dart';
import 'package:hello_chat/models/chat_user.dart';
import 'package:hello_chat/utils/utilities.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser chatUser;
  const ProfileScreen({super.key, required this.chatUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  //Image File path
  String? _file;
  final picker = ImagePicker();

  //Validation key
  final _formKey = GlobalKey<FormState>();

  final nameControllor = TextEditingController();
  final aboutControllor = TextEditingController();
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance.collection("users");

  //Pick file from gallery
  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _file = image.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Profile"),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        _file != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Image.file(
                                  File(_file!),
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: CachedNetworkImage(
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.fill,
                                  imageUrl: widget.chatUser.image,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                ),
                              ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: MaterialButton(
                            onPressed: () {
                              pickImage();
                            },
                            shape: CircleBorder(),
                            color: Colors.white,
                            child: Icon(Icons.edit),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      widget.chatUser.email,
                      style: TextStyle(fontSize: 17, color: Colors.purple),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    TextFormField(
                      // controller: nameControllor,
                      initialValue: widget.chatUser.name,
                      onSaved: (value) => Apis.me.name = value ?? "",
                      validator: (value) => value != null && value.isNotEmpty
                          ? null
                          : "Required Field",
                      style: TextStyle(
                        fontSize: 19,
                      ),
                      decoration: InputDecoration(
                          hintText: "Enter Name",
                          prefixIcon: Icon(
                            Icons.person,
                            color: Colors.purple,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50))),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    TextFormField(
                      // controller: aboutControllor,
                      initialValue: widget.chatUser.about,
                      onSaved: (val) => Apis.me.about = val ?? "",
                      validator: (val) => val != null && val.isNotEmpty
                          ? null
                          : "Required field",
                      style: TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                          prefixIcon:
                              Icon(Icons.info_outline, color: Colors.purple),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50))),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(150, 50),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          Apis.updateUserInfo().then((value) {
                            Utilities().toastMessage("Profile Updated");
                          });
                        }
                      },
                      icon: Icon(
                        Icons.save,
                      ),
                      label: Text(
                        "Save",
                      ),
                    ),
                    SizedBox(
                      height: 60,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(150, 50),
                              backgroundColor: Colors.redAccent),
                          onPressed: () {
                            auth.signOut();
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.logout, color: Colors.white),
                          label: Text(
                            "Logout",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
