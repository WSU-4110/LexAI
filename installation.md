Installation Guide: 

This document provides detailed system requirements and step-by-step instructions to build and install LexAI on macOS.

System Requirements: 
- **Operating System** | macOS 12.0 (Monterey) or newer |
- **Processor** | Apple Silicon (M1/M2/M3) |
- **Internet Connection** | Required for API calls and Firebase services |
- **Xcode** | 14.0+ | [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835)
- **Python** | 3.9+ | [python.org](https://www.python.org/downloads)
- **Git** | Latest | [git-scm.com](https://git-scm.com)
- **Firebase Account** | Free tier | [firebase.google.com](https://firebase.google.com)

Supported MacOS Versions:
- macOS 12 (Monterey)
- macOS 13 (Ventura)
- macOS 14 (Sonoma)
- macOS 15 (Sequoia)

Pre-installations: 
Step 1: Install Xcode
Step 2: Install node.js | https://nodejs.org/en/ 
Step 3: Install git | https://git-scm.com/downloads
Step 4: Install python 3.9+ | python.org/downloads
Step 5: Request to be added as a FireBase project member and download the GoogleService-Info.plist

Instructions to build and Install the Software
Step 1: Verify you have all prerequisite and pre-installations to build the project.
Step 2: Clone the repository | https://github.com/WSU-4110/LexAI.git
- In Command Prompt/Terminal
      git clone https://github.com/WSU-4110/LexAI.git
      cd LexAI
Step 3: Open XCode.
Step 4: Drop the GoogleService-Info.plist into the LexAI_IOS main folder 
Step 5: Install Python Dependencies
# Navigate to backend directory
cd backend

# Make an environment
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Install required packages
pip3 install requests
pip3 install json5
pip3 install PyPDF2
pip3 install python-dotenv

# If a requirements.txt file exists, use:
# pip3 install -r requirements.txt

# Deactivate the virtual environment when done
deactivate

Step 6: Locate the "Build" button on the top of the screen of XCode and press it to build the application.
Step 7: Locate the "Run" button on the top of the screen of XCode and press it to run the application.
