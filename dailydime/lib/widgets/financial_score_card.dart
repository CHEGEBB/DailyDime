// lib/widgets/financial_score_card.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' as vector;

class FinancialScoreCard extends StatelessWidget {
  final int score;

  const FinancialScoreCard({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine color based on score
    Color scoreColor;
    String healthStatus;
    String advice;

    if (score >= 80) {
      scoreColor = Colors.green;
      healthStatus = 'Excellent';
      advice = 'Your finances are in great shape! Consider increasing your investments and savings rate.';
    } else if (score >= 60) {
      scoreColor = const Color(0xFF4CAF50);
      healthStatus = 'Good';
      advice = 'You\'re doing well! Focus on reducing unnecessary expenses to improve further.';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      healthStatus = 'Average';
      advice = 'There\'s room for improvement. Try to pay down debts and stick to your budgets.';
    } else {
      scoreColor = Colors.red;
      healthStatus = 'Needs Attention';
      advice = 'Focus on reducing expenses and creating an emergency fund. Consider a detailed budget plan.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.health_and_safety_outlined,
                  color: scoreColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Financial Health Score',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: ScoreArcPainter(score, scoreColor),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          score.toString(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          'out of 100',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      healthStatus,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      advice,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreMetric('Budget', '${(score * 0.7).round()}%', scoreColor),
              _buildScoreMetric('Savings', '${(score * 0.6).round()}%', scoreColor),
              _buildScoreMetric('Debt', '${(score * 0.8).round()}%', scoreColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreMetric(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class ScoreArcPainter extends CustomPainter {
  final int score;
  final Color color;

  ScoreArcPainter(this.score, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Draw background arc
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      vector.radians(135),
      vector.radians(270),
      false,
      bgPaint,
    );

    // Draw score arc
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * vector.radians(270);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      vector.radians(135),
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}