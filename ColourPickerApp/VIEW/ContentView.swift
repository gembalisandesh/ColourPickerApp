//
//  ContentView.swift
//  ColourPickerApp
//
//  Created by Equipp on 19/09/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ColorViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                colorCardList
                
                generateColorButton
            }
            .navigationTitle("Colour Picker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    connectionStatusView
                }
            }
            .onAppear {
                viewModel.loadColorsFromUserDefaults()
                viewModel.fetchColorsFromFirebase()
            }
            .alert(isPresented: $viewModel.showingErrorAlert) {
                Alert(title: Text("Sync Failed"), message: Text("Will retry when back online."), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var colorCardList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.colorCards) { card in
                    ColorCardView(card: card)
                }
            }
            .padding()
        }
    }
    
    private var generateColorButton: some View {
        Button(action: generateRandomColor) {
            Text("Generate Random Color")
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    private var connectionStatusView: some View {
        HStack {
            Circle()
                .fill(viewModel.isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            
            Text(viewModel.isConnected ? "Online" : "Offline")
                .font(.caption)
                .foregroundColor(viewModel.isConnected ? .green : .red)
            
            Button(action: viewModel.toggleNetworkStatus) {
                Image(systemName: viewModel.isConnected ? "wifi" : "wifi.slash")
                    .foregroundColor(viewModel.isConnected ? .green : .red)
            }
        }
    }
    
    private func generateRandomColor() {
        let newColor = viewModel.randomColor()
        let hex = viewModel.colorToHex(color: newColor)
        let timestamp = Date()
        
        let colorCard = ColorCard(color: newColor, hex: hex, timestamp: "\(timestamp)")
        viewModel.colorCards.append(colorCard)
        viewModel.saveColorsToUserDefaults()
        
        if viewModel.isConnected {
            viewModel.syncWithFirebase(colorCard: colorCard)
        }
    }
}


#Preview {
    ContentView()
}
