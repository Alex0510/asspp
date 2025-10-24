//
//  ApplePackageTool.swift
//  ApplePackageTool
//
//  Created by qaq on 9/15/25.
//

import ApplePackage
import ArgumentParser
import Foundation

@main
struct ApplePackageTool: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "applepackage",
        abstract: "A tool for managing Apple apps",
        subcommands: [Login.self, Logout.self, Search.self, Versions.self, Download.self]
    )
}
