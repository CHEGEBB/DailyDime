// lib/screens/savings/create_goal_screen.dart

import 'package:dailydime/models/savings_model.dart';
import 'package:dailydime/providers/savings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:lottie/lottie.dart';

class CreateGoalScreen extends StatefulWidget {
  final SavingsGoal? existingGoal;
  
  const CreateGoalScreen({
    Key? key, 
    this.existingGoal,
  }) : super(key: key);

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetAmountController;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  SavingsGoalCategory _category = SavingsGoalCategory.other;
  Color _selectedColor = Colors.blue;
  
  bool _isEditing = false;
  bool _isLoading = false;
  
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];
  
  @override
  void initState() {
    super.initState();
    
    _isEditing = widget.existingGoal != null;
    
    // Initialize controllers
    _titleController = TextEditingController(text: widget.existingGoal?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingGoal?.description ?? '');
    _targetAmountController = TextEditingController(
      text: widget.existingGoal?.targetAmount.toString() ?? '',
    );
    
    // Set initial values if editing
    if (_isEditing) {
      _targetDate = widget.existingGoal!.targetDate;
      _category = widget.existingGoal!.category;
      _selectedColor = widget.existingGoal!.color;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }
  
  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF26D07C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      setState(() {
        _targetDate = pickedDate;
      });
    }
  }
  
  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final targetAmount = double.parse(_targetAmountController.text.trim());
    
    // Map category to icon
    String iconAsset;
    switch (_category) {
      case SavingsGoalCategory.travel:
        iconAsset = 'beach_access';
        break;
      case SavingsGoalCategory.education:
        iconAsset = 'school';
        break;
      case SavingsGoalCategory.electronics:
        iconAsset = 'laptop';
        break;
      case SavingsGoalCategory.vehicle:
        iconAsset = 'directions_car';
        break;
      case SavingsGoalCategory.housing:
        iconAsset = 'home';
        break;
      case SavingsGoalCategory.emergency:
        iconAsset = 'health_and_safety';
        break;
      case SavingsGoalCategory.retirement:
        iconAsset = 'account_balance';
        break;
      case SavingsGoalCategory.debt:
        iconAsset = 'money_off';
        break;
      case SavingsGoalCategory.investment:
        iconAsset = 'trending_up';
        break;
      case SavingsGoalCategory.other:
      default:
        iconAsset = 'savings';
        break;
    }
    
    bool success;
    
    if (_isEditing) {
      // Update existing goal
      final updatedGoal = widget.existingGoal!.copyWith(
        title: title,
        description: description,
        targetAmount: targetAmount,
        targetDate: _targetDate,
        category: _category,
        color: _selectedColor,
        iconAsset: iconAsset,
      );
      
      success = await savingsProvider.updateSavingsGoal(updatedGoal);
    } else {
      // Create new goal
      final newGoal = SavingsGoal(
        title: title,
        description: description,
        targetAmount: targetAmount,
        targetDate: _targetDate,
        category: _category,
        iconAsset: iconAsset,
        color: _selectedColor,
      );
      
      success = await savingsProvider.addSavingsGoal(newGoal);
    }
    
    setState(() {
      _isLoading = false;
    });
    
    if (success) {
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${_isEditing ? 'updating' : 'creating'} goal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Savings Goal' : 'Create Savings Goal'),
        backgroundColor: const Color(0xFF26D07C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with animation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF26D07C),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Lottie.asset(
                'assets/animations/savings_goal.json',
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Goal Title',
                        hintText: 'e.g. New Laptop, Dream Vacation',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add details about your goal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Target Amount
                    TextFormField(
                      controller: _targetAmountController,
                      decoration: InputDecoration(
                        labelText: 'Target Amount (KES)',
                        hintText: 'e.g. 50000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        try {
                          final amount = double.parse(value);
                          if (amount <= 0) {
                            return 'Amount must be greater than zero';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Target Date
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCategoryChip(SavingsGoalCategory.travel, 'Travel', Icons.beach_access),
                        _buildCategoryChip(SavingsGoalCategory.education, 'Education', Icons.school),
                        _buildCategoryChip(SavingsGoalCategory.electronics, 'Electronics', Icons.laptop),
                        _buildCategoryChip(SavingsGoalCategory.vehicle, 'Vehicle', Icons.directions_car),
                        _buildCategoryChip(SavingsGoalCategory.housing, 'Housing', Icons.home),
                        _buildCategoryChip(SavingsGoalCategory.emergency, 'Emergency', Icons.health_and_safety),
                        _buildCategoryChip(SavingsGoalCategory.retirement, 'Retirement', Icons.account_balance),
                        _buildCategoryChip(SavingsGoalCategory.debt, 'Debt', Icons.money_off),
                        _buildCategoryChip(SavingsGoalCategory.investment, 'Investment', Icons.trending_up),
                        _buildCategoryChip(SavingsGoalCategory.other, 'Other', Icons.savings),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Color
                    const Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions.map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == color ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                if (_selectedColor == color)
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: _selectedColor == color
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    CustomButton(
                      text: _isEditing ? 'Update Goal' : 'Create Goal',
                      onPressed: _isLoading ? null : _saveGoal,
                      isSmall: false,
                      isLoading: _isLoading,
                      buttonColor: const Color(0xFF26D07C),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryChip(SavingsGoalCategory category, String label, IconData icon) {
    final isSelected = _category == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _category = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF26D07C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF26D07C).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}