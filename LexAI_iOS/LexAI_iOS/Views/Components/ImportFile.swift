//
//  ImportFile.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/17/26.
//

import SwiftUI

import UniformTypeIdentifiers

struct ImportingExampleView: View {
    @State private var importing = false
    
    var body: some View {
        Button(action: {
            importing = true
        }, label: {
            Image(systemName: "square.and.arrow.up")
                .imageScale(.large)
                .foregroundStyle(Color("grape"))
            
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
    ImportingExampleView()
}
