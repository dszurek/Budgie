//
//  ShoppingListItemDetailView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/26/25.
//

import SwiftUI
import SwiftData

struct ShoppingListItemDetailView: View {
    @Bindable var item: ShoppingListItem
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var contentBackground: Color {
        colorScheme == .dark ? Color.black : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    var isEmbedded: Bool = false // New property to control styling
    
    var body: some View {
        ZStack {
            if !isEmbedded {
                contentBackground.ignoresSafeArea()
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header Image (if any)
                    if let url = item.imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 250)
                                    .cornerRadius(15)
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .frame(height: 200)
                                    .foregroundColor(.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(cardBackground)
                        .cornerRadius(15)
                        .padding()
                    }
                    
                    // Details Card
                    VStack(alignment: .leading, spacing: 20) {
                        // Title & Price
                        HStack(alignment: .top) {
                            Text(item.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("$\(String(format: "%.2f", item.price))")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        Divider()
                        
                        // Dates
                        VStack(alignment: .leading, spacing: 12) {
                            if let listName = item.parentList?.name {
                                DetailRow(icon: "list.bullet", title: "List", value: listName)
                            }
                            
                            DetailRow(icon: "calendar", title: "Desired Date", value: item.purchaseByDate.formatted(date: .long, time: .omitted))
                            
                            if let calculated = item.calculatedPurchaseDate {
                                DetailRow(icon: "star.fill", title: "Optimal Date", value: calculated.formatted(date: .long, time: .omitted), valueColor: .purple)
                                
                                if let balance = item.predictedBalanceAfterPurchase {
                                    DetailRow(icon: "chart.line.uptrend.xyaxis", title: "Predicted Balance", value: "$\(String(format: "%.2f", balance))", valueColor: .green)
                                }
                            } else if let error = item.calculationError {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("Could not schedule")
                                            .fontWeight(.medium)
                                    }
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            } else {
                                Text("Pending calculation...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }
                        
                        // Link
                        if let url = item.url {
                            Divider()
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "link")
                                    Text("View Item Online")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                    .background(isEmbedded ? Color.clear : cardBackground) // Transparent if embedded
                    .cornerRadius(20)
                    .shadow(color: isEmbedded ? .clear : .black.opacity(0.05), radius: 10, x: 0, y: 5) // No shadow if embedded
                    .padding(.horizontal, isEmbedded ? 0 : 16) // Remove horizontal padding if embedded
                    
                    Spacer()
                }
                .padding(.top)
            }
        }
        .navigationTitle(isEmbedded ? "" : "Item Details") // Hide title if embedded
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    var icon: String
    var title: String
    var value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}
