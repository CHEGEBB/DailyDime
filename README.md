# 💰 DailyDime - Smart AI-Powered Budgeting Assistant

> **Kenya's first AI-powered budgeting and savings assistant** designed for everyday Kenyans — from boda riders to university students and salaried individuals.

DailyDime is not your typical budgeting app. It's a **smart financial companion** that uses **Gemini 2.0 Flash AI** to analyze your daily income, balance, and spending habits to **suggest budgets**, **encourage savings**, and help you build lasting financial discipline. Whether you're a *boda rider*, *shopkeeper*, *university student*, or *freelancer*, DailyDime gives you full control over your money — one dime at a time.

---

## 🚀 Key Features

### 🧠 AI-Powered Budgeting (Powered by Gemini 2.0 Flash)
- Generates **personalized daily/weekly budgets** based on:
  - Income patterns from SMS analysis
  - Spending behavior tracking
  - Current M-Pesa balance
  - Financial goals and priorities
- Recommends **smart saving goals** with realistic timelines
- Offers **AI tips and nudges**: e.g. _"Skip snacks today and save KES 30 toward your earphones goal!"_
- **Intelligent spending alerts** before you overspend

### 💸 Comprehensive Financial Tracking
- **SMS-based transaction analysis** (M-Pesa, Airtel Money, T-Kash)
- Manual income/expense logging with voice input
- **Real-time balance monitoring** across multiple wallets
- Categorized expense tracking with smart categorization
- **Weekly/Monthly financial summaries** with AI insights

### 🐖 Smart Savings System
- Create **goal-based savings plans** (e.g. save KES 30/day for earphones)
- **AI-recommended savings targets** based on income patterns
- Visual progress bars and motivational reminders
- **Automated savings transfers** to M-Pesa savings accounts
- **Group savings support** for chamas and family goals

### 💳 M-Pesa Integration & SMS Analysis
- **Full M-Pesa integration** via Daraja API
- **SMS permission-based transaction reading**
- Auto-categorization of transactions
- Balance synchronization across accounts
- **Bill reminders** and recurring payment tracking

### 📱 Cross-Platform Experience
- **Flutter-powered** native Android app
- **Progressive Web App** for web access
- **Offline-first architecture** for reliable usage
- **Clean, intuitive UI** with Kenyan localization (Sheng/Swahili)

---

## 📁 Project Structure

```
lib/
├── main.dart                         # App starts here
├── config/                           # App configuration
│   ├── theme.dart                   # Colors, fonts, button styles
│   └── app_config.dart              # API keys and constants
├── models/                          # Data structures
│   ├── transaction.dart             # Transaction data structure
│   ├── budget.dart                  # Budget data structure
│   ├── savings_goal.dart            # Savings goal data structure
│   └── user.dart                    # User profile data structure
├── services/                        # Business logic and API calls
│   ├── database_service.dart        # Local storage (Hive)
│   ├── ai_service.dart              # Gemini AI integration
│   ├── sms_service.dart             # SMS reading for transactions
│   ├── mpesa_service.dart           # M-Pesa API integration
│   └── firebase_service.dart        # Firebase auth and cloud storage
├── providers/                       # State management
│   ├── auth_provider.dart           # User authentication state
│   ├── transaction_provider.dart    # Transaction management
│   ├── budget_provider.dart         # Budget management
│   └── savings_provider.dart        # Savings goals management
├── screens/                         # App screens
│   ├── splash_screen.dart           # Loading screen
│   ├── auth/                        # Authentication screens
│   │   ├── login_screen.dart        # Phone login
│   │   └── register_screen.dart     # User registration
│   ├── home_screen.dart             # Main dashboard
│   ├── transactions/                # Transaction screens
│   │   ├── transactions_screen.dart # List all transactions
│   │   ├── add_transaction_screen.dart # Add new transaction
│   │   └── sms_transactions_screen.dart # SMS-detected transactions
│   ├── budget/                      # Budget screens
│   │   ├── budget_screen.dart       # View current budget
│   │   └── create_budget_screen.dart # Create new budget
│   ├── savings/                     # Savings screens
│   │   ├── savings_screen.dart      # View all savings goals
│   │   └── create_goal_screen.dart  # Create new savings goal
│   ├── analytics_screen.dart        # Charts and insights
│   ├── ai_chat_screen.dart          # Chat with AI coach
│   └── profile_screen.dart          # User profile and settings
└── widgets/                         # Reusable UI components
    ├── common/                      # Common widgets
    │   ├── custom_button.dart       # Styled buttons
    │   ├── custom_text_field.dart   # Input fields
    │   └── loading_widget.dart      # Loading indicator
    ├── cards/                       # Card widgets
    │   ├── balance_card.dart        # Balance display
    │   ├── transaction_card.dart    # Transaction item
    │   ├── budget_card.dart         # Budget progress
    │   └── savings_card.dart        # Savings goal card
    └── charts/                      # Chart widgets
        ├── spending_chart.dart      # Spending breakdown
        └── progress_chart.dart      # Progress visualization
```

## 📝 **What Each File Does (Clear Explanations)**

### **CORE FILES (Start Here)**
- **`main.dart`** - App entry point, starts everything
- **`config/theme.dart`** - App colors, fonts, styling
- **`config/app_config.dart`** - API keys, constants

### **DATA LAYER**
- **`models/`** - Data structures (like TypeScript interfaces)
  - `transaction.dart` - What a transaction looks like
  - `budget.dart` - Budget data structure
  - `savings_goal.dart` - Savings goal structure
  - `user.dart` - User profile data

### **BUSINESS LOGIC**
- **`services/`** - Handle external APIs and storage
  - `database_service.dart` - Save/load data locally
  - `ai_service.dart` - Talk to Gemini AI
  - `sms_service.dart` - Read SMS transactions
  - `mpesa_service.dart` - M-Pesa integration
  - `firebase_service.dart` - Cloud storage & auth

- **`providers/`** - State management (like Redux)
  - `auth_provider.dart` - Login/logout state
  - `transaction_provider.dart` - Transaction operations
  - `budget_provider.dart` - Budget management
  - `savings_provider.dart` - Savings management

### **UI LAYER**
- **`screens/`** - Full-screen components
  - Core screens: `home_screen.dart`, `profile_screen.dart`
  - Auth screens: `login_screen.dart`, `register_screen.dart`
  - Feature screens: transactions, budget, savings
  - Advanced: `analytics_screen.dart`, `ai_chat_screen.dart`

- **`widgets/`** - Reusable UI components
  - `common/` - Basic widgets used everywhere
  - `cards/` - Card-style display components
  - `charts/` - Data visualization components

## 🎯 **Development Phases**

### **Phase 1: Foundation (Week 1-2)**
1. `main.dart` + `config/theme.dart` - Basic app setup
2. `models/transaction.dart` - Transaction structure
3. `services/database_service.dart` - Local storage
4. `screens/home_screen.dart` - Basic home screen

### **Phase 2: Core Features (Week 3-4)**
5. `providers/transaction_provider.dart` - Transaction state
6. `screens/transactions/add_transaction_screen.dart` - Add transactions
7. `screens/transactions/transactions_screen.dart` - View transactions
8. `widgets/cards/transaction_card.dart` - Display transactions

### **Phase 3: Advanced Features (Week 5-6)**
9. `services/ai_service.dart` - AI integration
10. `screens/budget/budget_screen.dart` - Budget management
11. `screens/savings/savings_screen.dart` - Savings goals
12. `services/sms_service.dart` - SMS reading

### **Phase 4: Polish (Week 7-8)**
13. `screens/auth/` - User authentication
14. `screens/analytics_screen.dart` - Charts and insights
15. `services/mpesa_service.dart` - M-Pesa integration
16. `screens/ai_chat_screen.dart` - AI chat interface

## 💡 **Why This Structure Works:**

✅ **Not overwhelming** - 25 files total (manageable)
✅ **Not too simple** - Has room for all features
✅ **Logical organization** - Similar to React Native
✅ **Clear progression** - Build step by step
✅ **Professional structure** - Can show to employers
✅ **Beginner-friendly** - Each file has one clear purpose

## 🚀 **Total File Count:**
- **Core**: 3 files
- **Models**: 4 files  
- **Services**: 5 files
- **Providers**: 4 files
- **Screens**: 14 files
- **Widgets**: 9 files
- **TOTAL**: 25 files (Perfect for learning!)

---

## 🛠 Technology Stack

| Technology | Purpose | Implementation |
|------------|---------|----------------|
| **Flutter (Dart)** | Cross-platform development | Native Android + Web |
| **Gemini 2.0 Flash** | AI budgeting and insights | Google AI SDK |
| **Firebase** | Backend services | Auth, Firestore, Analytics, Functions |
| **Hive** | Local storage | Offline-first data persistence |
| **M-Pesa Daraja API** | Mobile money integration | Transaction processing |
| **SMS Reading** | Transaction analysis | Permission-based SMS parsing |
| **Provider** | State management | Reactive state updates |
| **Shared Preferences** | Simple data storage | User preferences |
| **Local Notifications** | Reminders and alerts | Background notifications |

---

## 🔧 Backend Architecture

### Firebase Services
- **Authentication**: Phone number verification, user management
- **Firestore**: Cloud database for user data, transactions, budgets
- **Cloud Functions**: AI processing, SMS analysis, M-Pesa webhooks
- **Firebase Analytics**: User behavior tracking
- **Remote Config**: Feature flags and dynamic configuration

### Local Storage Strategy
- **Hive Database**: Primary offline storage for transactions, budgets, goals
- **Shared Preferences**: User settings and preferences
- **Encrypted Storage**: Sensitive data like M-Pesa credentials

---

## 🤖 AI Integration Features

### Gemini 2.0 Flash Capabilities
- **Budget Generation**: AI creates personalized budgets based on income patterns
- **Spending Analysis**: Intelligent categorization and spending insights
- **Savings Recommendations**: AI suggests optimal savings amounts and strategies
- **Financial Coaching**: Conversational AI for financial advice
- **Expense Prediction**: Predict future expenses based on historical data
- **Goal Achievement**: AI helps users stay on track with financial goals

### AI-Powered Features
- Smart expense categorization
- Personalized budget suggestions
- Spending behavior analysis
- Financial goal recommendations
- Motivational nudges and reminders
- Risk assessment for overspending

---

## 📱 Core Features Implementation

### SMS Transaction Analysis
- **Permission-based SMS reading**: Request user permission to read SMS
- **Bank SMS parsing**: Extract transaction details from M-Pesa, Airtel Money, T-Kash
- **Automatic categorization**: AI categorizes transactions automatically
- **Balance extraction**: Get current balance from SMS notifications
- **Transaction verification**: Cross-reference with manual entries

### M-Pesa Integration
- **Daraja API**: Full M-Pesa API integration for payments
- **Balance inquiry**: Check M-Pesa balance in real-time
- **Transaction history**: Fetch M-Pesa transaction history
- **Automated savings**: Transfer money to savings accounts
- **Bill payments**: Pay bills directly through the app

### Offline-First Architecture
- **Local data storage**: All data stored locally first
- **Sync when online**: Automatic sync with cloud when connected
- **Offline functionality**: Full app functionality without internet
- **Conflict resolution**: Handle data conflicts during sync

---

## 🎯 User Experience Features

### Intelligent Notifications
- **Spending alerts**: AI warns when approaching budget limits
- **Savings reminders**: Gentle nudges to save money
- **Bill reminders**: Never miss a payment deadline
- **Goal progress**: Celebrate milestones and achievements
- **AI insights**: Daily financial tips and recommendations

### Gamification Elements
- **Savings streaks**: Track consecutive days of saving
- **Achievement badges**: Reward financial milestones
- **Progress visualization**: Beautiful charts and progress bars
- **Challenges**: Weekly/monthly savings challenges
- **Leaderboards**: Compare progress with friends (optional)

---

## 🔐 Security & Privacy

### Data Protection
- **End-to-end encryption**: All sensitive data encrypted
- **Local storage**: Primary data storage on device
- **Minimal cloud sync**: Only necessary data synced to cloud
- **User control**: Users control what data to share
- **SMS privacy**: SMS data processed locally, not stored in cloud

### Security Features
- **App lock**: PIN/biometric authentication
- **Session management**: Secure session handling
- **API security**: Encrypted API communication
- **Data validation**: Input validation and sanitization
- **Audit logging**: Track all financial operations

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Firebase account
- M-Pesa Daraja API credentials
- Google AI API key (Gemini 2.0 Flash)

### Installation
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Configure Firebase (`google-services.json`)
4. Add API keys to `lib/config/app_config.dart`
5. Run the app: `flutter run`

### Environment Setup
```dart
// lib/config/app_config.dart
class AppConfig {
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String mpesaConsumerKey = 'YOUR_MPESA_CONSUMER_KEY';
  static const String mpesaConsumerSecret = 'YOUR_MPESA_CONSUMER_SECRET';
  static const String mpesaPasskey = 'YOUR_MPESA_PASSKEY';
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';
}
```

---

## 📊 API Integration

### M-Pesa Daraja API
- **Authentication**: OAuth 2.0 token generation
- **Balance inquiry**: Real-time balance checks
- **Transaction processing**: Payment processing
- **Callback handling**: Webhook processing
- **Error handling**: Comprehensive error management

### Gemini AI Integration
- **Budget generation**: Send financial data, receive personalized budgets
- **Spending analysis**: Analyze spending patterns
- **Savings recommendations**: AI-powered savings advice
- **Financial coaching**: Conversational financial assistance
- **Expense prediction**: Predict future spending patterns

### SMS Integration
- **Permission handling**: Request SMS permissions
- **SMS parsing**: Extract transaction data from SMS
- **Bank format support**: Support multiple bank SMS formats
- **Real-time processing**: Process SMS as they arrive
- **Data validation**: Validate extracted transaction data

---

## 🧪 Testing Strategy

### Unit Tests
- Model validation and serialization
- Utility functions and extensions
- Business logic and calculations
- API response parsing

### Integration Tests
- Firebase integration
- M-Pesa API integration
- SMS parsing functionality
- AI service integration

### Widget Tests
- UI component testing
- User interaction testing
- Navigation testing
- State management testing

---

## 🎨 UI/UX Design Principles

### Design Language
- **Material Design 3**: Modern Material Design components
- **Kenyan Context**: Colors and imagery relevant to Kenya
- **Accessibility**: WCAG compliant design
- **Responsive**: Works on all screen sizes
- **Intuitive**: Simple and easy to understand

### Color Scheme
- **Primary**: Kenya flag colors (red, green, black)
- **Secondary**: Money-related colors (gold, emerald)
- **Neutral**: Modern grays and whites
- **Success**: Green for positive financial actions
- **Warning**: Orange for budget alerts

---

## 🌟 Future Enhancements

### Phase 2 Features
- **Voice commands**: Voice-controlled expense logging
- **Receipt scanning**: OCR for receipt digitization
- **Investment tracking**: Track simple investments
- **Loan management**: Track loans and repayments
- **Tax calculations**: Simple tax computation

### Phase 3 Features
- **Multi-currency support**: Support for USD, EUR, etc.
- **Advanced AI**: More sophisticated financial advice
- **Social features**: Share goals with friends
- **Merchant integration**: Direct payments to merchants
- **Advanced analytics**: Detailed financial reports

---

## 📈 Success Metrics

### User Engagement
- Daily/Monthly Active Users
- Session duration and frequency
- Feature adoption rates
- User retention rates

### Financial Impact
- Average savings increase per user
- Budget adherence rates
- Financial goal achievement rates
- Spending reduction percentages

### Technical Metrics
- App performance and crash rates
- API response times
- SMS parsing accuracy
- AI recommendation effectiveness

---

## 🤝 Contributing

We welcome contributions from:
- Flutter developers
- AI/ML engineers
- UI/UX designers
- Financial literacy experts
- Beta testers (especially in Kenya)

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Submit a pull request

---

## 📞 Support & Contact

**Developer**: Brian Chege  
📧 Email: chegephil24@gmail.com  
🌐 Website: [brianchege.vercel.app](https://brianchege.vercel.app)  
💻 GitHub: [CHEGEBB](https://github.com/CHEGEBB)

### Beta Testing
Interested in testing DailyDime? We're looking for beta testers, especially:
- University students
- Boda boda riders
- Small business owners
- Anyone interested in better financial management

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 💡 Vision Statement

> "DailyDime isn't just about tracking money—it's about transforming how everyday Kenyans think about, save, and grow their money. We believe that with the right tools and AI-powered guidance, anyone can achieve financial freedom, one dime at a time."

---

## 🎯 Project Goals

### Short-term (3-6 months)
- ✅ Complete MVP with core features
- ✅ Beta testing with 100+ users
- ✅ M-Pesa integration working
- ✅ AI budgeting fully functional
- ✅ Play Store release

### Medium-term (6-12 months)
- 🎯 10,000+ active users
- 🎯 Advanced AI features
- 🎯 Group savings functionality
- 🎯 Partnership with local SACCOs
- 🎯 Financial literacy integration

### Long-term (1-2 years)
- 🎯 100,000+ users across Kenya
- 🎯 Expansion to other African countries
- 🎯 Full-featured financial platform
- 🎯 Integration with major banks
- 🎯 AI-powered financial coaching

---

## 🔥 Why DailyDime Will Succeed

1. **Real Problem**: Addresses actual financial challenges faced by Kenyans
2. **AI-Powered**: Uses cutting-edge AI for personalized financial advice
3. **Local Context**: Built specifically for Kenyan financial ecosystem
4. **Offline-First**: Works without constant internet connectivity
5. **User-Centric**: Simple, intuitive design for all education levels
6. **Scalable**: Architecture designed for growth and expansion

---

**DailyDime - Every Dime Counts. Every Dream Matters.**

> Transform your financial future with Kenya's smartest budgeting assistant.