//
//  Buttons.swift
//  Elykid
//
//  Created by Chandan on 20/10/24.
//

import SwiftUI

struct SmallButton: View {

    var buttonText: String
    var buttonColor: Color
    var buttonTextColor: Color
    var action : () -> Void

    var body: some View {

        Button{
            action()
        }label: {
            Text(buttonText)
                .customFont(.semiBold,15)
                .foregroundStyle(buttonTextColor)
                .padding(15)
                .frame(maxWidth: .infinity)
                .background(buttonColor)
                .cornerRadius(10)
        }
    }
}

struct BigButton: View {

    var buttonText: String
    var buttonColor: Color
    var buttonTextColor: Color
    var action : () -> Void

    var body: some View {
        Button{
            action()
        }label: {
            Text(buttonText)
                .customFont(.semiBold,20)
                .foregroundStyle(buttonTextColor)
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(buttonColor)
                .cornerRadius(15)
        }
    }
}

func princ(){
    print("working!")
}

#Preview {
    SmallButton(buttonText: "Register", buttonColor: .accent, buttonTextColor: .black, action: princ)
    BigButton(buttonText: "Personalize", buttonColor: .black, buttonTextColor: .white, action: princ)
}
