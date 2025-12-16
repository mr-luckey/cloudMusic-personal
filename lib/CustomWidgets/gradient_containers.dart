// Coded by Naseer Ahmed

import 'package:blackhole/Helpers/config.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class GradientContainer extends StatefulWidget {
  final Widget? child;
  final bool? opacity;
  const GradientContainer({required this.child, this.opacity});
  @override
  _GradientContainerState createState() => _GradientContainerState();
}

class _GradientContainerState extends State<GradientContainer> {
  MyTheme currentTheme = GetIt.I<MyTheme>();
  BoxDecoration? _cachedDecoration;
  Brightness? _lastBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDecoration();
  }

  void _updateDecoration() {
    final brightness = Theme.of(context).brightness;

    // Only rebuild decoration if brightness changed
    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      _cachedDecoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: brightness == Brightness.dark
              ? ((widget.opacity == true)
                  ? currentTheme.getTransBackGradient()
                  : currentTheme.getBackGradient())
              : [
                  const Color(0xfff5f9ff),
                  Colors.white,
                ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use RepaintBoundary to isolate gradient repaints
    return RepaintBoundary(
      child: Container(
        decoration: _cachedDecoration,
        child: widget.child,
      ),
    );
  }
}

class BottomGradientContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  const BottomGradientContainer({
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius,
  });
  @override
  _BottomGradientContainerState createState() =>
      _BottomGradientContainerState();
}

class _BottomGradientContainerState extends State<BottomGradientContainer> {
  MyTheme currentTheme = GetIt.I<MyTheme>();
  BoxDecoration? _cachedDecoration;
  Brightness? _lastBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDecoration();
  }

  void _updateDecoration() {
    final brightness = Theme.of(context).brightness;

    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      _cachedDecoration = BoxDecoration(
        borderRadius: widget.borderRadius ??
            const BorderRadius.all(Radius.circular(15.0)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: brightness == Brightness.dark
              ? currentTheme.getBottomGradient()
              : [
                  Colors.white,
                  Theme.of(context).canvasColor,
                ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: widget.margin ?? const EdgeInsets.fromLTRB(25, 0, 25, 25),
        padding: widget.padding ?? const EdgeInsets.fromLTRB(10, 15, 10, 15),
        decoration: _cachedDecoration,
        child: widget.child,
      ),
    );
  }
}

class GradientCard extends StatefulWidget {
  final Widget child;
  final BorderRadius? radius;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;
  const GradientCard({
    required this.child,
    this.radius,
    this.elevation,
    this.margin,
    this.padding,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
  });
  @override
  _GradientCardState createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard> {
  MyTheme currentTheme = GetIt.I<MyTheme>();
  BoxDecoration? _cachedDecoration;
  Brightness? _lastBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDecoration();
  }

  void _updateDecoration() {
    final brightness = Theme.of(context).brightness;

    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      _cachedDecoration = BoxDecoration(
        gradient: LinearGradient(
          begin: widget.gradientBegin ?? Alignment.topLeft,
          end: widget.gradientEnd ?? Alignment.bottomRight,
          colors: widget.gradientColors ??
              (brightness == Brightness.dark
                  ? currentTheme.getCardGradient()
                  : [
                      Colors.white,
                      Theme.of(context).canvasColor,
                    ]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        elevation: widget.elevation ?? 3,
        shape: RoundedRectangleBorder(
          borderRadius: widget.radius ?? BorderRadius.circular(10.0),
        ),
        clipBehavior: Clip.antiAlias,
        margin: widget.margin ?? EdgeInsets.zero,
        color: Colors.transparent,
        child: widget.elevation == 0
            ? widget.child
            : DecoratedBox(
                decoration: _cachedDecoration!,
                child: Padding(
                  padding: widget.padding ?? EdgeInsets.zero,
                  child: widget.child,
                ),
              ),
      ),
    );
  }
}
