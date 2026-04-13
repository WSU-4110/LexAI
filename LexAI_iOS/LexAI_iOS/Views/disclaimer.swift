import SwiftUI
import Combine

struct LegalDisclaimerAlert: View {
    @State private var showAlert = false
    @StateObject private var manager = DisclaimerManager()

    var body: some View {
        Color.clear
            .onAppear {
                showAlert = true
            }
            .alert("Legal Disclaimer", isPresented: $showAlert) {
                Button("Agree & Continue", role: .cancel) {
                    manager.acceptDisclaimer()
                    showAlert = false
                }
            }message: {
                Text(
                    """
                    **Legal Disclaimer** 
                    LexAI is a student-developed educational project and is available
                    for informational purposes only 
                    LexAI does not provide professional legal advice, and the responses generated
                    by this application should not be blindly relied upon as a substitute for qualified
                    attorney advice.
                    By using this application, you acknowledge that information provided may be incomplete, inaccurate
                    , or outdated, and you agree to seek professional legal assistance if needed for any legal matters.
                    Thank You
                    """
                )
            }
    }
}

@MainActor
class DisclaimerManager: ObservableObject {
    @Published private(set) var hasAccepted = false

    func acceptDisclaimer() {
        hasAccepted = true
    }
    
    func resetDisclaimer() {
        hasAccepted = false
    }
}
