import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/weather_data.dart';
import '../../data/services/color_service.dart';
import '../../data/services/preferences_service.dart';
import '../../data/services/weather_service.dart';

class TempAndConditionText extends StatefulWidget {
  final WeatherData data;
  final Color? textRegionColor;

  const TempAndConditionText({
    super.key,
    required this.data,
    required this.textRegionColor,
  });

  @override
  State<TempAndConditionText> createState() => _TempAndConditionTextState();
}

class _TempAndConditionTextState extends State<TempAndConditionText> {
  ColorsOnImage? colorsOnImage;
  ColorScheme? lastColorScheme;

  @override
  void initState() {
    super.initState();
  }

  //this ensures that the color contrast checking logic only runs when it actually needs to
  @override
  void didUpdateWidget(covariant TempAndConditionText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.textRegionColor != widget.textRegionColor || lastColorScheme != Theme.of(context).colorScheme) {
      _recalculateColors();
      lastColorScheme = Theme.of(context).colorScheme;
    }
  }

  void _recalculateColors() {
    colorsOnImage = ColorsOnImage.getColorsOnImage(
      Theme.of(context).colorScheme,
      widget.textRegionColor ?? Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        //Container(width: 100, height: 100, color: colorsOnImage.regionColor,),
        SmoothTempTransition(
          target: unitConversion(widget.data.current.tempC,
          context.select((SettingsProvider p) => p.getTempUnit), decimals: 1) * 1.0,
          color: colorsOnImage?.colorPop ?? Theme.of(context).colorScheme.tertiaryFixedDim,
          fontSize: 77,
        ),
        Text(
          widget.data.current.condition,
          style: GoogleFonts.outfit(
            color: colorsOnImage?.descColor ?? Theme.of(context).colorScheme.surface,
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class SmoothTempTransition extends StatefulWidget {
  final double target;
  final Color color;
  final double fontSize;

  const SmoothTempTransition({super.key, required this.target, required this.color, required this.fontSize});

  @override
  State<SmoothTempTransition> createState() => _SmoothTempTransitionState();
}

class _SmoothTempTransitionState extends State<SmoothTempTransition> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SmoothTempTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _animation = Tween<double>(begin: _animation.value, end: widget.target).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value.toStringAsFixed(1)}°',
          style: TextStyle(
            color: widget.color,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w300,
          ),
        );
      },
    );
  }
}