// lib/screens/tools_screen.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/services/tools_service.dart';
import 'dart:ui';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  @override
  _ToolsScreenState createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  int _selectedToolIndex = -1;
  bool _isLoading = false;
  
  // Tool states
  final Map<String, bool> _expandedStates = {
    'receiptScanner': false,
    'budgetCalculator': false,
    'dailySpending': false,
    'recurringBills': false,
  };
  
  // Animation controllers
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleToolExpansion(String toolKey) {
    setState(() {
      // Reset all tools
      _expandedStates.forEach((key, value) {
        _expandedStates[key] = false;
      });
      
      // Expand the selected tool
      _expandedStates[toolKey] = !_expandedStates[toolKey]!;
      _selectedToolIndex = _expandedStates[toolKey]! ? _getToolIndexFromKey(toolKey) : -1;
    });
  }
  
  int _getToolIndexFromKey(String key) {
    switch (key) {
      case 'receiptScanner': return 0;
      case 'budgetCalculator': return 1;
      case 'dailySpending': return 2;
      case 'recurringBills': return 3;
      default: return -1;
    }
  }
  
  void _handleToolAction(String toolKey) async {
    setState(() => _isLoading = true);
    
    try {
      final toolsService = Provider.of<ToolsService>(context, listen: false);
      
      switch (toolKey) {
        case 'receiptScanner':
          await toolsService.scanReceipt();
          break;
        case 'budgetCalculator':
          // Handled in the budget calculator widget
          break;
        case 'dailySpending':
          await toolsService.generateDailySpendingReport();
          break;
        case 'recurringBills':
          await toolsService.detectRecurringBills();
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final toolsService = Provider.of<ToolsService>(context);
    final isAnyToolExpanded = _expandedStates.values.any((expanded) => expanded);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with floating effect
            _buildHeader(themeService),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search tools...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: themeService.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                ),
              ),
            ),
            
            // Main content
            Expanded(
              child: isAnyToolExpanded
                  ? _buildExpandedToolView(toolsService, themeService)
                  : _buildToolsGrid(toolsService, themeService),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(ThemeService themeService) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/pattern9.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeService.primaryColor.withOpacity(0.8),
                  themeService.primaryColor.withOpacity(0.6),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Smart Tools',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Boost your financial management',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 28,
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
  
  Widget _buildToolsGrid(ToolsService toolsService, ThemeService themeService) {
    final filteredTools = _getFilteredTools();
    
    if (filteredTools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty_search.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 16),
            Text(
              'No tools found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeService.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: themeService.subtextColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      childAspectRatio: 0.9,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: filteredTools.map((tool) {
        return _buildToolCard(tool, themeService);
      }).toList(),
    );
  }
  
  List<Map<String, dynamic>> _getFilteredTools() {
    final tools = [
      {
        'key': 'receiptScanner',
        'title': 'Receipt Scanner',
        'description': 'Scan receipts to extract transaction details automatically',
        'icon': Icons.document_scanner,
        'color': Colors.purple,
        'animation': 'assets/animations/scan.json',
      },
      {
        'key': 'budgetCalculator',
        'title': 'Smart Budget Calculator',
        'description': 'Get AI-powered budget recommendations based on your spending',
        'icon': Icons.calculate,
        'color': Colors.blue,
        'animation': 'assets/animations/calculator.json',
      },
      {
        'key': 'dailySpending',
        'title': 'Daily Spending Report',
        'description': 'Get insights about your daily transactions from SMS',
        'icon': Icons.bar_chart,
        'color': Colors.orange,
        'animation': 'assets/animations/report.json',
      },
      {
        'key': 'recurringBills',
        'title': 'Recurring Bills Manager',
        'description': 'Auto-detect and manage your recurring bills',
        'icon': Icons.repeat,
        'color': Colors.green,
        'animation': 'assets/animations/calendar.json',
      },
    ];
    
    if (_searchQuery.isEmpty) {
      return tools;
    }
    
    return tools.where((tool) {
      return tool['title'].toString().toLowerCase().contains(_searchQuery) ||
          tool['description'].toString().toLowerCase().contains(_searchQuery);
    }).toList();
  }
  
  Widget _buildToolCard(Map<String, dynamic> tool, ThemeService themeService) {
    return GestureDetector(
      onTap: () => _toggleToolExpansion(tool['key']),
      child: Container(
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: tool['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Lottie.asset(
                  tool['animation'],
                  height: 50,
                  width: 50,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                tool['title'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeService.textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                tool['description'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: themeService.subtextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpandedToolView(ToolsService toolsService, ThemeService themeService) {
    final tool = _getFilteredTools()[_selectedToolIndex];
    
    return Column(
      children: [
        // Tool header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _expandedStates.forEach((key, value) {
                      _expandedStates[key] = false;
                    });
                    _selectedToolIndex = -1;
                  });
                },
              ),
              const SizedBox(width: 16),
              Icon(
                tool['icon'],
                color: tool['color'],
              ),
              const SizedBox(width: 8),
              Text(
                tool['title'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeService.textColor,
                ),
              ),
            ],
          ),
        ),
        
        // Tool content
        Expanded(
          child: _buildToolContent(tool['key'], toolsService, themeService),
        ),
      ],
    );
  }
  
  Widget _buildToolContent(String toolKey, ToolsService toolsService, ThemeService themeService) {
    switch (toolKey) {
      case 'receiptScanner':
        return ReceiptScannerTool(toolsService: toolsService, themeService: themeService);
      case 'budgetCalculator':
        return BudgetCalculatorTool(toolsService: toolsService, themeService: themeService);
      case 'dailySpending':
        return DailySpendingTool(toolsService: toolsService, themeService: themeService);
      case 'recurringBills':
        return RecurringBillsTool(toolsService: toolsService, themeService: themeService);
      default:
        return const Center(child: Text('Tool not implemented'));
    }
  }
}

class ReceiptScannerTool extends StatefulWidget {
  final ToolsService toolsService;
  final ThemeService themeService;
  
  const ReceiptScannerTool({
    Key? key,
    required this.toolsService,
    required this.themeService,
  }) : super(key: key);

  @override
  _ReceiptScannerToolState createState() => _ReceiptScannerToolState();
}

class _ReceiptScannerToolState extends State<ReceiptScannerTool> {
  bool _isScanning = false;
  bool _hasScannedReceipt = false;
  Map<String, dynamic>? _scannedData;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _hasScannedReceipt ? _buildReceiptResult() : _buildScannerUI(),
    );
  }
  
  Widget _buildScannerUI() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.themeService.isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.themeService.isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/receipt_scan.json',
                  height: 200,
                  width: 200,
                ),
                const SizedBox(height: 24),
                Text(
                  'Scan Receipt',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.themeService.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Take a photo of your receipt to automatically extract transaction details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.themeService.subtextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: Text(_isScanning ? 'Scanning...' : 'Scan Receipt'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _isScanning
              ? null
              : () async {
                  setState(() {
                    _isScanning = true;
                  });
                  
                  try {
                    final result = await widget.toolsService.scanReceipt();
                    setState(() {
                      _isScanning = false;
                      _hasScannedReceipt = true;
                      _scannedData = result;
                    });
                  } catch (e) {
                    setState(() {
                      _isScanning = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.image),
          label: const Text('Upload from gallery'),
          onPressed: _isScanning
              ? null
              : () async {
                  setState(() {
                    _isScanning = true;
                  });
                  
                  try {
                    final result = await widget.toolsService.scanReceiptFromGallery();
                    setState(() {
                      _isScanning = false;
                      _hasScannedReceipt = true;
                      _scannedData = result;
                    });
                  } catch (e) {
                    setState(() {
                      _isScanning = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
        ),
      ],
    );
  }
  
  Widget _buildReceiptResult() {
    final extractedMerchant = _scannedData?['merchant'] ?? 'Unknown Merchant';
    final extractedTotal = _scannedData?['total'] ?? 0.0;
    final extractedDate = _scannedData?['date'] as DateTime? ?? DateTime.now();
    final extractedCategory = _scannedData?['category'] ?? 'Other';
    final items = _scannedData?['items'] as List<Map<String, dynamic>>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.themeService.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.themeService.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.storefront,
                      color: widget.themeService.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          extractedMerchant,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.themeService.textColor,
                          ),
                        ),
                        Text(
                          '${extractedDate.day}/${extractedDate.month}/${extractedDate.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.themeService.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppConfig.formatCurrency(extractedTotal),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.themeService.textColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.themeService.isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          extractedCategory,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.themeService.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Receipt Items',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.themeService.textColor,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No items found in receipt',
                    style: TextStyle(
                      color: widget.themeService.subtextColor,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(
                        item['name'] ?? 'Unknown Item',
                        style: TextStyle(
                          color: widget.themeService.textColor,
                        ),
                      ),
                      subtitle: Text(
                        item['quantity']?.toString() ?? '1',
                        style: TextStyle(
                          color: widget.themeService.subtextColor,
                        ),
                      ),
                      trailing: Text(
                        AppConfig.formatCurrency(item['price'] ?? 0.0),
                        style: TextStyle(
                          color: widget.themeService.textColor,
                        ),
                      ),
                    );
                  },
                ),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                onPressed: () {
                  // Enable editing of the scanned data
                  // This would open a form pre-filled with the extracted data
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                onPressed: () async {
                  try {
                    await widget.toolsService.saveScannedReceipt(_scannedData!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction saved successfully')),
                    );
                    setState(() {
                      _hasScannedReceipt = false;
                      _scannedData = null;
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        TextButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('Scan another receipt'),
          onPressed: () {
            setState(() {
              _hasScannedReceipt = false;
              _scannedData = null;
            });
          },
        ),
      ],
    );
  }
}

class BudgetCalculatorTool extends StatefulWidget {
  final ToolsService toolsService;
  final ThemeService themeService;
  
  const BudgetCalculatorTool({
    Key? key,
    required this.toolsService,
    required this.themeService,
  }) : super(key: key);

  @override
  _BudgetCalculatorToolState createState() => _BudgetCalculatorToolState();
}

class _BudgetCalculatorToolState extends State<BudgetCalculatorTool> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _savingsGoalController = TextEditingController();
  
  bool _isCalculating = false;
  bool _hasCalculatedBudget = false;
  Map<String, dynamic>? _budgetResults;
  
  // Expense controllers for recurring bills
  final Map<String, TextEditingController> _expenseControllers = {};
  final List<String> _expenseNames = [];
  
  @override
  void initState() {
    super.initState();
    _addDefaultExpenses();
    _loadExistingBills();
  }
  
  void _addDefaultExpenses() {
    _addExpense('Rent/Mortgage');
    _addExpense('Utilities');
    _addExpense('Transport');
  }
  
  void _loadExistingBills() async {
    try {
      final bills = await widget.toolsService.getRecurringBills();
      for (final bill in bills) {
        if (!_expenseNames.contains(bill['name'])) {
          _addExpense(bill['name'], bill['amount'].toString());
        }
      }
    } catch (e) {
      // Silently fail if bills can't be loaded
    }
  }
  
  void _addExpense(String name, [String initialValue = '']) {
    setState(() {
      if (!_expenseNames.contains(name)) {
        _expenseNames.add(name);
        _expenseControllers[name] = TextEditingController(text: initialValue);
      }
    });
  }
  
  void _removeExpense(String name) {
    setState(() {
      _expenseNames.remove(name);
      _expenseControllers[name]?.dispose();
      _expenseControllers.remove(name);
    });
  }
  
  @override
  void dispose() {
    _incomeController.dispose();
    _savingsGoalController.dispose();
    
    // Dispose all expense controllers
    for (final controller in _expenseControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _hasCalculatedBudget ? _buildBudgetResults() : _buildCalculatorForm(),
    );
  }
  
  Widget _buildCalculatorForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.themeService.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.themeService.infoColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: widget.themeService.infoColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Enter your monthly income and recurring expenses to get AI-powered budget recommendations',
                    style: TextStyle(
                      color: widget.themeService.textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Income field
          Text(
            'Monthly Income',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.themeService.textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: AppConfig.currencySymbol,
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your income';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Recurring expenses
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recurring Expenses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.themeService.textColor,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final nameController = TextEditingController();
                      return AlertDialog(
                        title: const Text('Add Expense'),
                        content: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Expense Name',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty) {
                                _addExpense(nameController.text);
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Expense list
          ..._expenseNames.map((name) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      name,
                      style: TextStyle(
                        color: widget.themeService.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _expenseControllers[name],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: AppConfig.currencySymbol,
                        hintText: '0.00',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () => _removeExpense(name),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 24),
          
          // Savings goal
          Text(
            'Monthly Savings Goal (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.themeService.textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _savingsGoalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: AppConfig.currencySymbol,
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Calculate button
          ElevatedButton(
            onPressed: _isCalculating
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isCalculating = true;
                      });
                      
                      try {
                        // Prepare expense data
                        final expenses = <Map<String, dynamic>>[];
                        for (final name in _expenseNames) {
                          final controller = _expenseControllers[name];
                          if (controller != null && controller.text.isNotEmpty) {
                            final amount = double.tryParse(controller.text) ?? 0.0;
                            if (amount > 0) {
                              expenses.add({
                                'name': name,
                                'amount': amount,
                              });
                            }
                          }
                        }
                        
                        // Calculate budget
                        final income = double.parse(_incomeController.text);
                        final savingsGoal = _savingsGoalController.text.isNotEmpty
                            ? double.parse(_savingsGoalController.text)
                            : 0.0;
                        
                        final result = await widget.toolsService.calculateBudget(
                          income: income,
                          expenses: expenses,
                          savingsGoal: savingsGoal,
                        );
                        
                        setState(() {
                          _isCalculating = false;
                          _hasCalculatedBudget = true;
                          _budgetResults = result;
                        });
                      } catch (e) {
                        setState(() {
                          _isCalculating = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isCalculating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calculate),
                const SizedBox(width: 8),
                Text(_isCalculating ? 'Calculating...' : 'Calculate Budget'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBudgetResults() {
    final totalIncome = _budgetResults?['income'] ?? 0.0;
    final totalExpenses = _budgetResults?['totalExpenses'] ?? 0.0;
    final savings = _budgetResults?['savings'] ?? 0.0;
    final discretionary = _budgetResults?['discretionary'] ?? 0.0;
    final recommendations = _budgetResults?['recommendations'] as List<dynamic>? ?? [];
    final dailySpendingLimit = _budgetResults?['dailyLimit'] ?? 0.0;
    final weeklySpendingLimit = _budgetResults?['weeklyLimit'] ?? 0.0;
    final categoryBreakdown = _budgetResults?['categoryBreakdown'] as Map<String, dynamic>? ?? {};
    
    return ListView(
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.themeService.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.themeService.textColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Income row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Income',
                    style: TextStyle(
                      color: widget.themeService.textColor,
                    ),
                  ),
                  Text(
                    AppConfig.formatCurrency(totalIncome),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.themeService.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Expenses row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Expenses',
                    style: TextStyle(
                      color: widget.themeService.textColor,
                    ),
                  ),
                  Text(
                    AppConfig.formatCurrency(totalExpenses),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Savings row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Savings',
                    style: TextStyle(
                      color: widget.themeService.textColor,
                    ),
                  ),
                  Text(
                    AppConfig.formatCurrency(savings),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Discretionary row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discretionary Spending',
                    style: TextStyle(
                      color: widget.themeService.textColor,
                    ),
                  ),
                  Text(
                    AppConfig.formatCurrency(discretionary),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.themeService.primaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Spending limits
              Text(
                'Recommended Spending Limits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.themeService.textColor,
                ),
              ),
              const SizedBox(height: 12),
              
              // Daily limit
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.themeService.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily',
                      style: TextStyle(
                        color: widget.themeService.textColor,
                      ),
                    ),
                    Text(
                      AppConfig.formatCurrency(dailySpendingLimit),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.themeService.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Weekly limit
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.themeService.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly',
                      style: TextStyle(
                        color: widget.themeService.textColor,
                      ),
                    ),
                    Text(
                      AppConfig.formatCurrency(weeklySpendingLimit),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.themeService.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Category breakdown
        if (categoryBreakdown.isNotEmpty) ...[
          Text(
            'Suggested Category Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.themeService.textColor,
            ),
          ),
          const SizedBox(height: 12),
          
          ...categoryBreakdown.entries.map((entry) {
            final categoryName = entry.key;
            final amount = entry.value as double;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.themeService.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryName,
                      style: TextStyle(
                        color: widget.themeService.textColor,
                      ),
                    ),
                    Text(
                      AppConfig.formatCurrency(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.themeService.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
        
        const SizedBox(height: 24),
        
        // AI Recommendations
        Text(
          'Smart Recommendations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.themeService.textColor,
          ),
        ),
        const SizedBox(height: 12),
        
        ...recommendations.map((recommendation) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.themeService.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.themeService.infoColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: widget.themeService.infoColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        color: widget.themeService.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        
        const SizedBox(height: 24),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Start Over'),
                onPressed: () {
                  setState(() {
                    _hasCalculatedBudget = false;
                    _budgetResults = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Set Budget'),
                onPressed: () async {
                  try {
                    await widget.toolsService.saveBudgetRecommendation(_budgetResults!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Budget saved successfully')),
                    );
                    // Navigate to budget screen
                    // This would typically be handled by your navigation system
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DailySpendingTool extends StatefulWidget {
  final ToolsService toolsService;
  final ThemeService themeService;
  
  const DailySpendingTool({
    Key? key,
    required this.toolsService,
    required this.themeService,
  }) : super(key: key);

  @override
  _DailySpendingToolState createState() => _DailySpendingToolState();
}

class _DailySpendingToolState extends State<DailySpendingTool> {
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadReport();
  }
  
  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final report = await widget.toolsService.generateDailySpendingReport(date: _selectedDate);
      setState(() {
        _reportData = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: widget.themeService.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Date:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.themeService.textColor,
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 90)),
                    lastDate: DateTime.now(),
                  );
                  
                  if (pickedDate != null && pickedDate != _selectedDate) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                    _loadReport();
                  }
                },
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.themeService.primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: widget.themeService.primaryColor,
                ),
                onPressed: _isLoading ? null : _loadReport,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Main content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/loading.json',
                          width: 150,
                          height: 150,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Analyzing your spending...',
                          style: TextStyle(
                            color: widget.themeService.textColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : _reportData == null
                    ? _buildEmptyState()
                    : _buildReportContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_data.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found for this date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.themeService.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different date or adding transactions',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.themeService.subtextColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            onPressed: _loadReport,
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportContent() {
    final totalSpent = _reportData?['totalSpent'] ?? 0.0;
    final transactions = _reportData?['transactions'] as List<dynamic>? ?? [];
    final categories = _reportData?['categories'] as Map<String, dynamic>? ?? {};
    final insights = _reportData?['insights'] as List<dynamic>? ?? [];
    final suggestions = _reportData?['suggestions'] as List<dynamic>? ?? [];
    
    return ListView(
      children: [
        // Total spent card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.themeService.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Total Spent Today',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.themeService.subtextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConfig.formatCurrency(totalSpent),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: totalSpent > 0
                      ? Colors.red
                      : widget.themeService.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${transactions.length} transactions',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.themeService.subtextColor,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Category breakdown
        if (categories.isNotEmpty) ...[
          Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.themeService.textColor,
            ),
          ),
          const SizedBox(height: 12),
          
          ...categories.entries.map((entry) {
            final categoryName = entry.key;
            final amount = entry.value as double;
            final percentage = totalSpent > 0 ? (amount / totalSpent * 100).toStringAsFixed(1) : '0';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.themeService.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(categoryName),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          color: widget.themeService.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppConfig.formatCurrency(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.themeService.textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.themeService.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.themeService.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
        
        const SizedBox(height: 24),
        
        // Transactions list
        Text(
          'Transactions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.themeService.textColor,
          ),
        ),
        const SizedBox(height: 12),
        
        ...transactions.map((transaction) {
          final title = transaction['title'] ?? 'Unknown';
          final amount = transaction['amount'] ?? 0.0;
          final category = transaction['category'] ?? 'Other';
          final time = transaction['time'] ?? '';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.themeService.isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: _getCategoryColor(category),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.themeService.textColor,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.themeService.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppConfig.formatCurrency(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        
        const SizedBox(height: 24),
        
        // AI insights
        Text(
          'AI Insights',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.themeService.textColor,
          ),
        ),
        const SizedBox(height: 12),
        
        ...insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.themeService.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.themeService.infoColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: widget.themeService.infoColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(
                        color: widget.themeService.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        
        const SizedBox(height: 24),
        
        // Suggestions
        Text(
          'Suggestions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.themeService.textColor,
          ),
        ),
        const SizedBox(height: 12),
        
        ...suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.themeService.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.themeService.successColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: widget.themeService.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        color: widget.themeService.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        
        const SizedBox(height: 24),
        
        // Export button
        ElevatedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Share Report'),
          onPressed: () async {
            try {
              await widget.toolsService.exportDailyReport(_reportData!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report shared successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          },
        ),
      ],
    );
  }
  
  Color _getCategoryColor(String category) {
    final normalizedCategory = category.toLowerCase();
    
    if (normalizedCategory.contains('food') || normalizedCategory.contains('grocery')) {
      return Colors.orange;
    } else if (normalizedCategory.contains('transport') || normalizedCategory.contains('travel')) {
      return Colors.blue;
    } else if (normalizedCategory.contains('shopping')) {
      return Colors.green;
    } else if (normalizedCategory.contains('bill') || normalizedCategory.contains('utility')) {
      return Colors.red;
    } else if (normalizedCategory.contains('entertainment')) {
      return Colors.purple;
    } else if (normalizedCategory.contains('health')) {
      return Colors.pink;
    } else {
      return Colors.grey;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    final normalizedCategory = category.toLowerCase();
    
    if (normalizedCategory.contains('food') || normalizedCategory.contains('grocery')) {
      return Icons.restaurant;
    } else if (normalizedCategory.contains('transport') || normalizedCategory.contains('travel')) {
      return Icons.directions_car;
    } else if (normalizedCategory.contains('shopping')) {
      return Icons.shopping_bag;
    } else if (normalizedCategory.contains('bill') || normalizedCategory.contains('utility')) {
      return Icons.receipt;
    } else if (normalizedCategory.contains('entertainment')) {
      return Icons.movie;
    } else if (normalizedCategory.contains('health')) {
      return Icons.medical_services;
    } else {
      return Icons.category;
    }
  }
}

class RecurringBillsTool extends StatefulWidget {
  final ToolsService toolsService;
  final ThemeService themeService;
  
  const RecurringBillsTool({
    Key? key,
    required this.toolsService,
    required this.themeService,
  }) : super(key: key);

  @override
  _RecurringBillsToolState createState() => _RecurringBillsToolState();
}

class _RecurringBillsToolState extends State<RecurringBillsTool> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _recurringBills = [];
  List<Map<String, dynamic>> _suggestedBills = [];
  List<Map<String, dynamic>> _upcomingBills = [];
  bool _isScanningForBills = false;
  
  @override
  void initState() {
    super.initState();
    _loadRecurringBills();
  }
  
  Future<void> _loadRecurringBills() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final bills = await widget.toolsService.getRecurringBills();
      final suggested = await widget.toolsService.getSuggestedRecurringBills();
      final upcoming = await widget.toolsService.getUpcomingBills();
      
      setState(() {
        _recurringBills = bills;
        _suggestedBills = suggested;
        _upcomingBills = upcoming;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _scanForBills() async {
    setState(() {
      _isScanningForBills = true;
    });
    
    try {
      await widget.toolsService.detectRecurringBills();
      await _loadRecurringBills();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isScanningForBills = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actions row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Bill'),
                  onPressed: () {
                    _showAddBillDialog();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    Icons.search,
                    color: widget.themeService.primaryColor,
                  ),
                  label: Text(
                    _isScanningForBills ? 'Scanning...' : 'Auto-Detect',
                    style: TextStyle(
                      color: widget.themeService.primaryColor,
                    ),
                  ),
                  onPressed: _isScanningForBills ? null : _scanForBills,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Main content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/loading.json',
                          width: 150,
                          height: 150,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading your bills...',
                          style: TextStyle(
                            color: widget.themeService.textColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : _recurringBills.isEmpty && _suggestedBills.isEmpty
                    ? _buildEmptyState()
                    : _buildBillsContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_list.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          Text(
            'No recurring bills found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.themeService.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your bills manually or use auto-detect to find them',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.themeService.subtextColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Bill'),
            onPressed: () {
              _showAddBillDialog();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildBillsContent() {
    final currentDate = DateTime.now();
    final currentMonth = '${currentDate.month}/${currentDate.year}';
    
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: widget.themeService.primaryColor,
            unselectedLabelColor: widget.themeService.subtextColor,
            indicatorColor: widget.themeService.primaryColor,
            tabs: const [
              Tab(text: 'Your Bills'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Suggested'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: TabBarView(
              children: [
                // Your Bills tab
                _recurringBills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animations/empty_list.json',
                              width: 150,
                              height: 150,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bills added yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.themeService.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your recurring bills to track them',
                              style: TextStyle(
                                color: widget.themeService.subtextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _recurringBills.length,
                        itemBuilder: (context, index) {
                          final bill = _recurringBills[index];
                          return _buildBillCard(bill);
                        },
                      ),
                
                // Upcoming bills tab
                _upcomingBills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animations/calendar_empty.json',
                              width: 150,
                              height: 150,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No upcoming bills',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.themeService.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add bills to see when they are due',
                              style: TextStyle(
                                color: widget.themeService.subtextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _upcomingBills.length,
                        itemBuilder: (context, index) {
                          final bill = _upcomingBills[index];
                          return _buildUpcomingBillCard(bill);
                        },
                      ),
                
                // Suggested bills tab
                _suggestedBills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animations/search_empty.json',
                              width: 150,
                              height: 150,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No suggested bills',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.themeService.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Auto-Detect" to find recurring bills',
                              style: TextStyle(
                                color: widget.themeService.subtextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _suggestedBills.length,
                        itemBuilder: (context, index) {
                          final bill = _suggestedBills[index];
                          return _buildSuggestedBillCard(bill);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBillCard(Map<String, dynamic> bill) {
    final name = bill['name'] ?? 'Unknown';
    final amount = bill['amount'] ?? 0.0;
    final frequency = bill['frequency'] ?? 'Monthly';
    final dueDay = bill['dueDay'] ?? 1;
    final category = bill['category'] ?? 'Bill';
    
    // Calculate next due date
    final now = DateTime.now();
    var nextDueDate = DateTime(now.year, now.month, dueDay);
    if (nextDueDate.isBefore(now)) {
      nextDueDate = DateTime(now.year, now.month + 1, dueDay);
    }
    
    // Format the date
    final dueDate = '${nextDueDate.day}/${nextDueDate.month}/${nextDueDate.year}';
    
    return Dismissible(
      key: Key(bill['id'] ?? name),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Bill'),
              content: Text('Are you sure you want to delete $name?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await widget.toolsService.deleteRecurringBill(bill['id']);
          _loadRecurringBills();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.themeService.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$frequency · Due $dueDate',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.themeService.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppConfig.formatCurrency(amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.themeService.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.themeService.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.themeService.primaryColor,
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
  
  Widget _buildUpcomingBillCard(Map<String, dynamic> bill) {
    final name = bill['name'] ?? 'Unknown';
    final amount = bill['amount'] ?? 0.0;
    final dueDate = bill['dueDate'] ?? DateTime.now();
    final category = bill['category'] ?? 'Bill';
    
    // Calculate days until due
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    final daysText = difference <= 0
        ? 'Due today'
        : difference == 1
            ? 'Due tomorrow'
            : 'Due in $difference days';
    
    final isPastDue = difference < 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPastDue
                    ? Colors.red.withOpacity(0.2)
                    : _getCategoryColor(category).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPastDue ? Icons.warning : _getCategoryIcon(category),
                color: isPastDue ? Colors.red : _getCategoryColor(category),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.themeService.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dueDate.day}/${dueDate.month}/${dueDate.year} · $daysText',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPastDue
                          ? Colors.red
                          : widget.themeService.subtextColor,
                      fontWeight: isPastDue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppConfig.formatCurrency(amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.themeService.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () {
                    // Mark as paid logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeService.successColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Mark Paid',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestedBillCard(Map<String, dynamic> bill) {
    final name = bill['name'] ?? 'Unknown';
    final amount = bill['amount'] ?? 0.0;
    final frequency = bill['frequency'] ?? 'Monthly';
    final category = bill['category'] ?? 'Bill';
    final confidence = bill['confidence'] ?? 80;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.themeService.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$frequency · ${AppConfig.formatCurrency(amount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.themeService.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.themeService.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$confidence% Match',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.themeService.infoColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Dismiss suggestion
                      setState(() {
                        _suggestedBills.removeWhere((element) => 
                            element['name'] == name && element['amount'] == amount);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await widget.toolsService.addRecurringBill(bill);
                        setState(() {
                          _suggestedBills.removeWhere((element) => 
                              element['name'] == name && element['amount'] == amount);
                        });
                        _loadRecurringBills();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Add Bill'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddBillDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final dueDayController = TextEditingController();
    String selectedFrequency = 'Monthly';
    String selectedCategory = 'Bill';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Recurring Bill'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Bill Name',
                        hintText: 'e.g. Netflix, Rent, Electricity',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: '0.00',
                        prefixText: AppConfig.currencySymbol,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                      ),
                      items: [
                        'Daily',
                        'Weekly',
                        'Biweekly',
                        'Monthly',
                        'Quarterly',
                        'Yearly',
                      ].map((frequency) {
                        return DropdownMenuItem<String>(
                          value: frequency,
                          child: Text(frequency),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedFrequency = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dueDayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Due Day (1-31)',
                        hintText: '1',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: [
                        'Bill',
                        'Utilities',
                        'Rent/Mortgage',
                        'Subscription',
                        'Insurance',
                        'Phone',
                        'Internet',
                        'Other',
                      ].map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name and amount are required')),
                      );
                      return;
                    }
                    
                    final dueDay = int.tryParse(dueDayController.text) ?? 1;
                    if (dueDay < 1 || dueDay > 31) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Due day must be between 1 and 31')),
                      );
                      return;
                    }
                    
                    try {
                      final bill = {
                        'name': nameController.text,
                        'amount': double.parse(amountController.text),
                        'frequency': selectedFrequency,
                        'dueDay': dueDay,
                        'category': selectedCategory,
                      };
                      
                      await widget.toolsService.addRecurringBill(bill);
                      Navigator.pop(context);
                      _loadRecurringBills();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Color _getCategoryColor(String category) {
    final normalizedCategory = category.toLowerCase();
    
    if (normalizedCategory.contains('utilities')) {
      return Colors.blue;
    } else if (normalizedCategory.contains('rent') || normalizedCategory.contains('mortgage')) {
      return Colors.purple;
    } else if (normalizedCategory.contains('subscription')) {
      return Colors.green;
    } else if (normalizedCategory.contains('insurance')) {
      return Colors.indigo;
    } else if (normalizedCategory.contains('phone')) {
      return Colors.orange;
    } else if (normalizedCategory.contains('internet')) {
      return Colors.teal;
    } else {
      return Colors.red;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    final normalizedCategory = category.toLowerCase();
    
    if (normalizedCategory.contains('utilities')) {
      return Icons.electric_bolt;
    } else if (normalizedCategory.contains('rent') || normalizedCategory.contains('mortgage')) {
      return Icons.home;
    } else if (normalizedCategory.contains('subscription')) {
      return Icons.subscriptions;
    } else if (normalizedCategory.contains('insurance')) {
      return Icons.health_and_safety;
    } else if (normalizedCategory.contains('phone')) {
      return Icons.phone;
    } else if (normalizedCategory.contains('internet')) {
      return Icons.wifi;
    } else {
      return Icons.receipt;
    }
  }
}