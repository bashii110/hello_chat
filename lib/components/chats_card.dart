// ─────────────────────────────────────────────
// FILE: lib/components/chats_card.dart
//
// PURPOSE: Renders one row in the contacts list
// on the Home screen.
//
// Each card shows:
//   - Profile photo (cached from URL)
//   - User's name
//   - Last message preview (from Firestore stream)
//   - Timestamp of the last message
//   - Unread message count badge (red circle)
//
// Tapping navigates to ChatRoom for that user.
// ─────────────────────────────────────────────

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hello_chat/helper/apis_help.dart';
import 'package:hello_chat/models/chat_user.dart';
import 'package:hello_chat/models/message.dart';
import 'package:hello_chat/screens/chat_room.dart';

import 'image_helper.dart';

class ChatsCard extends StatefulWidget {
  final ChatUser user;
  const ChatsCard({super.key, required this.user});

  @override
  State<ChatsCard> createState() => _ChatsCardState();
}

class _ChatsCardState extends State<ChatsCard> {
  // ── _formattedTime ────────────────────────────
  // PURPOSE: Convert a Unix millisecond timestamp
  // string into a short, readable display format.
  //
  // Logic:
  //   Today's message    → show "HH:mm"   (e.g. "09:45")
  //   Older message      → show "dd/MM"   (e.g. "07/06")
  //
  // Why two formats? Today's messages are recent
  // so time matters. Older ones just need the date.
  String _formattedTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dt =
      DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      final now = DateTime.now();

      // Check if the message was sent today
      final isToday = dt.day == now.day &&
          dt.month == now.month &&
          dt.year == now.year;

      if (isToday) {
        // Show HH:mm for today
        return '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
      } else {
        // Show dd/MM for older messages
        return '${dt.day.toString().padLeft(2, '0')}/'
            '${dt.month.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '';
    }
  }

  // ── build ────────────────────────────────────
  // PURPOSE: Build the list tile for one contact.
  //
  // Uses two nested StreamBuilders:
  //   1. getLastMessage() → shows preview text
  //   2. getUnreadCount() → shows badge number
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        // Tapping navigates to the ChatRoom screen
        // for this specific user.
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Pass the ChatUser object so ChatRoom
              // knows who we are chatting with.
              builder: (_) => ChatRoom(chatUser: widget.user),
            ),
          );
        },
        child: ListTile(
          // ── Profile photo ────────────────────
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            // child: CachedNetworkImage(
            //   height: 50,
            //   width: 50,
            //   fit: BoxFit.cover,
            //   imageUrl: widget.user.image,
            //   placeholder: (context, url) =>
            //   const CircularProgressIndicator(),
            //   errorWidget: (context, url, error) =>
            //   const CircleAvatar(child: Icon(Icons.person)),
            // ),
            child: UserAvatar(
              imageData: widget.user.image,
              radius: 25,
            ),
          ),

          // ── Name ─────────────────────────────
          title: Text(
            widget.user.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),

          // ── Last message preview ──────────────
          // StreamBuilder listens to getLastMessage().
          // When a new message arrives, this rebuilds
          // automatically showing the latest text.
          subtitle: StreamBuilder<QuerySnapshot>(
            stream: Apis.getLastMessage(widget.user),
            builder: (context, snapshot) {
              // No data yet → show "about" text as fallback
              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return Text(
                  widget.user.about,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                );
              }

              // Parse the latest message document
              final lastMsg = Message.fromJson(
                  snapshot.data!.docs.first.data()
                  as Map<String, dynamic>);

              // Show a microphone icon if voice note,
              // 📷 if image, otherwise the text preview
              final preview = lastMsg.type == 'image'
                  ? '📷 Photo'
                  : lastMsg.msg;

              return Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              );
            },
          ),

          // ── Trailing: timestamp + unread badge ─
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Timestamp ──────────────────
              StreamBuilder<QuerySnapshot>(
                stream: Apis.getLastMessage(widget.user),
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final lastMsg = Message.fromJson(
                      snapshot.data!.docs.first.data()
                      as Map<String, dynamic>);
                  return Text(
                    _formattedTime(lastMsg.sent),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45),
                  );
                },
              ),

              const SizedBox(height: 4),

              // ── Unread count badge ──────────
              // StreamBuilder listens to getUnreadCount().
              // Shows a red circle with a number if
              // there are unread messages. Hidden when
              // count is 0.
              StreamBuilder<int>(
                stream: Apis.getUnreadCount(widget.user),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;

                  // Hide badge when no unread messages
                  if (count == 0) return const SizedBox.shrink();

                  // Show red circle badge with count
                  return Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      // Cap display at 99+ to avoid overflow
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}