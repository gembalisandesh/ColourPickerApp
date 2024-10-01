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

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                colorCardList
                
                HStack {
                    generateColorButton
                    deleteAllColorsButton
                }
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
                Alert(
                    title: Text("Sync Failed"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred."),
                    dismissButton: .default(Text("OK"))
                )
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
        }
    }
    
    private var colorCardList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.colorCards) { card in
                    ColorCardView(card: card) {
                        viewModel.deleteColorCard(card)
                    }
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
                .frame(maxWidth: .infinity,maxHeight: 80)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    private var deleteAllColorsButton: some View {
        Button(action: deleteAllColors) {
            Text("Delete All Colors")
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity,maxHeight: 80)
                .background(Color.red)
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
    
    private func deleteAllColors() {
        viewModel.deleteAllColorsFromUserDefaults()
        
        if viewModel.isConnected {
            viewModel.deleteAllColorsFromFirebase()
        }
    }
}


#Preview {
    ContentView()
}
