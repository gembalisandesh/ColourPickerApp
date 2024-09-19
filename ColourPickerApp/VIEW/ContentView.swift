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
            VStack {
                ScrollView {
                    ForEach(viewModel.colorCards) { card in
                        VStack {
                            Rectangle()
                                .fill(card.color)
                                .frame(height: 150)
                                .cornerRadius(10)
                                .padding()
                            
                            Text("Hex: \(card.hex)")
                                .font(.title3)
                                .padding()
                            
                            Text("Timestamp: \(card.timestamp)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
              
                Button("Generate Random Color") {
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
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
              
                Text(viewModel.isConnected ? "Online" : "Offline")
                    .font(.caption)
                    .foregroundColor(viewModel.isConnected ? .green : .red)
                    .padding()
               
                Button(action: {
                    viewModel.toggleNetworkStatus()
                }) {
                    Text(viewModel.isConnected ? "Go Offline" : "Go Online")
                        .padding()
                        .background(viewModel.isConnected ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Colour Picker")
            .onAppear {
                viewModel.loadColorsFromUserDefaults()
                viewModel.fetchColorsFromFirebase()
            }
            .alert(isPresented: $viewModel.showingErrorAlert) {
                Alert(title: Text("Sync Failed"), message: Text("Will retry when back online."), dismissButton: .default(Text("OK")))
            }
        }
    }
}


#Preview {
    ContentView()
}
