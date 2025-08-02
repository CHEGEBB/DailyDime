// lib/widgets/crypto/market_sentiment_widget.dart

import 'package:flutter/material.dart';

class MarketSentimentWidget extends StatelessWidget {
  final double sentiment; // -100 to +100
  final double width;
  final double height;
  
  const MarketSentimentWidget({
    Key? key,
    required this.sentiment,
    this.width = 100,
    this.height = 30,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Normalize sentiment to 0-1 range
    final normalizedSentiment = (sentiment + 100) / 200;
    
    // Determine color
    final Color sentimentColor = _getSentimentColor(normalizedSentiment, theme);
    
    // Determine label
    final String sentimentLabel = _getSentimentLabel(normalizedSentiment);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: sentimentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: sentimentColor.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          // Background progress
          ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: width * normalizedSentiment,
                height: height,
                color: sentimentColor.withOpacity(0.2),
              ),
            ),
          ),
          
          // Label
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: sentimentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  sentimentLabel,
                  style: TextStyle(
                    color: sentimentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getSentimentColor(double normalizedSentiment, ThemeData theme) {
    if (normalizedSentiment > 0.75) {
      return Colors.green; // Very bullish
    } else if (normalizedSentiment > 0.6) {
      return const Color(0xFF4CAF50); // Bullish
    } else if (normalizedSentiment > 0.4) {
      return theme.colorScheme.primary; // Neutral
    } else if (normalizedSentiment > 0.25) {
      return const Color(0xFFF44336); // Bearish
    } else {
      return Colors.red; // Very bearish
    }
  }
  
  String _getSentimentLabel(double normalizedSentiment) {
    if (normalizedSentiment > 0.75) {
      return 'Very Bullish';
    } else if (normalizedSentiment > 0.6) {
      return 'Bullish';
    } else if (normalizedSentiment > 0.4) {
      return 'Neutral';
    } else if (normalizedSentiment > 0.25) {
      return 'Bearish';
    } else {
      return 'Very Bearish';
    }
  }
}