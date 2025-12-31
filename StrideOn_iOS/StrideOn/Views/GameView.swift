//
//  GameView.swift
//  StrideOn
//
//  Created by Chandan on 30/12/25.
//

import SwiftUI

import MapKit

struct GameView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    // Use user tracking mode
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    @ObservedObject private var locationManager = LocationManager.shared
    
    // --- Mock Data ---
    // Access mock data from shared model
    @ObservedObject private var mockData = MockData.shared
    
    private var gameState: GameState {
        mockData.gameState
    }

    var body: some View {
        ZStack(alignment: .top){
            // MARK: - Map Background
            Map(position: $position) {
                // Draw Claimed Areas (Polygons)
                ForEach(gameState.claimedAreas) { area in
                    MapPolygon(coordinates: area.points.map { $0.coordinate })
                        .foregroundStyle(Color(hex: area.colorHex).opacity(0.4))
                        .stroke(Color(hex: area.colorHex), lineWidth: 2)
                }
                
                // Draws the active trail (User)
                MapPolyline(coordinates: gameState.activeTrail.points.map { $0.coordinate })
                    .stroke(Color(hex: gameState.activeTrail.colorHex), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                
                // Show real user location
                if let userLoc = locationManager.userLocation {
                    Annotation("You", coordinate: userLoc.coordinate) {
                        Circle()
                            .fill(Color(hex: "#00FF00")) // Green
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(radius: 5)
                            .scaleEffect(1.0) // Fixes occasional sizing issues with Maps
                    }
                }
                
                // Draw other trails
                ForEach(gameState.otherTrails) { trail in
                    MapPolyline(coordinates: trail.points.map { $0.coordinate })
                        .stroke(Color(hex: trail.colorHex), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                    
                    if let lastPoint = trail.points.last {
                        Annotation("", coordinate: lastPoint.coordinate) {
                            Circle()
                                .fill(Color(hex: trail.colorHex))
                                .frame(width: 15, height: 15)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 3)
                        }
                    }
                }
            }
            .mapControlVisibility(.hidden) // Hides default map controls like zoom
            .ignoresSafeArea()
            .onAppear {
                locationManager.requestPermission()
                if !mockData.isSessionActive {
                     mockData.startSession()
                }
            }

            // MARK: - UI Overlay
            VStack {
                TopTimerView(elapsedTime: mockData.timeRemaining)
                Spacer()
                
                HStack(alignment: .bottom, spacing: 12) {
                    // Left column of stats (Distance, Conquered)
                    VStack(spacing: 12) {
                        
                        HStack{
                            VStack(alignment: .leading, spacing: 0){
                                Image(.locationIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 15)
                                    .foregroundColor(.white)
                                
                                Text("Distance")
                                    .customFont(.semiBold,13)
                                    .foregroundColor(.nsTxt)
                                    .padding([.top],5)
                                
                                HStack(spacing: 5){
                                    Text(String(format: "%.2f", mockData.gameState.totalDistance))
                                        .customFont(.semiBold,15)
                                        .foregroundColor(.white)
                                    
                                    Text("Km")
                                        .customFont(.semiBold,10)
                                        .foregroundColor(Color(.nsTxt))
                                }.padding([.top],5)
                            }.frame(alignment: .leading).padding([.leading, .trailing],15).padding([.top,.bottom],13).background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.black.opacity(0.65))
                            )
                            
                            CaloriesCard(value: String(format: "%.0f", mockData.gameState.caloriesBurned))
                        }
                        
                        HStack{
                            InfoCard(
                                iconName: "figure.walk",
                                value: "0.2",
                                unit: "Km",
                                label: "Distance"
                            )
                            
                            // MARK: Action Button
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }){
                                // NOTE: The dragon icon in the image is custom.
                                // An SF Symbol is used here as a placeholder.
                                Image(.logo)
                                    .resizable()
                                    .foregroundColor(.black).padding(20)
                                    .frame(width: 80, height: 80)
                                    .background(.accent)
                                    .cornerRadius(22)
                                    .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                            }
                        }
                        
                        
                    }
                }
            }
            .padding()
        }.padding(.top,40).padding(.bottom,20).navigationBarHidden(true).ignoresSafeArea(.all).statusBar(hidden: true)
    }
}

/// The top card view displaying the timer and group info.
struct TopTimerView: View {
    var elapsedTime: TimeInterval
    
    var body: some View {
        ZStack{
            HStack{
                Spacer()
                VStack(spacing: 2) {
                    Text(timeString(from: elapsedTime))
                        .customFont(.bold,30)
                        .foregroundColor(.white)
                    Text("Time Left")
                        .customFont(.semiBold,13)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }

            HStack{
                Spacer()
                GroupAvatarsView()
            }
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(.black.opacity(0.65))
        .clipShape(Capsule())
        .shadow(radius: 10)
    }
    
    func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// A reusable card for displaying a piece of information (e.g., Distance).
struct InfoCard: View {
    let iconName: String
    let value: String
    let unit: String
    let label: String

    var body: some View {
        HStack(spacing: 20) {
            Image(.mapLogo)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color(hex: "#252525"))
                ).frame(width: 50, height: 50)
            
            HStack(spacing: 5){
                Text("0.1")
                    .customFont(.semiBold,30)
                    .foregroundColor(.white)
                
                HStack(alignment: .top, spacing: 1) {
                    Text("km")
                        .customFont(.semiBold, 13)
                        .foregroundColor(Color(.nsTxt))
                    
                    Text("2")
                        .customFont(.semiBold, 9) // smaller font
                        .foregroundColor(Color(.nsTxt))
                }.padding(.top, 10)
                Spacer()
            }
            VStack{
                Text(label)
                    .font(.caption)
                    .padding(.top, 40)
            }
        }
        .padding(15)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.65))
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

/// A special card layout specifically for the Calories display.
struct CaloriesCard: View {
    let value: String
    
    var body: some View {
        HStack(spacing: 0) {
            Image(.calorieIcon)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color(hex: "#252525"))
                ).frame(width: 50, height: 50)
            
            Spacer().frame(width: 15)
            
            Text("238")
                .customFont(.semiBold,30)
                .foregroundColor(.white)
            
            Text("Kcal")
                .customFont(.semiBold,20)
                .foregroundColor(.gray).padding([.leading,.top], 7)
            
            Spacer()
        }
        .padding([.leading,.trailing],15)
        .padding([.top,.bottom],17)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(.black.opacity(0.65))
        .cornerRadius(22)
        .shadow(radius: 5)
    }
}

#Preview {
    GameView()
}
