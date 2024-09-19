//
//  ContentView.swift
//  ColourPickerApp
//
//  Created by Equipp on 19/09/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ColorViewModel()
    @State private var showOfflineAlert = false
    @State private var editingCard: ColorCard?
    @State private var showingColorPicker = false
    @State private var tempColor: Color = .red

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
            .alert("Device Offline", isPresented: $showOfflineAlert) {
                Button("Go Online") {
                    viewModel.toggleNetworkStatus()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your device is offline. Go online to sync with Firebase.")
            }
            .onChange(of: viewModel.isConnected) {
                if !viewModel.isConnected {
                    showOfflineAlert = true
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPicker("Select a color", selection: $tempColor)
                    .padding()
                Button("Save") {
                    if let editingCard = editingCard {
                        updateColor(editingCard)
                    }
                    showingColorPicker = false
                }
                .padding()
            }
        }
    }
    
    private var colorCardList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.colorCards) { card in
                    ColorCardView(card: card, onEdit: {
                        editingCard = card
                        tempColor = card.color
                        showingColorPicker = true
                    }, onDelete: {
                        deleteColor(card)
                    })
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
    
    private func updateColor(_ card: ColorCard) {
        if let index = viewModel.colorCards.firstIndex(where: { $0.id == card.id }) {
            let updatedCard = ColorCard(color: tempColor, hex: viewModel.colorToHex(color: tempColor), timestamp: "\(Date())")
            viewModel.colorCards[index] = updatedCard
            viewModel.saveColorsToUserDefaults()
            
            if viewModel.isConnected {
                viewModel.updateColorInFirebase(updatedCard)
            }
        }
    }
    
    private func deleteColor(_ card: ColorCard) {
        viewModel.colorCards.removeAll { $0.id == card.id }
        viewModel.saveColorsToUserDefaults()
        
        if viewModel.isConnected {
            viewModel.deleteColorFromFirebase(card)
        }
    }
}

#Preview {
    ContentView()
}
