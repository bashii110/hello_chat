// ─────────────────────────────────────────────
// FILE: lib/screens/chat_room.dart
//
// PURPOSE: The main chat screen between two users.
// Shows the message history, handles sending new
// messages, marks messages as read, and allows
// deleting messages with a long-press.
//
// HOW IT WORKS:
//   1. Receives the other user (ChatUser) as a
//      constructor argument from the Home screen.
//   2. Uses a StreamBuilder to listen to
//      Apis.getAllMessages() — messages auto-appear.
//   3. TextField + Send button calls Apis.sendMessage()
//   4. Each incoming message is auto-marked as read
//      via Apis.markMessageAsRead()
// ─────────────────────────────────────────────

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hello_chat/helper/apis_help.dart';
import 'package:hello_chat/models/chat_user.dart';
import 'package:hello_chat/models/message.dart';
import 'package:hello_chat/widgets/message_card.dart';

import '../components/image_helper.dart';

class ChatRoom extends StatefulWidget {
  // The person we are chatting with.
  // Passed in from the Home screen when user taps
  // on a contact in the list.
  final ChatUser chatUser;

  const ChatRoom({super.key, required this.chatUser});

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  // ── State variables ──────────────────────────

  // Controls the text input field at the bottom.
  // We read its content when the user taps Send.
  final _messageController = TextEditingController();

  // Keeps the list scrolled to the bottom when
  // new messages arrive. Attached to the ListView.
  final _scrollController = ScrollController();

  // Whether the send button should show a loading
  // spinner (true while writing to Firestore).
  bool _isSending = false;

  // ── dispose ──────────────────────────────────
  // PURPOSE: Clean up controllers when the screen
  // is removed from the widget tree.
  //
  // IMPORTANT: Always dispose controllers to avoid
  // memory leaks. Without this, the TextEditingController
  // keeps listening to memory even after the screen closes.
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── _scrollToBottom ───────────────────────────
  // PURPOSE: Animate the message list to the very
  // bottom after a new message is sent or received.
  //
  // Called after sendMessage() completes and also
  // after the StreamBuilder receives new data.
  //
  // Duration(300) = 300 millisecond animation.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ── _handleSend ──────────────────────────────
  // PURPOSE: Validate the text field, call
  // Apis.sendMessage(), then clear the input.
  //
  // Steps:
  //   1. Trim whitespace from the typed message
  //   2. If empty, do nothing
  //   3. Show loading indicator
  //   4. Call Apis.sendMessage() → writes to Firestore
  //   5. Clear the text field
  //   6. Hide loading indicator
  //   7. Scroll chat to the bottom
  Future<void> _handleSend() async {
    // Trim removes leading/trailing spaces.
    // If the user only typed spaces, treat as empty.
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Show a sending indicator
    setState(() => _isSending = true);

    // Write the message to Firestore.
    // 'text' is the message type (vs 'image' for photos).
    await Apis.sendMessage(widget.chatUser, text, 'text');

    // Clear the input field after sending
    _messageController.clear();

    // Hide the sending indicator
    setState(() => _isSending = false);

    // Scroll to the newest message
    _scrollToBottom();
  }

  // ── build ────────────────────────────────────
  // PURPOSE: Build the entire chat screen UI.
  //
  // Structure:
  //   Scaffold
  //   ├── AppBar (other user's name + avatar)
  //   ├── Body
  //   │   └── StreamBuilder (listens to messages)
  //   │       └── ListView (all MessageCards)
  //   └── Bottom bar (TextField + Send button)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── AppBar ────────────────────────────────
      // Shows the other user's profile photo,
      // name, and "last active" time.
      appBar: AppBar(
        // Disable the default back-button auto title
        titleSpacing: 0,
        title: Row(
          children: [
            // Profile photo in a circle
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              // child: CachedNetworkImage(
              //   height: 40,
              //   width: 40,
              //   fit: BoxFit.cover,
              //   imageUrl: widget.chatUser.image,
              //   // Shown while the image is loading
              //   placeholder: (context, url) =>
              //   const CircularProgressIndicator(),
              //   // Shown if image URL is broken
              //   errorWidget: (context, url, error) =>
              //   const CircleAvatar(child: Icon(Icons.person)),
              // ),
              child: UserAvatar(
                imageData: widget.chatUser.image,
                radius: 20,
              ),
            ),
            const SizedBox(width: 10),
            // Name and last-active text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatUser.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Last active: ${widget.chatUser.lastActive}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),

      // ── Body ──────────────────────────────────
      // The message list + input bar stacked vertically.
      body: Column(
        children: [
          // ── Message list ─────────────────────
          // Expands to fill all available space
          // between the AppBar and the input bar.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // getAllMessages() returns a live stream.
              // Every time a new message is added to
              // Firestore, this builder re-runs automatically.
              stream: Apis.getAllMessages(widget.chatUser),

              builder: (context, snapshot) {
                // ── Loading state ──────────────
                // Show spinner while the first batch
                // of messages is being fetched.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                // ── Error state ────────────────
                // Show error text if Firestore fails
                // (e.g. no internet, permission denied)
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }

                // ── Parse messages ─────────────
                // Convert each Firestore document
                // into a typed Message object.
                //
                // snapshot.data!.docs = list of
                // QueryDocumentSnapshot objects.
                // We map each one to Message.fromJson()
                final messages = snapshot.data!.docs
                    .map((doc) => Message.fromJson(
                    doc.data() as Map<String, dynamic>))
                    .toList();

                // ── Mark messages as read ──────
                // After messages load, loop through
                // each one and mark unread incoming
                // messages as read.
                //
                // We do this AFTER the build so we
                // don't call setState during build.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  for (final msg in messages) {
                    // Only mark messages that were
                    // sent TO us (not from us).
                    if (msg.fromId != Apis.user.uid &&
                        msg.read.isEmpty) {
                      Apis.markMessageAsRead(widget.chatUser, msg);
                    }
                  }
                  // Scroll to bottom after messages load
                  _scrollToBottom();
                });

                // ── Empty state ────────────────
                // No messages yet — show hint text
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Say hello! 👋',
                      style: TextStyle(
                          fontSize: 18, color: Colors.black45),
                    ),
                  );
                }

                // ── Message list ───────────────
                // Render each message as a MessageCard.
                // shrinkWrap + physics allow proper
                // scrolling behavior inside the Column.
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return MessageCard(
                      message: messages[index],
                      chatUser: widget.chatUser,
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ─────────────────────────
          // Sits at the bottom of the screen.
          // Contains: text field + send button.
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── _buildInputBar ────────────────────────────
  // PURPOSE: Build the message input row at the
  // bottom of the screen.
  //
  // Layout:
  //   [  TextField (expandable)  ] [Send Button]
  //
  // Extracted into its own method to keep build()
  // clean and readable.
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        // Top border separator between list and input
        border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          // ── TextField ─────────────────────────
          Expanded(
            child: TextField(
              controller: _messageController,
              // Allow multi-line messages (max 4 lines
              // before scrolling inside the field)
              maxLines: 4,
              minLines: 1,
              // Allow sending by pressing Enter on
              // hardware keyboards (desktop/web)
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Send Button ────────────────────────
          // Shows a spinner while sending, then
          // reverts to the send icon.
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.purple.shade400,
            child: _isSending
            // Sending in progress → show spinner
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
            // Idle → show send icon
                : IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}