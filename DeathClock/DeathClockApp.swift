//
//  DeathClockApp.swift
//  DeathClock
//
//  Created by Jon Plummer on 12/19/25.
//

import SwiftUI
import AppKit

@main
struct DeathClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Hide dock icon - menu bar only app (must be done before app finishes launching)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize menu bar controller after app is fully launched
        menuBarController = MenuBarController.shared
    }
}
