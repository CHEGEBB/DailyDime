// lib/widgets/cards/transaction_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/config/app_config.dart';

class TransactionCard extends StatelessWidget {
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final IconData icon;
  final Color color;
  final bool isSms;
  final VoidCallback onTap;
  final String? status;

  const TransactionCard({
    Key? key,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.icon,
    required this.color,
    this.isSms = false,
    required this.onTap,
    this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: AppConfig.currencySymbol + ' ',
      decimalDigits: 2,
    );

    // Status color
    Color statusColor = Colors.transparent;
    if (status != null) {
      if (status!.toLowerCase() == 'successful') {
        statusColor = Colors.green;
      } else if (status!.toLowerCase() == 'warning') {
        statusColor = Colors.orange;
      } else if (status!.toLowerCase() == 'error') {
        statusColor = Colors.red;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Transaction icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('hh:mm a').format(date)} · $category',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Amount and status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isExpense
                      ? '-${currencyFormat.format(amount)}'
                      : '+${currencyFormat.format(amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isExpense ? Colors.red.shade700 : const Color(0xFF26D07C),
                  ),
                ),
                const SizedBox(height: 4),
                if (status != null)
                  Text(
                    status!,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}