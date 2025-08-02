// lib/widgets/crypto/portfolio_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/models/crypto_models.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/widgets/crypto/glassmorphic_container.dart';

class PortfolioCard extends StatelessWidget {
  final Portfolio portfolio;
  final ThemeService themeService;
  
  const PortfolioCard({
    Key? key,
    required this.portfolio,
    required this.themeService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositiveChange = portfolio.percentChange24h >= 0;
    final formatter = NumberFormat('#,##0.00');
    
    return GlassmorphicContainer(
      width: double.infinity,
      height: 180,
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
                        '${portfolio.percentChange24h.toStringAsFixed(2)}%',
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
            Text(
              '\$${formatter.format(portfolio.totalValue)}',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: themeService.textColor,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${portfolio.wallets.length} wallets',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: themeService.subtextColor,
                  ),
                ),
                Text(
                  'Updated ${_getTimeAgo(portfolio.lastUpdated)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: themeService.subtextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}