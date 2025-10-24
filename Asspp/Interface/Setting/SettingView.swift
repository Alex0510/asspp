//
//  SettingView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

struct SettingView: View {
    @StateObject var vm = AppStore.this

    var body: some View {
        #if os(iOS)
            NavigationView {
                formContent
            }
            .navigationViewStyle(.stack)
            // 设置导航栏背景为透明
            .modifier(NavigationBarTransparentModifier())
            // iOS 15及以下版本的导航栏透明设置
            .onAppear {
                setupNavigationBarAppearance()
            }
        #else
            NavigationStack {
                formContent
            }
        #endif
    }

    private var formContent: some View {
        FormOnTahoeList {
            Section {
                Toggle("Demo Mode", isOn: $vm.demoMode)
            } header: {
                Text("Demo Mode")
            } footer: {
                Text("By enabling this, all your accounts and sensitive information will be redacted.")
            }
            Section {
                Button("Delete All Downloads", role: .destructive) {
                    Downloads.this.removeAll()
                }
            } header: {
                Text("Downloads")
            } footer: {
                Text("Manage downloads.")
            }
            Section {
                Text(ProcessInfo.processInfo.hostName)
                    .redacted(reason: .placeholder, isEnabled: vm.demoMode)
                Text(ApplePackage.Configuration.deviceIdentifier)
                    .font(.system(.body, design: .monospaced))
                    .redacted(reason: .placeholder, isEnabled: vm.demoMode)
                #if canImport(UIKit)
                    Button("Open Settings") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                #endif
                #if canImport(AppKit) && !canImport(UIKit)
                    Button("Open Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
                    }
                #endif
            } header: {
                Text("Host Name")
            } footer: {
                Text("Grant local network permission to install apps and communicate with system services. If hostname is empty, open Settings to grant permission.")
            }

            #if canImport(UIKit)
                Section {
                    Button("Install Certificate") {
                        UIApplication.shared.open(Installer.caURL)
                    }
                } header: {
                    Text("SSL")
                } footer: {
                    Text("On device installer requires your system to trust a self signed certificate. Tap the button to install it. After install, navigate to Settings > General > About > Certificate Trust Settings and enable full trust for the certificate.")
                }
            #endif

            #if canImport(AppKit) && !canImport(UIKit)
                Section {
                    Button("Show Certificate in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([Installer.ca])
                    }
                } header: {
                    Text("SSL")
                } footer: {
                    Text("On macOS, install certificates through System Keychain.")
                }
            #endif

            Section {
                Button("源码作者@Lakr233") {
                    #if canImport(UIKit)
                        UIApplication.shared.open(URL(string: "https://github.com/Lakr233/Asspp")!)
                    #endif
                    #if canImport(AppKit) && !canImport(UIKit)
                        NSWorkspace.shared.open(URL(string: "https://github.com/Lakr233/Asspp")!)
                    #endif
                }
                Button("修改作者@Mr.Eric") {
                    #if canImport(UIKit)
                        UIApplication.shared.open(URL(string: "http://t.me/Mr_Alex")!)
                    #endif
                    #if canImport(AppKit) && !canImport(UIKit)
                        NSWorkspace.shared.open(URL(string: "http://t.me/Mr_Alex")!)
                    #endif
                }
                Button("TG频道") {
                    #if canImport(UIKit)
                        UIApplication.shared.open(URL(string: "https://t.me/+2T-oJk2FFts4NDZl")!)
                    #endif
                    #if canImport(AppKit) && !canImport(UIKit)
                        NSWorkspace.shared.open(URL(string: "https://t.me/+2T-oJk2FFts4NDZl")!)
                    #endif
                }
            } header: {
                Text("About")
            } footer: {
                Text("Hope this app helps you!")
            }

            // 危险区域移动到内容区域上方，避免与底部椭圆形UI重叠
            Section {
                Button("Reset", role: .destructive) {
                    try? FileManager.default.removeItem(at: documentsDirectory)
                    try? FileManager.default.removeItem(at: temporaryDirectory)
                    #if canImport(UIKit)
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                    #endif
                    #if canImport(AppKit) && !canImport(UIKit)
                        NSApp.terminate(nil)
                    #endif
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        exit(0)
                    }
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("This will reset all your settings.")
            }

            // 添加底部填充，为椭圆形标签栏留出空间
            Section {} footer: {
                Color.clear
                    .frame(height: 50)
            }
        }
        .navigationTitle("Settings")
    }

    // 设置导航栏外观（iOS 15及以下版本）
    private func setupNavigationBarAppearance() {
        #if os(iOS)
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.backgroundEffect = nil
            appearance.shadowColor = .clear

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
        #endif
    }
}
