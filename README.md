<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=0:4A0080,50:7B2FBE,100:9B59B6&height=220&section=header&text=Hello%20Chat&fontSize=62&fontColor=ffffff&fontAlignY=36&desc=Real-time+Chat+%E2%80%A2+Flutter+%2B+Firebase&descAlignY=56&descSize=19&animation=fadeIn" width="100%"/>
</div>

<br/>

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.27.0-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.6.2-0175C2?style=flat-square&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=flat-square&logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-9B59B6?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-7B2FBE?style=flat-square)

[![Downloads](https://img.shields.io/github/downloads/bashii110/hello_chat/total?style=flat-square&color=9B59B6)](https://github.com/bashii110/hello_chat/releases)
[![GitHub Release](https://img.shields.io/github/v/release/bashii110/hello_chat?style=flat-square&color=7B2FBE)](https://github.com/bashii110/hello_chat/releases/latest)
[![Stars](https://img.shields.io/github/stars/bashii110/hello_chat?style=flat-square&color=9B59B6)](https://github.com/bashii110/hello_chat/stargazers)
[![Issues](https://img.shields.io/github/issues/bashii110/hello_chat?style=flat-square&color=7B2FBE)](https://github.com/bashii110/hello_chat/issues)

</div>

---

<div align="center">

### A full-featured, production-ready real-time chat app.
### Built with Flutter & Firebase — private, fast, and beautiful.

</div>

---

## 🌟 What makes it different

> Most tutorial chat apps dump every registered user on your screen the moment you sign in.  
> **Hello Chat** starts you with an empty inbox — just like WhatsApp.  
> Your contacts only appear after you actively find and message them. Privacy first, always.

---

## 📱 Screenshots

<div align="center">

<table>
<tr>
<td align="center">
<img src="https://github.com/user-attachments/assets/947df8ae-d5e4-4274-8d5d-c1318c79324d" width="180"/>
<br><b>Login</b>
</td>

<td align="center">
<img src="https://github.com/user-attachments/assets/c4ad20a0-5820-4ff5-b44a-2db3e306f8f7" width="180"/>
<br><b>Registration</b>
</td>

<td align="center">
<img src="https://github.com/user-attachments/assets/80fc609a-aa44-41f5-b781-6df0782e572b" width="180"/>
<br><b>Home</b>
</td>

<td align="center">
<img src="https://github.com/user-attachments/assets/e0b73b19-527b-4c8f-85c8-78593ed81792" width="180"/>
<br><b>Chat Room</b>
</td>

<td align="center">
<img src="https://github.com/user-attachments/assets/7f14bc61-16e7-4978-b762-22a7a684ba09" width="180"/>
<br><b>Profile</b>
</td>
</tr>
</table>

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%" valign="top">

### 🔐 Authentication
```
✔  Email & Password registration
✔  Google One-Tap Sign-In
✔  Email verification gate
✔  Password reset via email
✔  Persistent login sessions
✔  Secure logout
```

</td>
<td width="50%" valign="top">

### 💬 Real-time Messaging
```
✔  Instant messages via Firestore streams
✔  Sent / Read receipts (grey → blue ticks)
✔  Timestamps on every message
✔  Long-press to delete messages
✔  Last message preview in chat list
✔  Unread count badge (live)
```

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 👤 Profile System
```
✔  Update name and about text
✔  Camera or gallery photo upload
✔  Image stored as Base64 in Firestore
✔  Photo syncs to all contacts instantly
✔  Last active timestamp
✔  No external storage required
```

</td>
<td width="50%" valign="top">

### 🔍 Smart Contacts
```
✔  Empty home screen on first login
✔  Search all users by name or email
✔  Auto-add contact on first message
✔  Auto-appear in their list too
✔  Search within existing chats
✔  Remove contact without losing history
```

</td>
</tr>
</table>

---

<details>
<summary>🏗️ Project Structure</summary>

```
hello_chat/
│
├── lib/
│   ├── main.dart                     # Entry point — Firebase init
│   ├── firebase_options.dart         # Auto-generated Firebase config
│   │
│   ├── models/
│   │   ├── chat_user.dart            # User data model + fromJson/toJson
│   │   └── message.dart              # Message model + fromJson/toJson
│   │
│   ├── helper/
│   │   └── apis_help.dart            # ★ All Firebase operations live here
│   │
│   ├── screens/
│   │   ├── splash_screen.dart        # Auto-login detection
│   │   ├── home.dart                 # Contacts list + search
│   │   ├── chat_room.dart            # Real-time chat screen
│   │   ├── profile_screen.dart       # Edit profile + image upload
│   │   └── verify_email.dart         # Email verification screen
│   │
│   ├── Auth services/
│   │   ├── login_screen.dart         # Login + forgot password
│   │   └── signup_screen.dart        # New account registration
│   │
│   ├── components/
│   │   ├── chats_card.dart           # Contact card with preview + badge
│   │   ├── roundbutton.dart          # Reusable loading button
│   │   └── image_helper.dart         # Smart Base64 / URL image widget
│   │
│   ├── widgets/
│   │   └── message_card.dart         # Single chat bubble (sent/received)
│   │
│   └── utils/
│       └── utilities.dart            # Toast message helper
│
└── assets/
    └── images/                       # App icon and static assets
```

</details>

---

## 🗄️ Database Design

```
Firestore
│
├── users/{uid}
│   ├── id            → Firebase UID
│   ├── name          → Display name
│   ├── email         → Email address
│   ├── image         → Base64 string or Google photo URL
│   ├── about         → Status text
│   ├── last_active   → "yyyy-MM-dd HH:mm:ss"
│   ├── contact_of[]  → [uid1, uid2, ...]  ← who has me in their list
│   │
│   └── my_contacts/{contactUid}     ← subcollection
│       └── (full ChatUser fields)   ← copy of their profile
│
└── chats/{uid_uid}                  ← UIDs sorted + joined by _
    └── messages/{timestamp}
        ├── fromId  → sender UID
        ├── toId    → receiver UID
        ├── msg     → message text
        ├── type    → "text" | "image"
        ├── sent    → Unix ms timestamp (also used as doc ID)
        └── read    → Unix ms when read, or "" if unread
```

---

## 🔄 Core User Flows

```
First Launch
    ↓
Splash Screen checks FirebaseAuth.currentUser
    ↓                              ↓
 Logged in                    Not logged in
    ↓                              ↓
  Home                         Login Screen


Adding a Contact
    ↓
Tap FAB (pencil icon) on Home
    ↓
Search sheet opens → type name or email
    ↓
Tap "Chat" on any result
    ↓
ChatRoom opens → send first message
    ↓
sendMessage() writes to Firestore
    ↓
addContact() fires for BOTH users
    ↓
Both Home screens update in real-time


Profile Photo Update Sync
    ↓
User picks photo → compressed to Base64
    ↓
Saved to users/{uid}.image
    ↓
_syncProfileToContacts() reads contact_of[]
    ↓
Updates my entry in each person's my_contacts
    ↓
Their chat lists + chat rooms show new photo
```

---

## 🚀 Getting Started

### Requirements

| | Minimum |
|---|---|
| Flutter | 3.27.0 |
| Dart | 3.6.2 |
| Android SDK | API 23+ |
| iOS | 12.0+ |
| Java | 17+ |

### 1 — Clone

```bash
git clone https://github.com/bashii110/hello_chat.git
cd hello_chat
flutter pub get
```

### 2 — Firebase setup

```bash
# Install tools
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Login and connect your Firebase project
firebase login
flutterfire configure
```

Then place your config files:
```
android/app/google-services.json        ← from Firebase Console
ios/Runner/GoogleService-Info.plist     ← from Firebase Console
```

### 3 — Firestore Security Rules

Paste these into Firebase Console → Firestore → Rules:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;

      match /my_contacts/{contactId} {
        allow read, write: if request.auth.uid == uid;
      }
    }

    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null
        && chatId.matches('.*' + request.auth.uid + '.*');
    }
  }
}
```

### 4 — Run

```bash
# Development
flutter run

# Release APK
flutter build apk --release

# Web
flutter build web --release --base-href /hello_chat/
```

---

## 📦 Dependencies

```yaml
firebase_core:          # Firebase initialization
firebase_auth:          # Authentication — email + Google
cloud_firestore:        # Real-time NoSQL database
google_sign_in:         # Google OAuth flow
image_picker:           # Camera and gallery access
cached_network_image:   # Efficient URL image caching
fluttertoast:           # Lightweight toast messages
intl:                   # Date/time formatting
```

---

## 🛡️ Security

- Firebase API keys live in **GitHub Secrets** — never committed to source
- Profile photos are Base64 in Firestore — no public storage URLs
- Firestore rules enforce that users can only read/write their own data
- Password resets via Firebase secure tokens — expire after 1 hour
- Google Sign-In uses OAuth 2.0 — no passwords stored anywhere

---

## 🗺️ Roadmap

```
v1.0  ✅  Authentication (email + Google)
v1.0  ✅  Real-time messaging
v1.0  ✅  Read receipts
v1.0  ✅  Profile photo (Base64 Firestore)
v1.0  ✅  Contact system (WhatsApp style)

v1.1  🔲  Image messages (send photos in chat)
v1.1  🔲  Push notifications (FCM)
v1.1  🔲  CI/CD pipeline
v1.2  🔲  Voice messages
v1.2  🔲  Group chats
v1.3  🔲  End-to-end encryption
v1.3  🔲  Message reactions
v2.0  🔲  Video calls (WebRTC)
```

---

## 👨‍💻 About the Developer

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=soft&color=0:4A0080,100:9B59B6&height=90&text=Bashir%20Ahmed&fontSize=30&fontColor=ffffff" width="450"/>

**Final Year Software Engineering Student · Flutter Developer · Open to Work**

📍 Pakistan &nbsp;·&nbsp; 💼 Available for internship / junior roles

<br/>

[![Portfolio](https://img.shields.io/badge/Portfolio-bashii110.github.io-4A0080?style=for-the-badge)](https://bashii110.github.io/bashir_ahmed_portfolio/)
[![Email](https://img.shields.io/badge/Email-buxhiisd@gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:buxhiisd@gmail.com)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Bashir_Ahmed-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/Bashir%20Ahmed)
[![GitHub](https://img.shields.io/badge/GitHub-bashii110-181717?style=for-the-badge&logo=github)](https://github.com/bashii110)
[![Resume](https://img.shields.io/badge/Resume-Download-7B2FBE?style=for-the-badge&logo=googledrive&logoColor=white)](https://drive.google.com/file/d/1xqtLzeXhm-QGYgSfdOYin2CqbIvmEAcq/view?usp=drive_link)

</div>

---

## 📄 License

```
MIT License

Copyright (c) 2025 Bashir Ahmed

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software to use, copy, modify, merge, and distribute it,
subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
```

---

<div align="center">

**If this project helped you, drop a ⭐ — it means a lot!**

<br/>

*Built with 💜 using Flutter & Firebase*

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:9B59B6,100:4A0080&height=130&section=footer" width="100%"/>

</div>
