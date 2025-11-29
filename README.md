# Budgie 🦜
> **Smart Financial Planning for Students & Freelancers**

Budgie is a native iOS application built with **SwiftUI** and **SwiftData** designed to help individuals with sporadic income plan their finances. Unlike traditional budgeting apps that track past spending, Budgie uses a custom predictive algorithm to schedule future purchases without compromising financial safety.

## 📱 Project Overview

This project demonstrates a modern, production-ready iOS architecture focusing on:
- **Reactive UI** with SwiftUI.
- **Local Persistence** using the new SwiftData framework.
- **Complex Logic** encapsulated in a testable scheduling algorithm.
- **System Integration** via WidgetKit and App Groups.

## ✨ Key Features

- **Smart Purchase Scheduling**: The core feature. Users add items to a "Wish List," and the app calculates the optimal purchase date based on projected income, recurring expenses, and a "Rain Check" safety net.
- **Visual Timeline**: An interactive graph (built with Swift Charts) that visualizes projected balances 6 months into the future.
- **Sporadic Income Support**: Tailored for users with irregular paychecks (gigs, grants, freelance work).
- **Home Screen Widget**: A shared-codebase widget that displays the projected balance graph on the home screen.

## 🛠️ Technical Highlights

### Architecture
The app follows a clean **MVVM (Model-View-ViewModel)** pattern, leveraging SwiftUI's state management (`@Query`, `@Environment`) for a seamless data flow.

### The Scheduling Algorithm (`Algo.swift`)
The heart of the application is the `PurchaseScheduler`. It performs a daily simulation of the user's finances:
1.  **Projection**: Generates a daily balance timeline based on recurring income/expenses and manual checkpoints.
2.  **Safety Checks**: Ensures the balance never drops below the user-defined "Rain Check" threshold.
3.  **Optimization**: Iterates through potential purchase dates to find a window that maximizes savings and minimizes wait time.

### Data Persistence (SwiftData)
Budgie utilizes Apple's latest **SwiftData** framework for robust local storage.
- **Models**: `User`, `Income`, `Expense`, `ShoppingListItem`.
- **Relationships**: Cascading deletes and complex queries are handled natively.

### WidgetKit Integration
The `graphWidget` extension shares code with the main app via **App Groups**.
- **Data Sharing**: The main app serializes the projection data to a shared JSON file.
- **TimelineProvider**: The widget reads this shared data to render the `TimelineGraphView` independently.

## 💻 Tech Stack

- **Language**: Swift 5.0
- **UI**: SwiftUI, Swift Charts
- **Storage**: SwiftData, App Groups (UserDefaults/FileCoordinator)
- **Platform**: iOS 17.0+