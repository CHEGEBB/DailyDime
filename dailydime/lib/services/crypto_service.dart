// lib/services/crypto_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw_models;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/crypto_models.dart';
import '../config/app_config.dart';

class CryptoService {
  // API Clients
  final Client _appwriteClient;
  late final Databases _databases;
late final Account _account;
  final http.Client _httpClient;
  final GenerativeModel _aiModel;
  
  // Stream controllers
  final StreamController<PriceUpdate> _priceUpdateController = StreamController<PriceUpdate>.broadcast();
  final StreamController<Portfolio> _portfolioUpdateController = StreamController<Portfolio>.broadcast();
  
  // Cache
  final Map<String, Token> _tokenCache = {};
  final Map<String, double> _priceCache = {};
  DateTime? _lastPriceUpdate;
  Portfolio? _cachedPortfolio;
  
  // Configuration
  static const Duration _priceCacheDuration = Duration(minutes: 5);
  static const Duration _portfolioCacheDuration = Duration(minutes: 15);
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);
  
  // Collections
  late final String _cryptoWalletsCollection;
  late final String _cryptoTransactionsCollection;
  late final String _cryptoPricesCollection;
  late final String _cryptoInsightsCollection;
  
  // Singleton instance
  static CryptoService? _instance;
  
  // Get instance
  static CryptoService get instance {
    _instance ??= CryptoService._internal();
    return _instance!;
  }
  
  // Internal constructor
  CryptoService._internal()
      : _appwriteClient = Client()
          .setEndpoint(AppConfig.appwriteEndpoint)
          .setProject(AppConfig.appwriteProjectId),
        _httpClient = http.Client(),
        _aiModel = GenerativeModel(
          model: AppConfig.geminiModel,
          apiKey: AppConfig.geminiApiKey,
        ) {
    
    _databases = Databases(_appwriteClient);
    _account = Account(_appwriteClient);
    
    // Set collection IDs
    _cryptoWalletsCollection = 'crypto_wallets';
    _cryptoTransactionsCollection = 'crypto_transactions';
    _cryptoPricesCollection = 'crypto_prices';
    _cryptoInsightsCollection = 'crypto_insights';
    
    // Start background tasks
    _startPriceUpdateTask();
  }
  
  // Dispose resources
  void dispose() {
    _priceUpdateController.close();
    _portfolioUpdateController.close();
    _httpClient.close();
  }
  
  // Stream getters
  Stream<PriceUpdate> get priceUpdates => _priceUpdateController.stream;
  Stream<Portfolio> get portfolioUpdates => _portfolioUpdateController.stream;
  
  // ========== PORTFOLIO & WALLET MANAGEMENT ==========
  
  /// Get complete portfolio data across multiple wallets
  Future<Portfolio> getPortfolio(List<String> wallets) async {
    try {
      // Check cache first
      if (_cachedPortfolio != null && 
          DateTime.now().difference(_cachedPortfolio!.lastUpdated) < _portfolioCacheDuration) {
        return _cachedPortfolio!;
      }
      
      // If no wallets provided, fetch from database
      if (wallets.isEmpty) {
        final userWallets = await getWallets();
        wallets = userWallets.map((w) => w.address).toList();
      }
      
      // If still no wallets, return empty portfolio
      if (wallets.isEmpty) {
        return Portfolio(
          wallets: [],
          totalUsdValue: 0,
          dayChange: 0,
          dayChangePercentage: 0,
          allocation: {},
          lastUpdated: DateTime.now(),
        );
      }
      
      // Fetch data for each wallet in parallel
      final walletDataFutures = wallets.map((address) => _getWalletData(address));
      final walletDataList = await Future.wait(walletDataFutures);
      
      // Calculate portfolio totals
      double totalValue = 0;
      double totalDayChange = 0;
      Map<String, double> allocation = {};
      
      for (final wallet in walletDataList) {
        totalValue += wallet.getTotalUsdValue();
        
        // Update allocation data
        for (final token in wallet.tokens) {
          if (allocation.containsKey(token.symbol)) {
            allocation[token.symbol] = allocation[token.symbol]! + token.usdValue;
          } else {
            allocation[token.symbol] = token.usdValue;
          }
        }
      }
      
      // Calculate percentages for allocation
      if (totalValue > 0) {
        allocation.forEach((key, value) {
          allocation[key] = (value / totalValue) * 100;
        });
      }
      
      // Get 24h price changes to calculate total change
      final topTokens = allocation.keys.take(5).toList();
      final prices24hAgo = await _getPricesFromYesterday(topTokens);
      
      // Calculate 24h change
      for (final tokenSymbol in topTokens) {
        final currentValue = allocation[tokenSymbol]! * totalValue / 100;
        final priceNow = await getTokenPrice(tokenSymbol);
        final priceThen = prices24hAgo[tokenSymbol] ?? priceNow;
        
        if (priceThen > 0) {
          final valueYesterday = currentValue * priceThen / priceNow;
          totalDayChange += (currentValue - valueYesterday);
        }
      }
      
      // Calculate change percentage
      final dayChangePercentage = totalValue > 0 ? (totalDayChange / totalValue) * 100 : 0;
      
      // Create portfolio
      final portfolio = Portfolio(
        wallets: walletDataList,
        totalUsdValue: totalValue,
        dayChange: totalDayChange,
        dayChangePercentage: dayChangePercentage.toDouble(),
        allocation: allocation,
        lastUpdated: DateTime.now(),
      );
      
      // Cache the portfolio
      _cachedPortfolio = portfolio;
      
      // Send update to stream
      _portfolioUpdateController.add(portfolio);
      
      return portfolio;
    } catch (e) {
      // Log error and return empty portfolio
      debugPrint('Error getting portfolio: $e');
      return Portfolio(
        wallets: [],
        totalUsdValue: 0,
        dayChange: 0,
        dayChangePercentage: 0,
        allocation: {},
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Get total net worth (crypto + other assets)
  Future<double> getTotalNetWorth() async {
    try {
      // Get crypto portfolio
      final portfolio = await getPortfolio([]);
      final cryptoValue = portfolio.totalUsdValue;
      
      // TODO: Integrate with budget app to get other assets
      // For now, we'll just return crypto value
      return cryptoValue;
    } catch (e) {
      debugPrint('Error getting net worth: $e');
      return 0;
    }
  }
  
  /// Add a new wallet to track
  Future<void> addWallet(String address, String network) async {
    try {
      // Validate address format
      if (!AppConfig.isValidEthereumAddress(address)) {
        throw Exception('Invalid wallet address format');
      }
      
      // Check if network is supported
      if (!AppConfig.supportedNetworks.containsKey(network.toLowerCase())) {
        throw Exception('Unsupported network');
      }
      
      // Check if wallet already exists
      final existingWallets = await getWallets();
      if (existingWallets.any((w) => w.address.toLowerCase() == address.toLowerCase() && 
                               w.networkName.toLowerCase() == network.toLowerCase())) {
        throw Exception('Wallet already exists');
      }
      
      // Check wallet limit
      if (existingWallets.length >= AppConfig.maxWalletsPerUser) {
        throw Exception('Maximum number of wallets reached');
      }
      
      // Get current user
      final user = await _account.get();
      
      // Create wallet document
      await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoWalletsCollection,
        documentId: ID.unique(),
        data: {
          'address': address,
          'network_id': AppConfig.getChainId(network),
          'network_name': network,
          'user_id': user.$id,
          'label': 'My $network Wallet',
          'balance': 0,
          'last_updated': DateTime.now().toIso8601String(),
          'is_active': true,
        },
      );
      
      // Invalidate cache
      _cachedPortfolio = null;
      
      // Update portfolio in background
      getPortfolio([]).then((_) {});
    } catch (e) {
      debugPrint('Error adding wallet: $e');
      rethrow;
    }
  }
  
  /// Get all user wallets
  Future<List<Wallet>> getWallets() async {
    try {
      // Get current user
      final user = await _account.get();
      
      // Query wallets for user
      final result = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoWalletsCollection,
        queries: [
          Query.equal('user_id', user.$id),
          Query.equal('is_active', true),
        ],
      );
      
      // Convert to wallet objects
      return result.documents.map((doc) {
        return Wallet(
          id: doc.$id,
          address: doc.data['address'],
          networkId: doc.data['network_id'],
          networkName: doc.data['network_name'],
          label: doc.data['label'],
          balance: (doc.data['balance'] as num?)?.toDouble() ?? 0.0,
          tokens: [], // We'll load these separately when needed
          lastUpdated: DateTime.parse(doc.data['last_updated']),
          isActive: doc.data['is_active'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting wallets: $e');
      return [];
    }
  }
  
  /// Remove a wallet
  Future<bool> removeWallet(String walletId) async {
    try {
      // Soft delete - set is_active to false
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoWalletsCollection,
        documentId: walletId,
        data: {
          'is_active': false,
        },
      );
      
      // Invalidate cache
      _cachedPortfolio = null;
      
      return true;
    } catch (e) {
      debugPrint('Error removing wallet: $e');
      return false;
    }
  }
  
  /// Update wallet label
  Future<bool> updateWalletLabel(String walletId, String newLabel) async {
    try {
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoWalletsCollection,
        documentId: walletId,
        data: {
          'label': newLabel,
        },
      );
      
      // Invalidate cache
      _cachedPortfolio = null;
      
      return true;
    } catch (e) {
      debugPrint('Error updating wallet label: $e');
      return false;
    }
  }
  
  // ========== REAL-TIME DATA ==========
  
  /// Get current prices for multiple tokens
  Future<Map<String, double>> getCurrentPrices(List<String> tokens) async {
    Map<String, double> prices = {};
    
    try {
      // Check cache first for tokens that were recently updated
      final now = DateTime.now();
      final tokensToFetch = <String>[];
      
      for (final symbol in tokens) {
        if (_priceCache.containsKey(symbol) && 
            _lastPriceUpdate != null && 
            now.difference(_lastPriceUpdate!) < _priceCacheDuration) {
          prices[symbol] = _priceCache[symbol]!;
        } else {
          tokensToFetch.add(symbol);
        }
      }
      
      // If all prices were cached, return them
      if (tokensToFetch.isEmpty) {
        return prices;
      }
      
      // Fetch prices from API
      final joinedSymbols = tokensToFetch.join(',');
      final response = await _withRetry(() => _httpClient.get(
        Uri.parse('${AppConfig.coingeckoApiUrl}/simple/price?ids=$joinedSymbols&vs_currencies=usd&include_24h_change=true'),
        headers: {'Accept': 'application/json'},
      ));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Update cache and result
        for (final symbol in tokensToFetch) {
          if (data.containsKey(symbol.toLowerCase())) {
            final price = data[symbol.toLowerCase()]['usd'].toDouble();
            _priceCache[symbol] = price;
            prices[symbol] = price;
            
            // Create price update event
            final change = data[symbol.toLowerCase()]['usd_24h_change']?.toDouble() ?? 0.0;
            _priceUpdateController.add(PriceUpdate(
              symbol: symbol,
              price: price,
              change24h: change,
              timestamp: now,
            ));
          }
        }
        
        _lastPriceUpdate = now;
      } else {
        // Fallback to backup API or use cache
        await _fetchPricesFromBackupApi(tokensToFetch, prices);
      }
      
      return prices;
    } catch (e) {
      debugPrint('Error getting prices: $e');
      return prices;
    }
  }
  
  /// Get price for a single token
  Future<double> getTokenPrice(String symbol) async {
    final prices = await getCurrentPrices([symbol]);
    return prices[symbol] ?? 0.0;
  }
  
  /// Watch for real-time price updates
  Stream<PriceUpdate> watchPriceUpdates() {
    return _priceUpdateController.stream;
  }
  
  /// Get recent transactions for user wallets
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    try {
      // Get user wallets
      final wallets = await getWallets();
      if (wallets.isEmpty) {
        return [];
      }
      
      // Get wallet addresses
      final addresses = wallets.map((w) => w.address.toLowerCase()).toList();
      
      // Query transactions
      final result = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoTransactionsCollection,
        queries: [
          Query.equal('is_user_transaction', true),
          Query.orderDesc('timestamp'),
          Query.limit(limit),
        ],
      );
      
      // Parse transactions
      return result.documents.map((doc) => Transaction(
        id: doc.$id,
        hash: doc.data['hash'],
        from: doc.data['from'],
        to: doc.data['to'],
        tokenAddress: doc.data['token_address'],
        tokenSymbol: doc.data['token_symbol'],
        tokenName: doc.data['token_name'],
        tokenLogo: doc.data['token_logo'],
        value: (doc.data['value'] as num).toDouble(),
        valueUsd: (doc.data['value_usd'] as num).toDouble(),
        timestamp: DateTime.parse(doc.data['timestamp']),
        type: TransactionType.values.firstWhere(
          (t) => t.toString().split('.').last == doc.data['type'],
          orElse: () => TransactionType.transfer,
        ),
        networkId: doc.data['network_id'],
        networkName: doc.data['network_name'],
        status: TransactionStatus.values.firstWhere(
          (s) => s.toString().split('.').last == doc.data['status'],
          orElse: () => TransactionStatus.confirmed,
        ),
        budgetCategory: doc.data['budget_category'] ?? '',
        description: doc.data['description'] ?? '',
      )).toList();
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }
  
  /// Sync recent transactions for a wallet
  Future<void> syncWalletTransactions(String address, String network) async {
    try {
      final chainId = AppConfig.getChainId(network);
      final limit = 20; // Fetch last 20 transactions
      
      // Fetch transactions from Moralis
      final response = await _withRetry(() => _httpClient.get(
        Uri.parse('${AppConfig.moralisBaseUrl}/$address?chain=$chainId&limit=$limit'),
        headers: AppConfig.moralisHeaders,
      ));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactions = data['result'] as List<dynamic>;
        
        // Get current user
        final user = await _account.get();
        
        // Process each transaction
        for (final tx in transactions) {
          // Check if transaction already exists
          final existingTx = await _databases.listDocuments(
            databaseId: AppConfig.databaseId,
            collectionId: _cryptoTransactionsCollection,
            queries: [
              Query.equal('hash', tx['hash']),
              Query.equal('network_id', chainId),
            ],
          );
          
          if (existingTx.documents.isNotEmpty) {
            continue; // Skip if already exists
          }
          
          // Determine transaction type
          TransactionType txType;
          if (tx['from_address'].toString().toLowerCase() == address.toLowerCase()) {
            txType = TransactionType.send;
          } else if (tx['to_address'].toString().toLowerCase() == address.toLowerCase()) {
            txType = TransactionType.receive;
          } else {
            txType = TransactionType.transfer;
          }
          
          // Get token details
          String tokenSymbol = 'ETH';
          String tokenName = 'Ethereum';
          String tokenLogo = 'https://cryptologos.cc/logos/ethereum-eth-logo.png';
          
          if (tx['token_address'] != null && tx['token_address'].toString().isNotEmpty) {
            // This is a token transfer
            tokenSymbol = tx['token_symbol'] ?? 'Unknown';
            tokenName = tx['token_name'] ?? 'Unknown Token';
            tokenLogo = 'https://cryptologos.cc/logos/ethereum-eth-logo.png'; // Default logo
          }
          
          // Calculate USD value
          double valueUsd = 0;
          final tokenPrice = await getTokenPrice(tokenSymbol);
          final value = tx['value'] != null ? 
            double.parse(tx['value']) / pow(10, tx['decimal'] ?? 18) : 0.0;
          valueUsd = value * tokenPrice;
          
          // Save transaction
          await _databases.createDocument(
            databaseId: AppConfig.databaseId,
            collectionId: _cryptoTransactionsCollection,
            documentId: ID.unique(),
            data: {
              'hash': tx['hash'],
              'from': tx['from_address'],
              'to': tx['to_address'],
              'token_address': tx['token_address'] ?? '',
              'token_symbol': tokenSymbol,
              'token_name': tokenName,
              'token_logo': tokenLogo,
              'value': value,
              'value_usd': valueUsd,
              'timestamp': tx['block_timestamp'],
              'type': txType.toString().split('.').last,
              'network_id': chainId,
              'network_name': network,
              'status': 'confirmed',
              'budget_category': _determineBudgetCategory(txType, value, tokenSymbol),
              'description': '',
              'user_id': user.$id,
              'is_user_transaction': true,
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error syncing transactions: $e');
    }
  }
  
  /// Update transaction budget category
  Future<bool> updateTransactionCategory(String transactionId, String category) async {
    try {
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoTransactionsCollection,
        documentId: transactionId,
        data: {
          'budget_category': category,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error updating transaction category: $e');
      return false;
    }
  }
  
  /// Update transaction description
  Future<bool> updateTransactionDescription(String transactionId, String description) async {
    try {
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoTransactionsCollection,
        documentId: transactionId,
        data: {
          'description': description,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error updating transaction description: $e');
      return false;
    }
  }
  
  // ========== AI INTEGRATION (GEMINI) ==========
  
  /// Get AI-powered insights about the portfolio
  Future<List<AIInsight>> getPortfolioInsights() async {
    try {
      // Get portfolio data
      final portfolio = await getPortfolio([]);
      
      // If portfolio is empty, return default insights
      if (portfolio.wallets.isEmpty || portfolio.totalUsdValue == 0) {
        return _getDefaultInsights();
      }
      
      // Get transaction history
      final transactions = await getRecentTransactions(limit: 20);
      
      // Get market data
      final marketData = await getMarketOverview();
      
      // Prepare data for Gemini
      final portfolioData = {
        'total_value': portfolio.totalUsdValue,
        'allocation': portfolio.allocation,
        'day_change': portfolio.dayChange,
        'day_change_percentage': portfolio.dayChangePercentage,
        'transaction_count': transactions.length,
        'transaction_types': transactions
            .map((t) => t.type.toString().split('.').last)
            .toSet()
            .toList(),
        'market_cap': marketData.totalMarketCap,
        'market_sentiment': marketData.getFearIndex(),
      };
      
      // Generate insights using Gemini
      final content = [
        Content.text(
          'Generate 3 crypto portfolio insights based on this data: ${jsonEncode(portfolioData)}. '
          'Format each insight as a JSON object with fields: title, description, type (one of: general, recommendation, alert, opportunity, risk, education, budget). '
          'Make insights specific, actionable, and relevant to the portfolio composition. '
          'Return only a JSON array with 3 insights, no other text.'
        ),
      ];
      
      final response = await _withRetry(() => _aiModel.generateContent(content));
      final responseText = response.text;
      
      if (responseText == null || responseText.isEmpty) {
        return _getDefaultInsights();
      }
      
      // Parse insights from AI response
      try {
        final cleanJson = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final parsedData = jsonDecode(cleanJson) as List<dynamic>;
        
        final insights = parsedData.map((item) => AIInsight(
          id: ID.unique(),
          title: item['title'],
          description: item['description'],
          type: _parseAIInsightType(item['type']),
          actionUrl: '',
          timestamp: DateTime.now(),
          confidence: 0.85,
          metadata: {},
        )).toList();
        
        // Save insights to database
        for (final insight in insights) {
          await _databases.createDocument(
            databaseId: AppConfig.databaseId,
            collectionId: _cryptoInsightsCollection,
            documentId: insight.id,
            data: insight.toJson(),
          );
        }
        
        return insights;
      } catch (e) {
        debugPrint('Error parsing AI insights: $e');
        return _getDefaultInsights();
      }
    } catch (e) {
      debugPrint('Error getting portfolio insights: $e');
      return _getDefaultInsights();
    }
  }
  
  /// Generate budget advice based on crypto portfolio
  Future<String> generateBudgetAdvice() async {
    try {
      // Get portfolio data
      final portfolio = await getPortfolio([]);
      
      // If portfolio is empty, return default advice
      if (portfolio.wallets.isEmpty || portfolio.totalUsdValue == 0) {
        return 'Consider allocating a small portion of your budget to cryptocurrency investments to diversify your portfolio. Start with established assets like Bitcoin or Ethereum.';
      }
      
      // Get transaction history
      final transactions = await getRecentTransactions(limit: 20);
      
      // Get risk assessment
      final risk = await analyzeRisk();
      
      // Prepare data for Gemini
      final userData = {
        'portfolio_value': portfolio.totalUsdValue,
        'portfolio_allocation': portfolio.allocation,
        'risk_level': risk.getRiskLevel(),
        'transaction_frequency': transactions.length / 20, // transactions per day
        'primary_tokens': portfolio.allocation.entries
            .toList()
            .sublist(0, min(3, portfolio.allocation.length))
            .map((e) => e.key)
            .toList(),
      };
      
      // Generate advice using Gemini
      final content = [
        Content.text(
          'Generate personalized budget advice for a crypto investor with these characteristics: ${jsonEncode(userData)}. '
          'Focus on practical financial management suggestions that integrate crypto with traditional budgeting. '
          'Keep your response under 250 words, practical, and specific.'
        ),
      ];
      
      final response = await _withRetry(() => _aiModel.generateContent(content));
      final responseText = response.text;
      
      if (responseText == null || responseText.isEmpty) {
        return 'Consider balancing your crypto investments with traditional savings. Given market volatility, maintain an emergency fund covering 3-6 months of expenses in stable assets. Review your portfolio monthly and adjust based on performance and financial goals.';
      }
      
      return responseText.trim();
    } catch (e) {
      debugPrint('Error generating budget advice: $e');
      return 'Consider balancing your crypto investments with traditional savings. Given market volatility, maintain an emergency fund covering 3-6 months of expenses in stable assets. Review your portfolio monthly and adjust based on performance and financial goals.';
    }
  }
  
  /// Analyze portfolio risk using AI
  Future<RiskAssessment> analyzeRisk() async {
    try {
      // Get portfolio data
      final portfolio = await getPortfolio([]);
      
      // If portfolio is empty, return default risk assessment
      if (portfolio.wallets.isEmpty || portfolio.totalUsdValue == 0) {
        return RiskAssessment(
          overallRisk: 50,
          riskFactors: {
            'Diversification': 50,
            'Volatility': 60,
            'Liquidity': 40,
            'Market Exposure': 50,
          },
          suggestions: [
            'Start with established cryptocurrencies like Bitcoin or Ethereum',
            'Consider dollar-cost averaging to reduce timing risk',
            'Only invest what you can afford to lose',
          ],
        );
      }
      
      // Get market data
      final marketData = await getMarketOverview();
      
      // Calculate basic risk metrics
      double diversificationRisk = 100;
      double volatilityRisk = 60;
      double liquidityRisk = 40;
      double marketExposureRisk = 50;
      
      // Diversification risk decreases with more tokens
      if (portfolio.allocation.length >= 10) {
        diversificationRisk = 20;
      } else if (portfolio.allocation.length >= 5) {
        diversificationRisk = 40;
      } else if (portfolio.allocation.length >= 3) {
        diversificationRisk = 60;
      } else if (portfolio.allocation.length == 2) {
        diversificationRisk = 80;
      }
      
      // Check for stablecoin allocation
      bool hasStablecoins = portfolio.allocation.keys.any((token) => 
        token.toLowerCase() == 'usdt' || 
        token.toLowerCase() == 'usdc' || 
        token.toLowerCase() == 'dai' || 
        token.toLowerCase() == 'busd'
      );
      
      if (hasStablecoins) {
        volatilityRisk -= 20;
      }
      
      // Check for blue-chip allocation
      bool hasBluechips = portfolio.allocation.keys.any((token) => 
        token.toLowerCase() == 'btc' || 
        token.toLowerCase() == 'eth'
      );
      
      if (hasBluechips) {
        liquidityRisk -= 10;
        marketExposureRisk -= 10;
      }
      
      // Market sentiment factor
      final fearIndex = marketData.fear['value'] as int? ?? 50;
      if (fearIndex < 25) {
        // Extreme fear - market may be oversold
        marketExposureRisk += 10;
      } else if (fearIndex > 75) {
        // Extreme greed - market may be overbought
        marketExposureRisk += 20;
      }
      
      // Calculate overall risk
      final overallRisk = (diversificationRisk + volatilityRisk + liquidityRisk + marketExposureRisk) / 4;
      
      // Generate suggestions
      List<String> suggestions = [];
      
      if (diversificationRisk > 60) {
        suggestions.add('Consider adding more variety to your portfolio to reduce concentration risk');
      }
      
      if (volatilityRisk > 60) {
        suggestions.add('Add some stablecoins to your portfolio to reduce overall volatility');
      }
      
      if (liquidityRisk > 60) {
        suggestions.add('Ensure a portion of your portfolio is in highly liquid assets like BTC or ETH');
      }
      
      if (marketExposureRisk > 60) {
        suggestions.add('The current market sentiment indicates caution - consider reducing exposure temporarily');
      }
      
      if (suggestions.isEmpty) {
        suggestions.add('Your portfolio has a balanced risk profile - maintain your current strategy');
      }
      
      return RiskAssessment(
        overallRisk: overallRisk,
        riskFactors: {
          'Diversification': diversificationRisk,
          'Volatility': volatilityRisk,
          'Liquidity': liquidityRisk,
          'Market Exposure': marketExposureRisk,
        },
        suggestions: suggestions,
      );
    } catch (e) {
      debugPrint('Error analyzing risk: $e');
      return RiskAssessment(
        overallRisk: 50,
        riskFactors: {
          'Diversification': 50,
          'Volatility': 60,
          'Liquidity': 40,
          'Market Exposure': 50,
        },
        suggestions: [
          'Maintain a diversified portfolio across different cryptocurrencies',
          'Consider having some stablecoins as a hedge against volatility',
          'Only invest what you can afford to lose in high-risk assets',
        ],
      );
    }
  }
  
  // ========== MARKET DATA ==========
  
  /// Get overall market data
  Future<MarketData> getMarketOverview() async {
    try {
      // Fetch global market data
      final response = await _withRetry(() => _httpClient.get(
        Uri.parse('${AppConfig.coingeckoApiUrl}/global'),
        headers: {'Accept': 'application/json'},
      ));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as Map<String, dynamic>;
        
        // Fetch fear & greed index
        final fearResponse = await _httpClient.get(
          Uri.parse('https://api.alternative.me/fng/'),
          headers: {'Accept': 'application/json'},
        );
        
        Map<String, dynamic> fearData = {};
        if (fearResponse.statusCode == 200) {
          final fearResult = jsonDecode(fearResponse.body);
          fearData = fearResult['data'][0] as Map<String, dynamic>;
        } else {
          fearData = {
            'value': 50,
            'value_classification': 'Neutral',
            'timestamp': DateTime.now().toString(),
          };
        }
        
        // Fetch trending coins
        final trendingResponse = await _httpClient.get(
          Uri.parse('${AppConfig.coingeckoApiUrl}/search/trending'),
          headers: {'Accept': 'application/json'},
        );
        
        Map<String, dynamic> trendingData = {};
        if (trendingResponse.statusCode == 200) {
          final trendingResult = jsonDecode(trendingResponse.body);
          trendingData = {
            'coins': (trendingResult['coins'] as List).take(5).toList(),
            'updated_at': DateTime.now().toString(),
          };
        } else {
          trendingData = {
            'coins': [],
            'updated_at': DateTime.now().toString(),
          };
        }
        
        return MarketData(
          totalMarketCap: data['total_market_cap']['usd'].toDouble(),
          totalVolume24h: data['total_volume']['usd'].toDouble(),
          btcDominance: data['market_cap_percentage']['btc'].toDouble(),
          marketCapChange24h: data['market_cap_change_percentage_24h_usd'].toDouble(),
          trending: trendingData,
          fear: fearData,
        );
      } else {
        throw Exception('Failed to fetch market data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting market overview: $e');
      return MarketData(
        totalMarketCap: 0,
        totalVolume24h: 0,
        btcDominance: 0,
        marketCapChange24h: 0,
        trending: {},
        fear: {'value': 50, 'value_classification': 'Neutral'},
      );
    }
  }
  
  /// Get price history for a token
  Future<List<PriceHistory>> getPriceHistory(String token) async {
    try {
      final results = <PriceHistory>[];
      
      // Fetch data for different time frames
      for (final timeFrame in [TimeFrame.day, TimeFrame.week, TimeFrame.month]) {
        final days = timeFrame == TimeFrame.day ? 1 : 
                    timeFrame == TimeFrame.week ? 7 : 30;
        
        final response = await _withRetry(() => _httpClient.get(
          Uri.parse('${AppConfig.coingeckoApiUrl}/coins/$token/market_chart?vs_currency=usd&days=$days'),
          headers: {'Accept': 'application/json'},
        ));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final priceData = data['prices'] as List<dynamic>;
          
          final prices = priceData.map((point) {
            final timestamp = DateTime.fromMillisecondsSinceEpoch(point[0] as int);
            final price = point[1].toDouble();
            return PricePoint(timestamp: timestamp, price: price);
          }).toList();
          
          results.add(PriceHistory(
            symbol: token,
            prices: prices,
            timeFrame: timeFrame,
          ));
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error getting price history: $e');
      return [];
    }
  }
  
  // ========== HELPER METHODS ==========
  
  /// Get wallet data with token balances
  Future<Wallet> _getWalletData(String address) async {
    try {
      // Get wallet from database
      final walletResults = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoWalletsCollection,
        queries: [Query.equal('address', address)],
      );
      
      if (walletResults.documents.isEmpty) {
        throw Exception('Wallet not found');
      }
      
      final walletDoc = walletResults.documents.first;
      final networkId = walletDoc.data['network_id'];
      final networkName = walletDoc.data['network_name'];
      
      // Fetch balances from Moralis
      final response = await _withRetry(() => _httpClient.get(
        Uri.parse('${AppConfig.moralisBaseUrl}/$address/erc20?chain=$networkId'),
        headers: AppConfig.moralisHeaders,
      ));
      
      List<TokenBalance> tokens = [];
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokenData = data as List<dynamic>;
        
        // Process each token
        for (final token in tokenData) {
          final symbol = token['symbol'] ?? 'Unknown';
          final decimals = int.parse(token['decimals'] ?? '18');
          final rawBalance = token['balance'] ?? '0';
          
          // Convert balance
          final balance = double.parse(rawBalance) / pow(10, decimals);
          
          // Get token price
          final price = await getTokenPrice(symbol);
          final usdValue = balance * price;
          
          tokens.add(TokenBalance(
            tokenAddress: token['token_address'],
            symbol: symbol,
            name: token['name'] ?? 'Unknown Token',
            logoUrl: 'https://cryptologos.cc/logos/ethereum-eth-logo.png', // Default logo
            balance: balance,
            usdValue: usdValue,
            decimals: decimals,
          ));
        }
        
        // Also fetch native token balance
        final nativeResponse = await _withRetry(() => _httpClient.get(
          Uri.parse('${AppConfig.moralisBaseUrl}/$address/balance?chain=$networkId'),
          headers: AppConfig.moralisHeaders,
        ));
        
        double nativeBalance = 0;
        
        if (nativeResponse.statusCode == 200) {
          final nativeData = jsonDecode(nativeResponse.body);
          final rawBalance = nativeData['balance'] ?? '0';
          nativeBalance = double.parse(rawBalance) / pow(10, 18);
          
          // Get native token symbol
          String nativeSymbol = 'ETH';
          if (networkName.toLowerCase() == 'binance smart chain' || 
              networkName.toLowerCase() == 'bsc') {
            nativeSymbol = 'BNB';
          } else if (networkName.toLowerCase() == 'polygon') {
            nativeSymbol = 'MATIC';
          } else if (networkName.toLowerCase() == 'avalanche') {
            nativeSymbol = 'AVAX';
          } else if (networkName.toLowerCase() == 'fantom') {
            nativeSymbol = 'FTM';
          }
          
          // Get token price
          final price = await getTokenPrice(nativeSymbol);
          final usdValue = nativeBalance * price;
          
          tokens.add(TokenBalance(
            tokenAddress: '0x0000000000000000000000000000000000000000',
            symbol: nativeSymbol,
            name: nativeSymbol,
            logoUrl: 'https://cryptologos.cc/logos/ethereum-eth-logo.png', // Default logo
            balance: nativeBalance,
            usdValue: usdValue,
            decimals: 18,
          ));
          
          // Update wallet balance in database
          await _databases.updateDocument(
            databaseId: AppConfig.databaseId,
            collectionId: _cryptoWalletsCollection,
            documentId: walletDoc.$id,
            data: {
              'balance': nativeBalance,
              'last_updated': DateTime.now().toIso8601String(),
            },
          );
        }
      }
      
      return Wallet(
        id: walletDoc.$id,
        address: address,
        networkId: networkId,
        networkName: networkName,
        label: walletDoc.data['label'] ?? 'My Wallet',
        balance: (walletDoc.data['balance'] as num?)?.toDouble() ?? 0.0,
        tokens: tokens,
        lastUpdated: DateTime.parse(walletDoc.data['last_updated']),
        isActive: walletDoc.data['is_active'] ?? true,
      );
    } catch (e) {
      debugPrint('Error getting wallet data: $e');
      return Wallet(
        id: 'error',
        address: address,
        networkId: '0x1',
        networkName: 'Ethereum',
        tokens: [],
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Start background task to update prices
  void _startPriceUpdateTask() {
    // Update prices every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _updatePopularTokenPrices();
    });
    
    // Initial update
    _updatePopularTokenPrices();
  }
  
  /// Update prices for popular tokens
  Future<void> _updatePopularTokenPrices() async {
    try {
      // Get popular tokens
      final symbols = ['BTC', 'ETH', 'USDT', 'USDC', 'BNB', 'XRP', 'ADA', 'DOGE', 'MATIC'];
      await getCurrentPrices(symbols);
    } catch (e) {
      debugPrint('Error updating popular token prices: $e');
    }
  }
  
  /// Fetch yesterday's prices for calculating portfolio change
  Future<Map<String, double>> _getPricesFromYesterday(List<String> tokens) async {
    try {
      final Map<String, double> yesterdayPrices = {};
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final formattedDate = '${yesterday.day}-${yesterday.month}-${yesterday.year}';
      
      for (final token in tokens) {
        try {
          final response = await _httpClient.get(
            Uri.parse('${AppConfig.coingeckoApiUrl}/coins/$token/history?date=$formattedDate'),
            headers: {'Accept': 'application/json'},
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final price = data['market_data']['current_price']['usd'].toDouble();
            yesterdayPrices[token] = price;
          }
        } catch (e) {
          // If error, use current price
          yesterdayPrices[token] = await getTokenPrice(token);
        }
      }
      
      return yesterdayPrices;
    } catch (e) {
      debugPrint('Error getting yesterday prices: $e');
      return {};
    }
  }
  
  /// Fetch prices from backup API if primary fails
  Future<void> _fetchPricesFromBackupApi(List<String> tokens, Map<String, double> prices) async {
    try {
      for (final symbol in tokens) {
        if (!prices.containsKey(symbol)) {
          try {
            final response = await _httpClient.get(
              Uri.parse('${AppConfig.coingeckoApiUrl}/simple/price?ids=$symbol&vs_currencies=usd'),
              headers: {'Accept': 'application/json'},
            );
            
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body) as Map<String, dynamic>;
              if (data.containsKey(symbol.toLowerCase())) {
                prices[symbol] = data[symbol.toLowerCase()]['usd'].toDouble();
                _priceCache[symbol] = prices[symbol]!;
              }
            }
          } catch (e) {
            debugPrint('Error fetching backup price for $symbol: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in backup API: $e');
    }
  }
  
  /// Default budget category based on transaction type
  String _determineBudgetCategory(TransactionType type, double value, String symbol) {
    switch (type) {
      case TransactionType.send:
        return 'Investment';
      case TransactionType.receive:
        return 'Income';
      case TransactionType.swap:
        return 'Trading';
      case TransactionType.approve:
        return 'Fees';
      case TransactionType.stake:
        return 'Investment';
      case TransactionType.unstake:
        return 'Income';
      case TransactionType.claim:
        return 'Income';
      default:
        return 'Crypto';
    }
  }
  
  /// Default insights for new users
  List<AIInsight> _getDefaultInsights() {
    return [
      AIInsight(
        id: ID.unique(),
        title: 'Start Your Crypto Journey',
        description: 'Begin by adding your wallet addresses to track your crypto assets. Consider starting with established coins like Bitcoin or Ethereum.',
        type: AIInsightType.education,
        timestamp: DateTime.now(),
      ),
      AIInsight(
        id: ID.unique(),
        title: 'Set Up Dollar-Cost Averaging',
        description: 'Consider setting up regular small purchases of crypto to reduce the impact of volatility on your overall purchase price.',
        type: AIInsightType.recommendation,
        timestamp: DateTime.now(),
      ),
      AIInsight(
        id: ID.unique(),
        title: 'Learn About Crypto Security',
        description: 'Secure your crypto by using hardware wallets, enabling two-factor authentication, and never sharing your private keys.',
        type: AIInsightType.risk,
        timestamp: DateTime.now(),
      ),
    ];
  }
  
  /// Parse AI insight type from string
  AIInsightType _parseAIInsightType(String type) {
    switch (type.toLowerCase()) {
      case 'recommendation':
        return AIInsightType.recommendation;
      case 'alert':
        return AIInsightType.alert;
      case 'opportunity':
        return AIInsightType.opportunity;
      case 'risk':
        return AIInsightType.risk;
      case 'education':
        return AIInsightType.education;
      case 'budget':
        return AIInsightType.budget;
      default:
        return AIInsightType.general;
    }
  }
  
  /// Retry mechanism for API calls
  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        return await fn();
      } catch (e) {
        attempts++;
        if (attempts >= _maxRetries) {
          rethrow;
        }
        // Exponential backoff
        final delay = _baseRetryDelay.inMilliseconds * pow(2, attempts - 1).toInt();
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
    throw Exception('Max retry attempts reached');
  }
}