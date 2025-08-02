import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:appwrite/appwrite.dart';
import 'dart:async';

import '../config/app_config.dart';
import 'package:dailydime/models/crypto_models.dart';

/// Repository class for handling cryptocurrency data persistence
class CryptoRepository {
  // Appwrite client
  final Databases _databases;
  final String _userId;
  
  // Hive boxes for local caching
  late Box<CryptoWallet> _walletsBox;
  late Box<CryptoTransaction> _transactionsBox;
  late Box<TokenPrice> _pricesBox;
  late Box<PriceHistory> _historyBox;
  late Box<DeFiPosition> _defiPositionsBox;
  late Box<NFTAsset> _nftAssetsBox;
  late Box<Portfolio> _portfolioBox;
  late Box<Insight> _insightsBox;
  late Box<BudgetSuggestion> _suggestionsBox;
  late Box<RiskAssessment> _riskAssessmentBox;

  // Collection constants from config
  final String _cryptoWalletsCollection;
  final String _cryptoTransactionsCollection;
  final String _cryptoPricesCollection;
  final String _cryptoPortfolioCollection;
  final String _cryptoInsightsCollection;
  final String _cryptoDefiPositionsCollection;
  final String _cryptoNftAssetsCollection;

  final Uuid _uuid = const Uuid();
  
  CryptoRepository({
    required Databases databases,
    required String userId,
    required String cryptoWalletsCollection,
    required String cryptoTransactionsCollection,
    required String cryptoPricesCollection,
    required String cryptoPortfolioCollection,
    required String cryptoInsightsCollection,
    required String cryptoDefiPositionsCollection,
    required String cryptoNftAssetsCollection,
  }) : 
    _databases = databases,
    _userId = userId,
    _cryptoWalletsCollection = cryptoWalletsCollection,
    _cryptoTransactionsCollection = cryptoTransactionsCollection,
    _cryptoPricesCollection = cryptoPricesCollection,
    _cryptoPortfolioCollection = cryptoPortfolioCollection,
    _cryptoInsightsCollection = cryptoInsightsCollection,
    _cryptoDefiPositionsCollection = cryptoDefiPositionsCollection,
    _cryptoNftAssetsCollection = cryptoNftAssetsCollection;
  
  /// Initialize all Hive boxes
  Future<void> init() async {
    _walletsBox = await Hive.openBox<CryptoWallet>('crypto_wallets');
    _transactionsBox = await Hive.openBox<CryptoTransaction>('crypto_transactions');
    _pricesBox = await Hive.openBox<TokenPrice>('crypto_prices');
    _historyBox = await Hive.openBox<PriceHistory>('crypto_price_history');
    _defiPositionsBox = await Hive.openBox<DeFiPosition>('crypto_defi_positions');
    _nftAssetsBox = await Hive.openBox<NFTAsset>('crypto_nft_assets');
    _portfolioBox = await Hive.openBox<Portfolio>('crypto_portfolio');
    _insightsBox = await Hive.openBox<Insight>('crypto_insights');
    _suggestionsBox = await Hive.openBox<BudgetSuggestion>('crypto_budget_suggestions');
    _riskAssessmentBox = await Hive.openBox<RiskAssessment>('crypto_risk_assessment');
  }

  // ==========================================================================
  // WALLET OPERATIONS
  // ==========================================================================
  
  /// Get all wallets for the current user
  Future<List<CryptoWallet>> getWallets() async {
    try {
      // First try to get from cache
      final cachedWallets = _walletsBox.values.toList();
      if (cachedWallets.isNotEmpty) {
        return cachedWallets;
      }
      
      // Otherwise fetch from Appwrite
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoWalletsCollection,
        queries: [
          Query.equal('userId', _userId),
          Query.equal('isActive', true),
        ],
      );
      
      final wallets = response.documents.map((doc) {
        return CryptoWallet(
          id: doc.$id,
          address: doc.data['address'],
          network: doc.data['network'],
          name: doc.data['name'],
          userId: doc.data['userId'],
          tokens: (doc.data['tokens'] as List<dynamic>).map((token) {
            return TokenBalance(
              token: token['token'],
              tokenAddress: token['tokenAddress'],
              symbol: token['symbol'],
              balance: token['balance'].toDouble(),
              valueUsd: token['valueUsd'].toDouble(),
              decimals: token['decimals'],
              logoUrl: token['logoUrl'],
            );
          }).toList(),
          totalValue: doc.data['totalValue'].toDouble(),
          lastUpdated: DateTime.parse(doc.data['lastUpdated']),
          isActive: doc.data['isActive'],
        );
      }).toList();
      
      // Cache the wallets
      await _walletsBox.clear();
      for (final wallet in wallets) {
        await _walletsBox.put(wallet.id, wallet);
      }
      
      return wallets;
    } catch (e) {
      // On error, return cached data if available
      final cachedWallets = _walletsBox.values.toList();
      if (cachedWallets.isNotEmpty) {
        return cachedWallets;
      }
      
      rethrow;
    }
  }
  
  /// Add a new wallet
  Future<CryptoWallet> addWallet({
    required String address,
    required String network,
    String? name,
  }) async {
    try {
      // Validate the wallet doesn't already exist
      final existingWallets = await getWallets();
      final exists = existingWallets.any((w) => 
        w.address.toLowerCase() == address.toLowerCase() && 
        w.network == network
      );
      
      if (exists) {
        throw Exception('Wallet already exists');
      }
      
      // Create wallet in Appwrite
      final response = await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoWalletsCollection,
        documentId: 'unique()',
        data: {
          'address': address,
          'network': network,
          'name': name ?? 'Wallet ${existingWallets.length + 1}',
          'userId': _userId,
          'tokens': [],
          'totalValue': 0.0,
          'lastUpdated': DateTime.now().toIso8601String(),
          'isActive': true,
        },
      );
      
      // Create wallet object
      final wallet = CryptoWallet(
        id: response.$id,
        address: address,
        network: network,
        name: name ?? 'Wallet ${existingWallets.length + 1}',
        userId: _userId,
        tokens: [],
        totalValue: 0.0,
        lastUpdated: DateTime.now(),
        isActive: true,
      );
      
      // Update cache
      await _walletsBox.put(wallet.id, wallet);
      
      return wallet;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update wallet
  Future<CryptoWallet> updateWallet(CryptoWallet wallet) async {
    try {
      // Update in Appwrite
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoWalletsCollection,
        documentId: wallet.id,
        data: wallet.toJson(),
      );
      
      // Update cache
      await _walletsBox.put(wallet.id, wallet);
      
      return wallet;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Delete wallet (soft delete by setting isActive to false)
  Future<void> deleteWallet(String walletId) async {
    try {
      // Get wallet
      final wallet = _walletsBox.get(walletId);
      if (wallet == null) {
        throw Exception('Wallet not found');
      }
      
      // Update in Appwrite
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoWalletsCollection,
        documentId: walletId,
        data: {'isActive': false},
      );
      
      // Update cache
      final updatedWallet = wallet.copyWith(isActive: false);
      await _walletsBox.put(walletId, updatedWallet);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================================
  // TRANSACTION OPERATIONS
  // ==========================================================================
  
  /// Get transactions for a specific wallet
  Future<List<CryptoTransaction>> getWalletTransactions(String walletAddress, {int limit = 50}) async {
    try {
      // First try to get from cache
      final allTransactions = _transactionsBox.values.toList();
      final walletTransactions = allTransactions
          .where((tx) => 
              tx.from.toLowerCase() == walletAddress.toLowerCase() || 
              tx.to.toLowerCase() == walletAddress.toLowerCase())
          .toList();
      
      if (walletTransactions.isNotEmpty) {
        // Sort by timestamp, most recent first
        walletTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return walletTransactions.take(limit).toList();
      }
      
      // Otherwise fetch from Appwrite
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoTransactionsCollection,
        queries: [
          Query.equal('userId', _userId),
          Query.orQueries([
            Query.equal('from', walletAddress.toLowerCase()),
            Query.equal('to', walletAddress.toLowerCase()),
          ]),
          Query.orderDesc('timestamp'),
          Query.limit(limit),
        ],
      );
      
      final transactions = response.documents.map((doc) {
        return CryptoTransaction(
          id: doc.$id,
          hash: doc.data['hash'],
          network: doc.data['network'],
          from: doc.data['from'],
          to: doc.data['to'],
          token: doc.data['token'],
          tokenAddress: doc.data['tokenAddress'],
          symbol: doc.data['symbol'],
          amount: doc.data['amount'].toDouble(),
          valueUsd: doc.data['valueUsd'].toDouble(),
          timestamp: DateTime.parse(doc.data['timestamp']),
          type: TransactionType.values.firstWhere(
            (e) => e.toString().split('.').last == doc.data['type'],
            orElse: () => TransactionType.unknown,
          ),
          gasFee: doc.data['gasFee'].toDouble(),
          gasFeeUsd: doc.data['gasFeeUsd'].toDouble(),
          userId: doc.data['userId'],
          isSynced: doc.data['isSynced'] ?? false,
          appwriteId: doc.data['appwriteId'],
          budgetCategory: doc.data['budgetCategory'],
          notes: doc.data['notes'],
        );
      }).toList();
      
      // Cache the transactions
      for (final tx in transactions) {
        await _transactionsBox.put(tx.id, tx);
      }
      
      return transactions;
    } catch (e) {
      // On error, return cached data if available
      final allTransactions = _transactionsBox.values.toList();
      final walletTransactions = allTransactions
          .where((tx) => 
              tx.from.toLowerCase() == walletAddress.toLowerCase() || 
              tx.to.toLowerCase() == walletAddress.toLowerCase())
          .toList();
      
      if (walletTransactions.isNotEmpty) {
        walletTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return walletTransactions.take(limit).toList();
      }
      
      rethrow;
    }
  }
  
  /// Get all user transactions
  Future<List<CryptoTransaction>> getAllTransactions({int limit = 100}) async {
    try {
      // First try to get from cache
      final cachedTransactions = _transactionsBox.values.toList();
      if (cachedTransactions.isNotEmpty) {
        // Sort by timestamp, most recent first
        cachedTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return cachedTransactions.take(limit).toList();
      }
      
      // Otherwise fetch from Appwrite
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoTransactionsCollection,
        queries: [
          Query.equal('userId', _userId),
          Query.orderDesc('timestamp'),
          Query.limit(limit),
        ],
      );
      
      final transactions = response.documents.map((doc) {
        return CryptoTransaction(
          id: doc.$id,
          hash: doc.data['hash'],
          network: doc.data['network'],
          from: doc.data['from'],
          to: doc.data['to'],
          token: doc.data['token'],
          tokenAddress: doc.data['tokenAddress'],
          symbol: doc.data['symbol'],
          amount: doc.data['amount'].toDouble(),
          valueUsd: doc.data['valueUsd'].toDouble(),
          timestamp: DateTime.parse(doc.data['timestamp']),
          type: TransactionType.values.firstWhere(
            (e) => e.toString().split('.').last == doc.data['type'],
            orElse: () => TransactionType.unknown,
          ),
          gasFee: doc.data['gasFee'].toDouble(),
          gasFeeUsd: doc.data['gasFeeUsd'].toDouble(),
          userId: doc.data['userId'],
          isSynced: doc.data['isSynced'] ?? false,
          appwriteId: doc.data['appwriteId'],
          budgetCategory: doc.data['budgetCategory'],
          notes: doc.data['notes'],
        );
      }).toList();
      
      // Cache the transactions
      await _transactionsBox.clear();
      for (final tx in transactions) {
        await _transactionsBox.put(tx.id, tx);
      }
      
      return transactions;
    } catch (e) {
      // On error, return cached data if available
      final cachedTransactions = _transactionsBox.values.toList();
      if (cachedTransactions.isNotEmpty) {
        cachedTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return cachedTransactions.take(limit).toList();
      }
      
      rethrow;
    }
  }
  
  /// Save a new transaction
  Future<CryptoTransaction> saveTransaction(CryptoTransaction transaction) async {
    try {
      // Create in Appwrite
      final response = await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoTransactionsCollection,
        documentId: transaction.id,
        data: transaction.toJson(),
      );
      
      // Create transaction object
      final tx = CryptoTransaction(
        id: response.$id,
        hash: transaction.hash,
        network: transaction.network,
        from: transaction.from,
        to: transaction.to,
        token: transaction.token,
        tokenAddress: transaction.tokenAddress,
        symbol: transaction.symbol,
        amount: transaction.amount,
        valueUsd: transaction.valueUsd,
        timestamp: transaction.timestamp,
        type: transaction.type,
        gasFee: transaction.gasFee,
        gasFeeUsd: transaction.gasFeeUsd,
        userId: transaction.userId,
        isSynced: transaction.isSynced,
        appwriteId: transaction.appwriteId,
        budgetCategory: transaction.budgetCategory,
        notes: transaction.notes,
      );
      
      // Update cache
      await _transactionsBox.put(tx.id, tx);
      
      return tx;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update a transaction
  Future<CryptoTransaction> updateTransaction(CryptoTransaction transaction) async {
    try {
      // Update in Appwrite
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoTransactionsCollection,
        documentId: transaction.id,
        data: transaction.toJson(),
      );
      
      // Update cache
      await _transactionsBox.put(transaction.id, transaction);
      
      return transaction;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Add transaction with Appwrite budget app integration
  Future<CryptoTransaction> addTransactionWithBudgetIntegration({
    required CryptoTransaction transaction, 
    required String appwriteTransactionId
  }) async {
    try {
      // Update the transaction with Appwrite integration info
      final updatedTransaction = transaction.copyWith(
        isSynced: true,
        appwriteId: appwriteTransactionId,
      );
      
      return await updateTransaction(updatedTransaction);
    } catch (e) {
      rethrow;
    }
  }
  
  // ==========================================================================
  // PRICE OPERATIONS
  // ==========================================================================
  
  /// Save token price to local cache
  Future<void> cacheTokenPrice(TokenPrice price) async {
    await _pricesBox.put(price.token, price);
  }
  
  /// Get token price from local cache
  TokenPrice? getCachedTokenPrice(String token) {
    return _pricesBox.get(token);
  }
  
  /// Save multiple token prices to local cache
  Future<void> cacheTokenPrices(List<TokenPrice> prices) async {
    for (final price in prices) {
      await _pricesBox.put(price.token, price);
    }
  }
  
  /// Get all cached token prices
  List<TokenPrice> getAllCachedPrices() {
    return _pricesBox.values.toList();
  }
  
  /// Save price history to local cache
  Future<void> cachePriceHistory(PriceHistory history) async {
    final key = '${history.token}_${history.interval}';
    await _historyBox.put(key, history);
  }
  
  /// Get price history from local cache
  PriceHistory? getCachedPriceHistory(String token, String interval) {
    final key = '${token}_$interval';
    return _historyBox.get(key);
  }
  
  // ==========================================================================
  // PORTFOLIO OPERATIONS
  // ==========================================================================
  
  /// Save portfolio to both Appwrite and local cache
  Future<void> savePortfolio(Portfolio portfolio) async {
    try {
      // Convert portfolio to JSON for Appwrite
      final portfolioData = {
        'userId': _userId,
        'totalValue': portfolio.totalValue,
        'assetAllocation': portfolio.assetAllocation,
        'percentChange24h': portfolio.percentChange24h,
        'lastUpdated': portfolio.lastUpdated.toIso8601String(),
        // We don't save wallets here because they're in their own collection
      };
      
      // Check if portfolio document exists
      try {
        final existing = await _databases.listDocuments(
          databaseId: AppConfig.databaseId,
          collectionId: _cryptoPortfolioCollection,
          queries: [Query.equal('userId', _userId)],
        );
        
        if (existing.documents.isNotEmpty) {
          // Update existing
          await _databases.updateDocument(
            databaseId: AppConfig.databaseId,
            collectionId: _cryptoPortfolioCollection,
            documentId: existing.documents.first.$id,
            data: portfolioData,
          );
        } else {
          // Create new
          await _databases.createDocument(
            databaseId: AppConfig.databaseId,
            collectionId: _cryptoPortfolioCollection,
            documentId: 'unique()',
            data: portfolioData,
          );
        }
      } catch (e) {
        // Create new if error (likely doesn't exist)
        await _databases.createDocument(
          databaseId: AppConfig.databaseId,
          collectionId: _cryptoPortfolioCollection,
          documentId: 'unique()',
          data: portfolioData,
        );
      }
      
      // Save to local cache
      await _portfolioBox.put('current_portfolio', portfolio);
    } catch (e) {
      // At least try to cache locally if Appwrite fails
      await _portfolioBox.put('current_portfolio', portfolio);
      rethrow;
    }
  }
  
  /// Get the current portfolio from cache or Appwrite
  Future<Portfolio?> getPortfolio() async {
    try {
      // First try to get from cache
      final cachedPortfolio = _portfolioBox.get('current_portfolio');
      
      // Check if cache is recent enough (less than 5 minutes old)
      if (cachedPortfolio != null) {
        final cacheAge = DateTime.now().difference(cachedPortfolio.lastUpdated);
        if (cacheAge < AppConfig.cacheRefreshInterval) {
          return cachedPortfolio;
        }
      }
      
      // Get wallets
      final wallets = await getWallets();
      
      // Get portfolio summary from Appwrite
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoPortfolioCollection,
        queries: [Query.equal('userId', _userId)],
      );
      
      if (response.documents.isEmpty) {
        // Return cached portfolio if available
        return cachedPortfolio;
      }
      
      final doc = response.documents.first;
      
      // Create portfolio object
      final portfolio = Portfolio(
        wallets: wallets,
        totalValue: doc.data['totalValue'].toDouble(),
        assetAllocation: Map<String, double>.from(doc.data['assetAllocation']),
        percentChange24h: doc.data['percentChange24h'].toDouble(),
        lastUpdated: DateTime.parse(doc.data['lastUpdated']),
      );
      
      // Update cache
      await _portfolioBox.put('current_portfolio', portfolio);
      
      return portfolio;
    } catch (e) {
      // Return cached portfolio if available
      return _portfolioBox.get('current_portfolio');
    }
  }
  
  // ==========================================================================
  // DEFI POSITION OPERATIONS
  // ==========================================================================
  
  /// Get all DeFi positions
  Future<List<DeFiPosition>> getDefiPositions() async {
    try {
      // First try to get from cache
      final cachedPositions = _defiPositionsBox.values.toList();
      if (cachedPositions.isNotEmpty) {
        return cachedPositions;
      }
      
      // Otherwise fetch from Appwrite
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoDefiPositionsCollection,
        queries: [
          Query.equal('userId', _userId),
        ],
      );
      
      final positions = response.documents.map((doc) {
        return DeFiPosition(
          id: doc.$id,
          protocol: doc.data['protocol'],
          positionType: doc.data['positionType'],
          asset: doc.data['asset'],
          amount: doc.data['amount'].toDouble(),
          valueUsd: doc.data['valueUsd'].toDouble(),
          apr: doc.data['apr'].toDouble(),
          earned: doc.data['earned'].toDouble(),
          earnedUsd: doc.data['earnedUsd'].toDouble(),
          startDate: DateTime.parse(doc.data['startDate']),
          endDate: doc.data['endDate'] != null 
              ? DateTime.parse(doc.data['endDate']) 
              : null,
          walletAddress: doc.data['walletAddress'],
          network: doc.data['network'],
          userId: doc.data['userId'],
          lastUpdated: DateTime.parse(doc.data['lastUpdated']),
        );
      }).toList();
      
      // Cache the positions
      await _defiPositionsBox.clear();
      for (final position in positions) {
        await _defiPositionsBox.put(position.id, position);
      }
      
      return positions;
    } catch (e) {
      // On error, return cached data if available
      final cachedPositions = _defiPositionsBox.values.toList();
      if (cachedPositions.isNotEmpty) {
        return cachedPositions;
      }
      
      rethrow;
    }
  }
  
  /// Save a DeFi position
  Future<DeFiPosition> saveDeFiPosition(DeFiPosition position) async {
    try {
      // Create in Appwrite
      final response = await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoDefiPositionsCollection,
        documentId: position.id,
        data: position.toJson(),
      );
      
      // Create position object
      final savedPosition = DeFiPosition(
        id: response.$id,
        protocol: position.protocol,
        positionType: position.positionType,
        asset: position.asset,
        amount: position.amount,
        valueUsd: position.valueUsd,
        apr: position.apr,
        earned: position.earned,
        earnedUsd: position.earnedUsd,
        startDate: position.startDate,
        endDate: position.endDate,
        walletAddress: position.walletAddress,
        network: position.network,
        userId: position.userId,
        lastUpdated: position.lastUpdated,
      );
      
      // Update cache
      await _defiPositionsBox.put(savedPosition.id, savedPosition);
      
      return savedPosition;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update a DeFi position
  Future<DeFiPosition> updateDeFiPosition(DeFiPosition position) async {
    try {
      // Update in Appwrite
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoDefiPositionsCollection,
        documentId: position.id,
        data: position.toJson(),
      );
      
      // Update cache
      await _defiPositionsBox.put(position.id, position);
      
      return position;
    } catch (e) {
      rethrow;
    }
  }
  
  // ==========================================================================
  // NFT ASSET OPERATIONS
  // ==========================================================================
  
  /// Get all NFT assets
  Future<List<NFTAsset>> getNftAssets() async {
    try {
      // First try to get from cache
      final cachedAssets = _nftAssetsBox.values.toList();
      if (cachedAssets.isNotEmpty) {
        return cachedAssets;
      }
      
      // Otherwise fetch from Appwrite
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoNftAssetsCollection,
        queries: [
          Query.equal('userId', _userId),
        ],
      );
      
      final assets = response.documents.map((doc) {
        return NFTAsset(
          id: doc.$id,
          contractAddress: doc.data['contractAddress'],
          tokenId: doc.data['tokenId'],
          name: doc.data['name'],
          description: doc.data['description'],
          collection: doc.data['collection'],
          imageUrl: doc.data['imageUrl'],
          lastPrice: doc.data['lastPrice']?.toDouble(),
          floorPrice: doc.data['floorPrice']?.toDouble(),
          network: doc.data['network'],
          walletAddress: doc.data['walletAddress'],
          userId: doc.data['userId'],
          acquiredDate: DateTime.parse(doc.data['acquiredDate']),
          lastUpdated: DateTime.parse(doc.data['lastUpdated']),
        );
      }).toList();
      
      // Cache the assets
      await _nftAssetsBox.clear();
      for (final asset in assets) {
        await _nftAssetsBox.put(asset.id, asset);
      }
      
      return assets;
    } catch (e) {
      // On error, return cached data if available
      final cachedAssets = _nftAssetsBox.values.toList();
      if (cachedAssets.isNotEmpty) {
        return cachedAssets;
      }
      
      rethrow;
    }
  }
  
  /// Save an NFT asset
  Future<NFTAsset> saveNftAsset(NFTAsset asset) async {
    try {
      // Create in Appwrite
      final response = await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoNftAssetsCollection,
        documentId: asset.id,
        data: asset.toJson(),
      );
      
      // Create asset object
      final savedAsset = NFTAsset(
        id: response.$id,
        contractAddress: asset.contractAddress,
        tokenId: asset.tokenId,
        name: asset.name,
        description: asset.description,
        collection: asset.collection,
        imageUrl: asset.imageUrl,
        lastPrice: asset.lastPrice,
        floorPrice: asset.floorPrice,
        network: asset.network,
        walletAddress: asset.walletAddress,
        userId: asset.userId,
        acquiredDate: asset.acquiredDate,
        lastUpdated: asset.lastUpdated,
      );
      
      // Update cache
      await _nftAssetsBox.put(savedAsset.id, savedAsset);
      
      return savedAsset;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update an NFT asset
  Future<NFTAsset> updateNftAsset(NFTAsset asset) async {
    try {
      // Update in Appwrite
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoNftAssetsCollection,
        documentId: asset.id,
        data: asset.toJson(),
      );
      
      // Update cache
      await _nftAssetsBox.put(asset.id, asset);
      
      return asset;
    } catch (e) {
      rethrow;
    }
  }
  
  // ==========================================================================
  // AI INSIGHTS OPERATIONS
  // ==========================================================================
  
  /// Save an insight
  Future<Insight> saveInsight(Insight insight) async {
    try {
      // Create in Appwrite
      final response = await _databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoInsightsCollection,
        documentId: insight.id,
        data: insight.toJson(),
      );
      
      // Create insight object
      final savedInsight = Insight(
        id: response.$id,
        title: insight.title,
        description: insight.description,
        type: insight.type,
        assetReference: insight.assetReference,
        impactValue: insight.impactValue,
        generated: insight.generated,
        isRead: insight.isRead,
      );
      
      // Update cache
      await _insightsBox.put(savedInsight.id, savedInsight);
      
      return savedInsight;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get all insights
  Future<List<Insight>> getInsights() async {
    try {
      // First try to get from cache
      final cachedInsights = _insightsBox.values.toList();
      if (cachedInsights.isNotEmpty) {
        return cachedInsights;
      }
      
      // Otherwise fetch from Appwrite
      final response = await _databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoInsightsCollection,
        queries: [
          Query.orderDesc('generated'),
          Query.limit(50),
        ],
      );
      
      final insights = response.documents.map((doc) {
        return Insight(
          id: doc.$id,
          title: doc.data['title'],
          description: doc.data['description'],
          type: InsightType.values.firstWhere(
            (e) => e.toString().split('.').last == doc.data['type'],
            orElse: () => InsightType.marketTrend,
          ),
          assetReference: doc.data['assetReference'],
          impactValue: doc.data['impactValue']?.toDouble(),
          generated: DateTime.parse(doc.data['generated']),
          isRead: doc.data['isRead'] ?? false,
        );
      }).toList();
      
      // Cache the insights
      await _insightsBox.clear();
      for (final insight in insights) {
        await _insightsBox.put(insight.id, insight);
      }
      
      return insights;
    } catch (e) {
      // On error, return cached data if available
      final cachedInsights = _insightsBox.values.toList();
      if (cachedInsights.isNotEmpty) {
        return cachedInsights;
      }
      
      rethrow;
    }
  }
  
  /// Mark an insight as read
  Future<Insight> markInsightAsRead(String insightId) async {
    try {
      // Get insight
      final insight = _insightsBox.get(insightId);
      if (insight == null) {
        throw Exception('Insight not found');
      }
      
      // Update in Appwrite
      await _databases.updateDocument(
        databaseId: AppConfig.databaseId,
        collectionId: _cryptoInsightsCollection,
        documentId: insightId,
        data: {'isRead': true},
      );
      
      // Update cache
      final updatedInsight = insight.copyWith(isRead: true);
      await _insightsBox.put(insightId, updatedInsight);
      
      return updatedInsight;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Save a budget suggestion
  Future<void> saveBudgetSuggestion(BudgetSuggestion suggestion) async {
    await _suggestionsBox.put(suggestion.id, suggestion);
  }
  
  /// Get all budget suggestions
  List<BudgetSuggestion> getBudgetSuggestions() {
    return _suggestionsBox.values.toList();
  }
  
  /// Save a risk assessment
  Future<void> saveRiskAssessment(RiskAssessment assessment) async {
    await _riskAssessmentBox.put(assessment.id, assessment);
  }
  
  /// Get the latest risk assessment
  RiskAssessment? getLatestRiskAssessment() {
    final assessments = _riskAssessmentBox.values.toList();
    if (assessments.isEmpty) return null;
    
    // Sort by generated timestamp, most recent first
    assessments.sort((a, b) => b.generated.compareTo(a.generated));
    return assessments.first;
  }
  
  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================
  
  /// Generate a new unique ID
  String generateId() {
    return _uuid.v4();
  }
  
  /// Clear all cached data
  Future<void> clearCache() async {
    await _walletsBox.clear();
    await _transactionsBox.clear();
    await _pricesBox.clear();
    await _historyBox.clear();
    await _defiPositionsBox.clear();
    await _nftAssetsBox.clear();
    await _portfolioBox.clear();
    await _insightsBox.clear();
    await _suggestionsBox.clear();
    await _riskAssessmentBox.clear();
  }
}