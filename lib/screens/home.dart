import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello_chat/components/chats_card.dart';
import 'package:hello_chat/helper/apis_help.dart';
import 'package:hello_chat/models/chat_user.dart';
import 'package:hello_chat/screens/profile_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // for saving all users
  List<ChatUser> list= [];

  //For saving searches
  final List<ChatUser> list2= [];
  bool _isSearching=false;

  final auth = FirebaseAuth.instance;


  @override
  void initState() {
    super.initState();
     _loadUserData();

  }

  Future<void> _loadUserData() async {
    await Apis.selfInfo();
    setState(() {}); // Refresh UI after loading
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: ( didpop, result){
          if(_isSearching){
            setState(() {
              _isSearching= !_isSearching;
            });
            // return Future.value(false);

          } else{
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSearching ?
            Padding(
              padding: const EdgeInsets.only(bottom: 2, top: 1),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Name, Email, etc",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.black)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white60),
                    borderRadius: BorderRadius.circular(30)
                  )
                ),

                onChanged: (val){
                  list2.clear();

                  for (var i in list){
                    if(i.name.toLowerCase().contains(val.toLowerCase()) ||
                        i.name.toLowerCase().contains(val.toLowerCase())){
                      list2.add(i);
                    }
                    setState(() {
                      list2;
                    });
                  }
                },

              ),
            ) :
            Text("Hello Chat"),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(onPressed: () {
                setState(() {
                  _isSearching=!_isSearching;
                });
              }, icon: Icon( _isSearching ? Icons.clear_outlined :Icons.search_outlined)),
              IconButton(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(chatUser: Apis.me,)));
                  },
                  icon: Icon(Icons.more_vert)),

            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: StreamBuilder<QuerySnapshot>(
              stream: Apis.getAllUsers(),
              builder:
                  (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                } else {
                  var data = snapshot.data!.docs;
                  list = data.map((e) => ChatUser.fromJson(e.data() as Map<String, dynamic>)).toList();

                  return list.isNotEmpty ? ListView.builder(
                      itemCount: _isSearching ? list2.length : data.length,
                      itemBuilder: (context, index) {
                        return ChatsCard(user: _isSearching ? list2[index] : list[index]);
                      },
                    ) : Center(
                      child: Text("No connection found"),
                    );
                }
              },
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 25, right: 15),
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.purple.shade400,
              child: Icon(
                Icons.mark_unread_chat_alt_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
