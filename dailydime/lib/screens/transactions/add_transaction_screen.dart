// lib/screens/transactions/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/providers/transaction_provider.dart';
import 'package:dailydime/models/transaction.dart';
import 'package:dailydime/config/app_config.dart';
import 'package:dailydime/services/transaction_ai_service.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:flutter/services.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction; // Pass transaction for editing

  const AddTransactionScreen({
    Key? key,
    this.transaction,
  }) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isExpense = true;
  String _selectedCategory = 'Other';
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = Colors.purple.shade700;
  bool _isProcessing = false;

  // Category options with icons and colors
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Food',
      'icon': Icons.restaurant,
      'color': Colors.orange.shade700,
    },
    {
      'name': 'Transport',
      'icon': Icons.directions_bus,
      'color': Colors.blue.shade700,
    },
    {
      'name': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': Colors.pink.shade700,
    },
    {
      'name': 'Bills',
      'icon': Icons.receipt,
      'color': Colors.red.shade700,
    },
    {
      'name': 'Entertainment',
      'icon': Icons.movie,
      'color': Colors.purple.shade700,
    },
    {
      'name': 'Health',
      'icon': Icons.local_hospital,
      'color': Colors.red.shade400,
    },
    {
      'name': 'Education',
      'icon': Icons.school,
      'color': Colors.blue.shade800,
    },
    {
      'name': 'Income',
      'icon': Icons.payments,
      'color': Colors.green.shade700,
    },
    {
      'name': 'Salary',
      'icon': Icons.work,
      'color': Colors.green.shade800,
    },
    {
      'name': 'Transfer',
      'icon': Icons.swap_horiz,
      'color': Colors.blue.shade600,
    },
    {
      'name': 'Other',
      'icon': Icons.category,
      'color': Colors.purple.shade700,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing transaction data if editing
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _selectedDate = widget.transaction!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.transaction!.date);
      _isExpense = widget.transaction!.isExpense;
      _selectedCategory = widget.transaction!.category;
      _selectedIcon = widget.transaction!.icon;
      _selectedColor = widget.transaction!.color;
      
      if (widget.transaction!.description != null) {
        _descriptionController.text = widget.transaction!.description!;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, ThemeService themeService) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeService.primaryColor,
              onPrimary: Colors.white,
              onSurface: themeService.textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, ThemeService themeService) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeService.primaryColor,
              onPrimary: Colors.white,
              onSurface: themeService.textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Parse amount
        final amount = double.parse(_amountController.text);
        
        // Create DateTime with date and time
        final dateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        
        // Check if we need AI categorization
        if (_selectedCategory == 'Other' && _titleController.text.isNotEmpty) {
          final result = await TransactionAIService().categorizeTransaction(
            _titleController.text,
            amount,
          );
          
          if (result['success']) {
            final category = result['category'];
            _selectedCategory = category['category'];
            _selectedIcon = category['icon'];
            _selectedColor = category['color'];
            
            // If AI suggests this is income but user selected expense, respect user choice
            // but keep the category
            if (!category['isExpense'] && _isExpense) {
              // Keep _isExpense as true, but use the suggested category
            } else {
              _isExpense = category['isExpense'];
            }
          }
        }
        
        // Create transaction object
        final transaction = Transaction(
          id: widget.transaction?.id ?? 'manual-${DateTime.now().millisecondsSinceEpoch}',
          title: _titleController.text,
          amount: amount,
          date: dateTime,
          category: _selectedCategory,
          isExpense: _isExpense,
          icon: _selectedIcon,
          color: _selectedColor,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          isSms: false,
        );
        
        // Save to provider
        if (widget.transaction != null) {
          await Provider.of<TransactionProvider>(context, listen: false)
              .updateTransaction(transaction);
        } else {
          await Provider.of<TransactionProvider>(context, listen: false)
              .addTransaction(transaction);
        }
        
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: Text(
              widget.transaction != null ? 'Edit Transaction' : 'Add Transaction',
              style: TextStyle(
                color: themeService.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: themeService.surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: themeService.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing ? null : _saveTransaction,
                child: _isProcessing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(themeService.primaryColor),
                        ),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: themeService.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Transaction Type Toggle
                Card(
                  elevation: 0,
                  color: themeService.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isExpense = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isExpense 
                                        ? themeService.errorColor.withOpacity(0.1)
                                        : themeService.isDarkMode 
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isExpense 
                                          ? themeService.errorColor.withOpacity(0.3)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.arrow_upward,
                                          color: _isExpense 
                                              ? themeService.errorColor
                                              : themeService.subtextColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Expense',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _isExpense 
                                                ? themeService.errorColor
                                                : themeService.subtextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isExpense = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isExpense 
                                        ? themeService.successColor.withOpacity(0.1)
                                        : themeService.isDarkMode 
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: !_isExpense 
                                          ? themeService.successColor.withOpacity(0.3)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.arrow_downward,
                                          color: !_isExpense 
                                              ? themeService.successColor
                                              : themeService.subtextColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Income',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: !_isExpense 
                                                ? themeService.successColor
                                                : themeService.subtextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Amount and Title
                Card(
                  elevation: 0,
                  color: themeService.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeService.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(color: themeService.subtextColor),
                            prefixText: '${AppConfig.currencySymbol} ',
                            prefixStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: themeService.textColor,
                            ),
                            filled: true,
                            fillColor: themeService.isDarkMode 
                                ? const Color(0xFF2D3748)
                                : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: themeService.isDarkMode 
                                    ? Colors.grey.shade700 
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: themeService.isDarkMode 
                                    ? Colors.grey.shade700 
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: themeService.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          'Title',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          style: TextStyle(color: themeService.textColor),
                          decoration: InputDecoration(
                            hintText: 'e.g. Lunch at Restaurant',
                            hintStyle: TextStyle(color: themeService.subtextColor),
                            filled: true,
                            fillColor: themeService.isDarkMode 
                                ? const Color(0xFF2D3748)
                                : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: themeService.isDarkMode 
                                    ? Colors.grey.shade700 
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: themeService.isDarkMode 
                                    ? Colors.grey.shade700 
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: themeService.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          'Description (optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          style: TextStyle(color: themeService.textColor),
                          decoration: InputDecoration(
                            hintText: 'Add more details...',
                            hintStyle: TextStyle(color: themeService.subtextColor),
                            filled: true,
                            fillColor: themeService.isDarkMode 
                                ? const Color(0xFF2D3748)
                                : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: themeService.isDarkMode 
                                    ? Colors.grey.shade700 
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: themeService.isDarkMode 
                                    ? Colors.grey.shade700 
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: themeService.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Date and Time
                Card(
                  elevation: 0,
                  color: themeService.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date & Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, themeService),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: themeService.isDarkMode 
                                          ? Colors.grey.shade700 
                                          : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: themeService.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('MMM d, yyyy').format(_selectedDate),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: themeService.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(context, themeService),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: themeService.isDarkMode 
                                          ? Colors.grey.shade700 
                                          : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: themeService.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedTime.format(context),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: themeService.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Category
                Card(
                  elevation: 0,
                  color: themeService.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category['name'];
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category['name'];
                                  _selectedIcon = category['icon'];
                                  _selectedColor = category['color'];
                                  
                                  // Auto switch between income/expense based on category
                                  if (category['name'] == 'Income' || 
                                      category['name'] == 'Salary') {
                                    _isExpense = false;
                                  } else if (_selectedCategory != 'Other') {
                                    _isExpense = true;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? category['color'].withOpacity(0.1) 
                                      : themeService.isDarkMode 
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? category['color'] : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      category['icon'],
                                      color: isSelected 
                                          ? category['color'] 
                                          : themeService.subtextColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      category['name'],
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        color: isSelected 
                                            ? category['color'] 
                                            : themeService.subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You can also just enter a title and let AI categorize it for you.',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeService.subtextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Save Button
                ElevatedButton(
                  onPressed: _isProcessing ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeService.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: themeService.primaryColor.withOpacity(0.6),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.transaction != null ? 'Update Transaction' : 'Add Transaction',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}