//
//  UserView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/7/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct UserView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
    @Query private var settingsList: [User]

    private var settings: User {
        if let first = settingsList.first {
            return first
        } else {
            let new = User()
            context.insert(new)
            try? context.save()
            return new
        }
    }

    @State private var name: String = ""
    @State private var targetSavings: String = ""
    @State private var rainCheckMin: String = ""
    @State private var searchWindowMonths: Int = 3
    @State private var prioritizeEarlierDates: Bool = true
    @State private var isRainCheckHardConstraint: Bool = true
    @State private var projectionHorizonMonths: Int = 12
    @State private var widgetTimeframe: String = "3 Months"
    @State private var prioritizeSavingsGoal: Bool = true
    @State private var photoItem: PhotosPickerItem?
    @State private var pickedImage: PlatformImage?
    @State private var showAbout = false
    
    var contentBackground: Color {
        colorScheme == .dark ? Color.black : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    var titleColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 0. Base Background (Removed to reveal ContentView header)

            
            // 1. Header Background (Handled in ContentView)
            
            // 2. Title
            VStack {
                Text("You")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.top, 150) // Increased padding
                Spacer()
            }
            .ignoresSafeArea()
            
            // 3. Scrollable Content
            ScrollView {
                VStack(spacing: 0) {
                    // Transparent Spacer
                    Color.clear.frame(height: 140)
                    
                    // Content
                    VStack(spacing: 30) {
                        // Profile Header
                        VStack(spacing: 15) {
                            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                                if let pickedImage = pickedImage {
                                    #if canImport(UIKit)
                                    Image(uiImage: pickedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(.white, lineWidth: 3))
                                        .shadow(radius: 5)
                                    #elseif canImport(AppKit)
                                    Image(nsImage: pickedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(.white, lineWidth: 3))
                                        .shadow(radius: 5)
                                    #endif
                                } else if let data = settings.profileImageData, let ui = PlatformImage(data: data) {
                                    #if canImport(UIKit)
                                    Image(uiImage: ui)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(.white, lineWidth: 3))
                                        .shadow(radius: 5)
                                    #elseif canImport(AppKit)
                                    Image(nsImage: ui)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(.white, lineWidth: 3))
                                        .shadow(radius: 5)
                                    #endif
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .foregroundColor(.pink.opacity(0.5))
                                        .frame(width: 100, height: 100)
                                        .shadow(radius: 5)
                                }
                            }
                            .onChange(of: photoItem) { oldValue, newValue in
                                loadPhoto(newValue)
                            }
                            
                            TextField("Your Name", text: $name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .onSubmit { saveAll() }
                        }
                        
                        // Settings Cards
                        VStack(spacing: 20) {
                            Text("Financial Goals")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 15) {
                                HStack {
                                    Text("Target Savings")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    TextField("$0", text: $targetSavings)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 120)
                                        .padding(8)
                                        .background(Color.pink.opacity(0.05))
                                        .cornerRadius(8)
                                        .padding(8)
                                        .background(Color.pink.opacity(0.05))
                                        .cornerRadius(8)
                                        .onChange(of: targetSavings) { _, newValue in
                                            // Ensure valid input or empty
                                            if newValue == "0" { targetSavings = "" }
                                        }
                                }
                                
                                HStack {
                                    Text("Rain-Check Min")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    TextField("$0", text: $rainCheckMin)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 120)
                                        .padding(8)
                                        .background(Color.pink.opacity(0.05))
                                        .cornerRadius(8)
                                        .padding(8)
                                        .background(Color.pink.opacity(0.05))
                                        .cornerRadius(8)
                                        .onChange(of: rainCheckMin) { _, newValue in
                                            if newValue == "0" { rainCheckMin = "" }
                                        }
                                }
                            }
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                            
                            Text("Algorithm Settings")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 15) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Search Window Goal")
                                            .foregroundColor(.primary)
                                        Text("Tries +/- \(searchWindowMonths) months first, then expands search")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                    Text("\(searchWindowMonths)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.pink)
                                    Stepper("", value: $searchWindowMonths, in: 1...12)
                                        .labelsHidden()
                                }
                                
                                Toggle("Prioritize Savings Goal", isOn: $prioritizeSavingsGoal)
                                    .tint(.pink)
                                
                                Toggle("Prioritize Earlier Dates", isOn: $prioritizeEarlierDates)
                                    .tint(.pink)
                                
                                Toggle("Hard Rain Check Minimum", isOn: $isRainCheckHardConstraint)
                                    .tint(.pink)
                                
                                Divider()
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Projection Horizon")
                                            .foregroundColor(.primary)
                                        Text("How far into the future to predict")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Picker("", selection: $projectionHorizonMonths) {
                                        Text("6 Months").tag(6)
                                        Text("1 Year").tag(12)
                                        Text("2 Years").tag(24)
                                        Text("5 Years").tag(60)
                                    }
                                    .tint(.pink)
                                }
                                
                                Divider()
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Widget Range")
                                            .foregroundColor(.primary)
                                        Text("Timeframe to show on widget")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Picker("", selection: $widgetTimeframe) {
                                        Text("1 Week").tag("1 Week")
                                        Text("1 Month").tag("1 Month")
                                        Text("3 Months").tag("3 Months")
                                        Text("6 Months").tag("6 Months")
                                        Text("1 Year").tag("1 Year")
                                        Text("Full").tag("Full")
                                    }
                                    .tint(.pink)
                                }
                                
                                Text("Note: Widget may require an app restart to update immediately.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                            
                            // About Section
                            Button(action: { showAbout = true }) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.pink)
                                    Text("About Budgie")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(cardBackground)
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 120)
                    .frame(maxWidth: .infinity)
                    .background(contentBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }

            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .onAppear {
            name = settings.name
            targetSavings = settings.targetSavings == 0 ? "" : String(format: "%.2f", settings.targetSavings)
            rainCheckMin = settings.rainCheckMin == 0 ? "" : String(format: "%.2f", settings.rainCheckMin)
            searchWindowMonths = settings.searchWindowMonths
            prioritizeEarlierDates = settings.prioritizeEarlierDates

            isRainCheckHardConstraint = settings.isRainCheckHardConstraint
            projectionHorizonMonths = settings.projectionHorizonMonths == 0 ? 12 : settings.projectionHorizonMonths
            widgetTimeframe = settings.widgetTimeframe.isEmpty ? "3 Months" : settings.widgetTimeframe
            prioritizeSavingsGoal = settings.prioritizeSavingsGoal
        }
        .onChange(of: name) { saveAll() }
        .onChange(of: targetSavings) { saveAll() }
        .onChange(of: rainCheckMin) { saveAll() }
        .onChange(of: searchWindowMonths) { saveAll() }
        .onChange(of: prioritizeEarlierDates) { saveAll() }
        .onChange(of: isRainCheckHardConstraint) { saveAll() }
        .onChange(of: projectionHorizonMonths) { saveAll() }
        .onChange(of: prioritizeSavingsGoal) { saveAll() }
        .onChange(of: widgetTimeframe) { 
            saveAll()
            // Force widget to reload with new timeframe
            WidgetReloader.reloadWidget()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
    
    private func saveAll() {
        settings.name = name
        settings.targetSavings = Double(targetSavings) ?? 0
        settings.rainCheckMin   = Double(rainCheckMin)   ?? 0
        settings.searchWindowMonths = searchWindowMonths
        settings.prioritizeEarlierDates = prioritizeEarlierDates

        settings.isRainCheckHardConstraint = isRainCheckHardConstraint
        settings.projectionHorizonMonths = projectionHorizonMonths
        settings.widgetTimeframe = widgetTimeframe
        settings.prioritizeSavingsGoal = prioritizeSavingsGoal
        do { try context.save() }
        catch { print("Save failed:", error) }
    }
    
    private func loadPhoto(_ item: PhotosPickerItem?) {
        Task {
            guard let data = try? await item?.loadTransferable(type: Data.self) else { return }
            settings.profileImageData = data
            try? context.save()
            
            #if canImport(UIKit)
            if let ui = UIImage(data: data) {
                pickedImage = ui
            }
            #elseif canImport(AppKit)
            if let ns = NSImage(data: data) {
                pickedImage = ns
            }
            #endif
        }
    }
}

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif
