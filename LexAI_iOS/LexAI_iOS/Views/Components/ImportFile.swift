//
//  ImportFile.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/17/26.
//

import SwiftUI

import UniformTypeIdentifiers

struct ImportFile: View {
    @State private var importing = false
    
    var body: some View {
        Button(action: {
            importing = true
        }, label: {
            Image(systemName: "square.and.arrow.up")
                .resizable()
                .frame(width: 25, height: 35)
                .fontWeight(.bold)
                .foregroundStyle(Color.white)
                .shadow(radius: 8, x: 0, y: 8)
            
        })
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.plainText, .pdf]
        ) { result in
            switch result {
            case .success(let file):
                print(file.absoluteString)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

#Preview() {
    ImportFile()
}
