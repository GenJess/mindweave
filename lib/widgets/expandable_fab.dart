import 'package:flutter/material.dart';
import 'dart:math' as math;

class ExpandableFab extends StatefulWidget {
  final List<ActionButton> actions;
  final Widget? child;
  final bool initialOpen;
  final double distance;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ExpandableFab({
    super.key,
    required this.actions,
    this.child,
    this.initialOpen = false,
    this.distance = 80,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // Backdrop
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) => _open
                ? GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      color: Colors.black.withOpacity(0.3 * _expandAnimation.value),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
          // Action buttons
          ..._buildActionButtons(),
          
          // Main FAB
          FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: widget.backgroundColor ?? theme.colorScheme.primary,
            foregroundColor: widget.foregroundColor ?? theme.colorScheme.onPrimary,
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _expandAnimation.value * math.pi / 4,
                  child: widget.child ?? Icon(
                    _open ? Icons.close : Icons.add,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    final children = <Widget>[];
    final count = widget.actions.length;
    
    for (int i = 0; i < count; i++) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: 270.0 - (i * (90.0 / (count - 1))),
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.actions[i],
        ),
      );
    }
    
    return children;
  }
}

class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 28.0 + offset.dx,
          bottom: 28.0 + offset.dy,
          child: Transform.scale(
            scale: progress.value,
            child: child,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: backgroundColor ?? theme.colorScheme.secondaryContainer,
      elevation: 4.0,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: foregroundColor ?? theme.colorScheme.onSecondaryContainer,
        tooltip: tooltip,
      ),
    );
  }
}