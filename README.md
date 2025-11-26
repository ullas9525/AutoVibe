# 📳 AutoVibe

> **Silence is Golden. Automation is Platinum.**

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Kotlin](https://img.shields.io/badge/kotlin-%237F52FF.svg?style=for-the-badge&logo=kotlin&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)

**AutoVibe** is a smart, automated ringer manager for Android built with Flutter. It ensures you never embarrass yourself in a meeting or miss a call after work by automatically toggling your phone's vibration mode based on your custom schedule.

---

## ✨ Features

- **📅 Custom Schedules**: Set specific days and times for your phone to go silent (Vibrate) and when to ring out loud.
- **🔋 Doze-Proof Reliability**: Uses advanced `AlarmManager` logic (`allowWhileIdle`) to ensure schedules trigger exactly on time, even when your phone is sleeping.
- **🎨 Premium Dark UI**: A sleek, modern interface designed for comfort and ease of use.
- **🔊 Native Control**: Directly interacts with Android's `AudioManager` for reliable volume control.
- **🛠️ Debug Mode**: Built-in logging system to verify background execution.

---

## 🚀 How It Works

AutoVibe isn't just a simple timer. It uses a robust background service architecture to handle Android's aggressive battery optimizations.

1.  **Schedule**: You define a time range (e.g., "Work: 9:00 AM - 5:00 PM").
2.  **Sleep**: The app schedules a high-priority alarm using `AndroidAlarmManager`.
3.  **Wake & Execute**: Even if your phone is in deep sleep (Doze), AutoVibe wakes up for a split second, toggles your ringer mode via a custom Native Kotlin Plugin, and goes back to sleep.
4.  **Repeat**: It automatically reschedules itself for the next active day.

---

## 🛠️ Tech Stack

-   **Framework**: Flutter (Dart)
-   **Native Integration**: Kotlin (Android Method Channels)
-   **Background Processing**: `android_alarm_manager_plus`
-   **State Management**: `setState` (Keep it simple!)
-   **Storage**: `shared_preferences`

---

## 📸 Screenshots

| Dashboard | Create Schedule | Settings |
|:---:|:---:|:---:|
| *(Add Screenshot)* | *(Add Screenshot)* | *(Add Screenshot)* |

---

## 🔧 Installation

1.  Clone the repo
    ```bash
    git clone https://github.com/yourusername/autovibe.git
    ```
2.  Install dependencies
    ```bash
    flutter pub get
    ```
3.  Run on Android
    ```bash
    flutter run
    ```

> **Note**: This app requires the `MODIFY_AUDIO_SETTINGS` and `SCHEDULE_EXACT_ALARM` permissions.

---

## 🤝 Contributing

Contributions are welcome! Feel free to open an issue or submit a Pull Request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/yourusername">Your Name</a>
</p>
