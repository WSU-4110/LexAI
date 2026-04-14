//
//  LexAI_iOSApp.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/10/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFunctions
import FirebaseAppCheck


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
      return true
    }
    #if DEBUG
    AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
    #endif
    FirebaseApp.configure()

//#if DEBUG
    // Local-only development: point SDKs at Firebase emulators.
    // iOS Simulator can reach your Mac via localhost.
//    Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
//    Functions.functions().useEmulator(withHost: "127.0.0.1", port: 5001)
//#endif
    return true
  }
}

@main
struct LexAI_iOS: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}
