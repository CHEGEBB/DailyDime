import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/theme_service.dart';
import '../services/crypto_service.dart';
import '../models/crypto_models.dart';
import '../config/app_config.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({Key? key}) : super(key: key);

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> with SingleTickerProviderStateMixin {
  // Services
  late final CryptoService _cryptoService;
  
  // State variables
  Portfolio? _portfolio;
  List<Wallet> _wallets = [];
  List<Transaction> _transactions = [];
  MarketData? _marketData;
  List<AIInsight> _insights = [];
  RiskAssessment? _riskAssessment;
  String? _budgetAdvice;
  Map<String, List<PricePoint>> _priceCharts = {};
  
  // Animation controller
  late AnimationController _animationController;
  
  // Stream subscriptions
  StreamSubscription? _priceUpdateSubscription;
  StreamSubscription? _portfolioUpdateSubscription;
  
  // UI state
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  TimeFrame _selectedTimeFrame = TimeFrame.day;
  bool _isAddingWallet = false;
  String _newWalletAddress = '';
  String _selectedNetwork = 'ethereum';
  String _newWalletLabel = '';
  
  @override
  void initState() {
    super.initState();
    _cryptoService = CryptoService.instance;
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500),
    );
    
    // Initialize data
    _initializeData();
    
    // Subscribe to updates
    _priceUpdateSubscription = _cryptoService.priceUpdates.listen(_handlePriceUpdate);
    _portfolioUpdateSubscription = _cryptoService.portfolioUpdates.listen(_handlePortfolioUpdate);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _priceUpdateSubscription?.cancel();
    _portfolioUpdateSubscription?.cancel();
    super.dispose();
  }
  
  // Initialize all data
  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      // Load all data in parallel
      await Future.wait([
        _loadPortfolio(),
        _loadWallets(),
        _loadTransactions(),
        _loadMarketData(),
        _loadInsights(),
        _loadRiskAssessment(),
        _loadBudgetAdvice(),
      ]);
      
      // Load price charts for top assets
      if (_portfolio != null && _portfolio!.allocation.isNotEmpty) {
        final topAssets = _portfolio!.getAllocationEntries()
            .take(3)
            .map((e) => e.key)
            .toList();
            
        await _loadPriceCharts(topAssets);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Start animation
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load crypto data: $e';
      });
    }
  }
  
  // Load individual data components
  Future<void> _loadPortfolio() async {
    final portfolio = await _cryptoService.getPortfolio([]);
    setState(() {
      _portfolio = portfolio;
    });
  }
  
  Future<void> _loadWallets() async {
    final wallets = await _cryptoService.getWallets();
    setState(() {
      _wallets = wallets;
    });
  }
  
  Future<void> _loadTransactions() async {
    final transactions = await _cryptoService.getRecentTransactions();
    setState(() {
      _transactions = transactions;
    });
  }
  
  Future<void> _loadMarketData() async {
    final marketData = await _cryptoService.getMarketOverview();
    setState(() {
      _marketData = marketData;
    });
  }
  
  Future<void> _loadInsights() async {
    final insights = await _cryptoService.getPortfolioInsights();
    setState(() {
      _insights = insights;
    });
  }
  
  Future<void> _loadRiskAssessment() async {
    final riskAssessment = await _cryptoService.analyzeRisk();
    setState(() {
      _riskAssessment = riskAssessment;
    });
  }
  
  Future<void> _loadBudgetAdvice() async {
    final advice = await _cryptoService.generateBudgetAdvice();
    setState(() {
      _budgetAdvice = advice;
    });
  }
  
  Future<void> _loadPriceCharts(List<String> assets) async {
    for (final asset in assets) {
      try {
        final priceHistories = await _cryptoService.getPriceHistory(asset);
        
        if (priceHistories.isNotEmpty) {
          for (final history in priceHistories) {
            if (history.timeFrame == _selectedTimeFrame) {
              setState(() {
                _priceCharts[asset] = history.prices;
              });
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading price chart for $asset: $e');
      }
    }
  }
  
  // Handle real-time updates
  void _handlePriceUpdate(PriceUpdate update) {
    // Update UI with new price data
    setState(() {
      // If we have this token in our portfolio, update its price
      if (_portfolio != null) {
        for (final wallet in _portfolio!.wallets) {
          for (var i = 0; i < wallet.tokens.length; i++) {
            if (wallet.tokens[i].symbol.toLowerCase() == update.symbol.toLowerCase()) {
              // This would be handled through a proper state management solution
              // in a real app, but for simplicity we're just refreshing the data
              _loadPortfolio();
              break;
            }
          }
        }
      }
    });
  }
  
  void _handlePortfolioUpdate(Portfolio portfolio) {
    setState(() {
      _portfolio = portfolio;
    });
  }
  
  // UI Actions
  Future<void> _refreshData() async {
    HapticFeedback.mediumImpact();
    await _initializeData();
  }
  
  void _showAddWalletModal() {
    setState(() {
      _isAddingWallet = true;
      _newWalletAddress = '';
      _selectedNetwork = 'ethereum';
      _newWalletLabel = '';
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddWalletModal(),
    ).then((_) {
      setState(() {
        _isAddingWallet = false;
      });
    });
  }
  
 Future<void> _viewTransactionDetails(Transaction transaction) async {
  try {
    final url = transaction.getExplorerUrl();
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open transaction link')),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening transaction link')),
      );
    }
  }
}
  
  Future<void> _removeWallet(String walletId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _cryptoService.removeWallet(walletId);
      
      if (success) {
        // Refresh data
        await _loadWallets();
        await _loadPortfolio();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wallet removed successfully')),
        );
      } else {
        throw Exception('Failed to remove wallet');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove wallet: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _syncTransactions(Wallet wallet) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _cryptoService.syncWalletTransactions(wallet.address, wallet.networkName);
      
      // Refresh transactions
      await _loadTransactions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions synced successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sync transactions: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _changeTimeFrame(TimeFrame timeFrame) {
    setState(() {
      _selectedTimeFrame = timeFrame;
    });
    
    // Reload charts with new time frame
    if (_portfolio != null && _portfolio!.allocation.isNotEmpty) {
      final topAssets = _portfolio!.getAllocationEntries()
          .take(3)
          .map((e) => e.key)
          .toList();
          
      _loadPriceCharts(topAssets);
    }
  }
  
  
  // // Build UI Components
  // Widget _buildAddWalletModal() {
  //   final theme = Provider.of<ThemeService>(context);
  //   final isDark = theme.isDarkMode;
    
  //   return BackdropFilter(
  //     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  //     child: Container(
  //       padding: EdgeInsets.only(
  //         bottom: MediaQuery.of(context).viewInsets.bottom,
  //       ),
  //       decoration: BoxDecoration(
  //         color: theme.cardColor.withOpacity(0.95),
  //         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.all(24.0),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Text(
  //                   'Add Wallet',
  //                   style: Theme.of(context).textTheme.headlineSmall,
  //                 ),
  //                 IconButton(
  //                   icon: Icon(Icons.close),
  //                   onPressed: () => Navigator.pop(context),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 20),
  //             Text(
  //               'Wallet Address',
  //               style: Theme.of(context).textTheme.titleMedium,
  //             ),
  //             const SizedBox(height: 8),
  //             TextField(
  //               decoration: InputDecoration(
  //                 hintText: '0x...',
  //                 prefixIcon: Icon(Icons.account_balance_wallet_outlined),
  //               ),
  //               onChanged: (value) => _newWalletAddress = value,
  //             ),
  //             const SizedBox(height: 20),
  //             Text(
  //               'Network',
  //               style: Theme.of(context).textTheme.titleMedium,
  //             ),
  //             const SizedBox(height: 8),
  //             DropdownButtonFormField<String>(
  //               decoration: InputDecoration(
  //                 prefixIcon: Icon(Icons.lan_outlined),
  //               ),
  //               value: _selectedNetwork,
  //               items: AppConfig.supportedNetworks.keys.map((network) {
  //                 return DropdownMenuItem(
  //                   value: network,
  //                   child: Text(network.toUpperCase()),
  //                 );
  //               }).toList(),
  //               onChanged: (value) {
  //                 setState(() {
  //                   _selectedNetwork = value!;
  //                 });
  //               },
  //             ),
  //             const SizedBox(height: 20),
  //             Text(
  //               'Label (Optional)',
  //               style: Theme.of(context).textTheme.titleMedium,
  //             ),
  //             const SizedBox(height: 8),
  //             TextField(
  //               decoration: InputDecoration(
  //                 hintText: 'My Wallet',
  //                 prefixIcon: Icon(Icons.label_outline),
  //               ),
  //               onChanged: (value) => _newWalletLabel = value,
  //             ),
  //             const SizedBox(height: 24),
  //             SizedBox(
  //               width: double.infinity,
  //               child: ElevatedButton(
  //                 onPressed: _isLoading ? null : _addWallet,
  //                 style: ElevatedButton.styleFrom(
  //                   padding: const EdgeInsets.symmetric(vertical: 16),
  //                 ),
  //                 child: _isLoading
  //                     ? SizedBox(
  //                         height: 24,
  //                         width: 24,
  //                         child: CircularProgressIndicator(
  //                           strokeWidth: 2,
  //                           color: Colors.white,
  //                         ),
  //                       )
  //                     : Text('Add Wallet'),
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             if (_isLoading)
  //               Center(
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(8.0),
  //                   child: Text(
  //                     'Connecting to blockchain...',
  //                     style: Theme.of(context).textTheme.bodySmall,
  //                   ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Portfolio'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddWalletModal,
            tooltip: 'Add Wallet',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: theme.primaryColor,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: _buildPortfolioHeroCard(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Wallets',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              TextButton.icon(
                                icon: Icon(Icons.add, size: 18),
                                label: Text('Add'),
                                onPressed: _showAddWalletModal,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _wallets.isEmpty
                            ? _buildEmptyWalletsState()
                            : _buildWalletsList(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Market Overview',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              _buildTimeFrameSelector(),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildMarketOverview(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'Your Assets',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _portfolio == null || _portfolio!.totalUsdValue == 0
                            ? _buildEmptyAssetsState()
                            : _buildAssetsGrid(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'Recent Transactions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _transactions.isEmpty
                            ? _buildEmptyTransactionsState()
                            : _buildTransactionsList(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'AI Insights',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildAIInsights(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'Risk Assessment',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildRiskAssessment('medium'),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'Budget Integration',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildBudgetIntegration(),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 40),
                      ),
                    ],
                  ),
                ),
    );
  }

Future<void> _addWallet() async {
  if (_newWalletAddress.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a wallet address')),
    );
    return;
  }
  
  try {
    // Validate address
    if (!AppConfig.isValidEthereumAddress(_newWalletAddress)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid wallet address format')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    await _cryptoService.addWallet(_newWalletAddress, _selectedNetwork);
    
    // Refresh data
    await _loadWallets();
    await _loadPortfolio();
    
    // Close modal
    if (mounted) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet added successfully')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add wallet: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

Widget _buildAddWalletModal() {
  final theme = Provider.of<ThemeService>(context);
  
  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Wallet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Wallet Address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: '0x...',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              onChanged: (value) {
                setState(() {
                  _newWalletAddress = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Network',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lan_outlined),
              ),
              value: _selectedNetwork,
              items: AppConfig.supportedNetworks.keys.map((network) {
                return DropdownMenuItem(
                  value: network,
                  child: Text(network.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedNetwork = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Label (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'My Wallet',
                prefixIcon: Icon(Icons.label_outline),
              ),
              onChanged: (value) {
                setState(() {
                  _newWalletLabel = value;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addWallet, // This should now work
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Wallet'),
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Connecting to blockchain...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/loading2.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading your crypto portfolio...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    final theme = Provider.of<ThemeService>(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyWalletsState() {
  final theme = Provider.of<ThemeService>(context);
  
  return Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Wallets Yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first crypto wallet to start tracking your assets',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Wallet'),
                  onPressed: _showAddWalletModal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
  
  Widget _buildWalletsList() {
    final theme = Provider.of<ThemeService>(context);
    
    return Container(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _wallets.length,
        itemBuilder: (context, index) {
          final wallet = _wallets[index];
          
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor.withOpacity(0.15),
                          theme.secondaryColor.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                wallet.label.isEmpty 
                                    ? 'Wallet ${index + 1}' 
                                    : wallet.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  wallet.networkName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppConfig.formatWalletAddress(wallet.address),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${wallet.balance.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.sync, size: 20),
                                    onPressed: () => _syncTransactions(wallet),
                                    tooltip: 'Sync Transactions',
                                    color: theme.primaryColor,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 20),
                                    onPressed: () => _removeWallet(wallet.id),
                                    tooltip: 'Remove Wallet',
                                    color: theme.errorColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
Widget _buildPortfolioHeroCard() {
 final theme = Provider.of<ThemeService>(context);
 final hasPortfolio = _portfolio != null && _portfolio!.totalUsdValue > 0;
 
 // Simple fix - just set to 0 for now
 final percentChange = 0.0;
 
 return Card(
   elevation: 8,
   shadowColor: theme.primaryColor.withOpacity(0.3),
   shape: RoundedRectangleBorder(
     borderRadius: BorderRadius.circular(16),
   ),
   child: ClipRRect(
     borderRadius: BorderRadius.circular(16),
     child: BackdropFilter(
       filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
       child: Container(
         decoration: BoxDecoration(
           gradient: LinearGradient(
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
             colors: [
               theme.primaryColor.withOpacity(0.3),
               theme.secondaryColor.withOpacity(0.2),
             ],
           ),
           border: Border.all(
             color: theme.primaryColor.withOpacity(0.5),
             width: 1,
           ),
           borderRadius: BorderRadius.circular(16),
         ),
         child: Padding(
           padding: const EdgeInsets.all(20),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Icon(
                     Icons.account_balance_wallet,
                     color: theme.accentColor,
                     size: 24,
                   ),
                   const SizedBox(width: 8),
                   Text(
                     'Portfolio Value',
                     style: TextStyle(
                       fontSize: 16,
                       fontWeight: FontWeight.w500,
                       color: theme.textColor,
                     ),
                   ),
                   const Spacer(),
                   Container(
                     padding: const EdgeInsets.symmetric(
                       horizontal: 8,
                       vertical: 4,
                     ),
                     decoration: BoxDecoration(
                       color: theme.primaryColor.withOpacity(0.2),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                       'Live',
                       style: TextStyle(
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                         color: theme.primaryColor,
                       ),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               AnimatedSwitcher(
                 duration: const Duration(milliseconds: 300),
                 child: Text(
                   hasPortfolio
                       ? '\$${_portfolio!.totalUsdValue.toStringAsFixed(2)}'
                       : '\$0.00',
                   key: ValueKey<String>(hasPortfolio ? _portfolio!.totalUsdValue.toString() : '0'),
                   style: TextStyle(
                     fontSize: 32,
                     fontWeight: FontWeight.bold,
                     color: theme.textColor,
                   ),
                 ),
               ),
               const SizedBox(height: 20),
               if (hasPortfolio && _portfolio!.allocation.isNotEmpty)
                 Row(
                   children: _portfolio!.allocation.entries
                       .take(3)
                       .map((entry) {
                         return Expanded(
                           child: Row(
                             children: [
                               Container(
                                 width: 12,
                                 height: 12,
                                 decoration: BoxDecoration(
                                   color: _getTokenColor(entry.key),
                                   shape: BoxShape.circle,
                                 ),
                               ),
                               const SizedBox(width: 4),
                               Text(
                                 entry.key,
                                 style: TextStyle(
                                   fontSize: 12,
                                   color: theme.textColor.withOpacity(0.8),
                                 ),
                               ),
                               const SizedBox(width: 4),
                               Text(
                                 '${(entry.value * 100).toStringAsFixed(0)}%',
                                 style: TextStyle(
                                   fontSize: 12,
                                   fontWeight: FontWeight.bold,
                                   color: theme.textColor,
                                 ),
                               ),
                             ],
                           ),
                         );
                       })
                       .toList(),
                 )
               else
                 Center(
                   child: Text(
                     'Add wallets to track your portfolio',
                     style: TextStyle(
                       fontSize: 14,
                       color: theme.textColor.withOpacity(0.7),
                     ),
                   ),
                 ),
             ],
           ),
         ),
       ),
     ),
   ),
 );
}
  
  Widget _buildTimeFrameSelector() {
    final theme = Provider.of<ThemeService>(context);
    
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: theme.isDarkMode
            ? Colors.black.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _timeFrameButton('1D', TimeFrame.day),
          _timeFrameButton('1W', TimeFrame.week),
          _timeFrameButton('1M', TimeFrame.month),
          _timeFrameButton('1Y', TimeFrame.year),
        ],
      ),
    );
  }
  
  Widget _timeFrameButton(String label, TimeFrame timeFrame) {
    final theme = Provider.of<ThemeService>(context);
    final isSelected = _selectedTimeFrame == timeFrame;
    
    return GestureDetector(
      onTap: () => _changeTimeFrame(timeFrame),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : theme.textColor,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMarketOverview() {
 final theme = Provider.of<ThemeService>(context);
 
 if (_marketData == null) {
   return Padding(
     padding: const EdgeInsets.all(24.0),
     child: Center(
       child: Text(
         'Market data unavailable',
         style: TextStyle(
           color: theme.textColor.withOpacity(0.6),
         ),
       ),
     ),
   );
 }
 
 return Container(
   height: 220,
   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
   child: Card(
     elevation: 4,
     shape: RoundedRectangleBorder(
       borderRadius: BorderRadius.circular(16),
     ),
     child: Padding(
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               Text(
                 'Global Market Cap',
                 style: Theme.of(context).textTheme.titleMedium,
               ),
               const SizedBox(width: 8),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: theme.primaryColor.withOpacity(0.2),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(
                   'Live',
                   style: TextStyle(
                     fontSize: 12,
                     fontWeight: FontWeight.bold,
                     color: theme.primaryColor,
                   ),
                 ),
               ),
             ],
           ),
           const SizedBox(height: 8),
           Text(
             '\$${_formatLargeNumber(_marketData!.totalMarketCap)}',
             style: Theme.of(context).textTheme.headlineSmall,
           ),
           const SizedBox(height: 24),
           Expanded(
             child: _buildMarketChart(),
           ),
         ],
       ),
     ),
   ),
 );
}
  
  Widget _buildMarketChart() {
    final theme = Provider.of<ThemeService>(context);
    
    if (_marketData == null || _marketData!.volumeData.isEmpty) {
      return Center(
        child: Text(
          'Chart data unavailable',
          style: TextStyle(
            color: theme.textColor.withOpacity(0.6),
          ),
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // tooltipBgColor: theme.cardColor.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                return LineTooltipItem(
                  '\$${touchedSpot.y.toStringAsFixed(2)}B',
                  TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _marketData!.volumeData
                .asMap()
                .entries
                .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                .toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.5),
                theme.primaryColor,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.primaryColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: _marketData!.volumeData.reduce((a, b) => a < b ? a : b) * 0.9,
        maxY: _marketData!.volumeData.reduce((a, b) => a > b ? a : b) * 1.1,
      ),
    );
  }
  
  Widget _buildEmptyAssetsState() {
    final theme = Provider.of<ThemeService>(context);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Assets Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a wallet to start tracking your crypto assets',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Add Wallet'),
              onPressed: _showAddWalletModal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
Widget _buildAssetsGrid() {
  if (_portfolio == null || _portfolio!.wallets.isEmpty) {
    return const SizedBox.shrink();
  }
  
  final allTokens = <dynamic>[];
  for (final wallet in _portfolio!.wallets) {
    if (wallet.tokens.isNotEmpty) {
      allTokens.addAll(wallet.tokens);
    }
  }
  
  if (allTokens.isEmpty) {
    return _buildEmptyAssetsState();
  }
  
  // Group tokens by symbol and sum values
  final Map<String, dynamic> groupedTokens = {};
  for (final token in allTokens) {
    final symbol = token.symbol ?? 'UNKNOWN';
    if (!groupedTokens.containsKey(symbol)) {
      groupedTokens[symbol] = token;
    } else {
      final existing = groupedTokens[symbol]!;
      // Create a new token with combined values - adjust based on your Token class
      groupedTokens[symbol] = token; // Simplified - you'll need to properly combine token data
    }
  }
  
  // Sort by USD value
  final sortedTokens = groupedTokens.values.toList()
    ..sort((a, b) => (b.usdValue ?? 0.0).compareTo(a.usdValue ?? 0.0));
  
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        for (int i = 0; i < sortedTokens.length; i += 2) 
          Row(
            children: [
              Expanded(
                child: _buildAssetCard(sortedTokens[i]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: i + 1 < sortedTokens.length
                    ? _buildAssetCard(sortedTokens[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
      ],
    ),
  );
}

  
  Widget _buildAssetCard(dynamic token) {
  final theme = Provider.of<ThemeService>(context);
  
  // Add null checks for all token properties
  final symbol = token.symbol ?? 'N/A';
  final name = token.name ?? 'Unknown';
  final amount = token.amount ?? 0.0;
  final usdValue = token.usdValue ?? 0.0;
  final currentPrice = token.currentPrice ?? token.priceUsd ?? 0.0;
  final priceChange = token.priceChangePercent24h ?? token.priceChangePercentage24h ?? 0.0;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getTokenColor(symbol).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      symbol.isNotEmpty ? symbol.substring(0, 1) : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getTokenColor(symbol),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      Text(
                        name.length > 12 ? '${name.substring(0, 12)}...' : name,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${amount.toStringAsFixed(amount < 1 ? 4 : 2)} $symbol',
              style: TextStyle(
                fontSize: 14,
                color: theme.textColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${usdValue.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '\$${currentPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textColor.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: priceChange >= 0
                        ? theme.successColor.withOpacity(0.2)
                        : theme.errorColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: priceChange >= 0
                          ? theme.successColor
                          : theme.errorColor,
                    ),
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

  Widget _buildEmptyTransactionsState() {
    final theme = Provider.of<ThemeService>(context);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your recent crypto transactions will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _refreshData,
              child: Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionsList() {
  if (_transactions.isEmpty) {
    return _buildEmptyTransactionsState();
  }
  
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: _transactions.take(5).map((tx) => _buildTransactionItem(tx)).toList(),
    ),
  );
}
  
  Widget _buildTransactionItem(Transaction transaction) {
 final theme = Provider.of<ThemeService>(context);
 
 final IconData icon = transaction.type == TransactionType.sent
     ? Icons.arrow_upward
     : transaction.type == TransactionType.received
         ? Icons.arrow_downward
         : Icons.swap_horiz;
         
 final Color iconColor = transaction.type == TransactionType.sent
     ? theme.errorColor
     : transaction.type == TransactionType.received
         ? theme.successColor
         : theme.infoColor;
 
 return Card(
   margin: const EdgeInsets.only(bottom: 12),
   shape: RoundedRectangleBorder(
     borderRadius: BorderRadius.circular(12),
   ),
   child: InkWell(
     onTap: () => _viewTransactionDetails(transaction),
     borderRadius: BorderRadius.circular(12),
     child: Padding(
       padding: const EdgeInsets.all(16),
       child: Row(
         children: [
           Container(
             width: 42,
             height: 42,
             decoration: BoxDecoration(
               color: iconColor.withOpacity(0.2),
               shape: BoxShape.circle,
             ),
             child: Center(
               child: Icon(
                 icon,
                 color: iconColor,
                 size: 20,
               ),
             ),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     Text(
                       _getTransactionTitle(transaction),
                       style: TextStyle(
                         fontWeight: FontWeight.bold,
                         color: theme.textColor,
                       ),
                     ),
                     const Spacer(),
                     Text(
                       '${transaction.type == TransactionType.sent ? '-' : transaction.type == TransactionType.received ? '+' : ''}${transaction.value.toStringAsFixed(transaction.value < 1 ? 4 : 2)} ${transaction.tokenSymbol}',
                       style: TextStyle(
                         fontWeight: FontWeight.bold,
                         color: transaction.type == TransactionType.sent
                             ? theme.errorColor
                             : transaction.type == TransactionType.received
                                 ? theme.successColor
                                 : theme.textColor,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 4),
                 Row(
                   children: [
                     Text(
                       (transaction.timestamp ?? transaction.date ?? DateTime.now().toString()).substring(0, 10),
                       style: TextStyle(
                         fontSize: 12,
                         color: theme.textColor.withOpacity(0.7),
                       ),
                     ),
                     const Spacer(),
                     Text(
                       '\$${(transaction.valueUsd ?? 0.0).toStringAsFixed(2)}',
                       style: TextStyle(
                         fontSize: 12,
                         color: theme.textColor.withOpacity(0.7),
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
  
  Widget _buildAIInsights() {
  final theme = Provider.of<ThemeService>(context);
  
  if (_insights.isEmpty) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Insights Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add more wallets or transactions to get AI-powered insights',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  return SizedBox(
    height: 180,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _insights.length,
      itemBuilder: (context, index) {
        final insight = _insights[index];
        
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getInsightColor(insight.type).withOpacity(0.15),
                        _getInsightColor(insight.type).withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: _getInsightColor(insight.type).withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getInsightIcon(insight.type as InsightType),
                              color: _getInsightColor(insight.type),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getInsightTitle(insight.type as InsightType),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getInsightColor(insight.type),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Text(
                            insight.description ?? 'No description available',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(
                            onPressed: () {
                              // Show detailed insight
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 30),
                            ),
                            child: Text(
                              'Learn More',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getInsightColor(insight.type),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

  
  Widget _buildRiskAssessment(String defaultRiskLevel) {
  final theme = Provider.of<ThemeService>(context);
  
  if (_riskAssessment == null) {
    return const SizedBox.shrink();
  }
  
  // Use a default risk level if _riskAssessment.riskLevel is null
  final riskLevel = _riskAssessment!.riskLevel ?? RiskLevel.medium;
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: _getRiskColor(riskLevel),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Portfolio Risk: ${_getRiskLevelName(riskLevel)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getRiskColor(riskLevel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _getRiskValue(riskLevel),
                minHeight: 8,
                backgroundColor: theme.cardColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getRiskColor(riskLevel),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _riskAssessment!.analysis ?? 'Risk analysis unavailable',
              style: TextStyle(
                fontSize: 14,
                color: theme.textColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_riskAssessment!.suggestions ?? _riskAssessment!.recommendations ?? []).map((rec) {
                return Chip(
                  label: Text(
                    rec,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  backgroundColor: theme.primaryColor.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildBudgetIntegration() {
    final theme = Provider.of<ThemeService>(context);
    
    if (_budgetAdvice == null || _budgetAdvice!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sync,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Budget Integration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect your crypto portfolio to your budget to get personalized financial advice.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Connect to budget
                    },
                    child: Text('Connect to Budget'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Budget Recommendations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _budgetAdvice!,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // View budget
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('View Budget'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply recommendations
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Apply'),
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
  
  // Helper methods
  String _getTransactionTitle(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.sent:
        return 'Sent ${transaction.tokenSymbol}';
      case TransactionType.received:
        return 'Received ${transaction.tokenSymbol}';
      case TransactionType.swap:
        return 'Swapped ${transaction.tokenSymbol}';
      default:
        return 'Transaction';
    }
  }
  
  String _formatLargeNumber(double number) {
    if (number >= 1000000000000) {
      return '${(number / 1000000000000).toStringAsFixed(2)}T';
    } else if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    } else {
      return number.toStringAsFixed(2);
    }
  }
  
  Color _getTokenColor(String symbol) {
  // Remove the context access since this is called from build methods
  switch (symbol.toUpperCase()) {
    case 'BTC':
      return const Color(0xFFF7931A);
    case 'ETH':
      return const Color(0xFF627EEA);
    case 'BNB':
      return const Color(0xFFF3BA2F);
    case 'SOL':
      return const Color(0xFF00FFA3);
    case 'ADA':
      return const Color(0xFF0033AD);
    case 'XRP':
      return const Color(0xFF23292F);
    case 'DOT':
      return const Color(0xFFE6007A);
    case 'AVAX':
      return const Color(0xFFE84142);
    case 'USDT':
      return const Color(0xFF26A17B);
    case 'USDC':
      return const Color(0xFF2775CA);
    default:
      // Generate a color based on the symbol
      int hash = 0;
      for (int i = 0; i < symbol.length; i++) {
        hash = symbol.codeUnitAt(i) + ((hash << 5) - hash);
      }
      return Color((hash & 0xFFFFFF) | 0xFF000000);
  }
}

  
  Color _getInsightColor(AIInsightType type) {
    final theme = Provider.of<ThemeService>(context);
    
    switch (type) {
      case InsightType.opportunity:
        return theme.successColor;
      case InsightType.warning:
        return theme.warningColor;
      case InsightType.recommendation:
        return theme.infoColor;
      case InsightType.education:
        return theme.primaryColor;
      default:
        return theme.primaryColor;
    }
  }
  
  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.opportunity:
        return Icons.trending_up;
      case InsightType.warning:
        return Icons.warning_amber;
      case InsightType.recommendation:
        return Icons.lightbulb_outline;
      case InsightType.education:
        return Icons.school;
      default:
        return Icons.info_outline;
    }
  }
  
  String _getInsightTitle(InsightType type) {
    switch (type) {
      case InsightType.opportunity:
        return 'Opportunity';
      case InsightType.warning:
        return 'Warning';
      case InsightType.recommendation:
        return 'Recommendation';
      case InsightType.education:
        return 'Education';
      default:
        return 'Insight';
    }
  }
  
  Color _getRiskColor(RiskLevel riskLevel) {
    final theme = Provider.of<ThemeService>(context);
    
    switch (riskLevel) {
      case RiskLevel.low:
        return theme.successColor;
      case RiskLevel.medium:
        return theme.warningColor;
      case RiskLevel.high:
        return theme.errorColor;
      case RiskLevel.veryHigh:
        return Color(0xFFD70040);
      default:
        return theme.infoColor;
    }
  }
  
  String _getRiskLevelName(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.veryHigh:
        return 'Very High';
      default:
        return 'Unknown';
    }
  }
  
  double _getRiskValue(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return 0.25;
      case RiskLevel.medium:
        return 0.5;
      case RiskLevel.high:
        return 0.75;
      case RiskLevel.veryHigh:
        return 1.0;
      default:
        return 0.0;
    }
  }
}

class RiskLevel {
  static const low = 'Low';
  static const medium = 'Medium';
  static const high = 'High';
  static const veryHigh = 'Very High';
}

class InsightType {
  static const opportunity = 'Opportunity';
  static const recommendation = 'Recommendation'; // Added this line
  static const warning = 'Warning'; // Added this line
  static const education = 'Education'; // Added this line
}