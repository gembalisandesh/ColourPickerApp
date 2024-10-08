//
//  ColourCardView.swift
//  ColourPickerApp
//
//  Created by Equipp on 19/09/24.
//

import SwiftUI

struct ColorCardView: View {
    let card: ColorCard
    let onDelete: () -> Void 
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 15)
                .fill(card.color)
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Hex: \(card.hex)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(formatTimestamp(card.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                }
            }
            .padding(.trailing, 10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss Z"
        
        if let date = dateFormatter.date(from: timestamp) {
            dateFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            return dateFormatter.string(from: date)
        }
        
        return timestamp
    }
}

#Preview {
    VStack(spacing: 20) {
        ColorCardView(card: ColorCard(color: .red, hex: "#FF0000", timestamp: "2024-09-19T10:30:00 +0000"), onDelete: {
            print("Deleted red color card")
        })
        ColorCardView(card: ColorCard(color: .blue, hex: "#0000FF", timestamp: "2024-09-19T11:45:00 +0000"), onDelete: {
            print("Deleted blue color card")
        })
    }
    .padding()
}
