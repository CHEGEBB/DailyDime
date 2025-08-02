import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import '../config/app_config.dart';
import 'package:dailydime/models/crypto_models.dart';
import 'package:dailydime/utils/crypto_repository.dart';
import './crypto_ai_service.dart';

/// Main service class for cryptocurrency integration
class CryptoService {
  // Appwrite client dependencies
  final Client _client;
  final Databases _databases;
  final Account _account;
  
  // Repository and services
  final CryptoRepository _repository;
  late final CryptoAiService _aiService;
  
  // API endpoints
  final String _moralisApiKey;
  final String _moralisBaseUrl;
  
  // User info
  final String _userId;
  
  // Stream controllers for real-time updates
  final StreamController<Portfolio> _portfolioStreamController = StreamController<Portfolio>.broadcast();
  final StreamController<List<CryptoTransaction>> _transactionsStreamController = StreamController<List<CryptoTransaction>>.broadcast();
  final StreamController<Map<String, TokenPrice>> _pricesStreamController = StreamController<Map<String, TokenPrice>>.broadcast();
  final StreamController<List<Insight>> _insightsStreamController = StreamController<List<Insight>>.broadcast();
  
  // Cached data
  Map<String, TokenPrice> _cachedPrices = {};
  DateTime _lastPriceUpdate = DateTime(1970);
  
  // UUID generator
  final Uuid _uuid = const Uuid();
  
  // Background timer for data refresh
  Timer? _priceRefreshTimer;
  Timer? _portfolioRefreshTimer;
  
  CryptoService({
    required Client client,
    required Databases databases,
    required Account account,
    required String userId,
    required String moralisApiKey,
    required String moralisBaseUrl,
    required String cryptoWalletsCollection,
    required String cryptoTransactionsCollection,
    required String cryptoPricesCollection,
    required String cryptoPortfolioCollection,
    required String cryptoInsightsCollection,
    required String cryptoDefiPositionsCollection,
    required String cryptoNftAssetsCollection,
    required String geminiApiKey,
    required String geminiModel,
  }) : 
    _client = client,
    _databases = databases,
    _account = account,
    _userId = userId,
    _moralisApiKey = moralisApiKey,
    _moralisBaseUrl = moralisBaseUrl,
    _repository = CryptoRepository(
      databases: databases,
      userId: userId,
      cryptoWalletsCollection: cryptoWalletsCollection,
      cryptoTransactionsCollection: cryptoTransactionsCollection,
      cryptoPricesCollection: cryptoPricesCollection,
      cryptoPortfolioCollection: cryptoPortfolioCollection,
      cryptoInsightsCollection: cryptoInsightsCollection,
      cryptoDefiPositionsCollection: cryptoDefiPositionsCollection,
      cryptoNftAssetsCollection: cryptoNftAssetsCollection,
    ) {
      // Initialize AI service after constructor body
      _aiService = CryptoAiService(
        repository: _repository,
        cryptoService: this,
        apiKey: geminiApiKey,
        model: geminiModel,
      );
  }
  
  /// Initialize the service
  Future<void> init() async {
    // Initialize the repository
    await _repository.init();
    
    // Start background refresh timers
    _startPriceRefreshTimer();
    _startPortfolioRefreshTimer();
    
    // Initial data loading
    await _loadInitialData();
  }
  
  /// Dispose resources
  void dispose() {
    _portfolioStreamController.close();
    _transactionsStreamController.close();
    _pricesStreamController.close();
    _insightsStreamController.close();
    
    _priceRefreshTimer?.cancel();
    _portfolioRefreshTimer?.cancel();
  }
  
  // ==========================================================================
  // STREAMS
  // ==========================================================================
  
  /// Stream of portfolio updates
  Stream<Portfolio> get portfolioStream => _portfolioStreamController.stream;
  
  /// Stream of transaction updates
  Stream<List<CryptoTransaction>> get transactionsStream => _transactionsStreamController.stream;
  
  /// Stream of price updates
  Stream<Map<String, TokenPrice>> get pricesStream => _pricesStreamController.stream;
  
  /// Stream of insights
  Stream<List<Insight>> get insightsStream => _insightsStreamController.stream;
  
  // ==========================================================================
  // WALLET MANAGEMENT
  // ==========================================================================
  
  /// Get the user's portfolio
  Future<Portfolio> getPortfolio() async {
    try {
      final portfolio = await _repository.getPortfolio();
      
      if (portfolio != null) {
        return portfolio;
      }
      
      // If no portfolio exists, create an empty one
      final wallets = await _repository.getWallets();
      final emptyPortfolio = Portfolio(
        wallets: wallets,
        totalValue: 0.0,
        assetAllocation: {},
        percentChange24h: 0.0,
        lastUpdated: DateTime.now(),
      );
      
      await _repository.savePortfolio(emptyPortfolio);
      return emptyPortfolio;
    } catch (e) {
      // Return an empty portfolio on error
      return Portfolio(
        wallets: [],
        totalValue: 0.0,
        assetAllocation: {},
        percentChange24h: 0.0,
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Get the total net worth (crypto + traditional assets)
  Future<double> getTotalNetWorth() async {
    try {
      // Get crypto portfolio value
      final portfolio = await getPortfolio();
      final cryptoValue = portfolio.totalValue;
      
      // TODO: Add integration with traditional assets from budget app
      // This is a placeholder - in a real implementation, you would
      // fetch the user's traditional assets from the budget app
      const traditionalValue = 0.0;
      
      return cryptoValue + traditionalValue;
    } catch (e) {
      throw Exception('Failed to get total net worth: ${e.toString()}');
    }
  }
  
  /// Get asset allocation as a percentage map
  Future<Map<String, double>> getAssetAllocation() async {
    try {
      final portfolio = await getPortfolio();
      return portfolio.assetAllocation;
    } catch (e) {
      throw Exception('Failed to get asset allocation: ${e.toString()}');
    }
  }
  
  /// Add a new wallet
  Future<CryptoWallet> addWallet({
    required String address,
    required String network,
    String? name,
  }) async {
    try {
      // Validate address format
      if (network == 'ethereum' || AppConfig.supportedNetworks.keys.contains(network)) {
        if (!AppConfig.isValidEthereumAddress(address)) {
          throw Exception('Invalid Ethereum address format');
        }
      } else if (network == 'bitcoin') {
        if (!AppConfig.isValidBitcoinAddress(address)) {
          throw Exception('Invalid Bitcoin address format');
        }
      }
      
      // Check wallet limit
      final wallets = await _repository.getWallets();
      if (wallets.length >= AppConfig.maxWalletsPerUser) {
        throw Exception('Maximum number of wallets reached (${AppConfig.maxWalletsPerUser})');
      }
      
      // Add wallet
      final wallet = await _repository.addWallet(
        address: address,
        network: network,
        name: name,
      );
      
      // Refresh wallet data
      await _refreshWalletData(wallet);
      
      // Update portfolio
      await _updatePortfolio();
      
      return wallet;
    } catch (e) {
      throw Exception('Failed to add wallet: ${e.toString()}');
    }
  }
  
  /// Remove a wallet
  Future<void> removeWallet(String walletId) async {
    try {
      await _repository.deleteWallet(walletId);
      
      // Update portfolio
      await _updatePortfolio();
    } catch (e) {
      throw Exception('Failed to remove wallet: ${e.toString()}');
    }
  }
  
  /// Rename a wallet
  Future<CryptoWallet> renameWallet(String walletId, String newName) async {
    try {
      // Get the wallet
      final wallets = await _repository.getWallets();
      final wallet = wallets.firstWhere((w) => w.id == walletId);
      
      // Update the wallet
      final updatedWallet = wallet.copyWith(name: newName);
      return await _repository.updateWallet(updatedWallet);
    } catch (e) {
      throw Exception('Failed to rename wallet: ${e.toString()}');
    }
  }
  
  // ==========================================================================
  // TRANSACTION MANAGEMENT
  // ==========================================================================
  
  /// Get recent transactions
  Future<List<CryptoTransaction>> getRecentTransactions({int limit = 50}) async {
    try {
      return await _repository.getAllTransactions(limit: limit);
    } catch (e) {
      throw Exception('Failed to get recent transactions: ${e.toString()}');
    }
  }
  
  /// Get wallet transactions
  Future<List<CryptoTransaction>> getWalletTransactions(String walletAddress, {int limit = 50}) async {
    try {
      return await _repository.getWalletTransactions(walletAddress, limit: limit);
    } catch (e) {
      throw Exception('Failed to get wallet transactions: ${e.toString()}');
    }
  }
  
  /// Sync transactions to Appwrite
  Future<void> syncTransactionsToAppwrite() async {
    try {
      final transactions = await _repository.getAllTransactions();
      
      // Filter transactions that haven't been synced yet
      final unsynced = transactions.where((tx) => !tx.isSynced).toList();
      
      for (final tx in unsynced) {
        // Create a transaction in the budget app's transaction collection
        final response = await _databases.createDocument(
          databaseId: AppConfig.databaseId,
          collectionId: AppConfig.transactionsCollection,
          documentId: 'unique()',
          data: {
            'userId': _userId,
            'amount': tx.valueUsd * (tx.type == TransactionType.receive ? 1 : -1),
            'category': tx.budgetCategory ?? _determineBudgetCategory(tx),
            'date': tx.timestamp.toIso8601String(),
            'description': '${tx.type.toString().split('.').last} ${tx.symbol}',
            'isCrypto': true,
            'cryptoTxHash': tx.hash,
            'cryptoAmount': tx.amount,
            'cryptoSymbol': tx.symbol,
            'cryptoNetwork': tx.network,
            'notes': tx.notes ?? 'Crypto transaction',
          },
        );
        
        // Update the crypto transaction with the Appwrite ID
        final updatedTx = tx.copyWith(
          isSynced: true,
          appwriteId: response.$id,
        );
        
        await _repository.updateTransaction(updatedTx);
      }
    } catch (e) {
      throw Exception('Failed to sync transactions to Appwrite: ${e.toString()}');
    }
  }
  
  /// Watch for new transactions
  Stream<CryptoTransaction> watchTransactions() async* {
    // This is a complex implementation that would require continuous blockchain monitoring
    // For now, we'll create a simplified version that periodically checks for new transactions
    
    final wallets = await _repository.getWallets();
    
    for (final wallet in wallets) {
      // Get current known transactions for this wallet
      final knownTxs = await _repository.getWalletTransactions(wallet.address);
      final knownHashes = knownTxs.map((tx) => tx.hash).toSet();
      
      // Fetch latest transactions from the blockchain
      final newTxs = await _fetchWalletTransactions(wallet.address, wallet.network);
      
      // Filter out transactions we already know about
      final genuinelyNewTxs = newTxs.where((tx) => !knownHashes.contains(tx.hash)).toList();
      
      // Save and yield each new transaction
      for (final tx in genuinelyNewTxs) {
        await _repository.saveTransaction(tx);
        yield tx;
      }
    }
  }
  
  // ==========================================================================
  // PRICE & MARKET DATA
  // ==========================================================================
  
  /// Get current prices for all tracked tokens
  Future<Map<String, TokenPrice>> getCurrentPrices() async {
    try {
      // Check if we have recent cached prices
      final now = DateTime.now();
      if (_cachedPrices.isNotEmpty && 
          now.difference(_lastPriceUpdate) < const Duration(minutes: 2)) {
        return _cachedPrices;
      }
      
      // Get all tokens we need prices for
      final portfolio = await getPortfolio();
      final tokens = <String>{};
      
      for (final wallet in portfolio.wallets) {
        for (final token in wallet.tokens) {
          tokens.add(token.token);
        }
      }
      
      // Add major tokens even if not in portfolio
      tokens.addAll(['bitcoin', 'ethereum', 'tether', 'usd-coin', 'binancecoin']);
      
      // Fetch prices from CoinGecko
      final response = await http.get(
        Uri.parse('${AppConfig.coingeckoApiUrl}/coins/markets?vs_currency=usd&ids=${tokens.join(',')}&order=market_cap_desc&per_page=100&page=1&sparkline=false&price_change_percentage=24h'),
      );
      
      if (response.statusCode != 200) {
        // Try cached prices if available
        if (_cachedPrices.isNotEmpty) {
          return _cachedPrices;
        }
        throw Exception('Failed to fetch prices: ${response.body}');
      }
      
      final List<dynamic> data = jsonDecode(response.body);
      
      // Convert to TokenPrice objects
      final prices = <String, TokenPrice>{};
      for (final item in data) {
        final price = TokenPrice(
          token: item['id'],
          symbol: item['symbol'].toUpperCase(),
          price: item['current_price'].toDouble(),
          change24h: item['price_change_percentage_24h'] ?? 0.0,
          volume24h: item['total_volume'] ?? 0.0,
          marketCap: item['market_cap'] ?? 0.0,
          lastUpdated: DateTime.now(),
        );
        
        prices[price.token] = price;
        
        // Cache price
        await _repository.cacheTokenPrice(price);
      }
      
      // Update cached prices
      _cachedPrices = prices;
      _lastPriceUpdate = now;
      
      // Notify listeners
      _pricesStreamController.add(prices);
      
      return prices;
    } catch (e) {
      // Try to get cached prices
      final cachedPrices = _repository.getAllCachedPrices();
      if (cachedPrices.isNotEmpty) {
        final pricesMap = {for (var price in cachedPrices) price.token: price};
        return pricesMap;
      }
      
      throw Exception('Failed to get current prices: ${e.toString()}');
    }
  }
  
  /// Get price history for a token
  Future<PriceHistory> getPriceHistory(String token, Duration period) async {
    try {
      // Check if we have cached history
      final days = period.inDays == 0 ? 1 : period.inDays;
      final interval = days <= 1 ? '5minute' : days <= 7 ? 'hourly' : 'daily';
      
      final cachedHistory = _repository.getCachedPriceHistory(token, interval);
      if (cachedHistory != null) {
        final cacheAge = DateTime.now().difference(cachedHistory.lastUpdated);
        
        // Use cache if it's recent enough
        if (cacheAge < const Duration(minutes: 30)) {
          return cachedHistory;
        }
      }
      
      // Fetch from CoinGecko
      final response = await http.get(
        Uri.parse('${AppConfig.coingeckoApiUrl}/coins/$token/market_chart?vs_currency=usd&days=$days'),
      );
      
      if (response.statusCode != 200) {
        // Try cached history if available
        if (cachedHistory != null) {
          return cachedHistory;
        }
        throw Exception('Failed to fetch price history: ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      
      // Parse price points
      final prices = (data['prices'] as List<dynamic>).map((point) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(point[0] as int);
        final price = point[1].toDouble();
        return PricePoint(timestamp: timestamp, price: price);
      }).toList();
      
      // Create history object
      final history = PriceHistory(
        token: token,
        symbol: token.toUpperCase(), // Simplification
        prices: prices,
        interval: interval,
        startDate: prices.first.timestamp,
        endDate: prices.last.timestamp,
        lastUpdated: DateTime.now(),
      );
      
      // Cache the history
      await _repository.cachePriceHistory(history);
      
      return history;
    } catch (e) {
      // Try to return cached history
      final days = period.inDays == 0 ? 1 : period.inDays;
      final interval = days <= 1 ? '5minute' : days <= 7 ? 'hourly' : 'daily';
      
      final cachedHistory = _repository.getCachedPriceHistory(token, interval);
      if (cachedHistory != null) {
        return cachedHistory;
      }
      
      throw Exception('Failed to get price history: ${e.toString()}');
    }
  }
  
  /// Get market overview data
  Future<MarketData> getMarketOverview() async {
    try {
      // Fetch global data from CoinGecko
      final globalResponse = await http.get(
        Uri.parse('${AppConfig.coingeckoApiUrl}/global'),
      );
      
      if (globalResponse.statusCode != 200) {
        throw Exception('Failed to fetch global market data: ${globalResponse.body}');
      }
      
      final globalData = jsonDecode(globalResponse.body)['data'];
      
      // Fetch top gainers/losers
      final response = await http.get(
        Uri.parse('${AppConfig.coingeckoApiUrl}/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false&price_change_percentage=24h'),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch market data: ${response.body}');
      }
      
      final List<dynamic> coinsData = jsonDecode(response.body);
      
      // Sort by 24h change to find top gainers and losers
      final sortedCoins = [...coinsData];
      sortedCoins.sort((a, b) => 
        (b['price_change_percentage_24h'] ?? 0.0)
            .compareTo(a['price_change_percentage_24h'] ?? 0.0));
      
      // Create token price objects for top gainers
      final topGainers = sortedCoins.take(5).map((item) {
        return TokenPrice(
          token: item['id'],
          symbol: item['symbol'].toUpperCase(),
          price: item['current_price'].toDouble(),
          change24h: item['price_change_percentage_24h'] ?? 0.0,
          volume24h: item['total_volume'] ?? 0.0,
          marketCap: item['market_cap'] ?? 0.0,
          lastUpdated: DateTime.now(),
        );
      }).toList();
      
      // Create token price objects for top losers
      final topLosers = sortedCoins.reversed.take(5).map((item) {
        return TokenPrice(
          token: item['id'],
          symbol: item['symbol'].toUpperCase(),
          price: item['current_price'].toDouble(),
          change24h: item['price_change_percentage_24h'] ?? 0.0,
          volume24h: item['total_volume'] ?? 0.0,
          marketCap: item['market_cap'] ?? 0.0,
          lastUpdated: DateTime.now(),
        );
      }).toList();
      
      // Create market data object
      return MarketData(
        totalMarketCap: globalData['total_market_cap']['usd'].toDouble(),
        totalVolume24h: globalData['total_volume']['usd'].toDouble(),
        btcDominance: globalData['market_cap_percentage']['btc'].toDouble(),
        marketCapChange24h: globalData['market_cap_change_percentage_24h_usd'].toDouble(),
        topGainers: topGainers,
        topLosers: topLosers,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      // Create a fallback market data object
      return MarketData(
        totalMarketCap: 0.0,
        totalVolume24h: 0.0,
        btcDominance: 0.0,
        marketCapChange24h: 0.0,
        topGainers: [],
        topLosers: [],
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  // ==========================================================================
  // AI INSIGHTS
  // ==========================================================================
  
  /// Generate budget advice
  Future<BudgetSuggestion> generateBudgetAdvice() async {
    try {
      return await _aiService.generateBudgetAdvice();
    } catch (e) {
      throw Exception('Failed to generate budget advice: ${e.toString()}');
    }
  }
  
  /// Get portfolio insights
  Future<List<Insight>> getPortfolioInsights() async {
    try {
      final insights = await _aiService.getPortfolioInsights();
      
      // Notify listeners
      _insightsStreamController.add(insights);
      
      return insights;
    } catch (e) {
      throw Exception('Failed to get portfolio insights: ${e.toString()}');
    }
  }
  
  /// Analyze spending pattern
  Future<String> analyzeSpendingPattern() async {
    try {
      return await _aiService.analyzeSpendingPattern();
    } catch (e) {
      throw Exception('Failed to analyze spending pattern: ${e.toString()}');
    }
  }
  
  /// Assess portfolio risk
  Future<RiskAssessment> assessPortfolioRisk() async {
    try {
      return await _aiService.assessPortfolioRisk();
    } catch (e) {
      throw Exception('Failed to assess portfolio risk: ${e.toString()}');
    }
  }
  
  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================
  
  /// Validate a transaction
  Future<bool> validateTransaction(CryptoTransaction tx) async {
    try {
      // For Ethereum-based chains, use Moralis to verify the transaction
      if (AppConfig.supportedNetworks.containsKey(tx.network)) {
        final chainId = AppConfig.getChainId(tx.network);
        
        final response = await http.get(
          Uri.parse('$_moralisBaseUrl/transaction/${tx.hash}?chain=$chainId'),
          headers: AppConfig.moralisHeaders,
        );
        
        if (response.statusCode != 200) {
          return false;
        }
        
        final data = jsonDecode(response.body);
        
        // Verify basic transaction data
        return data['hash'] == tx.hash &&
               data['from_address']?.toLowerCase() == tx.from.toLowerCase() &&
               data['to_address']?.toLowerCase() == tx.to.toLowerCase();
      }
      
      // For other chains, we'd need specific implementations
      // Default to true for now
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Estimate gas fees for a network
  Future<double> estimateGasFees(String network) async {
    try {
      final chainId = AppConfig.getChainId(network);
      
      // Use Moralis to get current gas price
      final response = await http.get(
        Uri.parse('$_moralisBaseUrl/chains/$chainId/gas'),
        headers: AppConfig.moralisHeaders,
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch gas price: ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      
      // Convert to gwei
      final gasPrice = double.parse(data['result']['fast']['gasPrice']) / 1e9;
      
      // Estimate cost for a standard ERC20 transfer (using 65,000 gas)
      return gasPrice * 65000 / 1e9;
    } catch (e) {
      throw Exception('Failed to estimate gas fees: ${e.toString()}');
    }
  }
  
  // ==========================================================================
  // PRIVATE HELPER METHODS
  // ==========================================================================
  
  /// Start timer to refresh prices periodically
  void _startPriceRefreshTimer() {
    _priceRefreshTimer?.cancel();
    _priceRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      getCurrentPrices();
    });
  }
  
  /// Start timer to refresh portfolio periodically
  void _startPortfolioRefreshTimer() {
    _portfolioRefreshTimer?.cancel();
    _portfolioRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updatePortfolio();
    });
  }
  
  /// Load initial data
  Future<void> _loadInitialData() async {
    try {
      // Load prices
      await getCurrentPrices();
      
      // Load portfolio
      final portfolio = await getPortfolio();
      _portfolioStreamController.add(portfolio);
      
      // Load transactions
      final transactions = await getRecentTransactions();
      _transactionsStreamController.add(transactions);
      
      // Load insights
      final insights = await _repository.getInsights();
      _insightsStreamController.add(insights);
      
      // Sync any unsynced transactions
      await syncTransactionsToAppwrite();
    } catch (e) {
      // Fail silently and try again later
      print('Failed to load initial data: ${e.toString()}');
    }
  }
  
  /// Refresh wallet data by fetching latest balances and transactions
  Future<void> _refreshWalletData(CryptoWallet wallet) async {
    try {
      // Get token balances
      final tokens = await _fetchWalletBalances(wallet.address, wallet.network);
      
      // Get price data
      final prices = await getCurrentPrices();
      
      // Calculate token values
      double totalValue = 0.0;
      final tokenBalances = <TokenBalance>[];
      
      for (final token in tokens.entries) {
        final tokenId = token.key.toLowerCase();
        final balance = token.value;
        final symbol = token.key;
        
        // Find token price (approximate match if needed)
        TokenPrice? price = prices[tokenId];
        if (price == null) {
          // Try to find by symbol
          price = prices.values.firstWhereOrNull(
            (p) => p.symbol.toLowerCase() == symbol.toLowerCase()
          );
        }
        
        final valueUsd = price != null ? balance * price.price : 0.0;
        totalValue += valueUsd;
        
        tokenBalances.add(TokenBalance(
          token: tokenId,
          tokenAddress: token.key,
          symbol: symbol,
          balance: balance,
          valueUsd: valueUsd,
          decimals: 18, // Default for most tokens
        ));
      }
      
      // Update wallet
      final updatedWallet = wallet.copyWith(
        tokens: tokenBalances,
        totalValue: totalValue,
        lastUpdated: DateTime.now(),
      );
      
      await _repository.updateWallet(updatedWallet);
      
      // Fetch and save recent transactions
      final transactions = await _fetchWalletTransactions(wallet.address, wallet.network);
      for (final tx in transactions) {
        // Check if transaction already exists
        try {
          await _repository.saveTransaction(tx);
        } catch (e) {
          // Likely already exists, continue
        }
      }
    } catch (e) {
      throw Exception('Failed to refresh wallet data: ${e.toString()}');
    }
  }
  
  /// Update portfolio data
  Future<void> _updatePortfolio() async {
    try {
      // Get wallets
      final wallets = await _repository.getWallets();
      
      // Get prices
      final prices = await getCurrentPrices();
      
      // Refresh wallet data
      for (final wallet in wallets) {
        await _refreshWalletData(wallet);
      }
      
      // Recalculate portfolio stats
      double totalValue = 0.0;
      final assetMap = <String, double>{};
      
      // Sum up wallet values and create asset allocation map
      for (final wallet in wallets) {
        totalValue += wallet.totalValue;
        
        for (final token in wallet.tokens) {
          if (assetMap.containsKey(token.symbol)) {
            assetMap[token.symbol] = assetMap[token.symbol]! + token.valueUsd;
          } else {
            assetMap[token.symbol] = token.valueUsd;
          }
        }
      }
      
      // Convert asset values to percentages
      final assetAllocation = totalValue > 0 
          ? assetMap.map((k, v) => MapEntry(k, (v / totalValue) * 100))
          : <String, double>{};
      
      // Calculate 24h change
      double percentChange24h = 0.0;
      if (totalValue > 0) {
        double weightedChange = 0.0;
        
        for (final entry in assetAllocation.entries) {
          final symbol = entry.key;
          final allocation = entry.value;
          
          // Find token price
          final price = prices.values.firstWhereOrNull(
            (p) => p.symbol.toLowerCase() == symbol.toLowerCase()
          );
          
          if (price != null) {
            // Weight the change by allocation percentage
            weightedChange += price.change24h * (allocation / 100);
          }
        }
        
        percentChange24h = weightedChange;
      }
      
      // Create updated portfolio
      final portfolio = Portfolio(
        wallets: wallets,
        totalValue: totalValue,
        assetAllocation: assetAllocation,
        percentChange24h: percentChange24h,
        lastUpdated: DateTime.now(),
      );
      
      // Save portfolio
      await _repository.savePortfolio(portfolio);
      
      // Notify listeners
      _portfolioStreamController.add(portfolio);
    } catch (e) {
      throw Exception('Failed to update portfolio: ${e.toString()}');
    }
  }
  
  /// Fetch wallet balances from Moralis
  Future<Map<String, double>> _fetchWalletBalances(String address, String network) async {
    try {
      final chainId = AppConfig.getChainId(network);
      
      // Fetch native balance
      final nativeResponse = await http.get(
        Uri.parse('$_moralisBaseUrl/$address/balance?chain=$chainId'),
        headers: AppConfig.moralisHeaders,
      );
      
      if (nativeResponse.statusCode != 200) {
        throw Exception('Failed to fetch native balance: ${nativeResponse.body}');
      }
      
      final nativeData = jsonDecode(nativeResponse.statusCode == 200 ? nativeResponse.body : '{"balance":"0"}');
      final nativeBalance = double.parse(nativeData['balance'] ?? '0') / 1e18;
      
      // Determine native symbol
      String nativeSymbol;
      switch (network) {
        case 'ethereum':
          nativeSymbol = 'ETH';
          break;
        case 'bsc':
          nativeSymbol = 'BNB';
          break;
        case 'polygon':
          nativeSymbol = 'MATIC';
          break;
        case 'avalanche':
          nativeSymbol = 'AVAX';
          break;
        case 'fantom':
          nativeSymbol = 'FTM';
          break;
        case 'arbitrum':
          nativeSymbol = 'ETH';
          break;
        default:
          nativeSymbol = 'ETH';
      }
      
      // Fetch token balances
      final tokenResponse = await http.get(
        Uri.parse('$_moralisBaseUrl/$address/erc20?chain=$chainId'),
        headers: AppConfig.moralisHeaders,
      );
      
      final balances = <String, double>{
        nativeSymbol: nativeBalance,
      };
      
      if (tokenResponse.statusCode == 200) {
        final List<dynamic> tokens = jsonDecode(tokenResponse.body);
        
        for (final token in tokens) {
          final symbol = token['symbol'] ?? 'UNKNOWN';
          final decimals = int.parse(token['decimals'] ?? '18');
          final balance = double.parse(token['balance'] ?? '0') / pow(10, decimals);
          
          balances[symbol] = balance;
        }
      }
      
      return balances;
    } catch (e) {
      // Return just the major token for the network if there's an error
      switch (network) {
        case 'ethereum':
          return {'ETH': 0.0};
        case 'bsc':
          return {'BNB': 0.0};
        case 'polygon':
          return {'MATIC': 0.0};
        case 'avalanche':
          return {'AVAX': 0.0};
        case 'fantom':
          return {'FTM': 0.0};
        case 'arbitrum':
          return {'ETH': 0.0};
        default:
          return {};
      }
    }
  }
  
  /// Fetch wallet transactions from Moralis
  Future<List<CryptoTransaction>> _fetchWalletTransactions(String address, String network) async {
    try {
      final chainId = AppConfig.getChainId(network);
      
      // Fetch transactions
      final response = await http.get(
        Uri.parse('$_moralisBaseUrl/$address/transfers?chain=$chainId&limit=20'),
        headers: AppConfig.moralisHeaders,
      );
      
      if (response.statusCode != 200) {
        return [];
      }
      
      final data = jsonDecode(response.body);
      
      if (!data.containsKey('result') || data['result'] == null) {
        return [];
      }
      
      final List<dynamic> txs = data['result'];
      
      // Get current prices
      await getCurrentPrices();
      
      // Convert to CryptoTransaction objects
      return txs.map((tx) {
        // Determine transaction type
        TransactionType type;
        if (tx['from_address']?.toLowerCase() == address.toLowerCase()) {
          type = TransactionType.send;
        } else {
          type = TransactionType.receive;
        }
        
        // Get token information
        String token = tx['token_address'] ?? 'native';
        String symbol = tx['token_symbol'] ?? _getNativeSymbol(network);
        final decimals = int.parse(tx['token_decimals'] ?? '18');
        final amount = double.parse(tx['value'] ?? '0') / pow(10, decimals);
        
        // Calculate USD value (approximate using current prices)
        double valueUsd = 0.0;
        final tokenPrice = _cachedPrices[token.toLowerCase()] ?? 
                          _cachedPrices.values.firstWhereOrNull(
                            (p) => p.symbol.toLowerCase() == symbol.toLowerCase()
                          );
        if (tokenPrice != null) {
          valueUsd = amount * tokenPrice.price;
        }
        
        return CryptoTransaction(
          id: _uuid.v4(),
          hash: tx['transaction_hash'] ?? '',
          network: network,
          from: tx['from_address'] ?? '',
          to: tx['to_address'] ?? '',
          amount: amount,
          symbol: symbol,
          token: token,
          valueUsd: valueUsd,
          type: type,
          timestamp: DateTime.parse(tx['block_timestamp'] ?? DateTime.now().toIso8601String()),
          blockNumber: int.parse(tx['block_number'] ?? '0'),
          gasUsed: double.parse(tx['gas'] ?? '0'),
          gasPrice: double.parse(tx['gas_price'] ?? '0'),
          status: tx['confirmed'] == true ? TransactionStatus.confirmed : TransactionStatus.pending,
          isSynced: false,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Get native symbol for a network
  String _getNativeSymbol(String network) {
    switch (network) {
      case 'ethereum':
        return 'ETH';
      case 'bsc':
        return 'BNB';
      case 'polygon':
        return 'MATIC';
      case 'avalanche':
        return 'AVAX';
      case 'fantom':
        return 'FTM';
      case 'arbitrum':
        return 'ETH';
      default:
        return 'ETH';
    }
  }
  
  /// Determine budget category for a crypto transaction
  String _determineBudgetCategory(CryptoTransaction tx) {
    switch (tx.type) {
      case TransactionType.send:
        // Check if it's a DeFi transaction, NFT purchase, etc.
        if (tx.to.toLowerCase() == '0x0000000000000000000000000000000000000000') {
          return 'Investment'; // Staking or burning
        } else if (tx.valueUsd > 1000) {
          return 'Investment'; // Large transfers likely investments
        } else {
          return 'Transfer'; // Regular transfers
        }
      case TransactionType.receive:
        return 'Income'; // Received tokens
      case TransactionType.swap:
        return 'Investment'; // Trading activity
      case TransactionType.stake:
        return 'Investment'; // Staking
      case TransactionType.unstake:
        return 'Investment'; // Unstaking
      case TransactionType.mint:
        return 'Investment'; // Minting NFTs or tokens
      case TransactionType.burn:
        return 'Investment'; // Burning tokens
    }
  }
}

// Extension method for math operations
extension on double {
  double pow(int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}

// Math utility for power operations
double pow(double base, int exponent) {
  double result = 1.0;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}