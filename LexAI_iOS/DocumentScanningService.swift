//
//  DocumentScanningService.swift
//  LexAI_iOS
//
//  Created by Leah Hashwi on 3/15/26
//  Assignment 4-Singleton Pattern
//

import UIKit
import Vision

class DocumentScanningService {
    
    // MARK: - Singleton Instance
    static let shared = DocumentScanningService()
    
    // Private init ensures only one instance exists
    private init() {
        print("📄 DocumentScanningService initialized (Singleton)")
    }
    
    // MARK: - Public Methods
    
    /// Extracts text from a single image
    func extractText(from image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { 
            print("❌ Failed to get CGImage")
            return nil 
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        
        // Add legal terminology to improve recognition
        request.customWords = [
            "plaintiff", "defendant", "lawsuit", "contract", 
            "agreement", "lease", "tenant", "landlord", 
            "court", "legal", "attorney", "lawyer",
            "immigration", "visa", "citizen", "court date"
        ]
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        
        do {
            try handler.perform([request])
            guard let observations = request.results else { 
                return nil 
            }
            
            let text = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            return text.isEmpty ? nil : text
        } catch {
            print("❌ Text extraction error: \(error)")
            return nil
        }
    }
    
    /// Processes multiple scanned pages and combines the text
    func processScannedDocuments(from scan: VNDocumentCameraScan) -> String {
        var allText = ""
        
        for pageIndex in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: pageIndex)
            if let text = extractText(from: image) {
                allText += text + "\n"
            }
        }
        
        return allText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Formats legal text for better readability
    func formatLegalText(_ text: String) -> String {
        let paragraphs = text.components(separatedBy: "\n\n")
        var formattedParagraphs: [String] = []
        
        for paragraph in paragraphs {
            let sentences = paragraph.components(separatedBy: ". ")
            let formattedSentences = sentences.map { sentence in
                if let firstChar = sentence.first {
                    return String(firstChar).uppercased() + sentence.dropFirst()
                }
                return sentence
            }
            formattedParagraphs.append(formattedSentences.joined(separator: ". "))
        }
        
        return formattedParagraphs.joined(separator: "\n\n")
    }
    
    /// Analyzes document type based on content
    func detectDocumentType(from text: String) -> String {
        let lowercased = text.lowercased()
        
        if lowercased.contains("lease") || lowercased.contains("rent") || lowercased.contains("landlord") {
            return "Lease Agreement"
        } else if lowercased.contains("court") || lowercased.contains("judge") || lowercased.contains("lawsuit") {
            return "Court Document"
        } else if lowercased.contains("immigration") || lowercased.contains("visa") || lowercased.contains("citizen") {
            return "Immigration Form"
        } else {
            return "General Document"
        }
    }
}