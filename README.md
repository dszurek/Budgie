# Budgie - Smart Financial Planning for Students

Budgie is a financial planning app designed specifically for students and individuals with sporadic income. It helps users visualize their financial future, plan large purchases without stress, and maintain a safety net.

## 🚀 Getting Ready for Publication

This guide outlines the steps to prepare and publish Budgie to the Apple App Store.

### 1. Prerequisites
- **Apple Developer Account:** Ensure you have an active enrollment ($99/year).
- **Xcode:** Latest stable version installed.
- **App Store Connect:** Access to create and manage apps.

### 2. Final Code Check
- [x] **Bundle Identifier:** Ensure `com.yourname.Budgie` (or similar) matches your App Store Connect entry.
- [x] **Signing & Capabilities:**
    - **Team:** Select your Apple Developer Team in Project Settings -> Signing & Capabilities.
    - **App Groups:** Ensure the App Group (e.g., `group.com.yourname.Budgie`) is active and checked for both the main App target and the Widget extension target.
- [x] **Version & Build:** Set Version to `1.0.0` and Build to `1`.
- [x] **App Icon:** Verify all sizes are populated in `Assets.xcassets/AppIcon`.

### 3. App Store Connect Setup
1. Log in to [App Store Connect](https://appstoreconnect.apple.com).
2. Click **My Apps** -> **(+) New App**.
3. **Platforms:** iOS.
4. **Name:** Budgie (or your chosen unique name).
5. **Primary Language:** English (US).
6. **Bundle ID:** Select the one matching your Xcode project.
7. **SKU:** A unique ID (e.g., `BUDGIE_IOS_001`).
8. **User Access:** Full Access.

### 4. Store Listing Details
Use the content from `AppStoreSummary.md` to fill in:
- **Title & Subtitle**
- **Description**
- **Keywords**
- **Support URL:** Link to your website or GitHub repo.
- **Marketing URL:** (Optional) Link to your landing page.

### 5. Screenshots & Previews
You need screenshots for:
- **iPhone 6.9" Display** (iPhone 16 Pro Max) - 1320 x 2868 px
- **iPhone 6.5" Display** (iPhone 11 Pro Max / XS Max) - 1242 x 2688 px
- **iPhone 5.5" Display** (iPhone 8 Plus) - 1242 x 2208 px

**Key Screens to Capture:**
1. **Budget Tab:** Showing Income/Expenses and Balance.
2. **Wish Lists:** Showing a list with items and the "Buy on" dates.
3. **Timeline:** Showing the graph with purchase dots and balance line.
4. **Item Details:** Showing the "Optimal Date" calculation.
5. **Widget:** Showing the home screen widget.

### 6. Privacy Policy
You must provide a URL to a privacy policy. Since Budgie stores data locally (SwiftData) and doesn't collect analytics (unless you added some), a simple policy stating "Data is stored locally on your device and is not collected by the developer" is sufficient. You can host this on a free GitHub Pages site or similar.

### 7. Archiving & Uploading
1. In Xcode, select **Any iOS Device (arm64)** as the build target.
2. Go to **Product** -> **Archive**.
3. Once archiving is complete, the Organizer window will open.
4. Click **Distribute App**.
5. Select **App Store Connect** -> **Upload**.
6. Follow the prompts (keep default settings for signing and stripping symbols).
7. Click **Upload**.

### 8. TestFlight (Beta Testing)
1. Once uploaded, go to App Store Connect -> **TestFlight**.
2. Wait for the build to finish processing.
3. Add **Internal Testers** (yourself and team) to test immediately.
4. Create an **External Testing** group to invite friends via email or public link.

### 9. Submission for Review
1. Go to **App Store** tab in App Store Connect.
2. Scroll to **Build** and select the uploaded build.
3. Fill in **App Review Information** (contact info, notes).
4. Click **Add for Review**.
5. Wait for Apple's approval (usually 24-48 hours).

## 🛠️ Troubleshooting
- **Widget not updating:** Check App Group configuration in both targets.
- **Build failed:** Check Signing & Capabilities for expired profiles.
- **Upload failed:** Ensure Version/Build numbers are incremented if you uploaded a previous build.

## 📄 License
[Your License Here]
