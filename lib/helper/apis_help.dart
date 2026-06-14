// ─────────────────────────────────────────────
// FILE: lib/helper/apis_help.dart
//
// PURPOSE: Central service class for ALL Firebase
// operations in the app.
//
// ── ARCHITECTURE CHANGE (Production redesign) ─
// OLD: getAllUsers() loaded EVERY registered user
//      and dumped them on the home screen. Bad for
//      privacy, bad for performance, not how real
//      chat apps work.
//
// NEW: Two separate concepts:
//   1. "My Contacts" — users I have added.
//      Stored in: users/{myUid}/my_contacts/{theirUid}
//      Home screen shows ONLY these people.
//
//   2. "Search All Users" — only used in the FAB
//      search sheet when explicitly looking someone up.
//      Results are shown but NOT added to contacts
//      until the user consciously taps "Add".
//
// Firestore structure (new):
//   users/
//     {uid}/
//       my_contacts/        ← subcollection (new)
//         {contactUid}/     ← one doc per contact
//           (same fields as ChatUser)
//   chats/
//     {chatId}/messages/    ← unchanged
// ─────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hello_chat/models/chat_user.dart';
import 'package:hello_chat/models/message.dart';
import 'package:intl/intl.dart';

class Apis {
  // ── Firebase instances ───────────────────────
  static final auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ── Current logged-in user's profile ─────────
  // Loaded once on app start via selfInfo().
  // Available app-wide without re-fetching.
  static late ChatUser me;

  // ── Convenience getter ───────────────────────
  // Apis.user → FirebaseAuth.instance.currentUser!
  static User get user => auth.currentUser!;

  // ════════════════════════════════════════════
  // USER PROFILE METHODS
  // ════════════════════════════════════════════

  // ── userExist ────────────────────────────────
  // PURPOSE: Check if logged-in user has a
  // profile doc in Firestore.
  // Used after Google Sign-In.
  static Future<bool> userExist() async {
    return (await firestore
        .collection('users')
        .doc(user.uid)
        .get())
        .exists;
  }

  // ── selfInfo ─────────────────────────────────
  // PURPOSE: Load current user's profile into
  // Apis.me so all screens can access it.
  static Future<void> selfInfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .then((u) async {
      if (u.exists) {
        me = ChatUser.fromJson(u.data()!);
      } else {
        await createUser().then((_) => selfInfo());
      }
    });
  }

  // ── createUser ───────────────────────────────
  // PURPOSE: Create a new profile document in
  // Firestore for a first-time user.
  // Firestore path: users/{uid}
  static Future<void> createUser() async {
    final formatted =
    DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final chatUser = ChatUser(
      name: user.displayName ?? 'No Name',
      id: user.uid,
      email: user.email ?? '',
      image: user.photoURL ?? '',
      lastActive: formatted,
      about: 'Hey! Whats Up',
    );

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // ── updateUserInfo ────────────────────────────
  // PURPOSE: Save changed profile fields to
  // Firestore. Only patches name, about, image.
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
      'image': me.image,
    });
  }

  // ── updateLastActive ─────────────────────────
  // PURPOSE: Stamp current time on user's doc.
  // Called on app open and after sending a message.
  static Future<void> updateLastActive() async {
    final formatted =
    DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'last_active': formatted});
  }

  // ════════════════════════════════════════════
  // CONTACTS METHODS  (NEW — replaces getAllUsers)
  // ════════════════════════════════════════════

  // ── getMyContacts ─────────────────────────────
  // PURPOSE: Stream of ONLY the users I have
  // explicitly added as contacts.
  //
  // WHY THIS INSTEAD OF getAllUsers():
  //   Old way → loaded every single user in the DB.
  //   With 10,000 users that's 10,000 Firestore reads
  //   every time the home screen opens. Expensive + bad
  //   for privacy (strangers see each other).
  //
  //   New way → each user has their own subcollection
  //   'my_contacts'. Only people YOU added appear.
  //   Zero reads for users you've never talked to.
  //
  // Firestore path: users/{myUid}/my_contacts/
  // Returns: real-time Stream so new contacts appear
  //          without refresh.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyContacts() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_contacts') // subcollection
        .snapshots(); // live updates
  }

  // ── addContact ────────────────────────────────
  // PURPOSE: Add another user to my contacts list.
  // Called when the user taps "Start Chat" or "Add"
  // in the FAB search sheet.
  //
  // HOW IT WORKS:
  //   Writes the other user's full profile data into
  //   MY my_contacts subcollection using THEIR uid
  //   as the document ID. This way we can fetch their
  //   latest info and show it in the chat list.
  //
  // Firestore path: users/{myUid}/my_contacts/{theirUid}
  //
  // NOTE: This is ONE-WAY. Adding someone does not
  // add you to their contacts. They only see you
  // after they message you back (which triggers
  // addContact on their side too — see sendMessage).
  static Future<void> addContact(ChatUser contactUser) async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_contacts')
        .doc(contactUser.id) // doc ID = their UID
        .set(contactUser.toJson()); // store their full profile
  }

  // ── removeContact ─────────────────────────────
  // PURPOSE: Remove a user from my contacts list.
  // Does NOT delete the chat history — just removes
  // them from the visible list on Home screen.
  // Chat history stays in chats/{chatId}/messages/.
  //
  // Firestore path: users/{myUid}/my_contacts/{theirUid}
  static Future<void> removeContact(String contactUid) async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_contacts')
        .doc(contactUid)
        .delete();
  }

  // ── isContact ────────────────────────────────
  // PURPOSE: Check if a specific user is already
  // in my contacts list.
  //
  // Used in the search sheet to show "Added" badge
  // vs "Add" button so user knows who they already
  // have in their list.
  //
  // Returns: true if they are in my_contacts,
  //          false if not.
  static Future<bool> isContact(String otherUid) async {
    final doc = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_contacts')
        .doc(otherUid)
        .get();
    return doc.exists;
  }

  // ── searchUsers ───────────────────────────────
  // PURPOSE: Search ALL registered users by name
  // or email. Only used in the FAB search sheet —
  // never shown on the main home screen.
  //
  // HOW IT WORKS:
  //   Fetches all users (one-time read, not a stream)
  //   then filters client-side by the search query.
  //
  // WHY NOT A FIRESTORE QUERY:
  //   Firestore doesn't support "contains" text search
  //   natively. For a production app with millions of
  //   users you'd use Algolia or Typesense. For this
  //   app size, client-side filter is perfectly fine.
  //
  // Returns: List<ChatUser> matching the query.
  //          Excludes the current user from results.
  static Future<List<ChatUser>> searchUsers(String query) async {
    // Return empty list if query is blank
    // (no point hitting Firestore for empty string)
    if (query.trim().isEmpty) return [];

    final q = query.toLowerCase().trim();

    // One-time fetch of all users (not a stream)
    final snapshot = await firestore.collection('users').get();

    return snapshot.docs
        .map((doc) => ChatUser.fromJson(doc.data()))
        .where((u) =>
    u.id != user.uid && // exclude myself
        (u.name.toLowerCase().contains(q) || // match name
            u.email.toLowerCase().contains(q))) // match email
        .toList();
  }

  // ════════════════════════════════════════════
  // CHAT / MESSAGE METHODS
  // ════════════════════════════════════════════

  // ── getChatId ────────────────────────────────
  // PURPOSE: Build a shared, deterministic chat ID
  // for two users. Sorts UIDs so A+B and B+A always
  // produce the same ID.
  //
  // Example: uid "zzz" + uid "aaa" → "aaa_zzz"
  static String getChatId(String otherUserId) {
    final ids = [user.uid, otherUserId]..sort();
    return ids.join('_');
  }

  // ── getAllMessages ────────────────────────────
  // PURPOSE: Real-time stream of all messages in
  // a conversation, ordered oldest → newest.
  // Used by ChatRoom's StreamBuilder.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser chatUser) {
    return firestore
        .collection('chats/${getChatId(chatUser.id)}/messages/')
        .orderBy('sent', descending: false)
        .snapshots();
  }

  // ── sendMessage ──────────────────────────────
  // PURPOSE: Write a new message to Firestore.
  //
  // EXTRA STEP (new behaviour):
  //   After sending, we also call addContact() for
  //   BOTH sides. This means:
  //   - If I search and message someone, they
  //     automatically appear in MY contacts list.
  //   - And I automatically appear in THEIR contacts
  //     list when they receive the message.
  //   This is how WhatsApp works — you don't need
  //   to manually "accept" a contact request. The
  //   first message creates the connection both ways.
  //
  // Firestore path: chats/{chatId}/messages/{timestamp}
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, String type) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final message = Message(
      fromId: user.uid,
      toId: chatUser.id,
      msg: msg,
      type: type,
      sent: time,
      read: '',
    );

    // Write the message document
    await firestore
        .collection('chats/${getChatId(chatUser.id)}/messages/')
        .doc(time)
        .set(message.toJson());

    // ── Auto-add to contacts (both sides) ───────
    // Add receiver to MY contacts if not already there.
    // This makes them appear on my Home screen.
    await addContact(chatUser);

    // Add ME to THEIR contacts using my own profile.
    // This makes me appear on their Home screen when
    // they receive my message.
    await firestore
        .collection('users')
        .doc(chatUser.id) // their contacts list
        .collection('my_contacts')
        .doc(user.uid) // my UID as document ID
        .set(me.toJson()); // my profile data

    // Stamp last active time on my profile
    await updateLastActive();
  }

  // ── markMessageAsRead ─────────────────────────
  // PURPOSE: Fill the 'read' field when receiver
  // opens the chat. Empty read = unread.
  // Only marks messages sent BY the other person.
  static Future<void> markMessageAsRead(
      ChatUser chatUser, Message message) async {
    if (message.fromId == user.uid) return;

    await firestore
        .collection('chats/${getChatId(chatUser.id)}/messages/')
        .doc(message.sent)
        .update(
        {'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  // ── getLastMessage ────────────────────────────
  // PURPOSE: Stream of the single most recent
  // message in a conversation. Used for the
  // preview line on each chat card in Home.
  // .limit(1) keeps this cheap — only 1 doc read.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser chatUser) {
    return firestore
        .collection('chats/${getChatId(chatUser.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  // ── deleteMessage ─────────────────────────────
  // PURPOSE: Permanently delete a message document
  // from Firestore. Triggered on long-press confirm.
  static Future<void> deleteMessage(
      ChatUser chatUser, Message message) async {
    await firestore
        .collection('chats/${getChatId(chatUser.id)}/messages/')
        .doc(message.sent)
        .delete();
  }

  // ── getUnreadCount ────────────────────────────
  // PURPOSE: Count unread messages (read == '')
  // sent TO me in a conversation.
  // Returns Stream<int> for the live badge on Home.
  static Stream<int> getUnreadCount(ChatUser chatUser) {
    return firestore
        .collection('chats/${getChatId(chatUser.id)}/messages/')
        .where('toId', isEqualTo: user.uid)
        .where('read', isEqualTo: '')
        .snapshots()
        .map((snap) => snap.docs.length);
  }


  static Future<void> syncProfileToContacts() async {
    final usersSnapshot = await firestore.collection('users').get();

    for (final userDoc in usersSnapshot.docs) {
      final contactRef = firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('my_contacts')
          .doc(user.uid);

      final contactDoc = await contactRef.get();

      if (contactDoc.exists) {
        await contactRef.update({
          'name': me.name,
          'about': me.about,
          'image': me.image,
        });
      }
    }
  }
}