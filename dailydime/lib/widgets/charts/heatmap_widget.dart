// lib/widgets/heatmap_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/config/app_config.dart';

class SpendingHeatmapWidget extends StatelessWidget {
  final DateTime startDate;
  final Map<DateTime, double> spendingData;
  
  const SpendingHeatmapWidget({
    Key? key,
    required this.startDate,
    required this.spendingData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeatMapCalendar(
          defaultColor: Colors.white,
          flexible: true,
          colorMode: ColorMode.color,
          datasets: _processDataset(),
          colorsets: _getColorsets(),
          monthFontSize: 14,
          weekFontSize: 12,
          textColor: Colors.black,
          showColorTip: false,
          initDate: startDate,
          onClick: (date) {
            final spending = spendingData[DateTime(date.year, date.month, date.day)];
            if (spending != null) {
              _showSpendingDetails(context, date, spending);
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildColorLabel('Low', Colors.green.shade100),
            const SizedBox(width: 16),
            _buildColorLabel('Medium', Colors.green.shade300),
            const SizedBox(width: 16),
            _buildColorLabel('High', Colors.green.shade500),
            const SizedBox(width: 16),
            _buildColorLabel('Very High', Colors.green.shade700),
          ],
        ),
      ],
    );
  }

  Map<DateTime, int> _processDataset() {
    // Find the max spending to normalize values
    double maxSpending = 0;
    spendingData.forEach((date, amount) {
      if (amount > maxSpending) {
        maxSpending = amount;
      }
    });

    // Convert to HeatMap dataset (values from 0-5)
    Map<DateTime, int> dataset = {};
    spendingData.forEach((date, amount) {
      final normalizedValue = (amount / maxSpending * 4).ceil();
      dataset[date] = normalizedValue;
    });

    return dataset;
  }

  Map<int, Color> _getColorsets() {
    return {
      0: Colors.grey.shade100,
      1: Colors.green.shade100,
      2: Colors.green.shade300,
      3: Colors.green.shade500,
      4: Colors.green.shade700,
    };
  }

  Widget _buildColorLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  void _showSpendingDetails(BuildContext context, DateTime date, double amount) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            dateFormat.format(date),
            style: const TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Spending: ${AppConfig.currencySymbol} ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                date.weekday >= 6 
                    ? 'Weekend spending tends to be higher than weekdays.'
                    : 'Weekday spending is typically lower than weekends.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to transactions for that day
              },
              child: const Text('View Transactions'),
            ),
          ],
        );
      },
    );
  }
}