// lib/screens/savings/create_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dailydime/widgets/common/custom_button.dart';
import 'package:dailydime/config/theme.dart';

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
  final List<String> _iconOptions = [
    'laptop', 'beach_access', 'directions_car', 'home', 
    'phone_android', 'school', 'health_and_safety', 'shopping_bag'
  ];
  
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
      default: return Icons.laptop;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Create Savings Goal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal Icon Selection
                Text(
                  'Choose an icon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _iconOptions.length,
                    itemBuilder: (context, index) {
                      final iconName = _iconOptions[index];
                      final isSelected = iconName == _selectedIcon;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIcon = iconName;
                          });
                        },
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIconData(iconName),
                            size: 32,
                            color: isSelected 
                                ? Colors.white 
                                : theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Goal Name
                Text(
                  'What are you saving for?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _goalNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. New Laptop, Holiday Trip',
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Target Amount
                Text(
                  'How much do you need?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    prefixText: 'KES ',
                    hintText: '0',
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Target Date
                Text(
                  'When do you need it by?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
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
                      color: theme.colorScheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.onBackground,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Savings Frequency
                Text(
                  'How often do you want to save?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                  ),
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
                
                const SizedBox(height: 24),
                
                // Recommended Amount
                if (_targetAmountController.text.isNotEmpty &&
                    int.tryParse(_targetAmountController.text) != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
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
                                color: theme.colorScheme.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calculate,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Recommended Savings',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getRecommendedSavings(),
                          style: const TextStyle(
                            fontSize: 14,
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
                    // Here we would save the goal and navigate back
                    Navigator.pop(context);
                  },
                  isSmall: false, // Add the required parameter
                ),
                
                const SizedBox(height: 16),
                
                CustomButton(
                  text: 'Cancel',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  isOutlined: true,
                  isSmall: false, // Add the required parameter
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    
    return 'To reach your goal by ${_targetDate.day}/${_targetDate.month}/${_targetDate.year}, you need to save approximately KES ${recommendedAmount.toStringAsFixed(2)} per $period.';
  }
}