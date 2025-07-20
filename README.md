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

## 🛠 Technology Stack

| Technology | Purpose | Implementation |
|------------|---------|----------------|
| **Flutter (Dart)** | Cross-platform development | Native Android + Web |
| **Appwrite** | Backend-as-a-Service | Database, Auth, Storage, Functions |
| **Gemini 2.0 Flash** | AI budgeting and insights | Google AI SDK |
| **Hive** | Local storage | Offline-first data persistence |
| **M-Pesa Daraja API** | Mobile money integration | Transaction processing |
| **SMS Reading** | Transaction analysis | Permission-based SMS parsing |
| **Provider** | State management | Reactive state updates |
| **Shared Preferences** | Simple data storage | User preferences |
| **Local Notifications** | Reminders and alerts | Background notifications |

---

## 🔧 Backend Architecture with Appwrite

### Why Appwrite for DailyDime?
- ⚡ **Rapid Development**: Backend ready in hours, not weeks
- 📱 **Phone Authentication**: Built-in SMS verification for Kenyan numbers
- 🔄 **Real-time Database**: Perfect for financial data updates
- 🔐 **Built-in Security**: Role-based permissions and encryption
- 📁 **File Storage**: For receipts and document uploads
- ⚙️ **Cloud Functions**: Custom logic for AI and M-Pesa integration
- 💰 **Cost-effective**: Free tier covers development and early users

### Appwrite Services Used

#### 🔐 Authentication
- **Phone Authentication**: SMS-based verification using Kenyan phone numbers
- **User Management**: Profile creation and management
- **Session Management**: Secure session handling
- **Guest Sessions**: Allow users to try app before registration

#### 🗄️ Database (Collections)
- **users**: User profiles and preferences
- **transactions**: All financial transactions
- **budgets**: User budgets and AI recommendations
- **savings_goals**: Savings targets and progress
- **categories**: Expense categorization
- **notifications**: User notifications and reminders

#### 📁 Storage
- **receipts**: Uploaded receipt images
- **user_documents**: ID verification documents
- **backups**: Data backup files
- **ai_insights**: Generated AI reports and insights

#### ⚙️ Functions (Server-side Logic)
- **ai-budget-generator**: Gemini AI integration for budget creation
- **mpesa-integration**: M-Pesa Daraja API calls
- **sms-analyzer**: SMS transaction parsing
- **notification-scheduler**: Automated reminders
- **financial-insights**: AI-powered spending analysis

---

## 📁 Project Structure

```
lib/
├── main.dart                         # App starts here
├── config/                           # App configuration
│   ├── theme.dart                   # Colors, fonts, button styles
│   ├── app_config.dart              # API keys and constants
│   └── appwrite_config.dart         # Appwrite configuration
├── models/                          # Data structures
│   ├── transaction.dart             # Transaction data structure
│   ├── budget.dart                  # Budget data structure
│   ├── savings_goal.dart            # Savings goal data structure
│   ├── user.dart                    # User profile data structure
│   └── appwrite_models.dart         # Appwrite-specific models
├── services/                        # Business logic and API calls
│   ├── database_service.dart        # Local storage (Hive)
│   ├── appwrite_service.dart        # Appwrite backend service
│   ├── auth_service.dart            # Authentication service
│   ├── ai_service.dart              # Gemini AI integration
│   ├── sms_service.dart             # SMS reading for transactions
│   ├── mpesa_service.dart           # M-Pesa API integration
│   └── sync_service.dart            # Online/offline sync
├── providers/                       # State management
│   ├── auth_provider.dart           # User authentication state
│   ├── transaction_provider.dart    # Transaction management
│   ├── budget_provider.dart         # Budget management
│   ├── savings_provider.dart        # Savings goals management
│   └── sync_provider.dart           # Sync status management
├── screens/                         # App screens
│   ├── splash_screen.dart           # Loading screen
│   ├── auth/                        # Authentication screens
│   │   ├── login_screen.dart        # Phone login
│   │   ├── verify_otp_screen.dart   # OTP verification
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

---

## 🎯 **Development Phases with Appwrite**

### **Phase 1: Appwrite Setup & Authentication (Week 1)**
1. **Appwrite Setup**: Configure Appwrite instance
2. **Authentication**: Phone number login/registration
3. **Database Schema**: Create collections for users, transactions, budgets
4. **Basic Service**: `appwrite_service.dart` for backend calls

### **Phase 2: Core Features (Week 2)**
5. **Transaction Management**: CRUD operations with Appwrite
6. **Local Storage**: Offline-first with Hive + Appwrite sync
7. **Real-time Updates**: Live transaction updates
8. **Basic UI Integration**: Connect UI to Appwrite backend

### **Phase 3: AI & Advanced Features (Week 3)**
9. **Appwrite Functions**: Deploy AI and M-Pesa functions
10. **AI Integration**: Budget generation via Appwrite functions
11. **SMS Processing**: Transaction extraction and categorization
12. **M-Pesa Integration**: Payment processing through Appwrite

### **Phase 4: Polish & Launch (Week 4)**
13. **Analytics & Charts**: Financial insights dashboard
14. **Notifications**: Smart alerts and reminders
15. **Testing & Debug**: Comprehensive testing
16. **Play Store Release**: Production deployment

---

## 🚀 Quick Start with Appwrite

### 1. Appwrite Setup
```bash
# Install Appwrite CLI
npm install -g appwrite-cli

# Login to Appwrite
appwrite login

# Initialize project
appwrite init project
```

### 2. Flutter Dependencies
```yaml
# pubspec.yaml
dependencies:
  appwrite: ^11.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  provider: ^6.1.1
  http: ^0.13.6
  sms_maintained: ^1.0.0
  permission_handler: ^11.0.1
```

### 3. Appwrite Configuration
```dart
// lib/config/appwrite_config.dart
class AppwriteConfig {
  static const String projectId = 'YOUR_PROJECT_ID';
  static const String endpoint = 'YOUR_APPWRITE_ENDPOINT';
  static const String databaseId = 'dailydime_db';
  
  // Collection IDs
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String budgetsCollection = 'budgets';
  static const String savingsGoalsCollection = 'savings_goals';
  static const String categoriesCollection = 'categories';
  
  // Storage Bucket IDs
  static const String receiptsBucket = 'receipts';
  static const String documentsBucket = 'documents';
  
  // Function IDs
  static const String aiBudgetFunction = 'ai-budget-generator';
  static const String mpesaFunction = 'mpesa-integration';
  static const String smsAnalyzerFunction = 'sms-analyzer';
}
```

### 4. Appwrite Service Setup
```dart
// lib/services/appwrite_service.dart
import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';

class AppwriteService {
  static final Client _client = Client();
  static late Account _account;
  static late Databases _databases;
  static late Storage _storage;
  static late Functions _functions;

  static void initialize() {
    _client
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    
    _account = Account(_client);
    _databases = Databases(_client);
    _storage = Storage(_client);
    _functions = Functions(_client);
  }

  // Getters
  static Account get account => _account;
  static Databases get databases => _databases;
  static Storage get storage => _storage;
  static Functions get functions => _functions;
}
```

---

## 📊 Appwrite Database Schema

### Collections Structure

#### 👤 Users Collection
```json
{
  "name": "users",
  "attributes": [
    {"key": "phone", "type": "string", "required": true},
    {"key": "full_name", "type": "string", "required": true},
    {"key": "occupation", "type": "string", "required": false},
    {"key": "monthly_income", "type": "integer", "required": false},
    {"key": "savings_target", "type": "integer", "required": false},
    {"key": "preferred_language", "type": "string", "default": "en"},
    {"key": "notification_preferences", "type": "string", "array": true},
    {"key": "created_at", "type": "datetime", "required": true},
    {"key": "updated_at", "type": "datetime", "required": true}
  ]
}
```

#### 💰 Transactions Collection
```json
{
  "name": "transactions",
  "attributes": [
    {"key": "user_id", "type": "string", "required": true},
    {"key": "amount", "type": "integer", "required": true},
    {"key": "type", "type": "string", "required": true}, // income/expense
    {"key": "category", "type": "string", "required": true},
    {"key": "description", "type": "string", "required": false},
    {"key": "source", "type": "string", "required": false}, // manual/sms/mpesa
    {"key": "sms_id", "type": "string", "required": false},
    {"key": "mpesa_code", "type": "string", "required": false},
    {"key": "transaction_date", "type": "datetime", "required": true},
    {"key": "created_at", "type": "datetime", "required": true}
  ]
}
```

#### 📊 Budgets Collection
```json
{
  "name": "budgets",
  "attributes": [
    {"key": "user_id", "type": "string", "required": true},
    {"key": "period_type", "type": "string", "required": true}, // daily/weekly/monthly
    {"key": "total_budget", "type": "integer", "required": true},
    {"key": "categories", "type": "string", "array": true},
    {"key": "ai_generated", "type": "boolean", "default": false},
    {"key": "start_date", "type": "datetime", "required": true},
    {"key": "end_date", "type": "datetime", "required": true},
    {"key": "status", "type": "string", "default": "active"}, // active/completed/paused
    {"key": "created_at", "type": "datetime", "required": true}
  ]
}
```

#### 🎯 Savings Goals Collection
```json
{
  "name": "savings_goals",
  "attributes": [
    {"key": "user_id", "type": "string", "required": true},
    {"key": "title", "type": "string", "required": true},
    {"key": "description", "type": "string", "required": false},
    {"key": "target_amount", "type": "integer", "required": true},
    {"key": "current_amount", "type": "integer", "default": 0},
    {"key": "daily_target", "type": "integer", "required": false},
    {"key": "target_date", "type": "datetime", "required": false},
    {"key": "priority", "type": "string", "default": "medium"}, // low/medium/high
    {"key": "status", "type": "string", "default": "active"}, // active/completed/paused
    {"key": "created_at", "type": "datetime", "required": true}
  ]
}
```

---

## ⚙️ Appwrite Functions

### 1. AI Budget Generator Function
```javascript
// functions/ai-budget-generator/src/index.js
const { Client, Databases } = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_FUNCTION_API_KEY);

  const databases = new Databases(client);

  try {
    const { userId, income, expenses, goals } = JSON.parse(req.body);
    
    // Call Gemini AI API
    const aiResponse = await generateBudgetWithAI({
      income,
      expenses, 
      goals,
      userContext: await getUserContext(userId)
    });

    // Save AI-generated budget to database
    const budget = await databases.createDocument(
      'dailydime_db',
      'budgets',
      ID.unique(),
      {
        user_id: userId,
        ...aiResponse,
        ai_generated: true
      }
    );

    return res.json({ success: true, budget });
  } catch (err) {
    error('Budget generation failed: ' + err.message);
    return res.json({ success: false, error: err.message }, 500);
  }
};
```

### 2. M-Pesa Integration Function
```javascript
// functions/mpesa-integration/src/index.js
module.exports = async ({ req, res, log, error }) => {
  try {
    const { action, amount, phoneNumber, userId } = JSON.parse(req.body);
    
    switch (action) {
      case 'balance_inquiry':
        return await checkMpesaBalance(phoneNumber);
      case 'send_money':
        return await sendMoney(amount, phoneNumber);
      case 'request_money':
        return await requestMoney(amount, phoneNumber);
      case 'pay_bill':
        return await payBill(amount, phoneNumber, billNumber);
      default:
        throw new Error('Invalid M-Pesa action');
    }
  } catch (err) {
    error('M-Pesa integration failed: ' + err.message);
    return res.json({ success: false, error: err.message }, 500);
  }
};
```

---

## 🔐 Security & Privacy with Appwrite

### Authentication Security
- **SMS-based Authentication**: Secure phone number verification
- **Session Management**: Automatic session handling
- **Role-based Access**: Users can only access their own data
- **Rate Limiting**: Built-in API rate limiting

### Data Protection
- **Encryption**: All data encrypted at rest and in transit
- **GDPR Compliant**: Built-in privacy controls
- **Local Storage**: Primary data stored locally (Hive)
- **Selective Sync**: Only necessary data synced to cloud

### Permissions Structure
```json
{
  "users": {
    "read": ["user:userId"],
    "write": ["user:userId"]
  },
  "transactions": {
    "read": ["user:userId"],
    "write": ["user:userId"],
    "create": ["user:userId"]
  },
  "budgets": {
    "read": ["user:userId"],
    "write": ["user:userId"]
  }
}
```

---

## 🚀 Deployment & Environment Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Appwrite Cloud account or self-hosted instance
- M-Pesa Daraja API credentials
- Google AI API key (Gemini 2.0 Flash)

### Environment Configuration
```dart
// lib/config/app_config.dart
class AppConfig {
  // Appwrite Configuration
  static const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
  static const String appwriteProjectId = 'YOUR_APPWRITE_PROJECT_ID';
  
  // AI Configuration
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  
  // M-Pesa Configuration
  static const String mpesaConsumerKey = 'YOUR_MPESA_CONSUMER_KEY';
  static const String mpesaConsumerSecret = 'YOUR_MPESA_CONSUMER_SECRET';
  static const String mpesaPasskey = 'YOUR_MPESA_PASSKEY';
  static const String mpesaShortcode = 'YOUR_MPESA_SHORTCODE';
  
  // Environment
  static const bool isProduction = bool.fromEnvironment('PRODUCTION');
}
```

### Installation Steps
1. **Clone & Setup**
   ```bash
   git clone https://github.com/yourusername/dailydime.git
   cd dailydime
   flutter pub get
   ```

2. **Appwrite Setup**
   ```bash
   # Install Appwrite CLI
   npm install -g appwrite-cli
   
   # Initialize Appwrite project
   appwrite init project
   appwrite deploy collection
   appwrite deploy function
   ```

3. **Configure Environment**
   ```bash
   # Copy environment template
   cp lib/config/app_config.dart.example lib/config/app_config.dart
   
   # Add your API keys and configuration
   # Edit app_config.dart with your credentials
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

---

## 📱 Real-time Features with Appwrite

### Live Transaction Updates
```dart
// Real-time subscription to user transactions
AppwriteService.databases.listDocuments(
  databaseId: AppwriteConfig.databaseId,
  collectionId: AppwriteConfig.transactionsCollection,
  queries: [
    Query.equal('user_id', currentUser.id),
    Query.orderDesc('transaction_date'),
  ],
).then((response) {
  // Handle initial transactions
}).catchError((error) {
  // Handle error
});

// Subscribe to real-time updates
final subscription = AppwriteService.client.subscribe([
  'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.transactionsCollection}.documents'
]);

subscription.stream.listen((response) {
  // Handle real-time transaction updates
  if (response.events.contains('databases.*.collections.*.documents.*.create')) {
    // New transaction created
    handleNewTransaction(response.payload);
  }
});
```

---

## 🎯 Project Goals & Timeline

### ✅ **Phase 1: Foundation (Week 1)**
- [x] Appwrite project setup and configuration
- [x] Database collections and permissions
- [x] Flutter project structure with Appwrite integration
- [x] Basic authentication (phone number + OTP)
- [x] User profile management

### 🎯 **Phase 2: Core Features (Week 2)**
- [ ] Transaction CRUD with real-time updates
- [ ] Offline-first architecture with Hive + Appwrite sync
- [ ] SMS transaction parsing and categorization  
- [ ] Basic budget creation and management
- [ ] Savings goals tracking

### 🚀 **Phase 3: Advanced Features (Week 3)**
- [ ] Appwrite Functions for AI integration
- [ ] Gemini AI budget generation
- [ ] M-Pesa integration via Appwrite Functions
- [ ] Smart notifications and reminders
- [ ] Analytics dashboard with charts

### 🎉 **Phase 4: Launch Ready (Week 4)**
- [ ] Comprehensive testing and bug fixes
- [ ] Performance optimization
- [ ] UI/UX polishing
- [ ] Play Store preparation and release
- [ ] User onboarding and tutorials

---

## 🎉 Why This Appwrite Approach Wins

### ⚡ **Speed Benefits**
- **Backend ready in 1 day** vs 1-2 weeks with Firebase/custom
- **Phone auth works out-of-the-box** for Kenyan numbers
- **Real-time updates** without complex WebSocket setup
- **File uploads** ready for receipts and documents

### 💰 **Cost Benefits**
- **Free tier** covers development and early users (75,000 MAUs)
- **Predictable pricing** as you scale
- **No surprise bills** like Firebase can have
- **Self-hosted option** for full control

### 🛠 **Developer Experience**
- **Less configuration** than Firebase
- **Built-in security** with role-based permissions
- **Easy function deployment** for custom logic
- **Great Flutter integration** with official SDK

### 📈 **Scalability**
- **Horizontal scaling** built-in
- **Global CDN** for fast performance in Kenya
- **Database optimization** handles financial data well
- **Migration path** to self-hosted if needed

---

**Ready to build your financial future? Let's make DailyDime happen! 🚀**

> **DailyDime + Appwrite = Fastest path from idea to launched app**

**Every Dime Counts. Every Dream Matters. Every Day Counts.**