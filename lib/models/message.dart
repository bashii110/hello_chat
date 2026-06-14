// ─────────────────────────────────────────────
// FILE: lib/models/message.dart
//
// PURPOSE: Defines the data structure for a
// single chat message. Every message stored in
// Firestore maps to one of these objects.
// ─────────────────────────────────────────────

class Message {
  // ── Fields ──────────────────────────────────

  // Unique ID of the sender (Firebase UID)
  final String fromId;

  // Unique ID of the receiver (Firebase UID)
  final String toId;

  // The actual text content of the message
  final String msg;

  // Type of message: "text" or "image"
  final String type;

  // Unix timestamp (milliseconds) when the message was sent
  final String sent;

  // Unix timestamp when receiver read the message.
  // Empty string "" means it has NOT been read yet.
  final String read;

  // ── Constructor ──────────────────────────────
  const Message({
    required this.fromId,
    required this.toId,
    required this.msg,
    required this.type,
    required this.sent,
    required this.read,
  });

  // ── fromJson ─────────────────────────────────
  // Converts a raw Firestore document (Map) into
  // a typed Message object.
  //
  // Called like:  Message.fromJson(doc.data())
  //
  // The ?. and ?? operators protect against null
  // values coming from Firestore (e.g. old docs
  // that are missing a field).
  Message.fromJson(Map<String, dynamic> json)
      : fromId = json['fromId']?.toString() ?? '',
        toId = json['toId']?.toString() ?? '',
        msg = json['msg']?.toString() ?? '',
        type = json['type']?.toString() ?? 'text',
        sent = json['sent']?.toString() ?? '',
        read = json['read']?.toString() ?? '';

  // ── toJson ───────────────────────────────────
  // Converts this Message object into a plain Map
  // so Firestore can store it as a document.
  //
  // Called like:  firestore.set(message.toJson())
  Map<String, dynamic> toJson() {
    return {
      'fromId': fromId,
      'toId': toId,
      'msg': msg,
      'type': type,
      'sent': sent,
      'read': read,
    };
  }
}