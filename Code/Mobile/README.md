# Car Maintenance Assistant

An intelligent mobile application designed to assist car owners with diagnosing vehicle problems, finding solutions for common issues, and accessing maintenance tips. The application leverages advanced AI technologies to provide accurate, practical advice for vehicle maintenance.

## 🚗 Overview

The Car Maintenance Assistant is a comprehensive solution for vehicle owners who need immediate assistance with car problems. Using artificial intelligence and a database of common car issues, the application helps users identify problems and provides step-by-step guidance to resolve them. 

## ✨ Key Features

- **AI-Powered Chatbot**: Integrates with Google's Gemini AI to answer car maintenance questions with natural, conversational responses
- **Problem Diagnosis**: Helps identify common car issues based on symptoms described by users
- **Local Knowledge Base**: Stores frequently asked questions and solutions for offline access
- **Real-time Streaming Responses**: Displays AI responses as they are generated for a more interactive experience
- **Conversation History**: Maintains context of previous interactions for more relevant answers
- **User Authentication**: Secure login system to personalize the experience
- **Offline Capability**: Access to common solutions even without internet connection
- **Multi-language Support**: Available in both English and Arabic

## 🔧 Technical Architecture

### Front-end
- **UI Framework**: Flutter for cross-platform compatibility
- **State Management**: Provider for efficient state management
- **UI Components**: Custom chat interface with streaming capability

### Back-end
- **AI Integration**: Google Generative AI (Gemini-2.0-flash model)
- **Local Storage**: SharedPreferences for storing chat history and cached responses
- **Environment Variables**: Secure storage of API keys using dotenv

### Data Management
- **Car Problems Database**: Repository of common car issues and solutions
- **Message Serialization**: Custom serialization for chat message objects
- **Duplicate Prevention**: Intelligent system to prevent repetitive questions and answers

## 🛠️ Technologies Used

- Flutter & Dart
- Google Generative AI
- SharedPreferences
- Firebase Authentication
- Firebase Storage
- Google Maps (for service centers)

## 📱 Installation

1. Ensure Flutter is installed and configured properly
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Create a `.env` file at the project root with your API keys:
   ```
   GEMINI_API_KEY=your_gemini_api_key
   ```
5. Run `flutter run` to start the application

## 🔍 How It Works

1. Users describe their car problem in the chat interface
2. The system first checks the local database for matching issues
3. If no match is found, the query is sent to the Gemini AI model
4. The AI generates a response that is streamed in real-time to the user
5. Solutions are cached for future reference

## 🔮 Future Enhancements

- Voice input for hands-free operation while working on vehicles
- Integration with OBD-II diagnostic tools for direct vehicle data
- Augmented reality guides for visual assistance during repairs
- Service center appointment scheduling
- Parts ordering integration

## 📝 Note for Developers

The project is built with a modular architecture to facilitate easy expansion of features. The AI component is designed to be replaceable or upgradable as newer language models become available.

## 📷 Screenshots

[Add screenshots of the application here]

## 📄 License

[Add license information here]

## 👥 Contributors

[Add contributors information here]

## 📂 Project Structure

The application follows a well-organized directory structure for maintainability and scalability:

### Core Files
- **main.dart**: Entry point of the application that initializes Firebase and sets up the app
- **splash_screen.dart**: Displays the initial loading screen with animations
- **firebase_options.dart**: Contains Firebase configuration for different platforms

### Key Directories
- **auth/**: Authentication-related screens and services for user login/registration
- **Chat/**: Contains the AI-powered chatbot implementation, including:
  - Chat bot screens
  - Gemini service integration
  - Message handling logic
  - Car problems database

- **constants/**: App-wide constants including:
  - Colors
  - Theme configurations
  - Text styles
  - API endpoints

- **models/**: Data models for the application:
  - ChatMessage
  - User
  - Vehicle
  - Maintenance records

- **payment/**: Payment processing functionality and screens

- **providers/**: State management using Provider pattern:
  - UserProvider
  - Authentication state
  - Settings preferences

- **screens/**: Main application screens:
  - Home
  - Profile
  - Vehicle management
  - Maintenance history

- **services/**: API and backend service integrations:
  - Firebase services
  - Analytics
  - External APIs

- **utils/**: Utility functions and helper classes:
  - Date formatters
  - String utilities
  - Validation helpers

- **widgets/**: Reusable UI components:
  - Chat bubbles
  - Custom buttons
  - Loading indicators
  - Cards and lists

## 🏗️ Architectural Design

The application implements a modified MVVM (Model-View-ViewModel) architecture with Provider for state management and dependency injection:

- **View Layer**: Flutter widgets that display UI elements and capture user input
- **ViewModel Layer**: Provider classes that manage business logic and state
- **Model Layer**: Data models and repositories for data access
- **Service Layer**: Handles external API communication and data processing

### Component Interaction Flow
```
UI Widget → Provider → Service/Repository → External API/Local Storage → Model → UI Widget
```

### State Management Strategy
The application uses a combination of:
- **Provider**: For app-wide state and dependency injection
- **StreamBuilder**: For reactive UI updates with streaming data sources
- **StatefulWidget**: For localized component-specific state

## 🔍 Technical Deep Dive

### Authentication System
- **Implementation**: Firebase Authentication with custom wrapper services
- **Features**: Email/password login, Google sign-in, password recovery
- **Security**: JWT token handling with secure storage and auto-refresh
- **State Persistence**: Maintains authentication state across app restarts

### AI Chat Implementation
- **Model Integration**: Uses Google Generative AI (Gemini) via official SDK
- **Prompt Engineering**: Custom prompt templates with context preservation for better responses
- **Response Streaming**: Real-time token-by-token display with cancellation support
- **Optimization**: Local caching of responses to reduce API calls
- **Fallback System**: Local database for offline response capability

### Data Flow Architecture
- **User Input**: Captured through UI, validated, and processed by view models
- **API Requests**: Managed through service classes with retry logic and error handling
- **Response Handling**: Parsed into model objects and distributed to UI via Providers
- **Persistence**: SharedPreferences for small data, local SQLite for larger datasets

### Performance Optimizations
- **Lazy Loading**: Images and heavy UI components loaded on-demand
- **Caching**: Multi-level caching strategy for network requests and AI responses
- **Widget Optimization**: Using const constructors and efficient rebuilds
- **Memory Management**: Proper disposal of streams and subscriptions

### Code Organization Principles
- **Feature-First**: Primary organization by feature rather than technical type
- **Dependency Inversion**: High-level modules don't depend on low-level modules
- **Single Responsibility**: Each class has a focused purpose
- **Separation of Concerns**: UI logic separated from business logic

## 📊 Database Schema

### ChatMessage
```dart
class ChatMessage {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final bool isUser;
  final String? senderName;
  
  // Methods for serialization/deserialization
}
```

### User
```dart
class User {
  final String? id;
  final String email;
  final String firstName;
  final String lastName;
  final String? photoURL;
  final List<Vehicle> vehicles;
  
  // User preferences and methods
}
```

### Vehicle
```dart
class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final List<MaintenanceRecord> maintenanceHistory;
  
  // Vehicle-specific methods
}
```

## 🧪 Testing Strategy

### Unit Tests
- Service classes
- Provider logic
- Data models
- Utility functions

### Widget Tests
- UI components
- Screen navigation
- Form validation

### Integration Tests
- End-to-end user flows
- API interaction
- Authentication processes

## 🛠️ Developer Tooling

### Environment Configuration
- Multiple environment support (dev, staging, production)
- Feature flags for phased rollouts
- Dynamic configuration updates

### Debugging Features
- Detailed logging system with severity levels
- Network request inspection
- AI response analysis tools
- Performance monitoring

### CI/CD Pipeline
- Automated testing on commits
- Build versioning
- Release management
