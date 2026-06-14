// ─────────────────────────────────────────────
// FILE: lib/widgets/message_card.dart
//
// PURPOSE: Renders a single chat message bubble.
//
// Decides layout based on who sent the message:
//   Sent BY me    → blue bubble on the RIGHT
//   Sent TO me    → grey bubble on the LEFT
//
// Also shows:
//   - Message timestamp (formatted HH:mm)
//   - Read receipt tick (✓ grey = sent, ✓ blue = read)
//   - Long-press → delete confirmation dialog
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:hello_chat/helper/apis_help.dart';
import 'package:hello_chat/models/chat_user.dart';
import 'package:hello_chat/models/message.dart';

class MessageCard extends StatelessWidget {
  // The message data object to render
  final Message message;

  // The other user — needed to call Apis.deleteMessage()
  final ChatUser chatUser;

  const MessageCard({
    super.key,
    required this.message,
    required this.chatUser,
  });

  // ── _isSentByMe ──────────────────────────────
  // PURPOSE: Determine if the current user sent
  // this message or received it.
  //
  // If message.fromId matches OUR uid → we sent it.
  // This decides bubble color and alignment.
  bool get _isSentByMe => message.fromId == Apis.user.uid;

  // ── _formattedTime ────────────────────────────
  // PURPOSE: Convert the raw Unix timestamp string
  // stored in message.sent into a human-readable
  // "HH:mm" format (e.g. "14:35").
  //
  // message.sent is a milliseconds-since-epoch
  // string like "1718012345678".
  String get _formattedTime {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          int.parse(message.sent));
      // Pad hours and minutes to always show 2 digits
      // e.g. 9:05 becomes "09:05"
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      // If timestamp can't be parsed, show nothing
      return '';
    }
  }

  // ── _showDeleteDialog ─────────────────────────
  // PURPOSE: Show a confirmation dialog before
  // deleting a message. If user confirms, calls
  // Apis.deleteMessage() to remove it from Firestore.
  //
  // Only shown for messages WE sent (you can't
  // delete someone else's messages).
  void _showDeleteDialog(BuildContext context) {
    // Only allow deletion of our own messages
    if (!_isSentByMe) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content:
        const Text('This message will be permanently deleted.'),
        actions: [
          // ── Cancel button ──────────────────
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          // ── Delete button ──────────────────
          TextButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.pop(ctx);
              // Then delete from Firestore.
              // This triggers the StreamBuilder to
              // rebuild without this message.
              await Apis.deleteMessage(chatUser, message);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ── build ────────────────────────────────────
  // PURPOSE: Build the message bubble widget.
  //
  // Uses Align to push:
  //   my messages    → right  (Alignment.centerRight)
  //   their messages → left   (Alignment.centerLeft)
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Long-press shows the delete dialog
      onLongPress: () => _showDeleteDialog(context),
      child: Align(
        // My messages go right, theirs go left
        alignment:
        _isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          // Max width = 75% of screen — prevents
          // long messages from spanning full width
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            // My messages = purple, theirs = light grey
            color: _isSentByMe
                ? Colors.purple.shade100
                : Colors.grey.shade200,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              // The corner "pointing" toward the avatar
              // is flat (0 radius) for the sender's side
              bottomLeft: _isSentByMe
                  ? const Radius.circular(16)
                  : Radius.zero,
              bottomRight: _isSentByMe
                  ? Radius.zero
                  : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Message text ─────────────────
              Text(
                message.msg,
                style: const TextStyle(
                    fontSize: 15, color: Colors.black87),
              ),

              const SizedBox(height: 4),

              // ── Timestamp + read receipt ──────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time string (e.g. "14:35")
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black45),
                  ),

                  // Read receipt — only show for OUR messages
                  if (_isSentByMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size: 14,
                      // Blue = read by receiver
                      // Grey = delivered but not read yet
                      color: message.read.isNotEmpty
                          ? Colors.blue
                          : Colors.black45,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}