//
//  ScanDocumentsView.swift
//  LexAI_iOS
//
//  Made by Leah Hashwi on 3/3/26.
//

import SwiftUI
import Vision
import VisionKit

///View for scanning documents
///-displays a scanned text preview
///-user can scan documents  and add scanned text back to the chat

struct ScanDocumentsView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onTextAdded: ((String) -> Void)?

    //Makes and configures the VNDocumentCameraViewController for document scanning
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    //Updates the view controller when SwiftUI state changes- keeps it currently empty as no updates are needed
    func updateUIViewController(
        _ uiViewController: VNDocumentCameraViewController,
        context: Context
    ) {}

    //Makes a coordinator to handle delegate methods from the document camera view controller
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: ScanDocumentsView

        init(_ parent: ScanDocumentsView) {
            self.parent = parent
        }

        //Processes the scanned document pages, extracts text from each page and calls the onTextAdded callback with the combined text
        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            //Process the scan
            var scannedText = ""
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                
                //To extract the text from the scan
                if let text = extractText(from: image) {
                    scannedText += text + "\n"
                }
            }

            if !scannedText.isEmpty {
                parent.onTextAdded?(scannedText.trimmingCharacters(in: .whitespacesAndNewlines))
            }

            parent.isPresented = false
        }

        //Handles cancellation of the document scanner by dismissing the view
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }

        //Handles errors during document scanning by logging the error and dismissing the view
        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            print("Document scanner error: \(error)")
            parent.isPresented = false
        }

        //Extracts text from a given UIImage using Vision's text recognition
        private func extractText(from image: UIImage) -> String? {
            guard let cgImage = image.cgImage else { return nil }
            
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
                guard let observations = request.results else { return nil }

                return observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
            } catch {
                print("Text extraction error: \(error)")
                return nil
            }
        }
    }
}

struct ScanDocumentsPreviewWrapper: View {
    @State private var showScanner = true

    //Gives a preview of the document scanner view for SwiftUI previews
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
