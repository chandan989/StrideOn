//
//  Home.swift
//  StrideOn
//
//  Created by Chandan on 30/12/25.
//

import SwiftUI
import MapKit


struct Home: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var wepinManager: WepinManager
    @State private var parentViewController: UIViewController?
    @ObservedObject private var mockData = MockData.shared // Observe the shared instance
    @ObservedObject private var locationManager = LocationManager.shared // Observe location manager
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    // Access mock data through the observed object
    private var activeTrail: Trail {
        mockData.gameState.activeTrail
    }
    
    // Computed property to easily get just the coordinates for the MapPolyline.
    private var routeCoordinates: [CLLocationCoordinate2D] {
        activeTrail.points.map { $0.coordinate }
    }
    
    var body: some View {
        NavigationStack{
            ZStack {

                
                VStack(alignment: .leading, spacing: 0){
                    
                    Spacer().frame(height: 40)
                    
                    HStack(alignment: .center){
                        Image(.logo)
                            .resizable()
                            .foregroundColor(Color("AccentColor"))
                            .scaledToFit()
                            .frame(height: 30)
                        
                        Spacer()
                        
                        NavigationLink(destination: VeryChatConnectionView()) {
                            HStack{
                                Image(.veryLogo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height:20)
                            }.padding([.top,.bottom],7).padding([.leading,.trailing],10).overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.signatureGrey, lineWidth: 2)
                            )
                        }
                    }
                    
                    Spacer().frame(height: 20)
                    
                    Text("Hi, \(mockData.gameState.currentUser?.userName ?? "User")") // Dynamic name
                        .customFont(.semiBold,13)
                        .foregroundStyle(.nsTxt)
                    
                    Text("Join a Run")
                        .customFont(.semiBold,20)
                        .foregroundStyle(.white).padding(.top, 5)
                    
                    Spacer().frame(height: 20)
                    
                    HStack(spacing: 15){
                        DateView(DayLetter: "T", Date: "30")
                        DateView(DayLetter: "W", Date: "31")
                        DateView(DayLetter: "T", Date: "1")
                        DateView(DayLetter: "F", Date: "2")
                        DateView(DayLetter: "S", Date: "3")
                        DateView(DayLetter: "S", Date: "4", isSelected: true)
                        DateView(DayLetter: "M", Date: "5")
                        DateView(DayLetter: "T", Date: "6")
                    }
                    
                    Spacer().frame(height: 20)
                    
                    Text("Enter Arena")
                        .customFont(.semiBold,17)
                        .foregroundStyle(.nsTxt)
                    
                    Spacer().frame(height: 10)
                    
                    NavigationLink(destination: GameView()) {
                        HStack(spacing: 20){
                            ZStack(alignment: .topLeading) {
                                Map(position: $cameraPosition) {
                                    // Draw Claimed Areas (Polygons)
                                    ForEach(mockData.gameState.claimedAreas) { area in
                                        MapPolygon(coordinates: area.points.map { $0.coordinate })
                                            .foregroundStyle(Color(hex: area.colorHex).opacity(0.4))
                                            .stroke(Color(hex: area.colorHex), lineWidth: 2)
                                    }
                                    
                                    // Add the route line to the map.
                                    MapPolyline(coordinates: routeCoordinates)
                                        .stroke(.accent, lineWidth: 5)
                                    
                                    // Show real user location if available
                                    if let userLoc = locationManager.userLocation {
                                        Annotation("You", coordinate: userLoc.coordinate) {
                                            Circle()
                                                .fill(Color(hex: "#00FF00")) // Green
                                                .frame(width: 12, height: 12)
                                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                                .shadow(radius: 5)
                                        }
                                    } else if let firstCoordinate = routeCoordinates.first {
                                        // Fallback to mock start if no user location
                                        Annotation("", coordinate: firstCoordinate) {
                                            Circle()
                                                .fill(Color(hex: "#00FF00")) // Green
                                                .frame(width: 12, height: 12)
                                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                                .shadow(radius: 5)
                                        }
                                    }
                                    
                                    // Draw Other Users (Moving Dots)
                                    ForEach(mockData.gameState.otherTrails) { trail in
                                        if let lastPoint = trail.points.last {
                                            Annotation("User", coordinate: lastPoint.coordinate) {
                                                Circle()
                                                    .fill(Color(hex: trail.colorHex))
                                                    .frame(width: 12, height: 12)
                                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                                    .shadow(radius: 3)
                                            }
                                        }
                                        MapPolyline(coordinates: trail.points.map { $0.coordinate })
                                            .stroke(Color(hex: trail.colorHex).opacity(0.5), lineWidth: 3)
                                    }
                                    
                                    // Add a small dot at the LAST coordinate.
                                    if let lastCoordinate = routeCoordinates.last {
                                        Annotation("", coordinate: lastCoordinate) {
                                            Circle()
                                                .fill(.accent)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                }
                                .mapStyle(.standard(elevation: .realistic,
                                                    emphasis: .muted,
                                                    pointsOfInterest: .excludingAll,
                                                    showsTraffic: false))
                                .ignoresSafeArea()
                                .preferredColorScheme(.dark)
                                .onAppear {
                                    locationManager.requestPermission()
                                }
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Image(.timeIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 15)
                                        .foregroundColor(.white)
                                    
                                    Text("Time")
                                        .customFont(.semiBold,13)
                                        .foregroundColor(Color(.nsTxt)).padding([.top,.bottom],2)
                                    
                                    Text(timeString(from: mockData.timeRemaining))
                                        .customFont(.semiBold,15)
                                        .foregroundColor(.white)
                                }
                                .padding(10)
                                .background(.black.opacity(0.6))
                                .cornerRadius(10)
                                .padding([.top, .leading], 10) // offset from edges
                                
                                GroupAvatarsView()
                                    .padding(10)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                
                                
                            }.frame(height: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            
                            VStack(spacing: 20){
                                VStack(alignment: .leading, spacing: 0){
                                    Image(.calorieIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 30)
                                        .foregroundColor(.white)
                                    
                                    Text("Calories")
                                        .customFont(.semiBold,13)
                                        .foregroundColor(.nsTxt)
                                        .padding([.top],5)
                                    
                                    HStack(spacing: 5){
                                        Text(String(format: "%.0f", mockData.gameState.caloriesBurned))
                                            .customFont(.semiBold,20)
                                            .foregroundColor(.white)
                                        
                                        Text("Kcal")
                                            .customFont(.semiBold,13)
                                            .foregroundColor(Color(.nsTxt))
                                    }.padding([.top],10)
                                    
                                    //                                HStack(spacing: 5){
                                    //                                    Image(systemName: "arrow.down")
                                    //                                        .resizable()
                                    //                                        .scaledToFit()
                                    //                                        .foregroundStyle(Color(hex: "#FF3F3F"))
                                    //                                        .frame(height: 15)
                                    //
                                    //                                    VStack(alignment: .leading, spacing: 0){
                                    //
                                    //                                        Text("-4.02%")
                                    //                                            .customFont(.semiBold,13)
                                    //                                            .foregroundColor(Color(hex: "#FF3F3F"))
                                    //
                                    //                                        Text("vs. previous week")
                                    //                                            .customFont(.semiBold,10)
                                    //                                            .foregroundColor(Color(.nsTxt))
                                    //
                                    //                                    }.padding(.leading,3)
                                    //                                }.padding(.top, 10)
                                    
                                }.frame(alignment: .leading).padding(15).overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.signatureGrey, lineWidth: 2)
                                )
                                
                                VStack(alignment: .leading, spacing: 0){
                                    Image(.mapLogo)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 30)
                                        .foregroundColor(.white)
                                    
                                    Text("Conqurered")
                                        .customFont(.semiBold,13)
                                        .foregroundColor(.nsTxt)
                                        .padding([.top],5)
                                    
                                    HStack(spacing: 5){
                                        Text(String(format: "%.1f", mockData.gameState.territoryClaimed))
                                            .customFont(.semiBold,20)
                                            .foregroundColor(.white)
                                        
                                        HStack(alignment: .top, spacing: 1) {
                                            Text("km")
                                                .customFont(.semiBold, 13)
                                                .foregroundColor(Color(.nsTxt))
                                            
                                            Text("2")
                                                .customFont(.semiBold, 9) // smaller font
                                                .foregroundColor(Color(.nsTxt))
                                        }
                                        
                                    }.padding([.top],10)
                                    
                                    //                                HStack(spacing: 5){
                                    //                                    Image(systemName: "arrow.up")
                                    //                                        .resizable()
                                    //                                        .scaledToFit()
                                    //                                        .foregroundStyle(.signatureGreen)
                                    //                                        .frame(height: 15)
                                    //
                                    //                                    VStack(alignment: .leading, spacing: 0){
                                    //
                                    //                                        Text("-4.02%")
                                    //                                            .customFont(.semiBold,13)
                                    //                                            .foregroundColor(.signatureGreen)
                                    //
                                    //                                        Text("vs. previous week")
                                    //                                            .customFont(.semiBold,10)
                                    //                                            .foregroundColor(Color(.nsTxt))
                                    //
                                    //                                    }.padding(.leading,3)
                                    //
                                    //
                                    //                                }.padding(.top, 10)
                                    
                                    
                                    
                                }.frame(alignment: .leading).padding(15).overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.signatureGrey, lineWidth: 2)
                                )
                                
                            }
                            
                            
                        }
                    }
                    
                    Spacer().frame(height: 20)
                    
                    Text("Your Progress")
                        .customFont(.semiBold,17)
                        .foregroundStyle(.nsTxt)
                    
                    Spacer().frame(height: 10)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20){
                            RecordCard(won: true, area: "0.5", change: "+4.02", positive: true)
                            RecordCard(won: false, area: "0.1", change: "-4.02", positive: false)
                            RecordCard(won: false, area: "0.2", change: "+2.02", positive: true)
                            
                        }
                    }
                    Spacer().frame(height: 100)
                }.padding([.leading,.trailing], 30)
                
                VStack{
                    Spacer()
                    
                    HStack {
                        Button {
                            
                        } label: {
                            Image(.homeIcon)
                                .padding(10)
                                .foregroundColor(Color("AccentColor"))
                        }.padding(10)
                        
                        Spacer()
                        
                        NavigationLink(destination: PowerUps()) {
                            Image(.powerupIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 25)
                                .padding(10)
                                .foregroundStyle(.white)
                            
                        }
                        
                        Spacer()
                        
                        Button {
                            if let vc = parentViewController {
                                wepinManager.openWallet(viewController: vc)
                            }
                        } label: {
                            Image(.walletIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25)
                                .padding(10)
                                .foregroundStyle(.white)
                        }
                        
                        Spacer().frame(width: 20)
                    }.background(Color.black).overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.signatureGrey, lineWidth: 2)
                    ).padding([.leading, .trailing],20)
                        .frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
                    Spacer().frame(height: 15)
                }.padding([.leading,.trailing], 20).padding(.bottom, 20)
            }.navigationBarHidden(true).ignoresSafeArea(.all).statusBar(hidden: true).background(.black)
            .background(ViewControllerResolver { vc in
                self.parentViewController = vc
                wepinManager.initWepin(viewController: vc)
            })
        }
    }
    
    func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct UserMarker: View {
    var body: some View {
        ZStack {
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    
                    // Base circle
                    path.addEllipse(in: CGRect(x: 0, y: h * 0.2, width: w, height: h * 0.8))
                    
                    // Top bump
                    path.addEllipse(in: CGRect(x: w * 0.35, y: 0, width: w * 0.4, height: h * 0.4))
                    
                    // Side bump
                    path.addEllipse(in: CGRect(x: w * 0.6, y: h * 0.25, width: w * 0.4, height: h * 0.5))
                }
                .fill(.accent)
            }
            .frame(width: 60, height: 60)
        }
    }
}


#Preview {
    Home()
}

struct DateView: View {
    
    var DayLetter: String
    var Date: String
    var isSelected: Bool = false
    
    var body: some View {
        if isSelected {
            VStack(spacing: 0){
                Text(DayLetter)
                    .customFont(.semiBold,13)
                    .foregroundColor(.black)
                
                Text(Date)
                    .customFont(.semiBold,13) // Using standard font for example
                    .foregroundColor(.black)
                
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 13)
                    .foregroundColor(.signatureGrey)
            }
            .frame(width: 20, height: 50).padding(8) // Add padding around the content first
            .background(
                // Then, set the background to be a rounded rectangle shape filled with your color
                RoundedRectangle(cornerRadius: 20)
                    .fill(.accent) // Using standard green for example, replace with .signatureGreen
            )
        }else{
            VStack{
                Text(DayLetter)
                    .customFont(.semiBold,13)
                    .foregroundStyle(.nsTxt)
                
                Text(Date)
                    .customFont(.semiBold,13)
                    .foregroundStyle(.nsTxt)
                
                
                
            }.frame(width: 17, height: 33).padding(8).overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.signatureGrey, lineWidth: 2)
            )
        }
    }
}

struct GroupAvatarsView: View {
    var body: some View {
        HStack(spacing: -12) {
            Image(.userIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .padding(8)
                .background(Color.green)
                .clipShape(Circle())
                .foregroundColor(.black)
            
            Image(.userIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .padding(8)
                .background(Color.cyan)
                .clipShape(Circle())
                .foregroundColor(.black)
            
            Text("+12")
                .customFont(.semiBold,15)
                .frame(width: 30, height: 30)
                .background(.accent)
                .clipShape(Circle())
                .foregroundColor(.black)
        }
    }
}

struct RecordCard: View {
    
    var won: Bool
    var area: String
    var change: String
    var positive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            
            HStack(spacing: 50){
                Image(.mapLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                    .foregroundColor(.white)
                
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(.trophyIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.black)
                    )
                    .offset(x: 5, y: -5).opacity(won ? 1.0 : 0.0)
                
            }
            
            
            Text("Conqurered")
                .customFont(.semiBold,13)
                .foregroundColor(.nsTxt)
                .padding([.top],5)
            
            HStack(spacing: 5){
                Text(area)
                    .customFont(.semiBold,20)
                    .foregroundColor(.white)
                
                HStack(alignment: .top, spacing: 1) {
                    Text("km")
                        .customFont(.semiBold, 13)
                        .foregroundColor(Color(.nsTxt))
                    
                    Text("2")
                        .customFont(.semiBold, 9)
                        .foregroundColor(Color(.nsTxt))
                }
                
            }.padding([.top],5)
            
            //                                HStack(spacing: 5){
            //                                    Text("238")
            //                                        .customFont(.semiBold,15)
            //                                        .foregroundColor(.white)
            //
            //                                    Text("Kcal")
            //                                        .customFont(.semiBold,13)
            //                                        .foregroundColor(Color(.nsTxt))
            //                                }.padding([.top],5)
            //
            Text(change+"%")
                .customFont(.semiBold,13)
                .foregroundColor(positive ? .accent  : .red)
            
        }.frame(alignment: .leading).padding(15).overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.signatureGrey, lineWidth: 2)
        )
    }
}

