//
//  LexAI_iOSApp.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/10/26.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct LexAI_iOS: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
