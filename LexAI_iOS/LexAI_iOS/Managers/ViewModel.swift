//
//  ViewModel.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/10/26.
//

import Foundation
import Firebase
import Combine

@MainActor
class ViewModel: ObservableObject {

    
    @Published var authManager = FirebaseManager()
    let db =  Firestore.firestore()
    
    init() {
    }
    
}
