//
//  PromptModel.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 3/24/26.
//
import Foundation
import FirebaseAuth

struct Prompt {
    let prompt: String
    let documents: [Any?]
    let location: String
    let language: String
    let user: User
}


//prompt: string,
//documents: [Any]?,
//location: string,
//language: string,
//user: email
