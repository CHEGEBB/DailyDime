// lib/screens/savings/create_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:intl/intl.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({Key? key}) : super(key: key);

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _goalNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 180));
  String _selectedSavingsFrequency = 'Daily';
  final List<String> _savingsFrequencies = ['Daily', 'Weekly', 'Monthly'];
  String _selectedIcon = 'laptop';
  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'laptop', 'label': 'Laptop', 'color': Colors.blue},
    {'name': 'beach_access', 'label': 'Holiday', 'color': Colors.orange},
    {'name': 'directions_car', 'label': 'Car', 'color': Colors.red},
    {'name': 'home', 'label': 'Home', 'color': Colors.teal},
    {'name': 'phone_android', 'label': 'Phone', 'color': Colors.purple},
    {'name': 'school', 'label': 'Education', 'color': Colors.indigo},
    {'name': 'health_and_safety', 'label': 'Health', 'color': Colors.pink},
    {'name': 'shopping_bag', 'label': 'Shopping', 'color': Colors.amber},
    {'name': 'savings', 'label': 'Custom', 'color': Colors.green},
  ];
  
  final accentColor = const Color(0xFF26D07C); // Emerald green
  bool _enableAutoSaving = true;
  
  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'laptop': return Icons.laptop;
      case 'beach_access': return Icons.beach_access;
      case 'directions_car': return Icons.directions_car;
      case 'home': return Icons.home;
      case 'phone_android': return Icons.phone_android;
      case 'school': return Icons.school;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'savings': return Icons.savings;
      default: return Icons.laptop;
    }
  }

  String _getRecommendedSavings() {
    if (_targetAmountController.text.isEmpty) return '';
    
    final targetAmount = int.tryParse(_targetAmountController.text) ?? 0;
    if (targetAmount <= 0) return '';
    
    final daysUntilTarget = _targetDate.difference(DateTime.now()).inDays;
    if (daysUntilTarget <= 0) return '';
    
    late double recommendedAmount;
    late String period;
    
    switch (_selectedSavingsFrequency) {
      case 'Daily':
        recommendedAmount = targetAmount / daysUntilTarget;
        period = 'day';
        break;
      case 'Weekly':
        recommendedAmount = targetAmount / (daysUntilTarget / 7);
        period = 'week';
        break;
      case 'Monthly':
        recommendedAmount = targetAmount / (daysUntilTarget / 30);
        period = 'month';
        break;
      default:
        recommendedAmount = targetAmount / daysUntilTarget;
        period = 'day';
    }
    
    return 'To reach your goal by ${DateFormat('dd MMM, yyyy').format(_targetDate)}, you need to save approximately KES ${recommendedAmount.toStringAsFixed(0)} per $period.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Create Savings Goal'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual preview of the goal
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/images/pattern5.png'),
                  fit: BoxFit.cover,
                  opacity: 0.2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconData(_selectedIcon),
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _goalNameController.text.isNotEmpty 
                          ? _goalNameController.text 
                          : 'New Savings Goal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _targetAmountController.text.isNotEmpty 
                          ? 'KES ${_targetAmountController.text}' 
                          : 'Target Amount',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main content
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Step 1 of 2',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Goal Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Goal Name
                    _buildFormLabel('What are you saving for?'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _goalNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. New Laptop, Holiday Trip',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.edit),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Goal Icon Selection
                    _buildFormLabel('Choose an icon'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 100,
                        ),
                        itemCount: _iconOptions.length,
                        itemBuilder: (context, index) {
                          final iconOption = _iconOptions[index];
                          final iconName = iconOption['name'] as String;
                          final iconLabel = iconOption['label'] as String;
                          final iconColor = iconOption['color'] as Color;
                          final isSelected = iconName == _selectedIcon;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIcon = iconName;
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? iconColor 
                                        : iconColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(color: iconColor, width: 2)
                                        : null,
                                  ),
                                  child: Icon(
                                    _getIconData(iconName),
                                    size: 30,
                                    color: isSelected 
                                        ? Colors.white 
                                        : iconColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  iconLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                    color: isSelected 
                                        ? iconColor 
                                        : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Target Amount
                    _buildFormLabel('How much do you need?'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _targetAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        prefixText: 'KES ',
                        hintText: '0',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Target Date
                    _buildFormLabel('When do you need it by?'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _targetDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: accentColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            _targetDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMM, yyyy').format(_targetDate),
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[800],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Savings Frequency
                    _buildFormLabel('How often do you want to save?'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.repeat),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedSavingsFrequency,
                                items: _savingsFrequencies.map((String frequency) {
                                  return DropdownMenuItem<String>(
                                    value: frequency,
                                    child: Text(frequency),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedSavingsFrequency = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Auto-saving option
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Enable AI-powered auto-saving',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Our AI will automatically suggest small amounts to save based on your spending patterns',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _enableAutoSaving,
                            onChanged: (value) {
                              setState(() {
                                _enableAutoSaving = value;
                              });
                            },
                            activeColor: accentColor,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recommended Amount
                    if (_targetAmountController.text.isNotEmpty &&
                        int.tryParse(_targetAmountController.text) != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calculate,
                                    color: accentColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Savings Plan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getRecommendedSavings(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 36),
                    
                    // Create Goal Button
                    CustomButton(
                      text: 'Create Savings Goal',
                      onPressed: () {
                        // Save goal and navigate back
                        Navigator.pop(context);
                      },
                      isSmall: false,
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
  
  Widget _buildFormLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }
}