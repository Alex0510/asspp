//
//  WelcomeView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ColorfulX
import SwiftUI

struct WelcomeView: View {
    @State var openInstruction: Bool = false
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 顶部空间
                Spacer()

                // 主要内容区域 - 图片和欢迎文字
                VStack(spacing: 32) {
                    Image(.avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)

                    Text("Welcome to Asspp")
                        .font(.system(.headline, design: .rounded))
                }

                // 中间空间 - 确保内容在中间
                Spacer()

                // 底部信息区域
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Text(version)
                        Button {
                            openInstruction = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        .buttonStyle(.borderless)
                        .popover(isPresented: $openInstruction) {
                            SimpleInstruction()
                                .padding(32)
                        }
                    }
                    Text("App Store itself is unstable, retry if needed.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, bottomPadding) // 根据设备类型调整底部间距
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ColorfulView(color: .constant(.winter))
                .opacity(0.25)
                .ignoresSafeArea()
        )
        #if os(macOS)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        #endif
    }

    // 根据设备类型和iOS版本调整底部间距
    private var bottomPadding: CGFloat {
        #if os(iOS)
            if #available(iOS 19.0, *) {
                // iOS 19+ 使用较小的间距
                return 10
            } else {
                // iOS 15-18 使用较大的间距
                return 100
            }
        #else
            return 20
        #endif
    }
}
