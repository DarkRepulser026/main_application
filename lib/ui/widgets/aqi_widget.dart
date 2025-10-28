import 'package:flutter/material.dart';

import '../../data/models/weather_data.dart';

class AqiWidget extends StatelessWidget {
  final WeatherData data;

  const AqiWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final aqi = data.aqi.aqiIndex;
    String quality;
    Color color;

    if (aqi == 1) {
      quality = 'Good';
      color = Colors.green;
    } else if (aqi == 2) {
      quality = 'Fair';
      color = Colors.yellow;
    } else if (aqi == 3) {
      quality = 'Moderate';
      color = Colors.orange;
    } else if (aqi == 4) {
      quality = 'Poor';
      color = Colors.red;
    } else {
      quality = 'Very Poor';
      color = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                aqi.toString(),
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Air Quality',
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                ),
                Text(
                  quality,
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}