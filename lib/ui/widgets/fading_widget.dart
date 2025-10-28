import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/weather_data.dart';
import '../../data/services/image_service.dart';

class FadingWidget extends StatefulWidget  {
  final WeatherData data;
  final ImageService? imageService;
  final DateTime time;

  const FadingWidget({super.key, required this.data, required this.time, required this.imageService});

  @override
  State<FadingWidget> createState() => _FadingWidgetState();
}

class _FadingWidgetState extends State<FadingWidget> with AutomaticKeepAliveClientMixin {
  bool _isVisible = true;
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer in the dispose method
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.imageService != null) {
      final dif = widget.time.difference(widget.data.fetchDatetime).inMinutes;

      String text = "Updated just now";

      if (dif > 0 && dif < 45) {
        text = "Updated $dif minutes ago";
      }
      else if (dif >= 45 && dif < 1440) {
        int hour = (dif + 30) ~/ 60;
        text = "Updated $hour hours ago";
      }
      else if (dif >= 1440) {
        int day = (dif + 720) ~/ 1440;
        text = "Updated $day days ago";
      }

      return AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
          ),
        ),
      );
    }
    return Container();
  }
}