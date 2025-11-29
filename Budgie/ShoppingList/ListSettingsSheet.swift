//
//  ListSettingsSheet.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/10/25.
//

import SwiftUI
import SwiftData

struct ListSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var list: ShoppingList
    
    @State private var name: String = ""
    @State private var selectedColor: Color = .blue
    
    let availableColors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .yellow, .gray]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("List Name") {
                    TextField("Name", text: $name)
                }
                
                Section("List Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                            // Custom Color Picker
                            ColorPicker("", selection: $selectedColor)
                                .labelsHidden()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        list.name = name
                        list.colorHex = selectedColor.toHex() ?? "#0000FF"
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = list.name
                selectedColor = Color(hex: list.colorHex)
            }
        }
    }
}
