import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hello_chat/models/chat_user.dart';

class ChatsCard extends StatefulWidget {
  final ChatUser user;
  const ChatsCard({super.key, required this.user});

  @override
  State<ChatsCard> createState() => _ChatsCardState();
}

class _ChatsCardState extends State<ChatsCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: (){},
        child: ListTile(

          // leading: CircleAvatar(child: Icon(Icons.person),),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              height: 40,
              width: 40,
              imageUrl: widget.user.image,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => CircleAvatar(child: Icon(Icons.person),),
            ),
          ),

          title: Text(widget.user.name),
          subtitle: Text(widget.user.about, maxLines: 1,),
          trailing: Text(widget.user.lastActive, style: TextStyle(color: Colors.black26),),
        ),
      ),
    );
  }
}
