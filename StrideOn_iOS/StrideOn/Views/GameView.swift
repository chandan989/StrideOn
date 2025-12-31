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
    
    @State private var position: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 37.3346, longitude: -122.0090),
            distance: 2500,
            heading: 0,
            pitch: 60
        )
    )
    
    // --- Mock Data ---
    // These arrays represent different routes on the map.
    
    /// The main route, shown in bright green.
    let mainRoute: [CLLocationCoordinate2D] = [
        .init(latitude: 37.3364, longitude: -122.0125),
        .init(latitude: 37.3348, longitude: -122.0109),
        .init(latitude: 37.3328, longitude: -122.0085)
    ]
    
    /// A secondary route, shown in cyan.
    let secondaryRoute: [CLLocationCoordinate2D] = [
        .init(latitude: 37.3391, longitude: -122.0118),
        .init(latitude: 37.3375, longitude: -122.0100)
    ]
    
    /// Another secondary route, shown in red.
    let tertiaryRoute: [CLLocationCoordinate2D] = [
        .init(latitude: 37.3378, longitude: -122.0070),
        .init(latitude: 37.3365, longitude: -122.0055)
    ]

    var body: some View {
        ZStack(alignment: .top){
            // MARK: - Map Background
            Map(position: $position) {
                // Draws the mock routes as polylines on the map.
                MapPolyline(coordinates: mainRoute)
                    .stroke(Color.green, lineWidth: 6)
                
                MapPolyline(coordinates: secondaryRoute)
                    .stroke(Color.cyan, lineWidth: 6)
                
                MapPolyline(coordinates: tertiaryRoute)
                    .stroke(Color.red, lineWidth: 6)
                
                // Adds circular annotations at the start of the secondary routes.
                Annotation("", coordinate: secondaryRoute.first!) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 15, height: 15)
                        .shadow(radius: 3)
                }
                
                Annotation("", coordinate: tertiaryRoute.first!) {
                     Circle()
                        .fill(Color.red)
                        .frame(width: 15, height: 15)
                        .shadow(radius: 3)
                }
            }
            .mapControlVisibility(.hidden) // Hides default map controls like zoom
            .ignoresSafeArea()

            // MARK: - UI Overlay
            VStack {
                TopTimerView()
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
                                    Text("0.2")
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
                            
                            CaloriesCard(value: "238")
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
    var body: some View {
        ZStack{
            HStack{
                Spacer()
                VStack(spacing: 2) {
                    Text("00:30:00")
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
