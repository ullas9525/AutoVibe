# AutoVibe — Project Score

**Evaluation Date:** 2026-04-02

---

## Scores (Out of 10)

| Category | Score | Justification |
|---|---|---|
| **UI (User Interface)** | 7/10 | Clean dark-theme design with card-based layout, accent colors, and status indicators. Deductions: no animations/transitions, no dynamic status card (e.g., "next alarm in 2h 15m"), day selector UX could be more polished. |
| **Output / Report Quality** | 8/10 | The app performs its core function reliably after the bug fix — alarms fire on time, ringer mode changes correctly, and diagnostic logs provide transparency. Deduction: no notification shown when vibrate mode activates (user has no visual confirmation unless they check the phone). |
| **Problem Relevance (Real-World Value)** | 9/10 | Highly relevant — automating ringer mode is a universal need. Android's built-in DND scheduling exists but is limited and not intuitive. AutoVibe provides a focused, user-friendly alternative. Deduction: limited to vibrate/normal toggle — doesn't support silent mode or custom volume levels. |

**Overall Score: 8/10**

---

## Score Deductions Explained

1. **UI (-3)**: No micro-animations, no dynamic "next activation" countdown, basic day selector circles
2. **Output (-2)**: No push notification when vibrate mode is activated/deactivated by the alarm
3. **Relevance (-1)**: Only handles vibrate ↔ normal, not silent mode or per-app volume control

---

## Suggested Features to Increase Score

| Priority | Feature | Impact |
|---|---|---|
| 1 | **Dynamic status card** — Show "Next activation in X hours" with live countdown | UI +1 |
| 2 | **Notification on activation** — Show a persistent notification while vibrate is active | Output +1 |
| 3 | **Micro-animations** — Smooth transitions for card creation/deletion, toggle animations | UI +1 |
| 4 | **Silent mode support** — Option to choose between vibrate and fully silent | Relevance +0.5 |
| 5 | **Quick toggle widget** — Home screen widget to enable/disable all schedules | Output +0.5 |
| 6 | **Reboot persistence** — Set `rescheduleOnReboot: true` and handle `BOOT_COMPLETED` | Output +0.5 |

### Implementation Sequence
First: Dynamic status card → Then: Notification on activation → Then: Micro-animations → Then: Silent mode support → Then: Widget → Then: Reboot persistence
