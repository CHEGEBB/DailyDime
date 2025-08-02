// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crypto_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PortfolioAdapter extends TypeAdapter<Portfolio> {
  @override
  final int typeId = 10;

  @override
  Portfolio read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Portfolio(
      wallets: (fields[0] as List).cast<CryptoWallet>(),
      totalValue: fields[1] as double,
      assetAllocation: (fields[2] as Map).cast<String, double>(),
      percentChange24h: fields[3] as double,
      lastUpdated: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Portfolio obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.wallets)
      ..writeByte(1)
      ..write(obj.totalValue)
      ..writeByte(2)
      ..write(obj.assetAllocation)
      ..writeByte(3)
      ..write(obj.percentChange24h)
      ..writeByte(4)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortfolioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CryptoWalletAdapter extends TypeAdapter<CryptoWallet> {
  @override
  final int typeId = 11;

  @override
  CryptoWallet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CryptoWallet(
      id: fields[0] as String,
      address: fields[1] as String,
      network: fields[2] as String,
      name: fields[3] as String?,
      userId: fields[4] as String,
      tokens: (fields[5] as List).cast<TokenBalance>(),
      totalValue: fields[6] as double,
      lastUpdated: fields[7] as DateTime,
      isActive: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CryptoWallet obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.network)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.userId)
      ..writeByte(5)
      ..write(obj.tokens)
      ..writeByte(6)
      ..write(obj.totalValue)
      ..writeByte(7)
      ..write(obj.lastUpdated)
      ..writeByte(8)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CryptoWalletAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TokenBalanceAdapter extends TypeAdapter<TokenBalance> {
  @override
  final int typeId = 12;

  @override
  TokenBalance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TokenBalance(
      token: fields[0] as String,
      tokenAddress: fields[1] as String,
      symbol: fields[2] as String,
      balance: fields[3] as double,
      valueUsd: fields[4] as double,
      decimals: fields[5] as int,
      logoUrl: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TokenBalance obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.token)
      ..writeByte(1)
      ..write(obj.tokenAddress)
      ..writeByte(2)
      ..write(obj.symbol)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.valueUsd)
      ..writeByte(5)
      ..write(obj.decimals)
      ..writeByte(6)
      ..write(obj.logoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenBalanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CryptoTransactionAdapter extends TypeAdapter<CryptoTransaction> {
  @override
  final int typeId = 13;

  @override
  CryptoTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CryptoTransaction(
      id: fields[0] as String,
      hash: fields[1] as String,
      network: fields[2] as String,
      from: fields[3] as String,
      to: fields[4] as String,
      token: fields[5] as String,
      tokenAddress: fields[6] as String,
      symbol: fields[7] as String,
      amount: fields[8] as double,
      valueUsd: fields[9] as double,
      timestamp: fields[10] as DateTime,
      type: fields[11] as TransactionType,
      gasFee: fields[12] as double,
      gasFeeUsd: fields[13] as double,
      userId: fields[14] as String,
      isSynced: fields[15] as bool,
      appwriteId: fields[16] as String?,
      budgetCategory: fields[17] as String?,
      notes: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CryptoTransaction obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hash)
      ..writeByte(2)
      ..write(obj.network)
      ..writeByte(3)
      ..write(obj.from)
      ..writeByte(4)
      ..write(obj.to)
      ..writeByte(5)
      ..write(obj.token)
      ..writeByte(6)
      ..write(obj.tokenAddress)
      ..writeByte(7)
      ..write(obj.symbol)
      ..writeByte(8)
      ..write(obj.amount)
      ..writeByte(9)
      ..write(obj.valueUsd)
      ..writeByte(10)
      ..write(obj.timestamp)
      ..writeByte(11)
      ..write(obj.type)
      ..writeByte(12)
      ..write(obj.gasFee)
      ..writeByte(13)
      ..write(obj.gasFeeUsd)
      ..writeByte(14)
      ..write(obj.userId)
      ..writeByte(15)
      ..write(obj.isSynced)
      ..writeByte(16)
      ..write(obj.appwriteId)
      ..writeByte(17)
      ..write(obj.budgetCategory)
      ..writeByte(18)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CryptoTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TokenPriceAdapter extends TypeAdapter<TokenPrice> {
  @override
  final int typeId = 15;

  @override
  TokenPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TokenPrice(
      token: fields[0] as String,
      symbol: fields[1] as String,
      price: fields[2] as double,
      change24h: fields[3] as double,
      volume24h: fields[4] as double,
      marketCap: fields[5] as double,
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TokenPrice obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.token)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.change24h)
      ..writeByte(4)
      ..write(obj.volume24h)
      ..writeByte(5)
      ..write(obj.marketCap)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PriceHistoryAdapter extends TypeAdapter<PriceHistory> {
  @override
  final int typeId = 16;

  @override
  PriceHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceHistory(
      token: fields[0] as String,
      symbol: fields[1] as String,
      prices: (fields[2] as List).cast<PricePoint>(),
      interval: fields[3] as String,
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime,
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PriceHistory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.token)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.prices)
      ..writeByte(3)
      ..write(obj.interval)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PricePointAdapter extends TypeAdapter<PricePoint> {
  @override
  final int typeId = 17;

  @override
  PricePoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PricePoint(
      timestamp: fields[0] as DateTime,
      price: fields[1] as double,
      volume: fields[2] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, PricePoint obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.volume);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PricePointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MarketDataAdapter extends TypeAdapter<MarketData> {
  @override
  final int typeId = 18;

  @override
  MarketData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MarketData(
      totalMarketCap: fields[0] as double,
      totalVolume24h: fields[1] as double,
      btcDominance: fields[2] as double,
      marketCapChange24h: fields[3] as double,
      topGainers: (fields[4] as List).cast<TokenPrice>(),
      topLosers: (fields[5] as List).cast<TokenPrice>(),
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MarketData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.totalMarketCap)
      ..writeByte(1)
      ..write(obj.totalVolume24h)
      ..writeByte(2)
      ..write(obj.btcDominance)
      ..writeByte(3)
      ..write(obj.marketCapChange24h)
      ..writeByte(4)
      ..write(obj.topGainers)
      ..writeByte(5)
      ..write(obj.topLosers)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetSuggestionAdapter extends TypeAdapter<BudgetSuggestion> {
  @override
  final int typeId = 19;

  @override
  BudgetSuggestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetSuggestion(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      actions: (fields[3] as List).cast<String>(),
      potentialSavings: fields[4] as double,
      riskLevel: fields[5] as String,
      generated: fields[6] as DateTime,
      isApplied: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetSuggestion obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.actions)
      ..writeByte(4)
      ..write(obj.potentialSavings)
      ..writeByte(5)
      ..write(obj.riskLevel)
      ..writeByte(6)
      ..write(obj.generated)
      ..writeByte(7)
      ..write(obj.isApplied);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetSuggestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InsightAdapter extends TypeAdapter<Insight> {
  @override
  final int typeId = 20;

  @override
  Insight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Insight(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as InsightType,
      assetReference: fields[4] as String?,
      impactValue: fields[5] as double?,
      generated: fields[6] as DateTime,
      isRead: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Insight obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.assetReference)
      ..writeByte(5)
      ..write(obj.impactValue)
      ..writeByte(6)
      ..write(obj.generated)
      ..writeByte(7)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RiskAssessmentAdapter extends TypeAdapter<RiskAssessment> {
  @override
  final int typeId = 22;

  @override
  RiskAssessment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RiskAssessment(
      id: fields[0] as String,
      overallRiskScore: fields[1] as double,
      riskCategory: fields[2] as String,
      riskFactors: (fields[3] as Map).cast<String, double>(),
      riskMitigationSuggestions: (fields[4] as List).cast<String>(),
      portfolioVolatility: fields[5] as double,
      generated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RiskAssessment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.overallRiskScore)
      ..writeByte(2)
      ..write(obj.riskCategory)
      ..writeByte(3)
      ..write(obj.riskFactors)
      ..writeByte(4)
      ..write(obj.riskMitigationSuggestions)
      ..writeByte(5)
      ..write(obj.portfolioVolatility)
      ..writeByte(6)
      ..write(obj.generated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskAssessmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeFiPositionAdapter extends TypeAdapter<DeFiPosition> {
  @override
  final int typeId = 23;

  @override
  DeFiPosition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeFiPosition(
      id: fields[0] as String,
      protocol: fields[1] as String,
      positionType: fields[2] as String,
      asset: fields[3] as String,
      amount: fields[4] as double,
      valueUsd: fields[5] as double,
      apr: fields[6] as double,
      earned: fields[7] as double,
      earnedUsd: fields[8] as double,
      startDate: fields[9] as DateTime,
      endDate: fields[10] as DateTime?,
      walletAddress: fields[11] as String,
      network: fields[12] as String,
      userId: fields[13] as String,
      lastUpdated: fields[14] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DeFiPosition obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.protocol)
      ..writeByte(2)
      ..write(obj.positionType)
      ..writeByte(3)
      ..write(obj.asset)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.valueUsd)
      ..writeByte(6)
      ..write(obj.apr)
      ..writeByte(7)
      ..write(obj.earned)
      ..writeByte(8)
      ..write(obj.earnedUsd)
      ..writeByte(9)
      ..write(obj.startDate)
      ..writeByte(10)
      ..write(obj.endDate)
      ..writeByte(11)
      ..write(obj.walletAddress)
      ..writeByte(12)
      ..write(obj.network)
      ..writeByte(13)
      ..write(obj.userId)
      ..writeByte(14)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeFiPositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NFTAssetAdapter extends TypeAdapter<NFTAsset> {
  @override
  final int typeId = 24;

  @override
  NFTAsset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NFTAsset(
      id: fields[0] as String,
      contractAddress: fields[1] as String,
      tokenId: fields[2] as String,
      name: fields[3] as String,
      description: fields[4] as String?,
      collection: fields[5] as String,
      imageUrl: fields[6] as String?,
      lastPrice: fields[7] as double?,
      floorPrice: fields[8] as double?,
      network: fields[9] as String,
      walletAddress: fields[10] as String,
      userId: fields[11] as String,
      acquiredDate: fields[12] as DateTime,
      lastUpdated: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NFTAsset obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.contractAddress)
      ..writeByte(2)
      ..write(obj.tokenId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.collection)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.lastPrice)
      ..writeByte(8)
      ..write(obj.floorPrice)
      ..writeByte(9)
      ..write(obj.network)
      ..writeByte(10)
      ..write(obj.walletAddress)
      ..writeByte(11)
      ..write(obj.userId)
      ..writeByte(12)
      ..write(obj.acquiredDate)
      ..writeByte(13)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NFTAssetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 14;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.send;
      case 1:
        return TransactionType.receive;
      case 2:
        return TransactionType.swap;
      case 3:
        return TransactionType.stake;
      case 4:
        return TransactionType.unstake;
      case 5:
        return TransactionType.reward;
      case 6:
        return TransactionType.bridge;
      case 7:
        return TransactionType.liquidity;
      case 8:
        return TransactionType.nft;
      case 9:
        return TransactionType.contract;
      case 10:
        return TransactionType.unknown;
      default:
        return TransactionType.send;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.send:
        writer.writeByte(0);
        break;
      case TransactionType.receive:
        writer.writeByte(1);
        break;
      case TransactionType.swap:
        writer.writeByte(2);
        break;
      case TransactionType.stake:
        writer.writeByte(3);
        break;
      case TransactionType.unstake:
        writer.writeByte(4);
        break;
      case TransactionType.reward:
        writer.writeByte(5);
        break;
      case TransactionType.bridge:
        writer.writeByte(6);
        break;
      case TransactionType.liquidity:
        writer.writeByte(7);
        break;
      case TransactionType.nft:
        writer.writeByte(8);
        break;
      case TransactionType.contract:
        writer.writeByte(9);
        break;
      case TransactionType.unknown:
        writer.writeByte(10);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InsightTypeAdapter extends TypeAdapter<InsightType> {
  @override
  final int typeId = 21;

  @override
  InsightType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InsightType.riskWarning;
      case 1:
        return InsightType.opportunityAlert;
      case 2:
        return InsightType.marketTrend;
      case 3:
        return InsightType.portfolioImbalance;
      case 4:
        return InsightType.feeOptimization;
      case 5:
        return InsightType.taxConsideration;
      case 6:
        return InsightType.educationalContent;
      case 7:
        return InsightType.priceAlert;
      default:
        return InsightType.riskWarning;
    }
  }

  @override
  void write(BinaryWriter writer, InsightType obj) {
    switch (obj) {
      case InsightType.riskWarning:
        writer.writeByte(0);
        break;
      case InsightType.opportunityAlert:
        writer.writeByte(1);
        break;
      case InsightType.marketTrend:
        writer.writeByte(2);
        break;
      case InsightType.portfolioImbalance:
        writer.writeByte(3);
        break;
      case InsightType.feeOptimization:
        writer.writeByte(4);
        break;
      case InsightType.taxConsideration:
        writer.writeByte(5);
        break;
      case InsightType.educationalContent:
        writer.writeByte(6);
        break;
      case InsightType.priceAlert:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
