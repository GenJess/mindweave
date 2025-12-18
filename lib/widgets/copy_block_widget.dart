import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindweave/models/copy_block.dart';

class CopyBlockWidget extends StatefulWidget {
  final CopyBlock copyBlock;
  final VoidCallback? onDelete;
  final Function(CopyBlock)? onUpdate;
  final bool isExpanded;

  const CopyBlockWidget({
    super.key,
    required this.copyBlock,
    this.onDelete,
    this.onUpdate,
    this.isExpanded = false,
  });

  @override
  State<CopyBlockWidget> createState() => _CopyBlockWidgetState();
}

class _CopyBlockWidgetState extends State<CopyBlockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    if (widget.onUpdate != null) {
      widget.onUpdate!(widget.copyBlock.copyWith(isExpanded: _isExpanded));
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.copyBlock.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.content_copy,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.copyBlock.content.length > 50
                          ? '${widget.copyBlock.content.substring(0, 50)}...'
                          : widget.copyBlock.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          widget.copyBlock.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _copyToClipboard,
                            icon: Icon(
                              Icons.copy,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(
                              'Copy',
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                          if (widget.onDelete != null) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: widget.onDelete,
                              icon: Icon(
                                Icons.delete,
                                size: 16,
                                color: theme.colorScheme.error,
                              ),
                              label: Text(
                                'Delete',
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}