// lib/widgets/crypto/token_icon.dart

import 'package:flutter/material.dart';

class TokenIcon extends StatelessWidget {
  final String symbol;
  final double size;
  final Color? color;
  
  const TokenIcon({
    Key? key,
    required this.symbol,
    this.size = 40,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the symbol to determine an icon or fallback to the first letter
    IconData? iconData = _getIconForSymbol(symbol);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color?.withOpacity(0.15) ?? Theme.of(context).colorScheme.primary.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: iconData != null
            ? Icon(
                iconData,
                color: color ?? Theme.of(context).colorScheme.primary,
                size: size * 0.5,
              )
            : Text(
                symbol.isNotEmpty ? symbol[0].toUpperCase() : '?',
                style: TextStyle(
                  color: color ?? Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
      ),
    );
  }
  
  IconData? _getIconForSymbol(String symbol) {
    final lowerSymbol = symbol.toLowerCase();
    
    switch (lowerSymbol) {
      case 'btc':
      case 'bitcoin':
        return Icons.currency_bitcoin;
      case 'eth':
      case 'ethereum':
        return Icons.hexagon;
      case 'usdt':
      case 'tether':
        return Icons.monetization_on;
      case 'bnb':
      case 'binancecoin':
        return Icons.currency_exchange;
      case 'usdc':
      case 'usd-coin':
        return Icons.circle;
      case 'xrp':
      case 'ripple':
        return Icons.waves;
      case 'ada':
      case 'cardano':
        return Icons.architecture;
      case 'sol':
      case 'solana':
        return Icons.bolt;
      case 'doge':
      case 'dogecoin':
        return Icons.pets;
      case 'dot':
      case 'polkadot':
        return Icons.bubble_chart;
      default:
        return null;
    }
  }
}