import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/weather_data.dart';
import '../../data/services/weather_service.dart';

class WavePainter extends CustomPainter {
  final double waveValue;
  final Color firstColor;
  final Color secondColor;
  final double hihi;

  WavePainter(this.waveValue, this.firstColor, this.secondColor, this.hihi);

  @override
  void paint(Canvas canvas, Size size) {
    final firstPaint = Paint()
      ..color = firstColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final secondPaint = Paint()
      ..color = secondColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path1 = Path();

    const amplitude = 2.15;
    const frequency = 21.0;
    final splitPoint = hihi * size.width;

    for (double x = 0; x <= splitPoint; x++) {
      final y = size.height / 2 +
          amplitude * sin((x / frequency * 2 * pi) + (waveValue * 2 * pi));
      if (x == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }

    path1.moveTo(splitPoint, size.height / 2 + 8);
    path1.lineTo(splitPoint, size.height / 2 - 8);

    final path2 = Path();

    for (double x = splitPoint; x <= size.width; x++) {
      final y = size.height / 2;
      if (x == splitPoint) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }

    canvas.drawPath(path2, secondPaint);
    canvas.drawPath(path1, firstPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ClockUpdater extends StatefulWidget {
  final int hourDiff;
  final double progress;
  final double width;

  const ClockUpdater({
    super.key,
    required this.hourDiff,
    required this.progress,
    required this.width,
  });

  @override
  State<ClockUpdater> createState() => _ClockUpdaterState();
}

class _ClockUpdaterState extends State<ClockUpdater> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startAlignedTimer();
  }

  void _startAlignedTimer() {
    final now = DateTime.now();

    //make a timer that will update every minute to show the local time

    final delay = Duration(
      seconds: 60 - now.second,
      milliseconds: -now.millisecond,
    );

    _timer = Timer(delay, () {
      if (mounted) {
        setState(() {});
      }

      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime localTime = now.add(Duration(hours: widget.hourDiff));
    String write = convertTime(localTime, context);

    final textPainter = TextPainter(
        text: TextSpan(text: write, style: const TextStyle(fontSize: 14)),
        textDirection: TextDirection.ltr);
    textPainter.layout();
    final textWidth = textPainter.width * 1.1;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.0,
        end: widget.progress,
      ),

      curve: Curves.easeInOut,

      duration: const Duration(milliseconds: 600),

      builder: (context, currentScale, child) {
        return Padding(
          padding: EdgeInsets.only(
              left: min(
                  max((currentScale * (widget.width - 53)) - textWidth / 2 + 5, 0),
                  widget.width - 53 - textWidth)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(write, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}

class WaveTicker extends StatefulWidget {
  final Widget child;
  final double currentWaveProgress;

  const WaveTicker({
    super.key,
    required this.child,
    required this.currentWaveProgress,
  });

  @override
  State<WaveTicker> createState() => _WaveTickerState();
}

class _WaveTickerState extends State<WaveTicker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
              _controller.value,
              Theme.of(context).colorScheme.tertiary,
              Theme.of(context).colorScheme.tertiaryContainer,
              widget.currentWaveProgress
          ),
          child: widget.child,
        );
      },
    );
  }
}

class SunStatusWidget extends StatefulWidget {
  final WeatherData data;
  final double width;

  const SunStatusWidget({super.key, required this.data, required this.width});

  @override
  State<SunStatusWidget> createState() => _SunStatusWidgetState();
}

class _SunStatusWidgetState extends State<SunStatusWidget> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentTime = DateTime.now();

    final localtimeOld = widget.data.localTime;

    int hourDiff = localtimeOld.hour - currentTime.hour;

    final double targetProgress = widget.data.sunStatus.sunstatus;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetProgress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,

      builder: (context, animatedProgress, child) {

        return Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 23),
          child: Column(
            children: [

              ClockUpdater(hourDiff: hourDiff, progress: targetProgress, width: widget.width),

              Padding(
                padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 11),
                child: SizedBox(
                  width: double.infinity,
                  height: 8.0,
                  child: WaveTicker(
                    currentWaveProgress: animatedProgress,
                    child: Container(),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4, top: 1),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 14,
                      ),
                    ),
                    Text(convertTime(widget.data.sunStatus.sunrise, context),
                      style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.tertiary),),
                    const Spacer(),
                    Text(convertTime(widget.data.sunStatus.sunset, context),
                      style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.secondary),),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 1),
                      child: Icon(Icons.nightlight_outlined,
                          color: Theme.of(context).colorScheme.secondary, size: 14),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}