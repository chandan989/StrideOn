//
//  InputBox.swift
//  Elykid
//
//  Created by Chandan on 20/10/24.
//

import SwiftUI

struct InputBox: View {

    var title: String
    var imageName: String
    var placeholder: String
    @Binding var value: String
    
    @State private var showError: Bool = false
    
    var body: some View {

        VStack {
            Text(title)
                .customFont(.semiBold, 17)
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        HStack {
            Image(imageName)
                .foregroundStyle(.nsTxt)
            TextField(placeholder, text: $value)
                .foregroundColor(Color(.label))
                .font(Font.custom("Lufga-Regular", size: 15))
                .textInputAutocapitalization(.never)
               
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.inputBorders, lineWidth: 1)
        )

        if placeholder.lowercased().contains("password") {
            Spacer().frame(height: 10)
            Text("Minimum 8 characters")
                .customFont(.regular, 13)
                .foregroundStyle(.nsTxt)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DropBox: View{
    var title: String
    var options: [String]
    var imageName: String
    var placeholdertxt: String
    @Binding var selectedOption: String

    var body: some View {

        VStack(alignment: .leading){
            Text(title)
                .foregroundStyle(Color(.label))
                .customFont(.semiBold, 17)
            Menu {
                ForEach(options, id: \.self){option in
                    Button(option, action: { selectedOption = option })
                }
            } label: {
                if selectedOption.isEmpty {
                    Label(placeholdertxt, image: imageName)
                        .padding()
                        .foregroundStyle(Color(.label))
                        .cornerRadius(8)
                }else{
                    Label(selectedOption, image: imageName)
                        .padding()
                        .foregroundStyle(Color(.label))
                        .cornerRadius(8)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.inputBorders, lineWidth: 1)
            )
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ToggleButton: View {
    var title: String
    @Binding var isOn: Bool
    @Binding var isEnabled: Bool
    var enabledColor: Color = .accentColor

    var body: some View {
        HStack {
            Text(title)
                .customFont(.bold,20).opacity(isEnabled ? 1 : 0.5)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: enabledColor)).padding(.trailing,2).disabled(!isEnabled)
        }
    }
}



#Preview {
    InputBox(title: "What's your email?",
             imageName: "Filled_email",
             placeholder: "Password",
             value: .constant(""))

    Spacer().frame(height: 40)

    DropBox(title: "Gender",options: ["Male", "Female"], imageName: "empty_users", placeholdertxt: "", selectedOption: .constant(""))
    
    ToggleButton(title: "Defender", isOn: .constant(false), isEnabled: .constant(true))

}
