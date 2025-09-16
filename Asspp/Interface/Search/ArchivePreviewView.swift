//
//  ArchivePreviewView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Kingfisher
import SwiftUI

struct ArchivePreviewView: View {
    let archive: AppStore.AppPackage

    var body: some View {
        HStack(spacing: 8) {
            KFImage(URL(string: archive.software.artworkUrl))
                .antialiased(true)
                .resizable()
                .cornerRadius(8)
                .frame(width: 32, height: 32, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(archive.software.name)
                        .font(.system(.body, design: .rounded))
                        .bold()
                    Spacer()
                    Text(archive.software.version)
                }
                Group {
                    Text("\(archive.software.bundleID)")
                }
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
