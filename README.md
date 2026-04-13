LexAI

Purpose:
LexAI is a macOS application that helps people in the United States navigate legal information when they struggle with English as their primary language. 
The application provides an accessible way for non-English speakers to understand legal information, 
ask questions about their rights, and analyze legal documents in a language they are comfortable with.
It also provides an intuitive interface, document handling, and multilingual support that could assist legal professionals with their clients.

Functionalities:

1. **Sidebar Navigation System** - Users can easily navigate between different sections of the app including new chat sessions, chat history, document upload, and settings using `SideBarView.swift`.

2. **Chat Interface** - Users can ask legal questions and receive AI-generated responses. The chat supports session handling, clearing chat history, and saving conversations using `ChatView.swift`.

3. **Multilingual Translation Pipeline** - Responses are automatically translated to support non-English users, making legal information accessible across language barriers.

4. **Legal Document Upload & Processing** - Users can scan and upload documents (such as lease agreements, court notices, or legal forms) using `parse_pdf.py` for text extraction and analysis.

5. **Michigan Legislation Data Retrieval** - The app fetches and structures real legislation data from Michigan using external APIs, storing results in JSON format (`bill_text.json`, `bill_details.json`).

6. **Data Chunking for Processing** - Legal text is split into smaller, manageable segments using `chunk_text.py` to enable efficient embedding and AI processing.

7. **Legal Disclaimer on First Launch** - A disclaimer (`disclaimer.swift`) informs users that LexAI is not a substitute for professional legal advice.

8. **Firebase Authentication & Backend** - User authentication and backend services are supported through Firebase integration.

Contributors:

**Hassan Alkhafaji** | Team Lead - Task organization, backend setup, authentication, GitHub workflow management, merge conflict resolution 

**Sara Al-hachami** | Frontend Developer - Sidebar navigation system (`SideBarView.swift`), chat interface (`ChatView.swift`), integration between components, GitHub assistance 

**Mirshod Sobirov** | Backend Developer - Michigan legislation API integration, JSON data structuring, text chunking logic (`chunk_text.py`), legal disclaimer implementation 

**Ayaan Amir** | Backend/AI Developer - Firebase functions, translation pipeline, response handling logic, chat response integration (`ChatView.swift`) 

**Leah Hashwi** | UI/Document Processing Developer - document scanning and upload, UI layout improvements (`HomeView.swift`, `ChatView.swift`), testing and refinement 





