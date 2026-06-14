// ─────────────────────────────────────────────
// FILE: lib/screens/home.dart
//
// PURPOSE: Main screen showing ONLY the users
// I have existing chats with (my contacts).
//
// ── PRODUCTION REDESIGN ──────────────────────
// OLD behaviour: Showed ALL registered users in
// the app — terrible for privacy and performance.
//
// NEW behaviour:
//   • Home list = only MY contacts (people I've
//     chatted with or explicitly added).
//   • Fresh account = EMPTY list with a friendly
//     "Start a conversation" prompt.
//   • FAB = search any registered user by name
//     or email, then tap to open chat.
//     First message auto-adds them as contact.
//
// ── How contacts appear ───────────────────────
//   1. I open FAB search → find someone → tap them
//      → ChatRoom opens → I send a message
//      → sendMessage() calls addContact() both ways
//      → they appear in my list, I appear in theirs
//
//   2. Someone messages me for the first time
//      → sendMessage() adds me to their contacts
//        AND adds them to my contacts automatically
//      → they appear in my list without me doing
//        anything
// ─────────────────────────────────────────────

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hello_chat/components/chats_card.dart';
import 'package:hello_chat/helper/apis_help.dart';
import 'package:hello_chat/models/chat_user.dart';
import 'package:hello_chat/screens/chat_room.dart';
import 'package:hello_chat/screens/profile_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // ── State variables ──────────────────────────

  // Full list of MY contacts (from my_contacts subcollection).
  // Populated by the StreamBuilder — not getAllUsers() anymore.
  List<ChatUser> _allContacts = [];

  // Filtered list shown when the search bar is active.
  // Built by _onSearchChanged() from _allContacts.
  final List<ChatUser> _searchResults = [];

  // Whether the AppBar search bar is visible.
  bool _isSearching = false;

  // Controller for the AppBar search TextField.
  // Allows clearing the field programmatically.
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSelfInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── _loadSelfInfo ─────────────────────────────
  // PURPOSE: Load my own profile (Apis.me) once.
  // Needed so the Profile screen and sendMessage()
  // both have access to my data without extra reads.
  Future<void> _loadSelfInfo() async {
    try {
      await Apis.selfInfo();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load profile: $e')),
        );
      }
    }
  }

  // ── _onSearchChanged ──────────────────────────
  // PURPOSE: Filter the contacts list (not all users)
  // as the user types in the AppBar search bar.
  //
  // This searches WITHIN my existing contacts only.
  // Searching all users happens in the FAB sheet.
  void _onSearchChanged(String val) {
    _searchResults.clear();
    for (final contact in _allContacts) {
      if (contact.name.toLowerCase().contains(val.toLowerCase()) ||
          contact.email.toLowerCase().contains(val.toLowerCase())) {
        _searchResults.add(contact);
      }
    }
    setState(() {});
  }

  // ── _toggleSearch ─────────────────────────────
  // PURPOSE: Show / hide the AppBar search bar.
  // Clears text and results when closing.
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchResults.clear();
      }
    });
  }

  // ════════════════════════════════════════════
  // FAB — SEARCH & ADD NEW CONTACT
  // ════════════════════════════════════════════

  // ── _showAddContactSheet ──────────────────────
  // PURPOSE: Bottom sheet that lets the user search
  // ALL registered users by name or email and start
  // a new chat with anyone they find.
  //
  // HOW IT WORKS:
  //   1. User types in the search field
  //   2. Apis.searchUsers(query) fetches from Firestore
  //      and filters client-side
  //   3. Results show a profile card with an
  //      "Added" badge or "Chat" button
  //   4. Tapping "Chat" opens ChatRoom directly
  //      — first message auto-adds them as contact
  void _showAddContactSheet() {
    // Local state for this sheet only.
    // We use StatefulBuilder so these variables
    // can rebuild the sheet without rebuilding Home.
    List<ChatUser> results = [];
    bool isSearching = false;
    Map<String, bool> contactStatusCache = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {

            // ── _runSearch ───────────────────
            // Calls Apis.searchUsers() and updates
            // the results list inside the sheet.
            // Also checks which results are already
            // in my contacts (to show "Added" badge).
            Future<void> runSearch(String query) async {
              if (query.trim().isEmpty) {
                setSheetState(() {
                  results = [];
                  isSearching = false;
                });
                return;
              }

              // Show loading indicator
              setSheetState(() => isSearching = true);

              // Fetch matching users from Firestore
              final found = await Apis.searchUsers(query);

              // For each result, check if already a contact
              for (final u in found) {
                if (!contactStatusCache.containsKey(u.id)) {
                  contactStatusCache[u.id] = await Apis.isContact(u.id);
                }
              }

              setSheetState(() {
                results = found;
                isSearching = false;
              });
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // ── Handle ────────────────
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // ── Sheet title ───────────
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'New Chat',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // ── Search field ──────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: TextField(
                          autofocus: true,
                          // Call runSearch on every keystroke.
                          // Debounce would be better for large
                          // user bases but fine for this scale.
                          onChanged: (val) => runSearch(val),
                          decoration: InputDecoration(
                            hintText: 'Search by name or email...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),

                      const Divider(height: 16),

                      // ── Results list ──────────
                      Expanded(
                        child: isSearching
                        // Loading spinner while searching
                            ? const Center(
                            child: CircularProgressIndicator())
                            : results.isEmpty
                        // Empty state
                            ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_search_rounded,
                                  size: 56,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text(
                                'Search for someone to chat with',
                                style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        )
                        // Results
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final foundUser = results[i];
                            final alreadyContact =
                                contactStatusCache[foundUser.id] ??
                                    false;

                            return _SearchResultTile(
                              user: foundUser,
                              alreadyContact: alreadyContact,
                              onChatTap: () {
                                // Close the sheet first
                                Navigator.pop(ctx);
                                // Open ChatRoom for this user.
                                // When they send the first message,
                                // sendMessage() auto-adds the contact.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatRoom(
                                        chatUser: foundUser),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (_isSearching) {
            _toggleSearch();
          } else {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: _isSearching
            // ── Search mode in AppBar ──────
                ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                hintStyle: const TextStyle(color: Colors.white60),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white12,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16),
              ),
            )
                : const Text('Hello Chat'),
            actions: [
              IconButton(
                onPressed: _toggleSearch,
                icon: Icon(_isSearching
                    ? Icons.close_rounded
                    : Icons.search_rounded),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileScreen(chatUser: Apis.me),
                  ),
                ),
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),

          // ── Body: MY contacts stream ──────────
          // Uses getMyContacts() NOT getAllUsers().
          // Only shows people in my_contacts subcollection.
          body: StreamBuilder<QuerySnapshot>(
            stream: Apis.getMyContacts(),
            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // Parse the my_contacts documents into ChatUser objects
              _allContacts = snapshot.data!.docs
                  .map((e) =>
                  ChatUser.fromJson(e.data() as Map<String, dynamic>))
                  .toList();

              // Which list to show: filtered (search) or full
              final displayList =
              _isSearching ? _searchResults : _allContacts;

              // ── EMPTY STATE ───────────────────
              // No contacts yet → show a friendly
              // prompt pointing to the FAB.
              // This is what a new user sees on first login.
              if (_allContacts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 72,
                        color: Colors.purple.shade100,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No chats yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the button below to find\nsomeone and start chatting',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: Colors.black38),
                      ),
                      const SizedBox(height: 32),
                      // Arrow pointing down toward FAB
                      Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.purple.shade300,
                        size: 28,
                      ),
                    ],
                  ),
                );
              }

              // ── SEARCH EMPTY STATE ────────────
              if (_isSearching && _searchResults.isEmpty) {
                return Center(
                  child: Text(
                    'No chats matching "${_searchController.text}"',
                    style: const TextStyle(color: Colors.black45),
                  ),
                );
              }

              // ── CHAT LIST ─────────────────────
              // Shows only my contacts, each as a ChatsCard
              // with last message preview + unread badge.
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  return ChatsCard(user: displayList[index]);
                },
              );
            },
          ),

          // ── FAB: Start new chat ───────────────
          // Opens the search sheet where users can
          // find anyone in the app and start chatting.
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 20, right: 10),
            child: FloatingActionButton(
              onPressed: _showAddContactSheet,
              backgroundColor: Colors.purple.shade400,
              tooltip: 'New chat',
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET: _SearchResultTile
//
// PURPOSE: One row in the FAB search results.
// Shows the found user's avatar, name, email, and
// either a "Chat" button or an "Added" badge.
//
// Kept as a private widget in this file because
// it's only used inside _showAddContactSheet().
// ─────────────────────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final ChatUser user;

  // Whether this person is already in my contacts.
  // Determines whether to show "Chat" or "Added".
  final bool alreadyContact;

  // Called when user taps "Chat" button.
  final VoidCallback onChatTap;

  const _SearchResultTile({
    required this.user,
    required this.alreadyContact,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

      // ── Avatar ────────────────────────────
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: CachedNetworkImage(
          height: 50,
          width: 50,
          fit: BoxFit.cover,
          imageUrl: user.image,
          placeholder: (_, __) =>
          const CircularProgressIndicator(),
          errorWidget: (_, __, ___) =>
          const CircleAvatar(child: Icon(Icons.person)),
        ),
      ),

      // ── Name + email ──────────────────────
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        user.email,
        style: const TextStyle(fontSize: 12, color: Colors.black45),
        overflow: TextOverflow.ellipsis,
      ),

      // ── Action button ─────────────────────
      // "Added" badge if already a contact.
      // "Chat" button if not yet a contact.
      trailing: alreadyContact
      // Already in contacts — show badge only
          ? Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          'Added',
          style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500),
        ),
      )
      // Not yet a contact — show Chat button
          : ElevatedButton(
        onPressed: onChatTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          minimumSize: const Size(70, 34),
        ),
        child: const Text('Chat',
            style: TextStyle(fontSize: 13)),
      ),

      // Tapping anywhere on the tile also opens chat
      onTap: onChatTap,
    );
  }
}