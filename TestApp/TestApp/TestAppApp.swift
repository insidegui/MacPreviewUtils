//
//  TestAppApp.swift
//  TestApp
//
//  Created by Guilherme Rambo on 24/12/22.
//

import SwiftUI
@testable import MacPreviewUtils

@main
struct TestAppApp: App {
    var body: some Scene {
        WindowGroup {
            let _ = ProcessPipe.current.activate()
//            Text("This app doesn't do anything when running, check out each individual view to see how MacPreviewUtils acts on SwiftUI previews.")
//                .multilineTextAlignment(.center)
//                .foregroundStyle(.secondary)
//                .padding()
            LoggingDemo()
        }
    }
}
