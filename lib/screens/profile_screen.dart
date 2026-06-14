// ─────────────────────────────────────────────
// FILE: lib/screens/profile_screen.dart
//
// PURPOSE: Profile view and edit screen.
//
// ── IMAGE STORAGE APPROACH ────────────────────
// Images are stored as Base64 strings directly
// inside the Firestore user document.
//
// NO Firebase Storage needed at all.
//
// HOW BASE64 WORKS:
//   A Base64 string is just an image file converted
//   into a long text string. Example:
//     /9j/4AAQSkZJRgABAQAA...  (very long string)
//
//   We store this string in the 'image' field of
//   the user document in Firestore, then display
//   it using Image.memory() which converts it
//   back to pixels.
//
// FLOW:
//   Pick image from gallery/camera
//   → read file bytes
//   → convert bytes to Base64 string
//   → save string to Firestore users/{uid}.image
//   → display with Image.memory(base64Decode(string))
//
// LIMITS:
//   Firestore document max size = 1MB.
//   A profile photo at 512×512, quality 60 is
//   roughly 30–100KB as Base64. Well within limits.
//   We compress aggressively to stay safe.
// ─────────────────────────────────────────────

import 'dart:convert';  // for base64Encode and base64Decode
import 'dart:io';       // for File class

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // ── State ────────────────────────────────────

  // The locally picked image file.
  // null = user hasn't picked a new photo yet.
  File? _pickedImageFile;

  // The Base64 string of the picked image.
  // Built in _pickImage() right after picking.
  // Saved to Firestore when user taps Save.
  String? _base64Image;

  // Text field controllers
  late final TextEditingController _nameController;
  late final TextEditingController _aboutController;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // True while saving to Firestore — shows overlay
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();

  // ── initState ────────────────────────────────
  // Pre-fill fields with existing data.
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.chatUser.name);
    _aboutController = TextEditingController(text: widget.chatUser.about);
  }

  // ── dispose ──────────────────────────────────
  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════
  // IMAGE PICKING + BASE64 CONVERSION
  // ════════════════════════════════════════════

  // ── _showImageSourcePicker ────────────────────
  // PURPOSE: Bottom sheet to choose Camera or Gallery.
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Colors.purple),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Colors.purple),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── _pickImage ────────────────────────────────
  // PURPOSE: Pick image from camera or gallery,
  // then immediately convert it to a Base64 string.
  //
  // WHY CONVERT TO BASE64 HERE (not at save time):
  //   So we can show a preview immediately AND
  //   we know the size before trying to save.
  //   If the Base64 is too large we can warn the user
  //   before they tap Save.
  //
  // imageQuality: 60  → aggressive compression
  //                      keeps Base64 string small
  //                      for Firestore doc limits
  // maxWidth/Height: 400 → smaller than Storage version
  //                         because we need smaller size
  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 60,    // compress to 60% — keeps file small
      maxWidth: 400,       // max 400px wide
      maxHeight: 400,      // max 400px tall
    );

    if (picked == null) return; // user cancelled

    final file = File(picked.path);

    // ── Convert to Base64 ───────────────────
    // readAsBytes() reads the file as raw bytes (Uint8List).
    // base64Encode() converts those bytes into a
    // plain text string that can be stored anywhere text goes.
    //
    // Example:
    //   bytes: [255, 216, 255, 224, ...]
    //   base64: "/9j/4AAQSkZJRgAB..."
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);

    // ── Size check ──────────────────────────
    // Base64 encoding inflates size by ~33%.
    // A 200KB image becomes ~266KB as Base64.
    // Firestore doc limit is 1MB — we warn at 700KB
    // to leave room for the other fields.
    //
    // base64String.length is the number of characters.
    // Each character = 1 byte in UTF-8.
    final sizeKb = base64String.length / 1024;

    if (sizeKb > 700) {
      // Image is too large even after compression.
      // Tell the user and don't set the image.
      Utilities().toastMessage(
          'Image too large (${sizeKb.toStringAsFixed(0)}KB). '
              'Please choose a smaller photo.');
      return;
    }

    // Update state: show preview + store Base64
    setState(() {
      _pickedImageFile = file;    // for local preview
      _base64Image = base64String; // for saving to Firestore
    });
  }

  // ════════════════════════════════════════════
  // SAVE PROFILE
  // ════════════════════════════════════════════

  // ── _saveProfile ─────────────────────────────
  // PURPOSE: Validate form then save name, about,
  // and (if changed) the new Base64 image string
  // all together in one Firestore write.
  //
  // WHY ONE WRITE:
  //   Fewer Firestore writes = lower cost + faster.
  //   We update all fields at once using .update()
  //   with a map that includes only changed fields.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // ── Update Apis.me in memory ────────────
      // This keeps the in-memory profile in sync
      // so other screens see the changes immediately
      // without needing a new Firestore fetch.
      Apis.me.name = _nameController.text.trim();
      Apis.me.about = _aboutController.text.trim();

      // Only update image if a new one was picked.
      // If _base64Image is null, keep existing image.
      if (_base64Image != null) {
        Apis.me.image = _base64Image!;
      }

      // ── Write to Firestore ──────────────────
      // updateUserInfo() writes name + about + image
      // from Apis.me to Firestore users/{uid}.
      await Apis.updateUserInfo();
      await Apis.syncProfileToContacts();

      // ── Update local widget data ────────────
      // So the profile screen itself reflects the
      // new values without rebuilding from parent.
      widget.chatUser.name = Apis.me.name;
      widget.chatUser.about = Apis.me.about;
      widget.chatUser.image = Apis.me.image;

      Utilities().toastMessage('Profile updated!');
    } catch (e) {
      Utilities().toastMessage('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ════════════════════════════════════════════
  // IMAGE DISPLAY HELPER
  // ════════════════════════════════════════════

  // ── _buildProfileImage ────────────────────────
  // PURPOSE: Show the right image depending on state.
  //
  // 3 possible states:
  //   1. User just picked a new image
  //      → show File preview (_pickedImageFile)
  //   2. User has an existing Base64 image in Firestore
  //      → show Image.memory(base64Decode(string))
  //   3. User has a URL image (Google sign-in photo)
  //      → show CachedNetworkImage(url)
  //   4. No image at all
  //      → show person icon placeholder
  //
  // HOW TO DETECT IF IMAGE FIELD IS BASE64 VS URL:
  //   A URL always starts with "http" or "https".
  //   A Base64 string starts with "/" or "i" or "A" etc.
  //   So we just check if the string starts with "http".
  Widget _buildProfileImage() {
    // State 1: new image just picked — show local preview
    if (_pickedImageFile != null) {
      return Image.file(
        _pickedImageFile!,
        height: 200,
        width: 200,
        fit: BoxFit.cover,
      );
    }

    final imageData = widget.chatUser.image;

    // State 2: empty image field — show placeholder
    if (imageData.isEmpty) {
      return _placeholderAvatar();
    }

    // State 3: it's a URL (Google Sign-In photo)
    // URLs start with "http" or "https"
    if (imageData.startsWith('http')) {
      return CachedNetworkImage(
        height: 200,
        width: 200,
        fit: BoxFit.cover,
        imageUrl: imageData,
        placeholder: (_, __) => _placeholderAvatar(),
        errorWidget: (_, __, ___) => _placeholderAvatar(),
      );
    }

    // State 4: it's a Base64 string stored in Firestore
    // base64Decode() converts the string back to bytes.
    // Image.memory() renders bytes directly as an image.
    try {
      return Image.memory(
        base64Decode(imageData), // decode Base64 → bytes
        height: 200,
        width: 200,
        fit: BoxFit.cover,
        // If decoding fails for any reason, show placeholder
        errorBuilder: (_, __, ___) => _placeholderAvatar(),
      );
    } catch (_) {
      return _placeholderAvatar();
    }
  }

  // ── _placeholderAvatar ────────────────────────
  // PURPOSE: Default purple circle with person icon.
  // Shown when no image is available.
  Widget _placeholderAvatar() {
    return Container(
      height: 200,
      width: 200,
      color: Colors.purple.shade50,
      child: Icon(Icons.person_rounded,
          size: 80, color: Colors.purple.shade300),
    );
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Stack(
          children: [
            // ── Scrollable content ────────────
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),

                      // ── Profile photo ─────────────
                      Center(
                        child: Stack(
                          children: [
                            // Photo circle
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: _buildProfileImage(),
                            ),
                            // Edit button overlay
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImageSourcePicker,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade400,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Email label (read only) ────
                      Text(
                        widget.chatUser.email,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple.shade400),
                      ),

                      const SizedBox(height: 30),

                      // ── Name field ────────────────
                      TextFormField(
                        controller: _nameController,
                        onSaved: (val) =>
                        Apis.me.name = val?.trim() ?? '',
                        validator: (val) =>
                        val != null && val.trim().isNotEmpty
                            ? null
                            : 'Name cannot be empty',
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Enter Name',
                          prefixIcon: const Icon(Icons.person_rounded,
                              color: Colors.purple),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50)),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ── About field ───────────────
                      TextFormField(
                        controller: _aboutController,
                        onSaved: (val) =>
                        Apis.me.about = val?.trim() ?? '',
                        validator: (val) =>
                        val != null && val.trim().isNotEmpty
                            ? null
                            : 'About cannot be empty',
                        maxLength: 100,
                        decoration: InputDecoration(
                          hintText: 'About...',
                          prefixIcon: const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.purple),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50)),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Save button ───────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: _isLoading ? null : _saveProfile,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Profile',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // ── Logout button ─────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () async {
                            await _auth.signOut();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                    (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Logout',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            // ── Loading overlay ───────────────
            // Shown while Firestore write is in progress.
            // Prevents tapping anything mid-save.
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Saving profile...',
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}