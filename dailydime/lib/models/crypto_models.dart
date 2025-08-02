import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'crypto_models.g.dart';

/// Represents a cryptocurrency portfolio containing all wallet and asset data
@JsonSerializable()
@HiveType(typeId: 10)
class Portfolio extends Equatable {
  @HiveField(0)
  final List<CryptoWallet> wallets;
  
  @HiveField(1)
  final double totalValue;
  
  @HiveField(2)
  final Map<String, double> assetAllocation;
  
  @HiveField(3)
  final double percentChange24h;
  
  @HiveField(4)
  final DateTime lastUpdated;

  const Portfolio({
    required this.wallets,
    required this.totalValue,
    required this.assetAllocation,
    required this.percentChange24h,
    required this.lastUpdated,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) => _$PortfolioFromJson(json);
  Map<String, dynamic> toJson() => _$PortfolioToJson(this);

  Portfolio copyWith({
    List<CryptoWallet>? wallets,
    double? totalValue,
    Map<String, double>? assetAllocation,
    double? percentChange24h,
    DateTime? lastUpdated,
  }) {
    return Portfolio(
      wallets: wallets ?? this.wallets,
      totalValue: totalValue ?? this.totalValue,
      assetAllocation: assetAllocation ?? this.assetAllocation,
      percentChange24h: percentChange24h ?? this.percentChange24h,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [wallets, totalValue, assetAllocation, percentChange24h, lastUpdated];
}

/// Represents a cryptocurrency wallet on a specific blockchain
@JsonSerializable()
@HiveType(typeId: 11)
class CryptoWallet extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String address;
  
  @HiveField(2)
  final String network;
  
  @HiveField(3)
  final String? name;
  
  @HiveField(4)
  final String userId;
  
  @HiveField(5)
  final List<TokenBalance> tokens;
  
  @HiveField(6)
  final double totalValue;
  
  @HiveField(7)
  final DateTime lastUpdated;
  
  @HiveField(8)
  final bool isActive;

  const CryptoWallet({
    required this.id,
    required this.address,
    required this.network,
    this.name,
    required this.userId,
    required this.tokens,
    required this.totalValue,
    required this.lastUpdated,
    this.isActive = true,
  });

  factory CryptoWallet.fromJson(Map<String, dynamic> json) => _$CryptoWalletFromJson(json);
  Map<String, dynamic> toJson() => _$CryptoWalletToJson(this);

  CryptoWallet copyWith({
    String? id,
    String? address,
    String? network,
    String? name,
    String? userId,
    List<TokenBalance>? tokens,
    double? totalValue,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return CryptoWallet(
      id: id ?? this.id,
      address: address ?? this.address,
      network: network ?? this.network,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      tokens: tokens ?? this.tokens,
      totalValue: totalValue ?? this.totalValue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, address, network, name, userId, tokens, totalValue, lastUpdated, isActive];
}

/// Represents a token balance within a wallet
@JsonSerializable()
@HiveType(typeId: 12)
class TokenBalance extends Equatable {
  @HiveField(0)
  final String token;
  
  @HiveField(1)
  final String tokenAddress;
  
  @HiveField(2)
  final String symbol;
  
  @HiveField(3)
  final double balance;
  
  @HiveField(4)
  final double valueUsd;
  
  @HiveField(5)
  final int decimals;
  
  @HiveField(6)
  final String? logoUrl;

  const TokenBalance({
    required this.token,
    required this.tokenAddress,
    required this.symbol,
    required this.balance,
    required this.valueUsd,
    required this.decimals,
    this.logoUrl,
  });

  factory TokenBalance.fromJson(Map<String, dynamic> json) => _$TokenBalanceFromJson(json);
  Map<String, dynamic> toJson() => _$TokenBalanceToJson(this);

  TokenBalance copyWith({
    String? token,
    String? tokenAddress,
    String? symbol,
    double? balance,
    double? valueUsd,
    int? decimals,
    String? logoUrl,
  }) {
    return TokenBalance(
      token: token ?? this.token,
      tokenAddress: tokenAddress ?? this.tokenAddress,
      symbol: symbol ?? this.symbol,
      balance: balance ?? this.balance,
      valueUsd: valueUsd ?? this.valueUsd,
      decimals: decimals ?? this.decimals,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  @override
  List<Object?> get props => [token, tokenAddress, symbol, balance, valueUsd, decimals, logoUrl];
}

/// Represents a cryptocurrency transaction
@JsonSerializable()
@HiveType(typeId: 13)
class CryptoTransaction extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String hash;
  
  @HiveField(2)
  final String network;
  
  @HiveField(3)
  final String from;
  
  @HiveField(4)
  final String to;
  
  @HiveField(5)
  final String token;
  
  @HiveField(6)
  final String tokenAddress;
  
  @HiveField(7)
  final String symbol;
  
  @HiveField(8)
  final double amount;
  
  @HiveField(9)
  final double valueUsd;
  
  @HiveField(10)
  final DateTime timestamp;
  
  @HiveField(11)
  final TransactionType type;
  
  @HiveField(12)
  final double gasFee;
  
  @HiveField(13)
  final double gasFeeUsd;
  
  @HiveField(14)
  final String userId;
  
  @HiveField(15)
  final bool isSynced;
  
  @HiveField(16)
  final String? appwriteId;
  
  @HiveField(17)
  final String? budgetCategory;
  
  @HiveField(18)
  final String? notes;

  const CryptoTransaction({
    required this.id,
    required this.hash,
    required this.network,
    required this.from,
    required this.to,
    required this.token,
    required this.tokenAddress,
    required this.symbol,
    required this.amount,
    required this.valueUsd,
    required this.timestamp,
    required this.type,
    required this.gasFee,
    required this.gasFeeUsd,
    required this.userId,
    this.isSynced = false,
    this.appwriteId,
    this.budgetCategory,
    this.notes,
  });

  factory CryptoTransaction.fromJson(Map<String, dynamic> json) => _$CryptoTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$CryptoTransactionToJson(this);

  CryptoTransaction copyWith({
    String? id,
    String? hash,
    String? network,
    String? from,
    String? to,
    String? token,
    String? tokenAddress,
    String? symbol,
    double? amount,
    double? valueUsd,
    DateTime? timestamp,
    TransactionType? type,
    double? gasFee,
    double? gasFeeUsd,
    String? userId,
    bool? isSynced,
    String? appwriteId,
    String? budgetCategory,
    String? notes,
  }) {
    return CryptoTransaction(
      id: id ?? this.id,
      hash: hash ?? this.hash,
      network: network ?? this.network,
      from: from ?? this.from,
      to: to ?? this.to,
      token: token ?? this.token,
      tokenAddress: tokenAddress ?? this.tokenAddress,
      symbol: symbol ?? this.symbol,
      amount: amount ?? this.amount,
      valueUsd: valueUsd ?? this.valueUsd,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      gasFee: gasFee ?? this.gasFee,
      gasFeeUsd: gasFeeUsd ?? this.gasFeeUsd,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
      appwriteId: appwriteId ?? this.appwriteId,
      budgetCategory: budgetCategory ?? this.budgetCategory,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id, hash, network, from, to, token, tokenAddress, symbol,
    amount, valueUsd, timestamp, type, gasFee, gasFeeUsd,
    userId, isSynced, appwriteId, budgetCategory, notes,
  ];
}

/// Enum representing the type of cryptocurrency transaction
@JsonEnum()
@HiveType(typeId: 14)
enum TransactionType {
  @JsonValue('send')
  @HiveField(0)
  send,
  
  @JsonValue('receive')
  @HiveField(1)
  receive,
  
  @JsonValue('swap')
  @HiveField(2)
  swap,
  
  @JsonValue('stake')
  @HiveField(3)
  stake,
  
  @JsonValue('unstake')
  @HiveField(4)
  unstake,
  
  @JsonValue('reward')
  @HiveField(5)
  reward,
  
  @JsonValue('bridge')
  @HiveField(6)
  bridge,
  
  @JsonValue('liquidity')
  @HiveField(7)
  liquidity,
  
  @JsonValue('nft')
  @HiveField(8)
  nft,
  
  @JsonValue('contract')
  @HiveField(9)
  contract,
  
  @JsonValue('unknown')
  @HiveField(10)
  unknown, mint, burn
}

/// Represents current price data for a token
@JsonSerializable()
@HiveType(typeId: 15)
class TokenPrice extends Equatable {
  @HiveField(0)
  final String token;
  
  @HiveField(1)
  final String symbol;
  
  @HiveField(2)
  final double price;
  
  @HiveField(3)
  final double change24h;
  
  @HiveField(4)
  final double volume24h;
  
  @HiveField(5)
  final double marketCap;
  
  @HiveField(6)
  final DateTime lastUpdated;

  const TokenPrice({
    required this.token,
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.volume24h,
    required this.marketCap,
    required this.lastUpdated,
  });

  factory TokenPrice.fromJson(Map<String, dynamic> json) => _$TokenPriceFromJson(json);
  Map<String, dynamic> toJson() => _$TokenPriceToJson(this);

  TokenPrice copyWith({
    String? token,
    String? symbol,
    double? price,
    double? change24h,
    double? volume24h,
    double? marketCap,
    DateTime? lastUpdated,
  }) {
    return TokenPrice(
      token: token ?? this.token,
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
      volume24h: volume24h ?? this.volume24h,
      marketCap: marketCap ?? this.marketCap,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [token, symbol, price, change24h, volume24h, marketCap, lastUpdated];
}

/// Represents historical price data for creating charts
@JsonSerializable()
@HiveType(typeId: 16)
class PriceHistory extends Equatable {
  @HiveField(0)
  final String token;
  
  @HiveField(1)
  final String symbol;
  
  @HiveField(2)
  final List<PricePoint> prices;
  
  @HiveField(3)
  final String interval;
  
  @HiveField(4)
  final DateTime startDate;
  
  @HiveField(5)
  final DateTime endDate;
  
  @HiveField(6)
  final DateTime lastUpdated;

  const PriceHistory({
    required this.token,
    required this.symbol,
    required this.prices,
    required this.interval,
    required this.startDate,
    required this.endDate,
    required this.lastUpdated,
  });

  factory PriceHistory.fromJson(Map<String, dynamic> json) => _$PriceHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$PriceHistoryToJson(this);

  PriceHistory copyWith({
    String? token,
    String? symbol,
    List<PricePoint>? prices,
    String? interval,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastUpdated,
  }) {
    return PriceHistory(
      token: token ?? this.token,
      symbol: symbol ?? this.symbol,
      prices: prices ?? this.prices,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [token, symbol, prices, interval, startDate, endDate, lastUpdated];
}

/// Individual price point for historical data
@JsonSerializable()
@HiveType(typeId: 17)
class PricePoint extends Equatable {
  @HiveField(0)
  final DateTime timestamp;
  
  @HiveField(1)
  final double price;
  
  @HiveField(2)
  final double? volume;

  const PricePoint({
    required this.timestamp,
    required this.price,
    this.volume,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) => _$PricePointFromJson(json);
  Map<String, dynamic> toJson() => _$PricePointToJson(this);

  PricePoint copyWith({
    DateTime? timestamp,
    double? price,
    double? volume,
  }) {
    return PricePoint(
      timestamp: timestamp ?? this.timestamp,
      price: price ?? this.price,
      volume: volume ?? this.volume,
    );
  }

  @override
  List<Object?> get props => [timestamp, price, volume];
}

/// Overall market data summary
@JsonSerializable()
@HiveType(typeId: 18)
class MarketData extends Equatable {
  @HiveField(0)
  final double totalMarketCap;
  
  @HiveField(1)
  final double totalVolume24h;
  
  @HiveField(2)
  final double btcDominance;
  
  @HiveField(3)
  final double marketCapChange24h;
  
  @HiveField(4)
  final List<TokenPrice> topGainers;
  
  @HiveField(5)
  final List<TokenPrice> topLosers;
  
  @HiveField(6)
  final DateTime lastUpdated;

  const MarketData({
    required this.totalMarketCap,
    required this.totalVolume24h,
    required this.btcDominance,
    required this.marketCapChange24h,
    required this.topGainers,
    required this.topLosers,
    required this.lastUpdated,
  });

  factory MarketData.fromJson(Map<String, dynamic> json) => _$MarketDataFromJson(json);
  Map<String, dynamic> toJson() => _$MarketDataToJson(this);

  MarketData copyWith({
    double? totalMarketCap,
    double? totalVolume24h,
    double? btcDominance,
    double? marketCapChange24h,
    List<TokenPrice>? topGainers,
    List<TokenPrice>? topLosers,
    DateTime? lastUpdated,
  }) {
    return MarketData(
      totalMarketCap: totalMarketCap ?? this.totalMarketCap,
      totalVolume24h: totalVolume24h ?? this.totalVolume24h,
      btcDominance: btcDominance ?? this.btcDominance,
      marketCapChange24h: marketCapChange24h ?? this.marketCapChange24h,
      topGainers: topGainers ?? this.topGainers,
      topLosers: topLosers ?? this.topLosers,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [totalMarketCap, totalVolume24h, btcDominance, marketCapChange24h, topGainers, topLosers, lastUpdated];
}

/// AI-generated budget suggestions
@JsonSerializable()
@HiveType(typeId: 19)
class BudgetSuggestion extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final List<String> actions;
  
  @HiveField(4)
  final double potentialSavings;
  
  @HiveField(5)
  final String riskLevel;
  
  @HiveField(6)
  final DateTime generated;
  
  @HiveField(7)
  final bool isApplied;

  const BudgetSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.actions,
    required this.potentialSavings,
    required this.riskLevel,
    required this.generated,
    this.isApplied = false,
  });

  factory BudgetSuggestion.fromJson(Map<String, dynamic> json) => _$BudgetSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$BudgetSuggestionToJson(this);

  BudgetSuggestion copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? actions,
    double? potentialSavings,
    String? riskLevel,
    DateTime? generated,
    bool? isApplied,
  }) {
    return BudgetSuggestion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      actions: actions ?? this.actions,
      potentialSavings: potentialSavings ?? this.potentialSavings,
      riskLevel: riskLevel ?? this.riskLevel,
      generated: generated ?? this.generated,
      isApplied: isApplied ?? this.isApplied,
    );
  }

  @override
  List<Object?> get props => [id, title, description, actions, potentialSavings, riskLevel, generated, isApplied];
}

/// AI-generated portfolio insights
@JsonSerializable()
@HiveType(typeId: 20)
class Insight extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final InsightType type;
  
  @HiveField(4)
  final String? assetReference;
  
  @HiveField(5)
  final double? impactValue;
  
  @HiveField(6)
  final DateTime generated;
  
  @HiveField(7)
  final bool isRead;

  const Insight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.assetReference,
    this.impactValue,
    required this.generated,
    this.isRead = false,
  });

  factory Insight.fromJson(Map<String, dynamic> json) => _$InsightFromJson(json);
  Map<String, dynamic> toJson() => _$InsightToJson(this);

  Insight copyWith({
    String? id,
    String? title,
    String? description,
    InsightType? type,
    String? assetReference,
    double? impactValue,
    DateTime? generated,
    bool? isRead,
  }) {
    return Insight(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      assetReference: assetReference ?? this.assetReference,
      impactValue: impactValue ?? this.impactValue,
      generated: generated ?? this.generated,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, title, description, type, assetReference, impactValue, generated, isRead];
}

/// Types of portfolio insights
@JsonEnum()
@HiveType(typeId: 21)
enum InsightType {
  @JsonValue('risk_warning')
  @HiveField(0)
  riskWarning,
  
  @JsonValue('opportunity_alert')
  @HiveField(1)
  opportunityAlert,
  
  @JsonValue('market_trend')
  @HiveField(2)
  marketTrend,
  
  @JsonValue('portfolio_imbalance')
  @HiveField(3)
  portfolioImbalance,
  
  @JsonValue('fee_optimization')
  @HiveField(4)
  feeOptimization,
  
  @JsonValue('tax_consideration')
  @HiveField(5)
  taxConsideration,
  
  @JsonValue('educational_content')
  @HiveField(6)
  educationalContent,
  
  @JsonValue('price_alert')
  @HiveField(7)
  priceAlert
}

/// Portfolio risk assessment
@JsonSerializable()
@HiveType(typeId: 22)
class RiskAssessment extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final double overallRiskScore; // 1-100
  
  @HiveField(2)
  final String riskCategory; // Low, Medium, High, Very High
  
  @HiveField(3)
  final Map<String, double> riskFactors; // Factor -> Score
  
  @HiveField(4)
  final List<String> riskMitigationSuggestions;
  
  @HiveField(5)
  final double portfolioVolatility;
  
  @HiveField(6)
  final DateTime generated;

  const RiskAssessment({
    required this.id,
    required this.overallRiskScore,
    required this.riskCategory,
    required this.riskFactors,
    required this.riskMitigationSuggestions,
    required this.portfolioVolatility,
    required this.generated,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) => _$RiskAssessmentFromJson(json);
  Map<String, dynamic> toJson() => _$RiskAssessmentToJson(this);

  RiskAssessment copyWith({
    String? id,
    double? overallRiskScore,
    String? riskCategory,
    Map<String, double>? riskFactors,
    List<String>? riskMitigationSuggestions,
    double? portfolioVolatility,
    DateTime? generated,
  }) {
    return RiskAssessment(
      id: id ?? this.id,
      overallRiskScore: overallRiskScore ?? this.overallRiskScore,
      riskCategory: riskCategory ?? this.riskCategory,
      riskFactors: riskFactors ?? this.riskFactors,
      riskMitigationSuggestions: riskMitigationSuggestions ?? this.riskMitigationSuggestions,
      portfolioVolatility: portfolioVolatility ?? this.portfolioVolatility,
      generated: generated ?? this.generated,
    );
  }

  @override
  List<Object?> get props => [id, overallRiskScore, riskCategory, riskFactors, riskMitigationSuggestions, portfolioVolatility, generated];
}

/// DeFi position data
@JsonSerializable()
@HiveType(typeId: 23)
class DeFiPosition extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String protocol;
  
  @HiveField(2)
  final String positionType; // Staking, Lending, LP, etc.
  
  @HiveField(3)
  final String asset;
  
  @HiveField(4)
  final double amount;
  
  @HiveField(5)
  final double valueUsd;
  
  @HiveField(6)
  final double apr;
  
  @HiveField(7)
  final double earned;
  
  @HiveField(8)
  final double earnedUsd;
  
  @HiveField(9)
  final DateTime startDate;
  
  @HiveField(10)
  final DateTime? endDate;
  
  @HiveField(11)
  final String walletAddress;
  
  @HiveField(12)
  final String network;
  
  @HiveField(13)
  final String userId;
  
  @HiveField(14)
  final DateTime lastUpdated;

  const DeFiPosition({
    required this.id,
    required this.protocol,
    required this.positionType,
    required this.asset,
    required this.amount,
    required this.valueUsd,
    required this.apr,
    required this.earned,
    required this.earnedUsd,
    required this.startDate,
    this.endDate,
    required this.walletAddress,
    required this.network,
    required this.userId,
    required this.lastUpdated,
  });

  factory DeFiPosition.fromJson(Map<String, dynamic> json) => _$DeFiPositionFromJson(json);
  Map<String, dynamic> toJson() => _$DeFiPositionToJson(this);

  DeFiPosition copyWith({
    String? id,
    String? protocol,
    String? positionType,
    String? asset,
    double? amount,
    double? valueUsd,
    double? apr,
    double? earned,
    double? earnedUsd,
    DateTime? startDate,
    DateTime? endDate,
    String? walletAddress,
    String? network,
    String? userId,
    DateTime? lastUpdated,
  }) {
    return DeFiPosition(
      id: id ?? this.id,
      protocol: protocol ?? this.protocol,
      positionType: positionType ?? this.positionType,
      asset: asset ?? this.asset,
      amount: amount ?? this.amount,
      valueUsd: valueUsd ?? this.valueUsd,
      apr: apr ?? this.apr,
      earned: earned ?? this.earned,
      earnedUsd: earnedUsd ?? this.earnedUsd,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      walletAddress: walletAddress ?? this.walletAddress,
      network: network ?? this.network,
      userId: userId ?? this.userId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    id, protocol, positionType, asset, amount, valueUsd, 
    apr, earned, earnedUsd, startDate, endDate, walletAddress,
    network, userId, lastUpdated,
  ];
}

/// NFT asset data
@JsonSerializable()
@HiveType(typeId: 24)
class NFTAsset extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String contractAddress;
  
  @HiveField(2)
  final String tokenId;
  
  @HiveField(3)
  final String name;
  
  @HiveField(4)
  final String? description;
  
  @HiveField(5)
  final String collection;
  
  @HiveField(6)
  final String? imageUrl;
  
  @HiveField(7)
  final double? lastPrice;
  
  @HiveField(8)
  final double? floorPrice;
  
  @HiveField(9)
  final String network;
  
  @HiveField(10)
  final String walletAddress;
  
  @HiveField(11)
  final String userId;
  
  @HiveField(12)
  final DateTime acquiredDate;
  
  @HiveField(13)
  final DateTime lastUpdated;

  const NFTAsset({
    required this.id,
    required this.contractAddress,
    required this.tokenId,
    required this.name,
    this.description,
    required this.collection,
    this.imageUrl,
    this.lastPrice,
    this.floorPrice,
    required this.network,
    required this.walletAddress,
    required this.userId,
    required this.acquiredDate,
    required this.lastUpdated,
  });

  factory NFTAsset.fromJson(Map<String, dynamic> json) => _$NFTAssetFromJson(json);
  Map<String, dynamic> toJson() => _$NFTAssetToJson(this);

  NFTAsset copyWith({
    String? id,
    String? contractAddress,
    String? tokenId,
    String? name,
    String? description,
    String? collection,
    String? imageUrl,
    double? lastPrice,
    double? floorPrice,
    String? network,
    String? walletAddress,
    String? userId,
    DateTime? acquiredDate,
    DateTime? lastUpdated,
  }) {
    return NFTAsset(
      id: id ?? this.id,
      contractAddress: contractAddress ?? this.contractAddress,
      tokenId: tokenId ?? this.tokenId,
      name: name ?? this.name,
      description: description ?? this.description,
      collection: collection ?? this.collection,
      imageUrl: imageUrl ?? this.imageUrl,
      lastPrice: lastPrice ?? this.lastPrice,
      floorPrice: floorPrice ?? this.floorPrice,
      network: network ?? this.network,
      walletAddress: walletAddress ?? this.walletAddress,
      userId: userId ?? this.userId,
      acquiredDate: acquiredDate ?? this.acquiredDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    id, contractAddress, tokenId, name, description, collection,
    imageUrl, lastPrice, floorPrice, network, walletAddress,
    userId, acquiredDate, lastUpdated,
  ];
}

/// API request error data
@JsonSerializable()
class CryptoApiError extends Equatable {
  final String code;
  final String message;
  final String? details;
  final DateTime timestamp;

  const CryptoApiError({
    required this.code,
    required this.message,
    this.details,
    required this.timestamp,
  });

  factory CryptoApiError.fromJson(Map<String, dynamic> json) => _$CryptoApiErrorFromJson(json);
  Map<String, dynamic> toJson() => _$CryptoApiErrorToJson(this);

  CryptoApiError copyWith({
    String? code,
    String? message,
    String? details,
    DateTime? timestamp,
  }) {
    return CryptoApiError(
      code: code ?? this.code,
      message: message ?? this.message,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [code, message, details, timestamp];
}