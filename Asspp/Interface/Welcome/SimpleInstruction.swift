//
//  SimpleInstruction.swift
//  Asspp
//
//  Created by qaq on 9/17/25.
//

import SwiftUI

struct SimpleInstruction: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("How to install an app?")
                .font(.system(.title))
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider().hidden()

            HStack {
                Image(systemName: "1.circle.fill")
                Text("Sign in to your account.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Image(systemName: "2.circle.fill")
                Text("Search for apps you want to install.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Image(systemName: "3.circle.fill")
                Text("Download and save the ipa file.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Image(systemName: "4.circle.fill")
                Text("Install the certificate in settings page.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Image(systemName: "5.circle.fill")
                Text("Install or AirDrop to install.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().hidden()
        }
        .font(.system(.body))
        .foregroundStyle(.primary)
        .mediumAndLargeDetents()
    }
}
