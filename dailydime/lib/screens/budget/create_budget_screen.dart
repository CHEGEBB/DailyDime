// lib/screens/budget/create_budget_screen.dart
import 'package:dailydime/models/budget.dart';
import 'package:dailydime/providers/budget_provider.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CreateBudgetScreen extends StatefulWidget {
  final Budget? budgetToEdit;
  
  const CreateBudgetScreen({Key? key, this.budgetToEdit}) : super(key: key);

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  late Color _selectedColor;
  late IconData _selectedIcon;
  bool _isProcessing = false;
  
  // Predefined categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.green},
    {'name': 'Transport', 'icon': Icons.directions_bus, 'color': Colors.blue},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.purple},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.orange},
    {'name': 'Utilities', 'icon': Icons.power, 'color': Colors.teal},
    {'name': 'Rent', 'icon': Icons.home, 'color': Colors.brown},
    {'name': 'Health', 'icon': Icons.medical_services, 'color': Colors.red},
    {'name': 'Education', 'icon': Icons.school, 'color': Colors.indigo},
    {'name': 'Personal', 'icon': Icons.person, 'color': Colors.pink},
    {'name': 'Travel', 'icon': Icons.flight, 'color': Colors.amber},
    {'name': 'Savings', 'icon': Icons.savings, 'color': Colors.cyan},
    {'name': 'Other', 'icon': Icons.category, 'color': Colors.blueGrey},
  ];
  
  // Budget periods with display names
  final List<Map<String, dynamic>> _periods = [
    {'period': BudgetPeriod.daily, 'name': 'Daily', 'icon': Icons.today},
    {'period': BudgetPeriod.weekly, 'name': 'Weekly', 'icon': Icons.view_week},
    {'period': BudgetPeriod.monthly, 'name': 'Monthly', 'icon': Icons.calendar_month},
    {'period': BudgetPeriod.yearly, 'name': 'Yearly', 'icon': Icons.calendar_today},
  ];

  @override
  void initState() {
    super.initState();
    
    // Set initial values if editing an existing budget
    if (widget.budgetToEdit != null) {
      _titleController.text = widget.budgetToEdit!.title;
      _amountController.text = widget.budgetToEdit!.amount.toString();
      _selectedCategory = widget.budgetToEdit!.category;
      _selectedPeriod = widget.budgetToEdit!.period;
      _startDate = widget.budgetToEdit!.startDate;
      _endDate = widget.budgetToEdit!.endDate;
      _selectedColor = widget.budgetToEdit!.color;
      _selectedIcon = widget.budgetToEdit!.icon;
    } else {
      // Default values for new budget
      _selectedColor = _getCategoryColor(_selectedCategory);
      _selectedIcon = _getCategoryIcon(_selectedCategory);
      _updateDateRangeForPeriod();
    }
  }
  
  void _updateDateRangeForPeriod() {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case BudgetPeriod.daily:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case BudgetPeriod.weekly:
        // Start from current day, end after 7 days
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = _startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case BudgetPeriod.monthly:
        // Start from first day of month, end at last day of month
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case BudgetPeriod.yearly:
        // Start from first day of year, end at last day of year
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
    }
    
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.scaffoldColor,
      appBar: AppBar(
        title: Text(
          widget.budgetToEdit == null ? 'Create Budget' : 'Edit Budget',
          style: TextStyle(
            color: themeService.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeService.surfaceColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeService.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: IconThemeData(color: themeService.textColor),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Budget amount input
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: themeService.isDarkMode 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How much do you want to budget?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'KES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeService.textColor,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 20,
                        color: themeService.subtextColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: themeService.isDarkMode 
                          ? const Color(0xFF2D3748)
                          : Colors.grey.shade100,
                    ),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                    textAlign: TextAlign.end,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Budget category selection
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: themeService.isDarkMode 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category['name'];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category['name'];
                            _selectedColor = category['color'];
                            _selectedIcon = category['icon'];
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? category['color'] 
                                    : category['color'].withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                category['icon'],
                                color: isSelected ? Colors.white : category['color'],
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category['name'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected 
                                    ? category['color'] 
                                    : themeService.subtextColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Budget details
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: themeService.isDarkMode 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Budget name
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: themeService.textColor),
                    decoration: InputDecoration(
                      labelText: 'Budget Name',
                      labelStyle: TextStyle(color: themeService.subtextColor),
                      hintText: 'e.g. Groceries, Dining Out',
                      hintStyle: TextStyle(color: themeService.subtextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: themeService.isDarkMode 
                              ? Colors.grey[700]! 
                              : Colors.grey[200]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: themeService.isDarkMode 
                              ? Colors.grey[700]! 
                              : Colors.grey[200]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeService.primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: themeService.isDarkMode 
                          ? const Color(0xFF2D3748)
                          : Colors.grey[50],
                      prefixIcon: Icon(
                        _selectedIcon,
                        color: _selectedColor,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for your budget';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Budget period selection
                  Text(
                    'Budget Period',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: _periods.map((period) {
                      final isSelected = _selectedPeriod == period['period'];
                      
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPeriod = period['period'];
                              _updateDateRangeForPeriod();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? themeService.primaryColor 
                                  : themeService.isDarkMode 
                                      ? const Color(0xFF2D3748)
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  period['icon'],
                                  color: isSelected 
                                      ? Colors.white 
                                      : themeService.subtextColor,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  period['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected 
                                        ? Colors.white 
                                        : themeService.subtextColor,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Date range
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: themeService.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _selectedPeriod == BudgetPeriod.daily || 
                                     _selectedPeriod == BudgetPeriod.monthly || 
                                     _selectedPeriod == BudgetPeriod.yearly
                                  ? null
                                  : () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.fromSwatch(
                                                primarySwatch: themeService.isDarkMode 
                                                    ? Colors.teal 
                                                    : Colors.green,
                                                brightness: themeService.isDarkMode 
                                                    ? Brightness.dark 
                                                    : Brightness.light,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      
                                      if (date != null) {
                                        setState(() {
                                          _startDate = date;
                                          // Ensure end date is after start date
                                          if (_endDate.isBefore(_startDate)) {
                                            _endDate = _startDate.add(const Duration(days: 6));
                                          }
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: themeService.isDarkMode 
                                      ? const Color(0xFF2D3748)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: themeService.isDarkMode 
                                        ? Colors.grey[700]! 
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: _selectedPeriod == BudgetPeriod.daily || 
                                             _selectedPeriod == BudgetPeriod.monthly || 
                                             _selectedPeriod == BudgetPeriod.yearly
                                          ? themeService.subtextColor
                                          : themeService.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(_startDate),
                                      style: TextStyle(
                                        color: _selectedPeriod == BudgetPeriod.daily || 
                                               _selectedPeriod == BudgetPeriod.monthly || 
                                               _selectedPeriod == BudgetPeriod.yearly
                                            ? themeService.subtextColor
                                            : themeService.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: themeService.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _selectedPeriod == BudgetPeriod.daily || 
                                     _selectedPeriod == BudgetPeriod.monthly || 
                                     _selectedPeriod == BudgetPeriod.yearly
                                  ? null
                                  : () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _endDate,
                                        firstDate: _startDate,
                                        lastDate: _startDate.add(const Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.fromSwatch(
                                                primarySwatch: themeService.isDarkMode 
                                                    ? Colors.teal 
                                                    : Colors.green,
                                                brightness: themeService.isDarkMode 
                                                    ? Brightness.dark 
                                                    : Brightness.light,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      
                                      if (date != null) {
                                        setState(() {
                                          _endDate = date;
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: themeService.isDarkMode 
                                      ? const Color(0xFF2D3748)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: themeService.isDarkMode 
                                        ? Colors.grey[700]! 
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: _selectedPeriod == BudgetPeriod.daily || 
                                             _selectedPeriod == BudgetPeriod.monthly || 
                                             _selectedPeriod == BudgetPeriod.yearly
                                          ? themeService.subtextColor
                                          : themeService.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(_endDate),
                                      style: TextStyle(
                                        color: _selectedPeriod == BudgetPeriod.daily || 
                                               _selectedPeriod == BudgetPeriod.monthly || 
                                               _selectedPeriod == BudgetPeriod.yearly
                                            ? themeService.subtextColor
                                            : themeService.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Create budget button
            CustomButton(
              isSmall: false,
              text: widget.budgetToEdit == null ? 'Create Budget' : 'Update Budget',
              onPressed: _saveBudget,
              isLoading: _isProcessing,
              icon: widget.budgetToEdit == null ? Icons.add : Icons.save, 
              buttonColor: themeService.primaryColor,
            ),
            
            if (widget.budgetToEdit != null) ...[
              const SizedBox(height: 16),
              CustomButton(
                isSmall: false,
                text: 'Delete Budget',
                onPressed: _deleteBudget,
                isOutlined: true,
                icon: Icons.delete,
                buttonColor: themeService.errorColor,
              ),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  void _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });
      
      try {
        final amount = double.parse(_amountController.text);
        final title = _titleController.text.trim().isEmpty 
            ? _selectedCategory 
            : _titleController.text.trim();
        
        final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
        final themeService = Provider.of<ThemeService>(context, listen: false);
        
        if (widget.budgetToEdit == null) {
          // Create new budget
          final newBudget = Budget(
            title: title,
            category: _selectedCategory,
            amount: amount,
            period: _selectedPeriod,
            startDate: _startDate,
            endDate: _endDate,
            color: _selectedColor,
            icon: _selectedIcon,
            tags: [_selectedCategory.toLowerCase()], 
          );
          
          await budgetProvider.createBudget(newBudget);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Budget created successfully'),
                backgroundColor: themeService.successColor,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          // Update existing budget
          final updatedBudget = widget.budgetToEdit!.copyWith(
            title: title,
            category: _selectedCategory,
            amount: amount,
            period: _selectedPeriod,
            startDate: _startDate,
            endDate: _endDate,
            color: _selectedColor,
            icon: _selectedIcon,
            tags: [_selectedCategory.toLowerCase()],
          );
          
          await budgetProvider.updateBudget(updatedBudget);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Budget updated successfully'),
                backgroundColor: themeService.successColor,
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        final themeService = Provider.of<ThemeService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: themeService.errorColor,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }
  
  void _deleteBudget() async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Text(
          'Delete Budget',
          style: TextStyle(color: themeService.textColor),
        ),
        content: Text(
          'Are you sure you want to delete this budget? This action cannot be undone.',
          style: TextStyle(color: themeService.subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeService.subtextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: themeService.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && widget.budgetToEdit != null) {
      setState(() {
        _isProcessing = true;
      });
      
      try {
        final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
        await budgetProvider.deleteBudget(widget.budgetToEdit!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Budget deleted successfully'),
              backgroundColor: themeService.successColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: themeService.errorColor,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }
  
  Color _getCategoryColor(String category) {
    final categoryItem = _categories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => _categories.last,
    );
    return categoryItem['color'];
  }
  
  IconData _getCategoryIcon(String category) {
    final categoryItem = _categories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => _categories.last,
    );
    return categoryItem['icon'];
  }
}