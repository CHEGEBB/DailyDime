// lib/models/crypto_models.dart

import 'dart:convert';
import 'package:flutter/material.dart';

/// Core model representing a cryptocurrency token
class Token {
  final String symbol;
  final String name;
  final String address;
  final String networkId;
  final String logoUrl;
  final int decimals;
  
  // Price information
  final double currentPrice;
  final double priceChangePercent24h;
  final double ath;
  final double atl;
  
  const Token({
    required this.symbol,
    required this.name,
    required this.address,
    required this.networkId,
    required this.logoUrl,
    this.decimals = 18,
    this.currentPrice = 0.0,
    this.priceChangePercent24h = 0.0,
    this.ath = 0.0,
    this.atl = 0.0, required amount, required usdValue,
  });
  
  Token copyWith({
    String? symbol,
    String? name,
    String? address,
    String? networkId,
    String? logoUrl,
    int? decimals,
    double? currentPrice,
    double? priceChangePercent24h,
    double? ath,
    double? atl,
  }) {
    return Token(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      address: address ?? this.address,
      networkId: networkId ?? this.networkId,
      logoUrl: logoUrl ?? this.logoUrl,
      decimals: decimals ?? this.decimals,
      currentPrice: currentPrice ?? this.currentPrice,
      priceChangePercent24h: priceChangePercent24h ?? this.priceChangePercent24h,
      ath: ath ?? this.ath,
      atl: atl ?? this.atl,
    );
  }
  
  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      networkId: json['network_id'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      decimals: json['decimals'] ?? 18,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      priceChangePercent24h: (json['price_change_percent_24h'] as num?)?.toDouble() ?? 0.0,
      ath: (json['ath'] as num?)?.toDouble() ?? 0.0,
      atl: (json['atl'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'address': address,
      'network_id': networkId,
      'logo_url': logoUrl,
      'decimals': decimals,
      'current_price': currentPrice,
      'price_change_percent_24h': priceChangePercent24h,
      'ath': ath,
      'atl': atl,
    };
  }
  
  String getFormattedPrice() {
    if (currentPrice >= 1000) {
      return '\$${currentPrice.toStringAsFixed(0)}';
    } else if (currentPrice >= 1) {
      return '\$${currentPrice.toStringAsFixed(2)}';
    } else if (currentPrice >= 0.01) {
      return '\$${currentPrice.toStringAsFixed(4)}';
    } else {
      return '\$${currentPrice.toStringAsFixed(6)}';
    }
  }
  
  Color getPriceChangeColor() {
    if (priceChangePercent24h > 0) {
      return const Color(0xFF10B981); // Green
    } else if (priceChangePercent24h < 0) {
      return const Color(0xFFEF4444); // Red
    } else {
      return Colors.grey;
    }
  }
  
  String getFormattedPriceChange() {
    final sign = priceChangePercent24h >= 0 ? '+' : '';
    return '$sign${priceChangePercent24h.toStringAsFixed(2)}%';
  }
}

/// Represents a user's crypto wallet
class Wallet {
  final String id;
  final String address;
  final String networkId;
  final String networkName;
  final String label;
  final double balance; // Native token balance
  final List<TokenBalance> tokens;
  final DateTime lastUpdated;
  final bool isActive;
  
  const Wallet({
    required this.id,
    required this.address,
    required this.networkId,
    required this.networkName,
    this.label = '',
    this.balance = 0,
    this.tokens = const [],
    required this.lastUpdated,
    this.isActive = true,
  });
  
  Wallet copyWith({
    String? id,
    String? address,
    String? networkId,
    String? networkName,
    String? label,
    double? balance,
    List<TokenBalance>? tokens,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return Wallet(
      id: id ?? this.id,
      address: address ?? this.address,
      networkId: networkId ?? this.networkId,
      networkName: networkName ?? this.networkName,
      label: label ?? this.label,
      balance: balance ?? this.balance,
      tokens: tokens ?? this.tokens,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }
  
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? '',
      address: json['address'] ?? '',
      networkId: json['network_id'] ?? '',
      networkName: json['network_name'] ?? '',
      label: json['label'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      tokens: (json['tokens'] as List<dynamic>?)
          ?.map((token) => TokenBalance.fromJson(token))
          .toList() ?? [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'network_id': networkId,
      'network_name': networkName,
      'label': label,
      'balance': balance,
      'tokens': tokens.map((token) => token.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
      'is_active': isActive,
    };
  }
  
  String getFormattedAddress() {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
  
  double getTotalUsdValue() {
    double total = 0;
    for (var token in tokens) {
      total += token.usdValue;
    }
    return total;
  }
  
  String getNetworkIcon() {
    switch (networkName.toLowerCase()) {
      case 'ethereum':
        return 'assets/images/ethereum.png';
      case 'binance smart chain':
      case 'bsc':
        return 'assets/images/bsc.png';
      case 'polygon':
        return 'assets/images/polygon.png';
      case 'avalanche':
        return 'assets/images/avalanche.png';
      case 'fantom':
        return 'assets/images/fantom.png';
      case 'arbitrum':
        return 'assets/images/arbitrum.png';
      default:
        return 'assets/images/blockchain.png';
    }
  }
}

/// Represents a token balance within a wallet
class TokenBalance {
  final String tokenAddress;
  final String symbol;
  final String name;
  final String logoUrl;
  final double balance;
  final double usdValue;
  final int decimals;
  
  const TokenBalance({
    required this.tokenAddress,
    required this.symbol,
    required this.name,
    required this.logoUrl,
    required this.balance,
    required this.usdValue,
    this.decimals = 18,
  });
  
  factory TokenBalance.fromJson(Map<String, dynamic> json) {
    return TokenBalance(
      tokenAddress: json['token_address'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      usdValue: (json['usd_value'] as num?)?.toDouble() ?? 0.0,
      decimals: json['decimals'] ?? 18,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'token_address': tokenAddress,
      'symbol': symbol,
      'name': name,
      'logo_url': logoUrl,
      'balance': balance,
      'usd_value': usdValue,
      'decimals': decimals,
    };
  }
  
  String getFormattedBalance() {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(2)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(2)}K';
    } else if (balance >= 1) {
      return balance.toStringAsFixed(2);
    } else {
      return balance.toStringAsFixed(balance < 0.0001 ? 8 : 4);
    }
  }
}

/// Represents the entire cryptocurrency portfolio
class Portfolio {
  final List<Wallet> wallets;
  final double totalUsdValue;
  final double dayChange;
  final double dayChangePercentage;
  final Map<String, double> allocation;
  final DateTime lastUpdated;
  
  const Portfolio({
    this.wallets = const [],
    this.totalUsdValue = 0.0,
    this.dayChange = 0.0,
    this.dayChangePercentage = 0.0,
    this.allocation = const {},
    required this.lastUpdated,
  });
  
  Portfolio copyWith({
    List<Wallet>? wallets,
    double? totalUsdValue,
    double? dayChange,
    double? dayChangePercentage,
    Map<String, double>? allocation,
    DateTime? lastUpdated,
  }) {
    return Portfolio(
      wallets: wallets ?? this.wallets,
      totalUsdValue: totalUsdValue ?? this.totalUsdValue,
      dayChange: dayChange ?? this.dayChange,
      dayChangePercentage: dayChangePercentage ?? this.dayChangePercentage,
      allocation: allocation ?? this.allocation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      wallets: (json['wallets'] as List<dynamic>?)
          ?.map((wallet) => Wallet.fromJson(wallet))
          .toList() ?? [],
      totalUsdValue: (json['total_usd_value'] as num?)?.toDouble() ?? 0.0,
      dayChange: (json['day_change'] as num?)?.toDouble() ?? 0.0,
      dayChangePercentage: (json['day_change_percentage'] as num?)?.toDouble() ?? 0.0,
      allocation: json['allocation'] != null
          ? Map<String, double>.from(json['allocation'])
          : {},
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'wallets': wallets.map((wallet) => wallet.toJson()).toList(),
      'total_usd_value': totalUsdValue,
      'day_change': dayChange,
      'day_change_percentage': dayChangePercentage,
      'allocation': allocation,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
  
  Color getDayChangeColor() {
    if (dayChange > 0) {
      return const Color(0xFF10B981); // Green
    } else if (dayChange < 0) {
      return const Color(0xFFEF4444); // Red
    } else {
      return Colors.grey;
    }
  }
  
  String getFormattedDayChange() {
    final sign = dayChange >= 0 ? '+' : '';
    return '$sign\$${dayChange.abs().toStringAsFixed(2)} ($sign${dayChangePercentage.toStringAsFixed(2)}%)';
  }
  
  List<MapEntry<String, double>> getAllocationEntries() {
    final entries = allocation.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

/// Represents a crypto transaction
class Transaction {
  final String id;
  final String hash;
  final String from;
  final String to;
  final String tokenAddress;
  final String tokenSymbol;
  final String tokenName;
  final String tokenLogo;
  final double value;
  final double valueUsd;
  final DateTime timestamp;
  final TransactionType type;
  final String networkId;
  final String networkName;
  final TransactionStatus status;
  final String budgetCategory;
  final String description;

  var date;
  
  const Transaction({
    required this.id,
    required this.hash,
    required this.from,
    required this.to,
    required this.tokenAddress,
    required this.tokenSymbol,
    required this.tokenName,
    required this.tokenLogo,
    required this.value,
    required this.valueUsd,
    required this.timestamp,
    required this.type,
    required this.networkId,
    required this.networkName,
    this.status = TransactionStatus.confirmed,
    this.budgetCategory = '',
    this.description = '',
  });
  
  Transaction copyWith({
    String? id,
    String? hash,
    String? from,
    String? to,
    String? tokenAddress,
    String? tokenSymbol,
    String? tokenName,
    String? tokenLogo,
    double? value,
    double? valueUsd,
    DateTime? timestamp,
    TransactionType? type,
    String? networkId,
    String? networkName,
    TransactionStatus? status,
    String? budgetCategory,
    String? description,
  }) {
    return Transaction(
      id: id ?? this.id,
      hash: hash ?? this.hash,
      from: from ?? this.from,
      to: to ?? this.to,
      tokenAddress: tokenAddress ?? this.tokenAddress,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      tokenName: tokenName ?? this.tokenName,
      tokenLogo: tokenLogo ?? this.tokenLogo,
      value: value ?? this.value,
      valueUsd: valueUsd ?? this.valueUsd,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      networkId: networkId ?? this.networkId,
      networkName: networkName ?? this.networkName,
      status: status ?? this.status,
      budgetCategory: budgetCategory ?? this.budgetCategory,
      description: description ?? this.description,
    );
  }
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      hash: json['hash'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      tokenAddress: json['token_address'] ?? '',
      tokenSymbol: json['token_symbol'] ?? '',
      tokenName: json['token_name'] ?? '',
      tokenLogo: json['token_logo'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      valueUsd: (json['value_usd'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      type: json['type'] != null
          ? TransactionType.values.firstWhere(
              (e) => e.toString() == 'TransactionType.${json['type']}',
              orElse: () => TransactionType.transfer,
            )
          : TransactionType.transfer,
      networkId: json['network_id'] ?? '',
      networkName: json['network_name'] ?? '',
      status: json['status'] != null
          ? TransactionStatus.values.firstWhere(
              (e) => e.toString() == 'TransactionStatus.${json['status']}',
              orElse: () => TransactionStatus.confirmed,
            )
          : TransactionStatus.confirmed,
      budgetCategory: json['budget_category'] ?? '',
      description: json['description'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hash': hash,
      'from': from,
      'to': to,
      'token_address': tokenAddress,
      'token_symbol': tokenSymbol,
      'token_name': tokenName,
      'token_logo': tokenLogo,
      'value': value,
      'value_usd': valueUsd,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'network_id': networkId,
      'network_name': networkName,
      'status': status.toString().split('.').last,
      'budget_category': budgetCategory,
      'description': description,
    };
  }
  
  IconData getTypeIcon() {
    switch (type) {
      case TransactionType.send:
        return Icons.arrow_upward;
      case TransactionType.receive:
        return Icons.arrow_downward;
      case TransactionType.swap:
        return Icons.swap_horiz;
      case TransactionType.approve:
        return Icons.check_circle_outline;
      case TransactionType.transfer:
        return Icons.sync_alt;
      case TransactionType.mint:
        return Icons.add_circle_outline;
      case TransactionType.burn:
        return Icons.remove_circle_outline;
      case TransactionType.stake:
        return Icons.lock_outline;
      case TransactionType.unstake:
        return Icons.lock_open;
      case TransactionType.claim:
        return Icons.redeem;
      case TransactionType.contract:
        return Icons.smart_toy_outlined;
    }
  }
  
  Color getTypeColor() {
    switch (type) {
      case TransactionType.send:
        return const Color(0xFFEF4444); // Red
      case TransactionType.receive:
        return const Color(0xFF10B981); // Green
      case TransactionType.swap:
        return const Color(0xFF3B82F6); // Blue
      case TransactionType.approve:
        return const Color(0xFF8B5CF6); // Purple
      case TransactionType.transfer:
        return const Color(0xFFF59E0B); // Amber
      case TransactionType.mint:
        return const Color(0xFF10B981); // Green
      case TransactionType.burn:
        return const Color(0xFFEF4444); // Red
      case TransactionType.stake:
        return const Color(0xFF8B5CF6); // Purple
      case TransactionType.unstake:
        return const Color(0xFF3B82F6); // Blue
      case TransactionType.claim:
        return const Color(0xFF10B981); // Green
      case TransactionType.contract:
        return const Color(0xFF6B7280); // Gray
    }
  }
  
  String getFormattedAmount() {
    final prefix = type == TransactionType.send ? '-' : 
                  type == TransactionType.receive ? '+' : '';
    return '$prefix${value.toStringAsFixed(value < 0.001 ? 6 : 4)} $tokenSymbol';
  }
  
  String getFormattedUsdAmount() {
    final prefix = type == TransactionType.send ? '-' : 
                  type == TransactionType.receive ? '+' : '';
    return '$prefix\$${valueUsd.toStringAsFixed(2)}';
  }
  
  String getFormattedHash() {
    if (hash.length <= 14) return hash;
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  }
  
  String getFormattedDate() {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
  
  String getExplorerUrl() {
    switch (networkName.toLowerCase()) {
      case 'ethereum':
        return 'https://etherscan.io/tx/$hash';
      case 'binance smart chain':
      case 'bsc':
        return 'https://bscscan.com/tx/$hash';
      case 'polygon':
        return 'https://polygonscan.com/tx/$hash';
      case 'avalanche':
        return 'https://snowtrace.io/tx/$hash';
      case 'fantom':
        return 'https://ftmscan.com/tx/$hash';
      case 'arbitrum':
        return 'https://arbiscan.io/tx/$hash';
      default:
        return 'https://etherscan.io/tx/$hash';
    }
  }
}

/// Represents cryptocurrency price history for charts
class PriceHistory {
  final String symbol;
  final List<PricePoint> prices;
  final TimeFrame timeFrame;
  
  const PriceHistory({
    required this.symbol,
    required this.prices,
    required this.timeFrame,
  });
  
  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      symbol: json['symbol'] ?? '',
      prices: (json['prices'] as List<dynamic>?)
          ?.map((price) => PricePoint.fromJson(price))
          .toList() ?? [],
      timeFrame: json['time_frame'] != null
          ? TimeFrame.values.firstWhere(
              (e) => e.toString() == 'TimeFrame.${json['time_frame']}',
              orElse: () => TimeFrame.day,
            )
          : TimeFrame.day,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'prices': prices.map((price) => price.toJson()).toList(),
      'time_frame': timeFrame.toString().split('.').last,
    };
  }
  
  double getHighestPrice() {
    if (prices.isEmpty) return 0;
    return prices.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }
  
  double getLowestPrice() {
    if (prices.isEmpty) return 0;
    return prices.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }
  
  double getPriceChange() {
    if (prices.length < 2) return 0;
    return prices.last.price - prices.first.price;
  }
  
  double getPriceChangePercentage() {
    if (prices.length < 2 || prices.first.price == 0) return 0;
    return (getPriceChange() / prices.first.price) * 100;
  }
}

/// Individual price point for charts
class PricePoint {
  final DateTime timestamp;
  final double price;
  
  const PricePoint({
    required this.timestamp,
    required this.price,
  });
  
  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'price': price,
    };
  }
}

/// Real-time price update event
class PriceUpdate {
  final String symbol;
  final double price;
  final double change24h;
  final DateTime timestamp;
  
  const PriceUpdate({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.timestamp,
  });
  
  factory PriceUpdate.fromJson(Map<String, dynamic> json) {
    return PriceUpdate(
      symbol: json['symbol'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      change24h: (json['change_24h'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'price': price,
      'change_24h': change24h,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  Color getChangeColor() {
    if (change24h > 0) {
      return const Color(0xFF10B981); // Green
    } else if (change24h < 0) {
      return const Color(0xFFEF4444); // Red
    } else {
      return Colors.grey;
    }
  }
  
  String getFormattedChange() {
    final sign = change24h >= 0 ? '+' : '';
    return '$sign${change24h.toStringAsFixed(2)}%';
  }
}

/// Crypto market overview data
class MarketData {
  final double totalMarketCap;
  final double totalVolume24h;
  final double btcDominance;
  final double marketCapChange24h;
  final Map<String, dynamic> trending;
  final Map<String, dynamic> fear;

  var volumeData;
  
  const MarketData({
    required this.totalMarketCap,
    required this.totalVolume24h,
    required this.btcDominance,
    required this.marketCapChange24h,
    required this.trending,
    required this.fear,
  });
  
  factory MarketData.fromJson(Map<String, dynamic> json) {
    return MarketData(
      totalMarketCap: (json['total_market_cap'] as num?)?.toDouble() ?? 0.0,
      totalVolume24h: (json['total_volume_24h'] as num?)?.toDouble() ?? 0.0,
      btcDominance: (json['btc_dominance'] as num?)?.toDouble() ?? 0.0,
      marketCapChange24h: (json['market_cap_change_24h'] as num?)?.toDouble() ?? 0.0,
      trending: json['trending'] ?? {},
      fear: json['fear'] ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'total_market_cap': totalMarketCap,
      'total_volume_24h': totalVolume24h,
      'btc_dominance': btcDominance,
      'market_cap_change_24h': marketCapChange24h,
      'trending': trending,
      'fear': fear,
    };
  }
  
  String getFormattedMarketCap() {
    if (totalMarketCap >= 1000000000000) {
      return '\$${(totalMarketCap / 1000000000000).toStringAsFixed(2)}T';
    } else if (totalMarketCap >= 1000000000) {
      return '\$${(totalMarketCap / 1000000000).toStringAsFixed(2)}B';
    } else {
      return '\$${(totalMarketCap / 1000000).toStringAsFixed(2)}M';
    }
  }
  
  String getFormattedVolume() {
    if (totalVolume24h >= 1000000000000) {
      return '\$${(totalVolume24h / 1000000000000).toStringAsFixed(2)}T';
    } else if (totalVolume24h >= 1000000000) {
      return '\$${(totalVolume24h / 1000000000).toStringAsFixed(2)}B';
    } else {
      return '\$${(totalVolume24h / 1000000).toStringAsFixed(2)}M';
    }
  }
  
  Color getMarketCapChangeColor() {
    if (marketCapChange24h > 0) {
      return const Color(0xFF10B981); // Green
    } else if (marketCapChange24h < 0) {
      return const Color(0xFFEF4444); // Red
    } else {
      return Colors.grey;
    }
  }
  
  String getFormattedMarketCapChange() {
    final sign = marketCapChange24h >= 0 ? '+' : '';
    return '$sign${marketCapChange24h.toStringAsFixed(2)}%';
  }
  
  String getFearIndex() {
    final value = (fear['value'] as num?)?.toInt() ?? 0;
    if (value <= 20) {
      return 'Extreme Fear';
    } else if (value <= 40) {
      return 'Fear';
    } else if (value <= 60) {
      return 'Neutral';
    } else if (value <= 80) {
      return 'Greed';
    } else {
      return 'Extreme Greed';
    }
  }
}

/// AI-generated insights about the portfolio
class AIInsight {
  final String id;
  final String title;
  final String description;
  final AIInsightType type;
  final String actionUrl;
  final DateTime timestamp;
  final double confidence;
  final Map<String, dynamic> metadata;
  
  const AIInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.actionUrl = '',
    required this.timestamp,
    this.confidence = 0.0,
    this.metadata = const {},
  });
  
  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] != null
          ? AIInsightType.values.firstWhere(
              (e) => e.toString() == 'AIInsightType.${json['type']}',
              orElse: () => AIInsightType.general,
            )
          : AIInsightType.general,
      actionUrl: json['action_url'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'action_url': actionUrl,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'metadata': metadata,
    };
  }
  
  IconData getTypeIcon() {
    switch (type) {
      case AIInsightType.general:
        return Icons.lightbulb_outline;
      case AIInsightType.recommendation:
        return Icons.tips_and_updates_outlined;
      case AIInsightType.alert:
        return Icons.warning_amber_outlined;
      case AIInsightType.opportunity:
        return Icons.trending_up;
      case AIInsightType.risk:
        return Icons.shield_outlined;
      case AIInsightType.education:
        return Icons.school_outlined;
      case AIInsightType.budget:
        return Icons.account_balance_wallet_outlined;
    }
  }
  
  Color getTypeColor() {
    switch (type) {
      case AIInsightType.general:
        return const Color(0xFF3B82F6); // Blue
      case AIInsightType.recommendation:
        return const Color(0xFF8B5CF6); // Purple
      case AIInsightType.alert:
        return const Color(0xFFEF4444); // Red
      case AIInsightType.opportunity:
        return const Color(0xFF10B981); // Green
      case AIInsightType.risk:
        return const Color(0xFFF59E0B); // Amber
      case AIInsightType.education:
        return const Color(0xFF6366F1); // Indigo
      case AIInsightType.budget:
        return const Color(0xFF0AB3B8); // Teal
    }
  }
}

/// AI-generated risk assessment
class RiskAssessment {
  final double overallRisk;
  final Map<String, double> riskFactors;
  final List<String> suggestions;
  final Map<String, dynamic> metadata;

  var riskLevel;

  var analysis;

  var recommendations;
  
  const RiskAssessment({
    required this.overallRisk,
    required this.riskFactors,
    required this.suggestions,
    this.metadata = const {},
  });
  
  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      overallRisk: (json['overall_risk'] as num?)?.toDouble() ?? 0.0,
      riskFactors: json['risk_factors'] != null
          ? Map<String, double>.from(json['risk_factors'])
          : {},
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      metadata: json['metadata'] ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'overall_risk': overallRisk,
      'risk_factors': riskFactors,
      'suggestions': suggestions,
      'metadata': metadata,
    };
  }
  
  String getRiskLevel() {
    if (overallRisk <= 20) {
      return 'Very Low';
    } else if (overallRisk <= 40) {
      return 'Low';
    } else if (overallRisk <= 60) {
      return 'Medium';
    } else if (overallRisk <= 80) {
      return 'High';
    } else {
      return 'Very High';
    }
  }
  
  Color getRiskColor() {
    if (overallRisk <= 20) {
      return const Color(0xFF10B981); // Green
    } else if (overallRisk <= 40) {
      return const Color(0xFF34D399); // Light Green
    } else if (overallRisk <= 60) {
      return const Color(0xFFF59E0B); // Amber
    } else if (overallRisk <= 80) {
      return const Color(0xFFF97316); // Orange
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }
  
  List<MapEntry<String, double>> getRiskFactorsEntries() {
    final entries = riskFactors.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

/// Enumeration for transaction types
enum TransactionType {
  send,
  receive,
  swap,
  approve,
  transfer,
  mint,
  burn,
  stake,
  unstake,
  claim,
  contract, sent, received,
}

/// Enumeration for transaction status
enum TransactionStatus {
  pending,
  confirmed,
  failed,
  cancelled,
}

/// Enumeration for chart time frames
enum TimeFrame {
  hour,
  day,
  week,
  month,
  year,
  all,
}

/// Enumeration for AI insight types
enum AIInsightType {
  general,
  recommendation,
  alert,
  opportunity,
  risk,
  education,
  budget,
}