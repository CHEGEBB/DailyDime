import 'package:appwrite/appwrite.dart';
import '../config/app_config.dart';

class AppwriteService {
  static final Client _client = Client();
  static late Account _account;
  static late Databases _databases;
  static late Storage _storage;
  static late Functions _functions;
  static late Realtime _realtime;

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;

    _client
        .setEndpoint(AppConfig.appwriteEndpoint)
        .setProject(AppConfig.appwriteProjectId);
    
    _account = Account(_client);
    _databases = Databases(_client);
    _storage = Storage(_client);
    _functions = Functions(_client);
    _realtime = Realtime(_client);

    _initialized = true;
    print('✅ Appwrite Service Initialized');
  }

  // Getters
  static Account get account => _account;
  static Databases get databases => _databases;
  static Storage get storage => _storage;
  static Functions get functions => _functions;
  static Realtime get realtime => _realtime;
  static Client get client => _client;

  // Helper method to check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      await _account.get();
      return true;
    } catch (e) {
      return false;
    }
  }
}