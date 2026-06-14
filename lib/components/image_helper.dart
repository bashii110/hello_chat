// ─────────────────────────────────────────────
// FILE: lib/components/image_helper.dart
//
// PURPOSE: A single reusable widget that smartly
// displays a user's profile image regardless of
// what format it is stored in.
//
// WHY THIS FILE EXISTS:
//   Profile images in this app can be stored in
//   two different formats:
//
//   1. URL string  → users who signed in with Google
//      get a photo URL like:
//      "https://lh3.googleusercontent.com/..."
//
//   2. Base64 string → users who uploaded a photo
//      from their device get a long Base64 string like:
//      "/9j/4AAQSkZJRgABAQAA..."
//
//   Instead of writing this if/else logic in every
//   single widget (ChatsCard, ChatRoom AppBar,
//   ProfileScreen, SearchResultTile...), we write it
//   ONCE here and reuse it everywhere.
//
// USAGE:
//   UserAvatar(imageData: user.image, radius: 20)
//
//   That's it. Pass the raw image string and a radius.
//   The widget figures out which format it is.
// ─────────────────────────────────────────────

import 'dart:convert'; // for base64Decode
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  // The raw image string from Firestore.
  // Could be a URL or a Base64 string.
  final String imageData;

  // Radius of the circular avatar.
  // radius: 20 → 40px diameter (chat list)
  // radius: 100 → 200px diameter (profile screen)
  final double radius;

  const UserAvatar({
    super.key,
    required this.imageData,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    // ── Case 1: No image ─────────────────────
    // Empty string → show default person icon
    if (imageData.isEmpty) {
      return _placeholder();
    }

    // ── Case 2: URL (Google Sign-In photo) ───
    // URLs always start with "http" or "https".
    // Use CachedNetworkImage for efficient loading
    // with automatic disk caching.
    if (imageData.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.purple.shade50,
        child: ClipOval(
          child: CachedNetworkImage(
            height: radius * 2,
            width: radius * 2,
            fit: BoxFit.cover,
            imageUrl: imageData,
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _placeholder(),
          ),
        ),
      );
    }

    // ── Case 3: Base64 string (uploaded photo) ─
    // Anything that doesn't start with "http" is
    // treated as Base64.
    //
    // base64Decode() converts the string back into
    // raw bytes (Uint8List).
    // Image.memory() renders those bytes as a widget.
    try {
      final bytes = base64Decode(imageData);
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.purple.shade50,
        child: ClipOval(
          child: Image.memory(
            bytes,
            height: radius * 2,
            width: radius * 2,
            fit: BoxFit.cover,
            // If decoding somehow fails, show placeholder
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        ),
      );
    } catch (_) {
      // base64Decode threw an exception —
      // malformed string, show placeholder
      return _placeholder();
    }
  }

  // ── _placeholder ─────────────────────────────
  // Default purple circle with person icon.
  // Shown when image is empty or fails to load.
  Widget _placeholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.purple.shade50,
      child: Icon(
        Icons.person_rounded,
        size: radius,
        color: Colors.purple.shade300,
      ),
    );
  }
}