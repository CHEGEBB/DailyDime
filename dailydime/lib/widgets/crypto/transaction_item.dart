// lib/widgets/crypto/transaction_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dailydime/models/crypto_models.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/widgets/crypto/glassmorphic_container.dart';
import 'package:dailydime/widgets/crypto/token_icon.dart';

class TransactionItem extends StatelessWidget {
  final CryptoTransaction transaction;
  final ThemeService themeService;
  final VoidCallback? onTap;
  
  const TransactionItem({
    Key? key,
    required this.transaction,
    required this.themeService,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isReceived = transaction.type == TransactionType.receive;
    final formatter = DateFormat.yMMMd().add_jm();
    
    Color statusColor;
    IconData statusIcon;
    
    switch (transaction.type) {
      case TransactionType.receive:
        statusColor = themeService.successColor;
        statusIcon = Icons.arrow_downward;
        break;
      case TransactionType.send:
        statusColor = themeService.infoColor;
        statusIcon = Icons.arrow_upward;
        break;
      case TransactionType.swap:
        statusColor = themeService.warningColor;
        statusIcon = Icons.swap_horiz;
        break;
      case TransactionType.stake:
        statusColor = themeService.accentColor;
        statusIcon = Icons.lock;
        break;
      case TransactionType.unstake:
        statusColor = themeService.primaryColor;
        statusIcon = Icons.lock_open;
        break;
      case TransactionType.mint:
        statusColor = themeService.secondaryColor;
        statusIcon = Icons.add_circle;
        break;
      case TransactionType.burn:
        statusColor = themeService.errorColor;
        statusIcon = Icons.remove_circle;
        break;
      case TransactionType.reward:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TransactionType.bridge:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TransactionType.liquidity:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TransactionType.nft:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TransactionType.contract:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TransactionType.unknown:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 80,
          borderRadius: 16,
          blur: 5,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeService.surfaceColor.withOpacity(0.1),
              themeService.surfaceColor.withOpacity(0.05),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.3),
              themeService.surfaceColor.withOpacity(0.1),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getTransactionTypeLabel(transaction.type),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: themeService.textColor,
                        ),
                      ),
                      Text(
                        formatter.format(transaction.timestamp),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: themeService.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${isReceived ? '+' : '-'}${transaction.amount.toStringAsFixed(4)} ${transaction.symbol}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeService.textColor,
                      ),
                    ),
                    Text(
                      '\$${transaction.valueUsd.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: themeService.subtextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getTransactionTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return 'Received';
      case TransactionType.send:
        return 'Sent';
      case TransactionType.swap:
        return 'Swapped';
      case TransactionType.stake:
        return 'Staked';
      case TransactionType.unstake:
        return 'Unstaked';
      case TransactionType.mint:
        return 'Minted';
      case TransactionType.burn:
        return 'Burned';
      case TransactionType.reward:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TransactionType.bridge:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TransactionType.liquidity:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TransactionType.nft:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TransactionType.contract:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TransactionType.unknown:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}