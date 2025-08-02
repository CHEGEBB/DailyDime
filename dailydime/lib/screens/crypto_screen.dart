// lib/screens/crypto_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:dailydime/models/crypto_models.dart';
import 'package:dailydime/services/crypto_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/widgets/crypto/glassmorphic_container.dart';
import 'package:dailydime/widgets/crypto/token_icon.dart';
import 'package:dailydime/widgets/crypto/market_sentiment_widget.dart';
import 'package:dailydime/widgets/crypto/portfolio_card.dart';
import 'package:dailydime/widgets/crypto/transaction_item.dart';
import 'package:dailydime/widgets/shimmer_loading.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({Key? key}) : super(key: key);

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CryptoService _cryptoService;
  late StreamSubscription<Portfolio> _portfolioSubscription;
  late StreamSubscription<Map<String, TokenPrice>> _pricesSubscription;
  late StreamSubscription<List<Insight>> _insightsSubscription;
  
  Portfolio? _portfolio;
  Map<String, TokenPrice> _prices = {};
  List<CryptoTransaction> _recentTransactions = [];
  List<Insight> _insights = [];
  MarketData? _marketData;
  String _selectedTimeframe = '1W';
  bool _isLoading = true;
  RiskAssessment? _riskAssessment;
  PriceHistory? _portfolioPriceHistory;

  bool _isAddingWallet = false;
  final TextEditingController _walletAddressController = TextEditingController();
  final TextEditingController _walletNameController = TextEditingController();
  String _selectedNetwork = 'ethereum';
  bool _isWalletAddressValid = false;
  String _walletError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Delayed to allow widgets to fully build
    Future.microtask(() {
      _cryptoService = Provider.of<CryptoService>(context, listen: false);
      _loadInitialData();
      _setupStreams();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _walletAddressController.dispose();
    _walletNameController.dispose();
    _portfolioSubscription.cancel();
    _pricesSubscription.cancel();
    _insightsSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      final portfolio = await _cryptoService.getPortfolio();
      final prices = await _cryptoService.getCurrentPrices();
      final transactions = await _cryptoService.getRecentTransactions(limit: 10);
      final marketData = await _cryptoService.getMarketOverview();
      final insights = await _cryptoService.getPortfolioInsights();
      final risk = await _cryptoService.assessPortfolioRisk();
      
      // For the most popular token in portfolio
      String topToken = 'ethereum'; // Default
      if (portfolio.assetAllocation.isNotEmpty) {
        topToken = portfolio.assetAllocation.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
            .toLowerCase();
      }
      
      // Get price history for visualization
      final history = await _cryptoService.getPriceHistory(
        topToken, 
        const Duration(days: 7)
      );
      
      setState(() {
        _portfolio = portfolio;
        _prices = prices;
        _recentTransactions = transactions;
        _marketData = marketData;
        _insights = insights;
        _riskAssessment = risk;
        _portfolioPriceHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading crypto data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupStreams() {
    // Portfolio updates
    _portfolioSubscription = _cryptoService.portfolioStream.listen((portfolio) {
      setState(() => _portfolio = portfolio);
    });
    
    // Price updates
    _pricesSubscription = _cryptoService.pricesStream.listen((prices) {
      setState(() => _prices = prices);
    });
    
    // Insights updates
    _insightsSubscription = _cryptoService.insightsStream.listen((insights) {
      setState(() => _insights = insights);
    });
  }

  Future<void> _refreshData() async {
    await _loadInitialData();
  }

  void _validateWalletAddress(String address) {
    setState(() {
      if (address.isEmpty) {
        _isWalletAddressValid = false;
        _walletError = '';
      } else if (address.length < 26) {
        _isWalletAddressValid = false;
        _walletError = 'Address too short';
      } else {
        _isWalletAddressValid = true;
        _walletError = '';
      }
    });
  }

  Future<void> _addWallet() async {
    if (!_isWalletAddressValid) return;
    
    try {
      setState(() => _isLoading = true);
      
      await _cryptoService.addWallet(
        address: _walletAddressController.text,
        network: _selectedNetwork,
        name: _walletNameController.text.isNotEmpty ? _walletNameController.text : null,
      );
      
      // Clear inputs and update state
      _walletAddressController.clear();
      _walletNameController.clear();
      setState(() {
        _isAddingWallet = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wallet added successfully'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add wallet: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      body: _isLoading 
          ? _buildLoadingView(themeService)
          : _buildMainContent(themeService),
    );
  }

  Widget _buildLoadingView(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/lottie.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your crypto portfolio...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeService themeService) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: themeService.primaryColor,
      backgroundColor: themeService.cardColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(themeService),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroPortfolioCard(themeService),
                _buildQuickActions(themeService),
                _buildTabBar(themeService),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPortfolioTab(themeService),
                _buildTransactionsTab(themeService),
                _buildDeFiTab(themeService),
                _buildNFTTab(themeService),
                _buildInsightsTab(themeService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeService themeService) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            title: Row(
              children: [
                Text(
                  'Crypto Portfolio',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: themeService.textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: themeService.textColor),
                  onPressed: () {}, // Would open notifications
                ),
                IconButton(
                  icon: Icon(Icons.search, color: themeService.textColor),
                  onPressed: () {}, // Would open search
                ),
              ],
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeService.primaryColor.withOpacity(0.3),
                    themeService.secondaryColor.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPortfolioCard(ThemeService themeService) {
    final portfolio = _portfolio;
    final isPositiveChange = portfolio?.percentChange24h ?? 0 >= 0;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 220,
        borderRadius: 24,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.primaryColor.withOpacity(0.1),
            themeService.secondaryColor.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.primaryColor.withOpacity(0.5),
            themeService.secondaryColor.withOpacity(0.5),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Total Portfolio Value',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: themeService.subtextColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositiveChange 
                          ? themeService.successColor.withOpacity(0.2)
                          : themeService.errorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositiveChange ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: isPositiveChange 
                              ? themeService.successColor
                              : themeService.errorColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${portfolio?.percentChange24h.toStringAsFixed(2)}%',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isPositiveChange 
                                ? themeService.successColor
                                : themeService.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: portfolio?.totalValue ?? 0,
                ),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    '\$${NumberFormat('#,##0.00').format(value)}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_portfolioPriceHistory != null && _portfolioPriceHistory!.prices.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: DateTimeAxis(
                      isVisible: false,
                      majorGridLines: const MajorGridLines(width: 0),
                    ),
                    primaryYAxis: NumericAxis(
                      isVisible: false,
                      majorGridLines: const MajorGridLines(width: 0),
                    ),
                    trackballBehavior: TrackballBehavior(
                      enable: true,
                      activationMode: ActivationMode.singleTap,
                      tooltipSettings: const InteractiveTooltip(
                        enable: true,
                        format: '\$point.y',
                      ),
                    ),
                    series: <ChartSeries>[
                      AreaSeries<PricePoint, DateTime>(
                        dataSource: _portfolioPriceHistory!.prices,
                        xValueMapper: (PricePoint data, _) => data.timestamp,
                        yValueMapper: (PricePoint data, _) => data.price,
                        color: isPositiveChange 
                            ? themeService.successColor.withOpacity(0.2)
                            : themeService.errorColor.withOpacity(0.2),
                        borderColor: isPositiveChange 
                            ? themeService.successColor
                            : themeService.errorColor,
                        borderWidth: 2,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPeriodSelector(themeService),
                  _buildAssetAllocationMiniPie(themeService),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeService themeService) {
    final timeframes = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];
    
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: themeService.surfaceColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: timeframes.map((timeframe) {
          final isSelected = timeframe == _selectedTimeframe;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedTimeframe = timeframe),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? themeService.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                timeframe,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? Colors.white : themeService.subtextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAssetAllocationMiniPie(ThemeService themeService) {
    final assetAllocation = _portfolio?.assetAllocation ?? {};
    if (assetAllocation.isEmpty) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: themeService.surfaceColor.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.pie_chart_outline, size: 16, color: themeService.subtextColor),
      );
    }
    
    final pieData = assetAllocation.entries.map((entry) {
      return PieChartData(entry.key, entry.value);
    }).toList();
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: themeService.primaryColor.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SfCircularChart(
        margin: EdgeInsets.zero,
        series: <CircularSeries>[
          DoughnutSeries<PieChartData, String>(
            dataSource: pieData,
            pointColorMapper: (PieChartData data, _) => _getColorForAsset(data.asset, themeService),
            xValueMapper: (PieChartData data, _) => data.asset,
            yValueMapper: (PieChartData data, _) => data.value,
            innerRadius: '60%',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                themeService,
                icon: Icons.add,
                label: 'Add Wallet',
                color: themeService.primaryColor,
                onTap: () => setState(() => _isAddingWallet = true),
              ),
              _buildActionButton(
                themeService,
                icon: Icons.swap_horiz,
                label: 'Swap',
                color: themeService.secondaryColor,
                onTap: () {},
              ),
              _buildActionButton(
                themeService,
                icon: Icons.send,
                label: 'Send',
                color: themeService.infoColor,
                onTap: () {},
              ),
              _buildActionButton(
                themeService,
                icon: Icons.qr_code_scanner,
                label: 'Receive',
                color: themeService.accentColor,
                onTap: () {},
              ),
              _buildActionButton(
                themeService,
                icon: Icons.bar_chart,
                label: 'Markets',
                color: themeService.warningColor,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeService themeService, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: themeService.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: themeService.surfaceColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: themeService.isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: themeService.primaryColor,
            boxShadow: [
              BoxShadow(
                color: themeService.primaryColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: themeService.subtextColor,
          labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
          tabs: const [
            Tab(text: 'Portfolio'),
            Tab(text: 'Transactions'),
            Tab(text: 'DeFi'),
            Tab(text: 'NFTs'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioTab(ThemeService themeService) {
    final wallets = _portfolio?.wallets ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Wallets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          wallets.isEmpty
              ? SliverToBoxAdapter(
                  child: _buildEmptyWalletsView(themeService),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildWalletCard(wallets[index], themeService),
                    childCount: wallets.length,
                  ),
                ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Market Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMarketOverviewCard(themeService),
                const SizedBox(height: 24),
                Text(
                  'Top Performers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTopPerformersGrid(themeService),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWalletsView(ThemeService themeService) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 200,
      borderRadius: 24,
      blur: 10,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          themeService.surfaceColor.withOpacity(0.1),
          themeService.surfaceColor.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          themeService.surfaceColor.withOpacity(0.3),
          themeService.surfaceColor.withOpacity(0.1),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: themeService.subtextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Wallets Connected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first wallet to start tracking your assets',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: themeService.subtextColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _isAddingWallet = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeService.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Add Wallet'),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(CryptoWallet wallet, ThemeService themeService) {
    final walletName = wallet.name ?? 'Wallet ${wallet.address.substring(0, 4)}...${wallet.address.substring(wallet.address.length - 4)}';
    final networkName = wallet.network.substring(0, 1).toUpperCase() + wallet.network.substring(1);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 120,
        borderRadius: 16,
        blur: 10,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.surfaceColor.withOpacity(0.1),
            themeService.surfaceColor.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.surfaceColor.withOpacity(0.3),
            themeService.surfaceColor.withOpacity(0.1),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNetworkColor(wallet.network, themeService).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getNetworkIcon(wallet.network),
                    color: _getNetworkColor(wallet.network, themeService),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      walletName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeService.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getNetworkColor(wallet.network, themeService).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            networkName,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getNetworkColor(wallet.network, themeService),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${wallet.address.substring(0, 6)}...${wallet.address.substring(wallet.address.length - 4)}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: themeService.subtextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${NumberFormat('#,##0.00').format(wallet.totalValue)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: themeService.textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${wallet.tokens.length} assets',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: themeService.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: themeService.subtextColor),
                onPressed: () {
                  // Would show wallet options
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketOverviewCard(ThemeService themeService) {
    final marketData = _marketData;
    if (marketData == null) {
      return _buildShimmerCard(height: 160);
    }
    
    final isPositiveChange = marketData.marketCapChange24h >= 0;
    
    return GlassmorphicContainer(
      width: double.infinity,
      height: 160,
      borderRadius: 16,
      blur: 10,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          themeService.surfaceColor.withOpacity(0.1),
          themeService.surfaceColor.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          themeService.surfaceColor.withOpacity(0.3),
          themeService.surfaceColor.withOpacity(0.1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositiveChange 
                        ? themeService.successColor.withOpacity(0.2)
                        : themeService.errorColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositiveChange ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: isPositiveChange 
                            ? themeService.successColor
                            : themeService.errorColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${marketData.marketCapChange24h.toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isPositiveChange 
                              ? themeService.successColor
                              : themeService.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildMarketSentimentIndicator(themeService),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMarketStat(
                    themeService,
                    title: 'Global Market Cap',
                    value: '\$${_formatLargeNumber(marketData.totalMarketCap)}',
                  ),
                ),
                Expanded(
                  child: _buildMarketStat(
                    themeService,
                    title: '24h Volume',
                    value: '\$${_formatLargeNumber(marketData.totalVolume24h)}',
                  ),
                ),
                Expanded(
                  child: _buildMarketStat(
                    themeService,
                    title: 'BTC Dominance',
                    value: '${marketData.btcDominance.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketSentimentIndicator(ThemeService themeService) {
    final marketData = _marketData;
    if (marketData == null) return const SizedBox();
    
    String sentiment;
    Color sentimentColor;
    
    if (marketData.marketCapChange24h > 5) {
      sentiment = 'Very Bullish';
      sentimentColor = themeService.successColor;
    } else if (marketData.marketCapChange24h > 1) {
      sentiment = 'Bullish';
      sentimentColor = themeService.successColor.withOpacity(0.8);
    } else if (marketData.marketCapChange24h > -1) {
      sentiment = 'Neutral';
      sentimentColor = themeService.infoColor;
    } else if (marketData.marketCapChange24h > -5) {
      sentiment = 'Bearish';
      sentimentColor = themeService.errorColor.withOpacity(0.8);
    } else {
      sentiment = 'Very Bearish';
      sentimentColor = themeService.errorColor;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: sentimentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sentimentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: sentimentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            sentiment,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: sentimentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStat(
    ThemeService themeService, {
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: themeService.subtextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeService.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformersGrid(ThemeService themeService) {
    final topGainers = _marketData?.topGainers ?? [];
    if (topGainers.isEmpty) {
      return _buildShimmerCard(height: 220);
    }
    
    return Container(
      height: 220,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: topGainers.length,
        itemBuilder: (context, index) => _buildTokenCard(topGainers[index], themeService),
      ),
    );
  }

  Widget _buildTokenCard(TokenPrice token, ThemeService themeService) {
    final isPositiveChange = token.change24h >= 0;
    
    return GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: 16,
      blur: 5,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          themeService.surfaceColor.withOpacity(0.1),
          themeService.surfaceColor.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          isPositiveChange 
              ? themeService.successColor.withOpacity(0.3)
              : themeService.errorColor.withOpacity(0.3),
          themeService.surfaceColor.withOpacity(0.1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getColorForAsset(token.symbol, themeService).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      token.symbol.substring(0, 1),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getColorForAsset(token.symbol, themeService),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    token.symbol,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${token.price < 0.01 ? token.price.toStringAsFixed(6) : token.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: themeService.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositiveChange 
                    ? themeService.successColor.withOpacity(0.2)
                    : themeService.errorColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositiveChange ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: isPositiveChange 
                        ? themeService.successColor
                        : themeService.errorColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${token.change24h.toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isPositiveChange 
                          ? themeService.successColor
                          : themeService.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTransactionFilter(themeService, 'All', isSelected: true),
              _buildTransactionFilter(themeService, 'Sent'),
              _buildTransactionFilter(themeService, 'Received'),
              _buildTransactionFilter(themeService, 'Swapped'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _recentTransactions.isEmpty
                ? _buildEmptyTransactionsView(themeService)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _recentTransactions.length,
                    itemBuilder: (context, index) => _buildTransactionItem(
                      _recentTransactions[index],
                      themeService,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionFilter(ThemeService themeService, String label, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? themeService.primaryColor : themeService.surfaceColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeService.primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isSelected ? Colors.white : themeService.subtextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionsView(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: themeService.subtextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Transactions Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: themeService.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(CryptoTransaction tx, ThemeService themeService) {
    final isReceived = tx.type == TransactionType.receive;
    final color = isReceived ? themeService.successColor : themeService.infoColor;
    final iconData = isReceived ? Icons.arrow_downward : Icons.arrow_upward;
    final formatter = DateFormat.yMMMd().add_jm();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 80,
        borderRadius: 16,
        blur: 5,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.surfaceColor.withOpacity(0.1),
            themeService.surfaceColor.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.surfaceColor.withOpacity(0.3),
            themeService.surfaceColor.withOpacity(0.1),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isReceived ? 'Received' : 'Sent',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeService.textColor,
                      ),
                    ),
                    Text(
                      formatter.format(tx.timestamp),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: themeService.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${isReceived ? '+' : '-'}${tx.amount.toStringAsFixed(4)} ${tx.symbol}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                  ),
                  Text(
                    '\$${tx.valueUsd.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: themeService.subtextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeFiTab(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_graph,
              size: 64,
              color: themeService.subtextColor,
            ),
            const SizedBox(height: 24),
            Text(
              'DeFi Dashboard Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: themeService.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Track your DeFi positions, staking rewards, and liquidity pools in one place',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeService.subtextColor,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Notify Me'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNFTTab(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: themeService.subtextColor,
            ),
            const SizedBox(height: 24),
            Text(
              'NFT Gallery Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: themeService.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'View your NFT collection, track floor prices, and explore the latest drops',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeService.subtextColor,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Notify Me'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRiskAssessmentCard(themeService),
                const SizedBox(height: 24),
                Text(
                  'AI Recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          _insights.isEmpty
              ? SliverToBoxAdapter(
                  child: _buildEmptyInsightsView(themeService),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildInsightCard(_insights[index], themeService),
                    childCount: _insights.length,
                  ),
                ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentCard(ThemeService themeService) {
    final risk = _riskAssessment;
    if (risk == null) {
      return _buildShimmerCard(height: 180);
    }
    
    Color riskColor;
    String riskLabel;
    
    switch (risk.riskLevel) {
      case 'low':
        riskColor = themeService.successColor;
        riskLabel = 'Low Risk';
        break;
      case 'medium':
        riskColor = themeService.warningColor;
        riskLabel = 'Medium Risk';
        break;
      case 'high':
        riskColor = themeService.errorColor;
        riskLabel = 'High Risk';
        break;
      default:
        riskColor = themeService.infoColor;
        riskLabel = 'Unknown Risk';
    }
    
    return GlassmorphicContainer(
      width: double.infinity,
      height: 180,
      borderRadius: 16,
      blur: 10,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          themeService.surfaceColor.withOpacity(0.1),
          themeService.surfaceColor.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          riskColor.withOpacity(0.5),
          themeService.surfaceColor.withOpacity(0.1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Portfolio Risk Assessment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    riskLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRiskMeter(risk.riskScore, themeService),
            const SizedBox(height: 16),
            Text(
              risk.summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: themeService.subtextColor,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskMeter(double riskScore, ThemeService themeService) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: riskScore / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeService.successColor,
                        themeService.warningColor,
                        themeService.errorColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Conservative',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: themeService.successColor,
              ),
            ),
            Text(
              'Balanced',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: themeService.warningColor,
              ),
            ),
            Text(
              'Aggressive',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: themeService.errorColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyInsightsView(ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: themeService.subtextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Insights Available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeService.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add more assets to your portfolio to receive personalized insights',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: themeService.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Insight insight, ThemeService themeService) {
    IconData iconData;
    Color iconColor;
    
    switch (insight.type) {
      case 'tip':
        iconData = Icons.lightbulb_outline;
        iconColor = themeService.infoColor;
        break;
      case 'alert':
        iconData = Icons.warning_amber_rounded;
        iconColor = themeService.warningColor;
        break;
      case 'opportunity':
        iconData = Icons.trending_up;
        iconColor = themeService.successColor;
        break;
      default:
        iconData = Icons.info_outline;
        iconColor = themeService.primaryColor;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 120,
        borderRadius: 16,
        blur: 5,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.surfaceColor.withOpacity(0.1),
            themeService.surfaceColor.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withOpacity(0.3),
            themeService.surfaceColor.withOpacity(0.1),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeService.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeService.subtextColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'AI Generated',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: themeService.subtextColor,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: themeService.surfaceColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            insight.type.capitalize(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: iconColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add Wallet Modal
  void _showAddWalletModal(BuildContext context, ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Add New Wallet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeService.textColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: themeService.subtextColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Wallet Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _walletAddressController,
                  onChanged: _validateWalletAddress,
                  decoration: InputDecoration(
                    hintText: '0x...',
                    filled: true,
                    fillColor: themeService.surfaceColor.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeService.subtextColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeService.subtextColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeService.primaryColor),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeService.errorColor),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.qr_code_scanner, color: themeService.primaryColor),
                      onPressed: () {
                        // Would scan QR code
                      },
                    ),
                    errorText: _walletError.isNotEmpty ? _walletError : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Wallet Name (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _walletNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. My Main Wallet',
                    filled: true,
                    fillColor: themeService.surfaceColor.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeService.subtextColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeService.subtextColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeService.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Network',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeService.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildNetworkSelector(setState, themeService),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isWalletAddressValid ? _addWallet : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeService.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: themeService.primaryColor.withOpacity(0.3),
                    ),
                    child: Text(
                      'Add Wallet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkSelector(StateSetter setState, ThemeService themeService) {
    final networks = [
      {'id': 'ethereum', 'name': 'Ethereum', 'icon': Icons.currency_bitcoin},
      {'id': 'bsc', 'name': 'BNB Chain', 'icon': Icons.currency_exchange},
      {'id': 'polygon', 'name': 'Polygon', 'icon': Icons.hexagon_outlined},
      {'id': 'avalanche', 'name': 'Avalanche', 'icon': Icons.ac_unit},
    ];
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: networks.map((network) {
        final isSelected = _selectedNetwork == network['id'];
        
        return GestureDetector(
          onTap: () => setState(() => _selectedNetwork = network['id']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? themeService.primaryColor : themeService.surfaceColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? themeService.primaryColor : themeService.subtextColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  network['icon'] as IconData,
                  color: isSelected ? Colors.white : themeService.subtextColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  network['name']!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : themeService.subtextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isAddingWallet) {
      _showAddWalletModal(context, Provider.of<ThemeService>(context));
      setState(() => _isAddingWallet = false);
    }
  }

  // Utility methods
  Widget _buildShimmerCard({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Color _getNetworkColor(String network, ThemeService themeService) {
    switch (network) {
      case 'ethereum':
        return const Color(0xFF627EEA);
      case 'bsc':
        return const Color(0xFFF3BA2F);
      case 'polygon':
        return const Color(0xFF8247E5);
      case 'avalanche':
        return const Color(0xFFE84142);
      case 'fantom':
        return const Color(0xFF1969FF);
      case 'arbitrum':
        return const Color(0xFF28A0F0);
      default:
        return themeService.primaryColor;
    }
  }

  IconData _getNetworkIcon(String network) {
    switch (network) {
      case 'ethereum':
        return Icons.currency_bitcoin;
      case 'bsc':
        return Icons.currency_exchange;
      case 'polygon':
        return Icons.hexagon_outlined;
      case 'avalanche':
        return Icons.ac_unit;
      case 'fantom':
        return Icons.flash_on;
      case 'arbitrum':
        return Icons.all_inclusive;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getColorForAsset(String asset, ThemeService themeService) {
    final colors = [
      themeService.primaryColor,
      themeService.secondaryColor,
      themeService.accentColor,
      themeService.infoColor,
      themeService.warningColor,
      themeService.successColor,
      themeService.errorColor,
    ];
    
    // Use the asset name to deterministically select a color
    final index = asset.codeUnits.fold<int>(0, (prev, element) => prev + element) % colors.length;
    return colors[index];
  }

  String _formatLargeNumber(double number) {
    if (number >= 1e12) {
      return '${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(2)}M';
    } else if (number >= 1e3) {
      return '${(number / 1e3).toStringAsFixed(2)}K';
    } else {
      return number.toStringAsFixed(2);
    }
  }
}

// Data models for UI
class PieChartData {
  final String asset;
  final double value;
  
  PieChartData(this.asset, this.value);
}

// Extension methods
extension StringExtension on String {
  String capitalize() {
    return this.isNotEmpty ? '${this[0].toUpperCase()}${this.substring(1)}' : this;
  }
}