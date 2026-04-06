//
//  PromptModel.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 3/24/26.
//
import Foundation
import FirebaseAuth

struct Prompt: Codable {
    let id: String
    let prompt: String
    let document: [String]
    let location: String
    let language: String
    let userID: String
}
