//
//  TarotApp.swift
//  Tarot
//
//  Created by Elijah Hudlow on 12/10/25.
//

import SwiftUI
import SwiftData

@main
struct TarotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TarotCard.self)
    }
}
