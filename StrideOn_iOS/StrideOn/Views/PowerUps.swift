//
//  PowerUps.swift
//  StrideOn
//
//  Created by Chandan on 30/12/25.
//

import SwiftUI

struct PowerUps: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPage = 0
    private let pages = ["Shield", "Invisible Potion"]
    private let images = ["safe_nut_icon", "invisiblity_potion"]
    private let title = ["Safe Nut", "Invisiblity Potion"]
    private let description = ["Protect your active trail for a short window so you can safely return and bank a huge claim.",
                               "Go temporarily invisible on the local map to secure large territories undetected."]
    
    @State private var sensitivity: Float = 0.50
    @State private var silence: Double = 300
    
    @State private var sheetHeight: CGFloat = 300
    @State private var infoSheetVisible: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(.backBtn).resizable().scaledToFit().frame(height: 40)
                }
                Spacer()
                Text("PowerUps").customFont(.semiBold,20).foregroundStyle(.white)
                Spacer()
                Button{
                    infoSheetVisible = true
                }label: {
                    Image(.infoBtn).resizable().scaledToFit().frame(height: 40)
                }
            }
            Spacer()
            
            VStack(spacing: 0) {
                TabView(selection: $selectedPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 0){
                            Image(images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                            Text(pages[index])
                                .customFont(.semiBold,20)
                                .padding(.top, 30)
                                .foregroundColor(Color(.white))
                            
                            Text(description[index])
                                .customFont(.regular,15)
                                .padding(.top, 5)
                                .foregroundColor(.nsTxt)
                                .frame(width: 150).multilineTextAlignment(.center)
                        }
                        .tag(index)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 350)

                HStack(spacing: 12) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(index == selectedPage ? Color.white : Color.gray.opacity(0.3))
                            .frame(width: index == selectedPage ? 20 : 10, height: 6)
                            .animation(.easeInOut, value: selectedPage)
                    }
                }.padding(30)
                
               
                Button{
                    
                }label: {
                    
                    Text(selectedPage==0 ? "Buy for 50 Very" : "Buy for 75 Very").customFont(.semiBold,20)
                        .foregroundColor(.white)
                        .background(Color.black).frame(maxWidth: .infinity).padding([.leading, .trailing],20).padding([.top,.bottom],15).overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.signatureGrey, lineWidth: 2)
                        )
                    
                }
            }
            
//            ScrollView{
//                HStack{
//                    VStack(spacing: 0){
//                        Image("voice_1").resizable().scaledToFit().frame(height: 150).padding(.bottom,30)
//                        Text("Alloy").customFont(.semiBold,20).foregroundStyle(Color(.label)).padding(.bottom,5)
//                        Text("Composed and direct").customFont(.regular,15).foregroundStyle(.nsTxt)
//                    }
//
//                    VStack(spacing: 0){
//                        Image("voice_1").resizable().scaledToFit().frame(height: 150).padding(.bottom,30)
//                        Text("Alloy").customFont(.semiBold,20).foregroundStyle(Color(.label)).padding(.bottom,5)
//                        Text("Composed and direct").customFont(.regular,15).foregroundStyle(.nsTxt)
//                    }
//
//
//                }
//            }
            Spacer()
            
        }.padding([.leading, .trailing],30).background(Color.black).onAppear(){
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        let AppearanceMode: Int = UserDefaults.standard.integer(forKey: "appearance")
                        if AppearanceMode == 1{
                            window.overrideUserInterfaceStyle = .light
                        }else if AppearanceMode == 2{
                            window.overrideUserInterfaceStyle = .dark
                        }
                    }
                }
            }
        }.sheet(isPresented: $infoSheetVisible) {
            
            VStack(alignment: .center, spacing: 0) {
                Spacer().frame(height: 40)
                Image(.powerupIcon).resizable().frame(width: 30, height: 30).foregroundStyle(Color(.label))
                Spacer().frame(height: 20)
                Text("PowerUps")
                    .customFont(.bold,20)
                Spacer().frame(height: 5)
                Text("Discover game-changing PowerUps that give you the ultimate advantage. Learn how each ability works, when to use it, and how it can help you secure territory, outsmart rivals, and level up your strategy.")
                    .customFont(.regular,16).multilineTextAlignment(.center).foregroundStyle(Color(.nsTxt))
                Spacer().frame(height: 20)
                Button{
                    infoSheetVisible = false
                }label: {
                    Text("Close")
                        .customFont(.bold, 18)
                        .padding([.top, .bottom], 10)
                        .padding([.leading, .trailing], 20)
                        .foregroundStyle(Color(.white))
                        .background(Color(.black))
                        .cornerRadius(20)
                }
                Spacer().frame(height: 10)
            }
            .padding([.leading,.trailing],30)
            .overlay {GeometryReader { geometry in
                Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
            }
            }.onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                sheetHeight = newHeight
            }.presentationDetents([.height(sheetHeight)]).presentationCornerRadius(30)
        }.navigationBarBackButtonHidden(true).statusBar(hidden: true)
    }
}


#Preview {
    PowerUps()
}
