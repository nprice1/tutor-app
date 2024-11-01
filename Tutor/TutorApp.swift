//
//  TutorApp.swift
//  Tutor
//
//  Created by Nolan Price on 9/11/24.
//

import SwiftUI

@main
struct TutorApp: App {
    
    @StateObject private var options = Options()
    
    var body: some Scene {
        WindowGroup {
            HomeView().environmentObject(options)
        }
    }
}
