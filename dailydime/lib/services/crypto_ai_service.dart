import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import 'package:dailydime/models/crypto_models.dart';
import 'package:dailydime/utils/crypto_repository.dart';
import 'package:dailydime/services/crypto_service.dart';

/// Service for AI-powered insights using Gemini API
class CryptoAiService {
  final CryptoRepository _repository;
  final CryptoService _cryptoService;
  final Uuid _uuid = const Uuid();
  
  // Gemini API config
  final String _apiKey;
  final String _model;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  CryptoAiService({
    required CryptoRepository repository,
    required CryptoService cryptoService,
    required String apiKey,
    required String model,
  }) : 
    _repository = repository,
    _cryptoService = cryptoService,
    _apiKey = apiKey,
    _model = model;

  /// Generate budget advice based on transaction history and portfolio
  Future<BudgetSuggestion> generateBudgetAdvice() async {
    try {
      // Get portfolio data
      final portfolio = await _repository.getPortfolio();
      if (portfolio == null) {
        throw Exception('Portfolio data not available');
      }
      
      // Get recent transactions
      final transactions = await _repository.getAllTransactions(limit: 50);
      
      // Get market data
      final marketData = await _cryptoService.getMarketOverview();
      
      // Get risk assessment
      final riskAssessment = await assessPortfolioRisk();
      
      // Prepare data for Gemini
      final prompt = _buildBudgetAdvicePrompt(
        portfolio: portfolio,
        transactions: transactions,
        marketData: marketData,
        riskAssessment: riskAssessment,
      );
      
      // Call Gemini API
      final response = await _callGeminiApi(prompt);
      
      // Parse the response
      final suggestion = _parseBudgetSuggestion(response);
      
      // Save the suggestion
      await _repository.saveBudgetSuggestion(suggestion);
      
      return suggestion;
    } catch (e) {
      throw Exception('Failed to generate budget advice: ${e.toString()}');
    }
  }
  
  /// Generate portfolio insights
  Future<List<Insight>> getPortfolioInsights() async {
    try {
      // Get portfolio data
      final portfolio = await _repository.getPortfolio();
      if (portfolio == null) {
        throw Exception('Portfolio data not available');
      }
      
      // Get market data
      final marketData = await _cryptoService.getMarketOverview();
      
      // Get DeFi positions
      final defiPositions = await _repository.getDefiPositions();
      
      // Prepare data for Gemini
      final prompt = _buildPortfolioInsightsPrompt(
        portfolio: portfolio,
        marketData: marketData,
        defiPositions: defiPositions,
      );
      
      // Call Gemini API
      final response = await _callGeminiApi(prompt);
      
      // Parse the response
      final insights = _parseInsights(response);
      
      // Save the insights
      for (final insight in insights) {
        await _repository.saveInsight(insight);
      }
      
      return insights;
    } catch (e) {
      throw Exception('Failed to generate portfolio insights: ${e.toString()}');
    }
  }
  
  /// Analyze spending patterns
  Future<String> analyzeSpendingPattern() async {
    try {
      // Get recent transactions
      final transactions = await _repository.getAllTransactions(limit: 100);
      
      // Prepare data for Gemini
      final prompt = _buildSpendingPatternPrompt(transactions);
      
      // Call Gemini API
      final response = await _callGeminiApi(prompt);
      
      return response;
    } catch (e) {
      throw Exception('Failed to analyze spending pattern: ${e.toString()}');
    }
  }
  
  /// Assess portfolio risk
  Future<RiskAssessment> assessPortfolioRisk() async {
    try {
      // Get portfolio data
      final portfolio = await _repository.getPortfolio();
      if (portfolio == null) {
        throw Exception('Portfolio data not available');
      }
      
      // Get market data
      final marketData = await _cryptoService.getMarketOverview();
      
      // Prepare data for Gemini
      final prompt = _buildRiskAssessmentPrompt(
        portfolio: portfolio,
        marketData: marketData,
      );
      
      // Call Gemini API
      final response = await _callGeminiApi(prompt);
      
      // Parse the response
      final assessment = _parseRiskAssessment(response);
      
      // Save the assessment
      await _repository.saveRiskAssessment(assessment);
      
      return assessment;
    } catch (e) {
      // Try to get cached assessment if available
      final cachedAssessment = _repository.getLatestRiskAssessment();
      if (cachedAssessment != null) {
        return cachedAssessment;
      }
      
      throw Exception('Failed to assess portfolio risk: ${e.toString()}');
    }
  }
  
  /// Get educational content about a specific crypto topic
  Future<String> getEducationalContent(String topic) async {
    try {
      // Prepare data for Gemini
      final prompt = '''
        Act as a cryptocurrency expert providing educational content.
        Create a concise but informative explanation about $topic.
        Include key concepts, important considerations, and practical advice.
        Structure your response for someone with basic knowledge of cryptocurrencies.
        Avoid technical jargon when possible, but explain necessary terms.
        Keep the response under 500 words.
      ''';
      
      // Call Gemini API
      final response = await _callGeminiApi(prompt);
      
      return response;
    } catch (e) {
      throw Exception('Failed to get educational content: ${e.toString()}');
    }
  }
  
  /// Get gas fee optimization suggestions
  Future<String> getGasFeeOptimizationSuggestions(String network) async {
    try {
      // Get current gas prices
      final gasFee = await _cryptoService.estimateGasFees(network);
      
      // Prepare data for Gemini
      final prompt = '''
        Act as a cryptocurrency gas fee optimization expert.
        The current estimated gas fee on $network is $gasFee.
        Provide practical suggestions for optimizing gas fees on this network.
        Include information about:
        - Whether current gas prices are high, average, or low
        - Best times to transact based on historical patterns
        - Transaction batching possibilities
        - Alternative networks to consider if applicable
        - Advanced techniques for reducing gas costs
        Format your response as practical advice that a user can immediately apply.
      ''';
      
      // Call Gemini API
      final response = await _callGeminiApi(prompt);
      
      return response;
    } catch (e) {
      throw Exception('Failed to get gas fee optimization suggestions: ${e.toString()}');
    }
  }
  
  /// Analyze a specific token/coin and provide investment insight
  Future<String> analyzeToken(String token, String symbol) async {
    try {
      // Get token price data
      final price = await _cryptoService.getCurrentPrices();
      final tokenPrice = price[token];
      
      if (tokenPrice == null) {
        throw Exception('Price data not available for $symbol');
      }
      
      // Get price history
      final history = await _cryptoService.getPriceHistory(token, const Duration(days: 30));
      
      // Prepare data for Gemini
      final prompt = '''
        Act as a cryptocurrency analyst providing investment insights.
        Analyze $symbol ($token) based on the following data:
        
        Current price: $${tokenPrice.price}
        24h change: ${tokenPrice.change24h}%
        24h volume: $${tokenPrice.volume24h}
        Market cap: $${tokenPrice.marketCap}
        
        The price has moved from $${history.prices.first.price} to $${history.prices.last.price} over the last 30 days.
        
        Provide a balanced analysis including:
        - Technical indicators (trend, support/resistance, volume patterns)
        - Key metrics evaluation
        - Potential catalysts or risks
        - Market sentiment
        
        Do not make explicit price predictions or financial advice, but frame insights as considerations.
        Keep the response under 400 words.
      ''';
      
      // Call Gemini API
      final response = await _callGeminiApi(prompt);
      
      return response;
    } catch (e) {
      throw Exception('Failed to analyze token: ${e.toString()}');
    }
  }
  
  // ==========================================================================
  // PRIVATE HELPER METHODS
  // ==========================================================================
  
  /// Build prompt for budget advice
  String _buildBudgetAdvicePrompt({
    required Portfolio portfolio,
    required List<CryptoTransaction> transactions,
    required MarketData marketData,
    required RiskAssessment riskAssessment,
  }) {
    // Calculate some metrics for better advice
    final totalCryptoValue = portfolio.totalValue;
    
    // Get transaction patterns
    final buys = transactions.where((tx) => tx.type == TransactionType.receive).length;
    final sells = transactions.where((tx) => tx.type == TransactionType.send).length;
    final totalGasFees = transactions.fold(0.0, (sum, tx) => sum + tx.gasFeeUsd);
    
    // Calculate portfolio allocation
    final allocation = portfolio.assetAllocation.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}%').join(', ');
    
    return '''
      Act as a crypto-savvy financial advisor helping with budget allocation.
      
      PORTFOLIO SUMMARY:
      - Total crypto value: $${totalCryptoValue.toStringAsFixed(2)}
      - 24h change: ${portfolio.percentChange24h.toStringAsFixed(2)}%
      - Asset allocation: $allocation
      - Risk level: ${riskAssessment.riskCategory} (${riskAssessment.overallRiskScore}/100)
      
      TRANSACTION PATTERNS:
      - Buys: $buys
      - Sells: $sells
      - Total gas fees spent: $${totalGasFees.toStringAsFixed(2)}
      
      MARKET OVERVIEW:
      - Total market cap: $${marketData.totalMarketCap.toStringAsFixed(0)}
      - 24h market change: ${marketData.marketCapChange24h.toStringAsFixed(2)}%
      - BTC dominance: ${marketData.btcDominance.toStringAsFixed(2)}%
      
      Based on this data, generate ONE specific budget suggestion with the following structure:
      1. A clear title (Starting with "TITLE: ")
      2. A detailed description of the suggestion (Starting with "DESCRIPTION: ")
      3. 2-3 specific actionable steps (Starting with "ACTIONS: " and each action on a new line starting with "- ")
      4. An estimated potential savings or gain amount (Starting with "POTENTIAL_SAVINGS: " just the number in USD)
      5. A risk level (Starting with "RISK_LEVEL: " and using only Low, Medium, or High)
      
      The suggestion should be specific, practical, and tailored to optimize the crypto portfolio while maintaining financial health.
    ''';
  }
  
  /// Build prompt for portfolio insights
  String _buildPortfolioInsightsPrompt({
    required Portfolio portfolio,
    required MarketData marketData,
    required List<DeFiPosition> defiPositions,
  }) {
    // Calculate some metrics
    final totalDeFiValue = defiPositions.fold(0.0, (sum, pos) => sum + pos.valueUsd);
    final avgApr = defiPositions.isEmpty ? 0.0 : 
        defiPositions.fold(0.0, (sum, pos) => sum + pos.apr) / defiPositions.length;
    
    final allocation = portfolio.assetAllocation.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}%').join(', ');
    
    return '''
      Act as a crypto portfolio analyst providing actionable insights.
      
      PORTFOLIO SUMMARY:
      - Total crypto value: $${portfolio.totalValue.toStringAsFixed(2)}
      - 24h change: ${portfolio.percentChange24h.toStringAsFixed(2)}%
      - Asset allocation: $allocation
      - Number of wallets: ${portfolio.wallets.length}
      
      DEFI POSITIONS:
      - Total DeFi value: $${totalDeFiValue.toStringAsFixed(2)}
      - Average APR: ${avgApr.toStringAsFixed(2)}%
      - Number of positions: ${defiPositions.length}
      
      MARKET OVERVIEW:
      - Total market cap: $${marketData.totalMarketCap.toStringAsFixed(0)}
      - 24h market change: ${marketData.marketCapChange24h.toStringAsFixed(2)}%
      - BTC dominance: ${marketData.btcDominance.toStringAsFixed(2)}%
      - Top gainer: ${marketData.topGainers.isNotEmpty ? marketData.topGainers.first.symbol + ' (+' + marketData.topGainers.first.change24h.toStringAsFixed(2) + '%)' : 'None'}
      - Top loser: ${marketData.topLosers.isNotEmpty ? marketData.topLosers.first.symbol + ' (' + marketData.topLosers.first.change24h.toStringAsFixed(2) + '%)' : 'None'}
      
      Based on this data, generate EXACTLY 3 insights with the following structure for each:
      1. INSIGHT_TITLE: A clear, concise title
      2. INSIGHT_DESCRIPTION: A detailed explanation of the insight (2-3 sentences)
      3. INSIGHT_TYPE: The type of insight (one of: riskWarning, opportunityAlert, marketTrend, portfolioImbalance, feeOptimization, taxConsideration, educationalContent, priceAlert)
      4. ASSET_REFERENCE: Specific asset or category this relates to (or "general" if not specific)
      5. IMPACT_VALUE: Estimated impact in USD or percentage (just the number, no currency symbol)
      
      Separate each insight with "---"
      
      Make the insights specific, actionable, and based on the data provided. Focus on portfolio optimization, risk management, and opportunity identification.
    ''';
  }
  
  /// Build prompt for spending pattern analysis
  String _buildSpendingPatternPrompt(List<CryptoTransaction> transactions) {
    // Calculate some metrics
    final totalSpent = transactions
        .where((tx) => tx.type == TransactionType.send)
        .fold(0.0, (sum, tx) => sum + tx.valueUsd);
    
    final totalReceived = transactions
        .where((tx) => tx.type == TransactionType.receive)
        .fold(0.0, (sum, tx) => sum + tx.valueUsd);
    
    final totalGasFees = transactions.fold(0.0, (sum, tx) => sum + tx.gasFeeUsd);
    
    // Group transactions by month
    final monthlyTransactions = <String, List<CryptoTransaction>>{};
    for (final tx in transactions) {
      final month = '${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}';
      if (!monthlyTransactions.containsKey(month)) {
        monthlyTransactions[month] = [];
      }
      monthlyTransactions[month]!.add(tx);
    }
    
    // Calculate monthly stats
    final monthlyStats = monthlyTransactions.entries.map((entry) {
      final month = entry.key;
      final txs = entry.value;
      final spent = txs
          .where((tx) => tx.type == TransactionType.send)
          .fold(0.0, (sum, tx) => sum + tx.valueUsd);
      final received = txs
          .where((tx) => tx.type == TransactionType.receive)
          .fold(0.0, (sum, tx) => sum + tx.valueUsd);
      final fees = txs.fold(0.0, (sum, tx) => sum + tx.gasFeeUsd);
      
      return '$month: Spent $${spent.toStringAsFixed(2)}, Received $${received.toStringAsFixed(2)}, Gas Fees $${fees.toStringAsFixed(2)}';
    }).join('\n');
    
    return '''
      Act as a crypto spending pattern analyst.
      
      TRANSACTION SUMMARY:
      - Total transactions: ${transactions.length}
      - Total spent: $${totalSpent.toStringAsFixed(2)}
      - Total received: $${totalReceived.toStringAsFixed(2)}
      - Total gas fees: $${totalGasFees.toStringAsFixed(2)}
      
      MONTHLY BREAKDOWN:
      $monthlyStats
      
      Based on this data, analyze the spending patterns and provide insights on:
      1. Trends in spending and receiving over time
      2. Gas fee efficiency and optimization opportunities
      3. Timing patterns (e.g., buying during market dips or peaks)
      4. Potential emotional trading patterns (FOMO, panic selling)
      5. Recommendations for improved spending discipline
      
      Format your response as a cohesive analysis with specific, actionable recommendations.
      Be honest but constructive in your assessment. If there are concerning patterns, highlight them tactfully.
    ''';
  }
  
  /// Build prompt for risk assessment
  String _buildRiskAssessmentPrompt({
    required Portfolio portfolio,
    required MarketData marketData,
  }) {
    // Calculate concentration metrics
    final topAsset = portfolio.assetAllocation.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topThreeAssets = portfolio.assetAllocation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThreeConcentration = topThreeAssets.take(3).fold(0.0, (sum, e) => sum + e.value);
    
    return '''
      Act as a crypto risk assessment expert.
      
      PORTFOLIO SUMMARY:
      - Total crypto value: $${portfolio.totalValue.toStringAsFixed(2)}
      - Number of assets: ${portfolio.assetAllocation.length}
      - Highest concentration: ${topAsset.key} (${topAsset.value.toStringAsFixed(2)}%)
      - Top 3 assets concentration: ${topThreeConcentration.toStringAsFixed(2)}%
      - 24h portfolio volatility: ${portfolio.percentChange24h.abs().toStringAsFixed(2)}%
      
      MARKET OVERVIEW:
      - Total market cap: $${marketData.totalMarketCap.toStringAsFixed(0)}
      - 24h market change: ${marketData.marketCapChange24h.toStringAsFixed(2)}%
      - BTC dominance: ${marketData.btcDominance.toStringAsFixed(2)}%
      
      Based on this data, provide a comprehensive risk assessment with the following structure:
      1. OVERALL_RISK_SCORE: A number from 1-100 representing the overall risk level
      2. RISK_CATEGORY: The risk category (Low, Medium, High, Very High)
      3. RISK_FACTORS: A list of risk factors and their individual scores (on a scale of 1-100):
         - Concentration risk: [score]
         - Volatility risk: [score]
         - Market risk: [score]
         - Liquidity risk: [score]
         - Correlation risk: [score]
      4. RISK_MITIGATION: A list of 3-5 specific suggestions to mitigate the identified risks
      5. PORTFOLIO_VOLATILITY: An estimated portfolio volatility score (just the number)
      
      Be thorough, data-driven, and specific in your assessment.
    ''';
  }
  
  /// Call the Gemini API
  Future<String> _callGeminiApi(String prompt) async {
    try {
      final url = '$_baseUrl/models/$_model:generateContent?key=$_apiKey';
      
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        }
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to call Gemini API: ${response.body}');
      }
      
      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['candidates'] == null || 
          jsonResponse['candidates'].isEmpty ||
          jsonResponse['candidates'][0]['content'] == null ||
          jsonResponse['candidates'][0]['content']['parts'] == null ||
          jsonResponse['candidates'][0]['content']['parts'].isEmpty) {
        throw Exception('Invalid response from Gemini API');
      }
      
      return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
    } catch (e) {
      throw Exception('Failed to call Gemini API: ${e.toString()}');
    }
  }
  
  /// Parse budget suggestion from Gemini response
  BudgetSuggestion _parseBudgetSuggestion(String response) {
    try {
      // Extract fields from response
      final titleMatch = RegExp(r'TITLE:\s*(.*?)(?:\n|$)').firstMatch(response);
      final descriptionMatch = RegExp(r'DESCRIPTION:\s*(.*?)(?=\nACTIONS:|$)', dotAll: true).firstMatch(response);
      final actionsMatch = RegExp(r'ACTIONS:\s*((?:- .*?\n?)+)').firstMatch(response);
      final savingsMatch = RegExp(r'POTENTIAL_SAVINGS:\s*(\d+(?:\.\d+)?)').firstMatch(response);
      final riskMatch = RegExp(r'RISK_LEVEL:\s*(Low|Medium|High)').firstMatch(response);
      
      // Extract actions as a list
      final actionsText = actionsMatch?.group(1) ?? '';
      final actions = actionsText
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.startsWith('- '))
          .map((s) => s.substring(2).trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      return BudgetSuggestion(
        id: _uuid.v4(),
        title: titleMatch?.group(1)?.trim() ?? 'Budget Optimization Suggestion',
        description: descriptionMatch?.group(1)?.trim() ?? 'No description provided',
        actions: actions.isEmpty ? ['Review your portfolio allocation', 'Monitor gas fees'] : actions,
        potentialSavings: double.tryParse(savingsMatch?.group(1) ?? '0') ?? 0.0,
        riskLevel: riskMatch?.group(1) ?? 'Medium',
        generated: DateTime.now(),
        isApplied: false,
      );
    } catch (e) {
      // Fallback to a default suggestion
      return BudgetSuggestion(
        id: _uuid.v4(),
        title: 'Optimize Your Crypto Strategy',
        description: 'Based on your transaction history and market conditions, consider adjusting your portfolio allocation and managing gas fees more efficiently.',
        actions: [
          'Review your portfolio allocation',
          'Monitor gas fees and transaction timing',
          'Consider DCA strategy for volatile assets'
        ],
        potentialSavings: 0.0,
        riskLevel: 'Medium',
        generated: DateTime.now(),
        isApplied: false,
      );
    }
  }
  
  /// Parse insights from Gemini response
  List<Insight> _parseInsights(String response) {
    try {
      // Split the response into individual insights
      final insightBlocks = response.split('---');
      
      return insightBlocks.map((block) {
        final titleMatch = RegExp(r'INSIGHT_TITLE:\s*(.*?)(?:\n|$)').firstMatch(block);
        final descriptionMatch = RegExp(r'INSIGHT_DESCRIPTION:\s*(.*?)(?=\nINSIGHT_TYPE:|$)', dotAll: true).firstMatch(block);
        final typeMatch = RegExp(r'INSIGHT_TYPE:\s*(riskWarning|opportunityAlert|marketTrend|portfolioImbalance|feeOptimization|taxConsideration|educationalContent|priceAlert)').firstMatch(block);
        final assetMatch = RegExp(r'ASSET_REFERENCE:\s*(.*?)(?:\n|$)').firstMatch(block);
        final impactMatch = RegExp(r'IMPACT_VALUE:\s*(\d+(?:\.\d+)?)').firstMatch(block);
        
        // Parse the insight type
        final typeStr = typeMatch?.group(1) ?? 'marketTrend';
        final insightType = InsightType.values.firstWhere(
          (t) => t.toString().split('.').last == typeStr,
          orElse: () => InsightType.marketTrend,
        );
        
        return Insight(
          id: _uuid.v4(),
          title: titleMatch?.group(1)?.trim() ?? 'Market Insight',
          description: descriptionMatch?.group(1)?.trim() ?? 'No description provided',
          type: insightType,
          assetReference: assetMatch?.group(1)?.trim(),
          impactValue: double.tryParse(impactMatch?.group(1) ?? '0'),
          generated: DateTime.now(),
          isRead: false,
        );
      }).toList();
    } catch (e) {
      // Fallback to a default insight
      return [
        Insight(
          id: _uuid.v4(),
          title: 'Market Trend Analysis',
          description: 'Current market conditions suggest maintaining a diversified portfolio with focus on blue-chip cryptocurrencies.',
          type: InsightType.marketTrend,
          assetReference: 'general',
          impactValue: null,
          generated: DateTime.now(),
          isRead: false,
        )
      ];
    }
  }
  
  /// Parse risk assessment from Gemini response
  RiskAssessment _parseRiskAssessment(String response) {
    try {
      // Extract fields from response
      final scoreMatch = RegExp(r'OVERALL_RISK_SCORE:\s*(\d+(?:\.\d+)?)').firstMatch(response);
      final categoryMatch = RegExp(r'RISK_CATEGORY:\s*(Low|Medium|High|Very High)').firstMatch(response);
      
      // Extract risk factors
      final riskFactorsSection = RegExp(r'RISK_FACTORS:\s*([\s\S]*?)(?=\n\w+:|$)').firstMatch(response)?.group(1) ?? '';
      final riskFactors = <String, double>{};
      
      final factorRegex = RegExp(r'- (.*?):\s*(\d+(?:\.\d+)?)');
      for (final match in factorRegex.allMatches(riskFactorsSection)) {
        final factor = match.group(1)?.trim() ?? '';
        final score = double.tryParse(match.group(2) ?? '0') ?? 0.0;
        if (factor.isNotEmpty) {
          riskFactors[factor] = score;
        }
      }
      
      // Extract risk mitigation suggestions
      final mitigationSection = RegExp(r'RISK_MITIGATION:\s*([\s\S]*?)(?=\n\w+:|$)').firstMatch(response)?.group(1) ?? '';
      final suggestions = mitigationSection
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.startsWith('- '))
          .map((s) => s.substring(2).trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      // Extract portfolio volatility
      final volatilityMatch = RegExp(r'PORTFOLIO_VOLATILITY:\s*(\d+(?:\.\d+)?)').firstMatch(response);
      
      return RiskAssessment(
        id: _uuid.v4(),
        overallRiskScore: double.tryParse(scoreMatch?.group(1) ?? '50') ?? 50.0,
        riskCategory: categoryMatch?.group(1) ?? 'Medium',
        riskFactors: riskFactors.isEmpty ? {'General Risk': 50.0} : riskFactors,
        riskMitigationSuggestions: suggestions.isEmpty ? 
            ['Diversify your portfolio', 'Consider rebalancing assets'] : suggestions,
        portfolioVolatility: double.tryParse(volatilityMatch?.group(1) ?? '0') ?? 0.0,
        generated: DateTime.now(),
      );
    } catch (e) {
      // Fallback to a default risk assessment
      return RiskAssessment(
        id: _uuid.v4(),
        overallRiskScore: 50.0,
        riskCategory: 'Medium',
        riskFactors: {
          'Concentration Risk': 50.0,
          'Volatility Risk': 60.0,
          'Market Risk': 50.0,
          'Liquidity Risk': 40.0,
          'Correlation Risk': 45.0,
        },
        riskMitigationSuggestions: [
          'Diversify your portfolio across different asset classes',
          'Consider rebalancing to reduce concentration in high-risk assets',
          'Implement a dollar-cost averaging strategy for volatile assets',
        ],
        portfolioVolatility: 15.0,
        generated: DateTime.now(),
      );
    }
  }
}