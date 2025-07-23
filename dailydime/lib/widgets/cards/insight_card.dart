// lib/widgets/cards/insight_card.dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class InsightCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData iconData;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final int? animationDelay;

  const InsightCard({
    Key? key,
    required this.title,
    required this.content,
    required this.iconData,
    required this.color,
    this.onTap,
    this.isLoading = false,
    this.animationDelay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widget = _buildCard(context);
    
    if (animationDelay != null) {
      return FadeInUp(
        delay: Duration(milliseconds: animationDelay!),
        duration: const Duration(milliseconds: 400),
        child: widget,
      );
    }
    
    return widget;
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIcon(),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextContent(),
        ),
        if (onTap != null) _buildArrowIcon(),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildArrowIcon() {
    return Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: Colors.grey.shade400,
    );
  }
}

// Extended version with more features for special use cases
class ExpandableInsightCard extends StatefulWidget {
  final String title;
  final String content;
  final IconData iconData;
  final Color color;
  final List<String>? additionalTips;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;
  final bool isExpanded;

  const ExpandableInsightCard({
    Key? key,
    required this.title,
    required this.content,
    required this.iconData,
    required this.color,
    this.additionalTips,
    this.actionButtonText,
    this.onActionPressed,
    this.isExpanded = false,
  }) : super(key: key);

  @override
  State<ExpandableInsightCard> createState() => _ExpandableInsightCardState();
}

class _ExpandableInsightCardState extends State<ExpandableInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: widget.color.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.iconData,
                        color: widget.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: widget.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.content,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                SizeTransition(
                  sizeFactor: _animation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.additionalTips != null && widget.additionalTips!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Colors.grey, thickness: 0.5),
                        const SizedBox(height: 16),
                        const Text(
                          'Additional Tips:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.additionalTips!.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: widget.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                      if (widget.actionButtonText != null && widget.onActionPressed != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onActionPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.color,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              widget.actionButtonText!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Compact version for smaller spaces
class CompactInsightCard extends StatelessWidget {
  final String content;
  final IconData iconData;
  final Color color;
  final VoidCallback? onTap;

  const CompactInsightCard({
    Key? key,
    required this.content,
    required this.iconData,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  iconData,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}