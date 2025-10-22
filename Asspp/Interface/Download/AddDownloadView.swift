
//
//  AddDownloadView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import ApplePackage
import AsyncHTTPClient
import NIO
import NIOHTTP1
import SwiftUI

// 将复杂的部分提取为子视图
struct BundleIDSection: View {
    @Binding var bundleID: String
    @Binding var searchType: EntityType
    @Binding var isLoadingVersions: Bool
    let onFetchVersions: () -> Void
    let isAccountAvailable: Bool

    @FocusState var searchKeyFocused: Bool

    var body: some View {
        Section {
            TextField("Bundle ID", text: $bundleID)
            #if os(iOS)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
            #endif
                .focused($searchKeyFocused)
            Picker("EntityType", selection: $searchType) {
                ForEach(EntityType.allCases, id: \.self) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Spacer()
                Button(action: onFetchVersions) {
                    if isLoadingVersions {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("查询中...")
                        }
                    } else {
                        Text("查询历史版本")
                    }
                }
                .disabled(bundleID.isEmpty || isLoadingVersions || !isAccountAvailable)
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(.vertical, 8)
        } header: {
            Text("Bundle ID")
        } footer: {
            Text("输入应用的Bundle ID来查询可下载的历史版本。对于已下架的应用，此功能特别有用。")
        }
    }
}

struct VersionSelectionSection: View {
    @Binding var availableVersions: [OffAppVersion]
    @Binding var selectedVersion: OffAppVersion?
    @Binding var manualVersionId: String
    @Binding var showManualInput: Bool

    var body: some View {
        Section {
            HStack {
                Text("选择版本")
                    .font(.headline)
                Spacer()
                Button(showManualInput ? "选择版本" : "手动输入") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showManualInput.toggle()
                    }
                }
                .font(.caption)
            }

            if !showManualInput {
                versionPicker
            } else {
                manualInputView
            }
        } header: {
            Text("版本选择")
        } footer: {
            if !availableVersions.isEmpty {
                Text("找到 \(availableVersions.count) 个历史版本")
            } else if showManualInput {
                Text("手动输入版本ID进行下载")
            }
        }
    }

    private var versionPicker: some View {
        VStack {
            Picker("选择版本", selection: Binding(
                get: { self.selectedVersion?.versionId ?? "" },
                set: { id in
                    self.selectedVersion = self.availableVersions.first(where: { $0.versionId == id })
                }
            )) {
                Text("请选择版本").tag("" as String)
                ForEach(availableVersions, id: \.versionId) { version in
                    Text("\(version.versionString) (\(version.releaseDate))")
                        .tag(version.versionId)
                }
            }
            .pickerStyle(.menu)

            if let selectedVersion = selectedVersion {
                VStack(alignment: .leading, spacing: 4) {
                    Text("版本ID: \(selectedVersion.versionId)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let releaseNotes = selectedVersion.releaseNotes {
                        Text("更新内容: \(releaseNotes)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var manualInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("手动输入版本ID")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("输入版本ID（数字）", text: $manualVersionId)
            #if os(iOS)
                .keyboardType(.numberPad)
            #endif
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Text("版本ID可以从第三方网站或历史版本列表中获取")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct AccountSection: View {
    @Binding var selection: AppStore.UserAccount.ID
    @ObservedObject var avm: AppStore
    let isDemoMode: Bool

    var body: some View {
        Section {
            Picker("Account", selection: $selection) {
                ForEach(avm.accounts) { account in
                    Text(account.account.email)
                        .id(account.id)
                }
            }
            .pickerStyle(.menu)
            .onAppear { selection = avm.accounts.first?.id ?? .init() }
            #if os(iOS)
                .redacted(reason: .placeholder, isEnabled: isDemoMode)
            #else
                .redacted(reason: isDemoMode ? .placeholder : [])
            #endif
        } header: {
            Text("Account")
        } footer: {
            Text("Select an account to download this app")
        }
    }
}

struct DownloadButtonSection: View {
    @Binding var obtainDownloadURL: Bool
    @Binding var hint: String
    let bundleID: String
    let account: AppStore.UserAccount?
    let onStartDownload: () -> Void

    var body: some View {
        Section {
            Button(obtainDownloadURL ? "Communicating with Apple..." : "Request Download") {
                onStartDownload()
            }
            .disabled(bundleID.isEmpty || obtainDownloadURL || account == nil)
        } footer: {
            if hint.isEmpty {
                Text("The package can be installed later from the Downloads page.")
            } else {
                Text(hint)
                    .foregroundStyle(.red)
            }
        }
    }
}

struct AddDownloadView: View {
    @State var bundleID: String = ""
    @State var searchType: EntityType = .iPhone
    @State var selection: AppStore.UserAccount.ID = .init()
    @State var obtainDownloadURL = false
    @State var hint = ""

    // 新增状态变量 - 版本查询功能
    @State private var isLoadingVersions = false
    @State private var availableVersions: [OffAppVersion] = []
    @State private var selectedVersion: OffAppVersion?
    @State private var manualVersionId: String = ""
    @State private var showManualInput = false

    @FocusState var searchKeyFocused

    @StateObject var avm = AppStore.this
    @StateObject var dvm = Downloads.this

    @Environment(\.dismiss) var dismiss

    var account: AppStore.UserAccount? {
        avm.accounts.first { $0.id == selection }
    }

    var body: some View {
        FormOnTahoeList {
            BundleIDSection(
                bundleID: $bundleID,
                searchType: $searchType,
                isLoadingVersions: $isLoadingVersions,
                onFetchVersions: fetchAppVersions,
                isAccountAvailable: account != nil,
                searchKeyFocused: _searchKeyFocused
            )

            if !availableVersions.isEmpty || showManualInput {
                VersionSelectionSection(
                    availableVersions: $availableVersions,
                    selectedVersion: $selectedVersion,
                    manualVersionId: $manualVersionId,
                    showManualInput: $showManualInput
                )
            }

            AccountSection(
                selection: $selection,
                avm: avm,
                isDemoMode: avm.demoMode
            )

            DownloadButtonSection(
                obtainDownloadURL: $obtainDownloadURL,
                hint: $hint,
                bundleID: bundleID,
                account: account,
                onStartDownload: startDownload
            )
        }
        .navigationTitle("Direct Download")
    }

    // 查询应用版本
    func fetchAppVersions() {
        guard account != nil else {
            hint = "请先选择账户"
            return
        }

        guard !bundleID.isEmpty else {
            hint = "请输入Bundle ID"
            return
        }

        searchKeyFocused = false
        isLoadingVersions = true
        hint = ""
        availableVersions = []
        selectedVersion = nil // 重置选择

        Task {
            do {
                let versions = try await fetchVersionsFromAPI(appId: bundleID)

                await MainActor.run {
                    self.availableVersions = versions
                    if !versions.isEmpty {
                        self.selectedVersion = versions.first
                    }
                    self.isLoadingVersions = false

                    if versions.isEmpty {
                        self.hint = "未找到该应用的历史版本，请检查Bundle ID是否正确或尝试手动输入版本ID"
                    } else {
                        self.hint = "找到 \(versions.count) 个历史版本"
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingVersions = false
                    self.hint = "获取版本失败: \(error.localizedDescription)"
                }
            }
        }
    }

    // 从第三方API获取版本信息
    private func fetchVersionsFromAPI(appId: String) async throws -> [OffAppVersion] {
        let urlString = "https://api.timbrd.com/apple/app-version/index.php?id=\(appId)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的API URL"])
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -2, userInfo: [NSLocalizedDescriptionKey: "网络请求失败"])
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API请求失败，状态码: \(httpResponse.statusCode)"])
        }

        do {
            let decoder = JSONDecoder()
            let versionData = try decoder.decode([APIAppVersion].self, from: data)

            // 转换为OffAppVersion并排序（最新的在前）
            return versionData
                .sorted { $0.external_identifier > $1.external_identifier }
                .map { apiVersion in
                    OffAppVersion(
                        versionString: apiVersion.bundle_version,
                        versionId: String(apiVersion.external_identifier),
                        releaseDate: formatDate(apiVersion.created_at),
                        releaseNotes: apiVersion.release_notes
                    )
                }
        } catch {
            throw NSError(domain: "ParseError", code: -3, userInfo: [NSLocalizedDescriptionKey: "数据解析失败: \(error.localizedDescription)"])
        }
    }

    // 直接使用软件ID和版本ID进行下载请求
    func startDownload() {
        guard let account else { return }
        searchKeyFocused = false
        obtainDownloadURL = true

        Task {
            do {
                // 获取版本ID
                let versionId: String
                if showManualInput {
                    versionId = manualVersionId
                } else if let selectedVersion = selectedVersion {
                    versionId = selectedVersion.versionId
                } else {
                    // 如果没有选择版本，使用默认值
                    versionId = ""
                }

                // 调用下载功能
                let (downloadOutput, appMetadata) = try await directDownloadCall(
                    bundleID: bundleID,
                    versionId: versionId,
                    account: account
                )

                // 使用从响应中获取的应用信息创建Software对象
                let temporarySoftware = Software(
                    id: appMetadata.itemId,
                    bundleID: appMetadata.bundleID,
                    name: appMetadata.itemName,
                    version: downloadOutput.bundleShortVersionString,
                    price: 0,
                    artistName: appMetadata.artistName,
                    sellerName: appMetadata.playlistName,
                    description: appMetadata.description,
                    averageUserRating: 0,
                    userRatingCount: 0,
                    artworkUrl: appMetadata.artworkUrl,
                    screenshotUrls: [],
                    minimumOsVersion: "0.0",
                    fileSizeBytes: appMetadata.fileSize,
                    releaseDate: appMetadata.releaseDate,
                    formattedPrice: "Free",
                    primaryGenreName: appMetadata.genre
                )

                // 创建应用包
                var appPackage = AppStore.AppPackage(software: temporarySoftware)
                appPackage.externalVersionID = versionId.isEmpty ? nil : versionId

                // 创建下载请求并添加到下载管理器
                let request = PackageManifest(
                    account: account,
                    package: appPackage,
                    downloadOutput: downloadOutput
                )

                // 添加到下载管理器并开始下载
                _ = dvm.add(request: request)
                dvm.resume(request: request)

                await MainActor.run {
                    obtainDownloadURL = false
                    hint = "Download Requested and Started"
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    obtainDownloadURL = false
                    hint = "Unable to retrieve download url, please try again later." + "\n" + error.localizedDescription
                }
            }
        }
    }

    // 直接调用下载功能 - 使用 Bundle ID 和版本 ID
    private func directDownloadCall(
        bundleID: String,
        versionId: String,
        account: AppStore.UserAccount
    ) async throws -> (DownloadOutput, AppMetadata) {
        var acc = account.account

        // 直接构造下载请求，不依赖 Software 对象
        let deviceIdentifier = Configuration.deviceIdentifier

        // 创建 HTTPClient 配置
        var config = HTTPClient.Configuration()
        config.tlsConfiguration = Configuration.tlsConfiguration
        config.redirectConfiguration = .disallow
        config.timeout = HTTPClient.Configuration.Timeout(
            connect: .seconds(Configuration.timeoutConnect),
            read: .seconds(Configuration.timeoutRead)
        )
        config.httpVersion = .http1Only

        let client = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: config
        )

        // 构造请求负载
        var payload: [String: Any] = [
            "creditDisplay": "",
            "guid": deviceIdentifier,
            "salableAdamId": bundleID, // 直接使用 Bundle ID
        ]

        if !versionId.isEmpty {
            payload["externalVersionId"] = versionId
        }

        let data = try PropertyListSerialization.data(fromPropertyList: payload, format: .xml, options: 0)

        // 创建请求头
        var headers = [(String, String)]()
        headers.append(("Content-Type", "application/x-apple-plist"))
        headers.append(("User-Agent", Configuration.userAgent))
        headers.append(("iCloud-DSID", acc.directoryServicesIdentifier))
        headers.append(("X-Dsid", acc.directoryServicesIdentifier))

        // 添加 cookie 头
        if let url = URL(string: "https://p25-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct") {
            for item in acc.cookie.buildCookieHeader(url) {
                headers.append(item)
            }
        }

        // 创建 HTTPClient 请求
        let request = try HTTPClient.Request(
            url: "https://p25-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct",
            method: .POST,
            headers: HTTPHeaders(headers),
            body: .data(data)
        )

        let response = try await client.execute(request: request).get()

        acc.cookie.mergeCookies(response.cookies)

        // 检查响应状态
        guard response.status.code == 200 else {
            throw NSError(domain: "DownloadError", code: Int(response.status.code), userInfo: [NSLocalizedDescriptionKey: "下载请求失败，状态码: \(response.status.code)"])
        }

        guard var body = response.body,
              let responseData = body.readData(length: body.readableBytes)
        else {
            throw NSError(domain: "DownloadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应体为空"])
        }

        // 解析响应
        let plist = try PropertyListSerialization.propertyList(
            from: responseData,
            options: [],
            format: nil
        ) as? [String: Any]
        guard let dict = plist else {
            throw NSError(domain: "DownloadError", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效的响应格式"])
        }

        // 检查错误
        if let failureType = dict["failureType"] as? String {
            switch failureType {
            case "2034":
                throw NSError(domain: "DownloadError", code: 2034, userInfo: [NSLocalizedDescriptionKey: "密码令牌已过期"])
            case "9610":
                throw NSError(domain: "DownloadError", code: 9610, userInfo: [NSLocalizedDescriptionKey: "需要许可证"])
            default:
                if let customerMessage = dict["customerMessage"] as? String {
                    throw NSError(domain: "DownloadError", code: Int(failureType) ?? -1, userInfo: [NSLocalizedDescriptionKey: customerMessage])
                }
                throw NSError(domain: "DownloadError", code: Int(failureType) ?? -1, userInfo: [NSLocalizedDescriptionKey: "下载失败: \(failureType)"])
            }
        }

        guard let items = dict["songList"] as? [[String: Any]], !items.isEmpty else {
            throw NSError(domain: "DownloadError", code: -3, userInfo: [NSLocalizedDescriptionKey: "响应中没有项目"])
        }

        let item = items[0]
        guard let url = item["URL"] as? String else {
            throw NSError(domain: "DownloadError", code: -4, userInfo: [NSLocalizedDescriptionKey: "缺少下载URL"])
        }

        guard let metadata = item["metadata"] as? [String: Any] else {
            throw NSError(domain: "DownloadError", code: -5, userInfo: [NSLocalizedDescriptionKey: "缺少元数据"])
        }

        let version = (metadata["bundleShortVersionString"] as? String)
        let bundleVersion = metadata["bundleVersion"] as? String

        guard let version = version, let bundleVersion = bundleVersion else {
            throw NSError(domain: "DownloadError", code: -6, userInfo: [NSLocalizedDescriptionKey: "缺少必要的信息"])
        }

        var sinfs: [Sinf] = []
        if let sinfData = item["sinfs"] as? [[String: Any]] {
            for sinfItem in sinfData {
                if let id = sinfItem["id"] as? Int64,
                   let data = sinfItem["sinf"] as? Data
                {
                    sinfs.append(Sinf(id: id, sinf: data))
                }
            }
        }

        guard !sinfs.isEmpty else {
            throw NSError(domain: "DownloadError", code: -7, userInfo: [NSLocalizedDescriptionKey: "响应中没有SINF"])
        }

        // 从元数据中提取应用信息
        let appMetadata = extractAppMetadata(from: metadata, bundleID: bundleID)

        // 创建下载输出
        let output = DownloadOutput(
            downloadURL: url,
            sinfs: sinfs,
            bundleShortVersionString: version,
            bundleVersion: bundleVersion
        )

        // 更新账户信息
        if let index = avm.accounts.firstIndex(where: { $0.id == account.id }) {
            avm.accounts[index].account = acc
        }

        return (output, appMetadata)
    }

    // 从元数据中提取应用信息
    private func extractAppMetadata(from metadata: [String: Any], bundleID: String) -> AppMetadata {
        let itemId = metadata["itemId"] as? Int64 ?? Int64(bundleID.hashValue)
        let itemName = metadata["itemName"] as? String ?? bundleID
        let artistName = metadata["artistName"] as? String ?? "Unknown"
        let playlistName = metadata["playlistName"] as? String ?? "Unknown"
        let bundleDisplayName = metadata["bundleDisplayName"] as? String ?? itemName
        let genre = metadata["genre"] as? String ?? "Application"
        let releaseDate = metadata["releaseDate"] as? String ?? ISO8601DateFormatter().string(from: Date())

        // 获取图标URL - 优先使用softwareIcon57x57URL，如果没有则使用artworkURL
        var artworkUrl = metadata["softwareIcon57x57URL"] as? String ?? ""
        if artworkUrl.isEmpty, let artworkURL = metadata["artworkURL"] as? String {
            artworkUrl = artworkURL
        }

        // 获取文件大小
        let fileSize: String?
        if let assetInfo = metadata["asset-info"] as? [String: Any],
           let fileSizeInt = assetInfo["file-size"] as? Int
        {
            fileSize = "\(fileSizeInt)"
        } else {
            fileSize = nil
        }

        // 获取描述 - 如果没有则使用默认描述
        let description = metadata["description"] as? String ?? "Downloaded app"

        // 获取实际的bundle ID
        let actualBundleID = metadata["softwareVersionBundleId"] as? String ?? bundleID

        return AppMetadata(
            itemId: itemId,
            bundleID: actualBundleID,
            itemName: itemName,
            artistName: artistName,
            playlistName: playlistName,
            bundleDisplayName: bundleDisplayName,
            genre: genre,
            releaseDate: releaseDate,
            artworkUrl: artworkUrl,
            fileSize: fileSize,
            description: description
        )
    }

    // 日期格式化工具函数
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd"

        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}

// 应用元数据结构
struct AppMetadata {
    let itemId: Int64
    let bundleID: String
    let itemName: String
    let artistName: String
    let playlistName: String
    let bundleDisplayName: String
    let genre: String
    let releaseDate: String
    let artworkUrl: String
    let fileSize: String?
    let description: String
}

// 数据模型 - 遵循 Hashable
struct OffAppVersion: Hashable {
    let versionString: String
    let versionId: String
    let releaseDate: String
    let releaseNotes: String?

    // 实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(versionId)
    }

    static func == (lhs: OffAppVersion, rhs: OffAppVersion) -> Bool {
        return lhs.versionId == rhs.versionId
    }
}

struct APIAppVersion: Codable {
    let bundle_version: String
    let external_identifier: Int
    let created_at: String
    let release_notes: String?
}

// 下载请求模型
struct DownloadRequest {
    let bundleIdentifier: String
    let versionId: String
    let account: AppStore.UserAccount
}
