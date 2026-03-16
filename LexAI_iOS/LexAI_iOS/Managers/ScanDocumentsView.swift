//
//  ScanDocumentsView.swift
//  LexAI_iOS
//
//  Made by Leah Hashwi on 3/3/26.
//

import SwiftUI
import VisionKit
import Vision

///View for scanning documents
///-displays a scanned text preview
///-user can scan documents and add scanned text back to the chat

struct ScanDocumentsView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onTextAdded: ((String) -> Void)?

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }


    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}


    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }


    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: ScanDocumentsView
        
        init(_ parent: ScanDocumentsView) {
            self.parent = parent
            print("Using Singleton: DocumentScanningService.shared")
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Use the singleton service
            let scannedText = DocumentScanningService.shared.processScannedDocuments(from: scan)
            let documentType = DocumentScanningService.shared.detectDocumentType(from: scannedText)
            let formattedText = DocumentScanningService.shared.formatLegalText(scannedText)
            
            if !formattedText.isEmpty {
                let finalText = "[\(documentType)]\n\n\(formattedText)"
                parent.onTextAdded?(finalText)
            }

            parent.isPresented = false
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanner error: \(error)")
            parent.isPresented = false
        }
        
        // Note: extractText method is now in DocumentScanningService.shared
    }
}

//preview wrapper for no crash and to still demo. it
struct ScanDocumentsPreviewWrapper: View {
    @State private var showScanner = true

    var body: some View {
        
        Text("Document Scanner Preview")
            .font(.title2)
            .padding()
            .fullScreenCover(isPresented: $showScanner) {
                
                Text("Scanner cannot run in preview")
                    .font(.headline)
            }
    }
}
#Preview {
    ScanDocumentsPreviewWrapper()
}