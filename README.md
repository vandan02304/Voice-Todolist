# 🎤 Voice-Driven To-Do List App (Flutter)

## 🚀 Overview

The Voice-Driven To-Do List App is a Flutter-based application that enables users to manage tasks entirely through voice commands. It supports offline functionality, real-time synchronization, and natural language understanding to provide a seamless hands-free experience.

---

## ✨ Features

* 🎤 **Voice Commands**

  * Add, update, delete, and query tasks using natural speech
* 🧠 **Natural Language Processing**

  * Extract task details like title, date, and time
* 💾 **Offline-First Architecture**

  * Works without internet using local storage (Hive)
* 🔄 **Auto Sync**

  * Syncs data with cloud (Firebase Firestore) when online
* 📡 **Real-Time Updates**

  * Tasks update instantly across multiple devices
* 🔊 **Voice Feedback**

  * Provides spoken confirmations and prompts
* 📱 **Clean UI**

  * Simple and intuitive task management interface

---

## 🛠️ Tech Stack

| Component        | Technology         |
| ---------------- | ------------------ |
| Frontend         | Flutter            |
| State Management | Riverpod           |
| Local Storage    | Hive               |
| Backend          | Firebase Firestore |
| Speech-to-Text   | speech_to_text     |
| Text-to-Speech   | flutter_tts        |
| Date Handling    | intl               |

---

## 📂 Project Structure

```
lib/
 ├── main.dart
 ├── models/
 ├── services/
 │    ├── speech_service.dart
 │    ├── tts_service.dart
 │    ├── sync_service.dart
 ├── providers/
 ├── screens/
 ├── widgets/
 ├── utils/
```

---

## ⚙️ Installation & Setup

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/your-username/voice-todo-app.git
cd voice-todo-app
```

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

---

### 3️⃣ Firebase Setup

1. Go to Firebase Console
2. Create a new project
3. Add Android/iOS app
4. Download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
5. Place files in appropriate directories
6. Enable **Cloud Firestore**

---

### 4️⃣ Run the App

```bash
flutter run
```

---

## 🧠 How It Works

1. User speaks a command
2. Speech is converted to text
3. Command is parsed using NLP logic
4. Task is stored locally (Hive)
5. If online → synced to Firebase
6. If offline → queued and synced later
7. App responds using voice feedback

---

## 📊 Data Models

### Task Model

* id
* title
* description
* dueDate
* status
* createdAt
* updatedAt
* isSynced

### Offline Command Model

* id
* commandText
* parsedAction
* timestamp
* isSynced

---

## ⚠️ Permissions Required

* Microphone (for voice input)
* Internet (for sync)
* Storage (for local caching)

---

## 🔮 Future Enhancements

* 🤖 AI-based smart task suggestions
* 📍 Location-based reminders
* 🔐 Voice authentication
* 🌙 Dark mode support
* 🧠 Advanced NLP using ML

---

## 🤝 Contribution

Contributions are welcome!
Feel free to fork the repository and submit pull requests.

---

## 📜 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

**Vandan Patel**
B.Tech IT | Cybersecurity Enthusiast

---

## ⭐ Support

If you like this project, give it a ⭐ on GitHub!
