import 'package:flutter/material.dart';

import '../../data/models/weather_data.dart';

class Circles extends StatelessWidget {
  final WeatherData data;

  const Circles({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 19, right: 19, bottom: 21, top: 1),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DescriptionCircle(
                text: '${data.current.feelsLikeC.round()}°',
                undercaption: 'Feels like',
                extra: '',
              ),
              _DescriptionCircle(
                text: '${data.current.humidity}',
                undercaption: 'Humidity',
                extra: '%',
              ),
              _DescriptionCircle(
                text: '${data.current.precipMm}',
                undercaption: 'Precip',
                extra: 'mm',
              ),
              _DescriptionCircle(
                text: '${data.current.windKph.round()}',
                undercaption: 'Wind',
                extra: 'km/h',
              ),
            ]
        )
    );
  }
}

class _DescriptionCircle extends StatelessWidget {
  final String text;
  final String undercaption;
  final String extra;

  const _DescriptionCircle({
    required this.text,
    required this.undercaption,
    required this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use the available width to determine circle size
          // Leave some margin if needed (e.g., 16px total horizontal padding)
          double diameter = constraints.maxWidth;
          // Optional: cap the size if too large
          diameter = diameter.clamp(40.0, 80.0); // adjust min/max as needed

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                undercaption,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              if (extra.isNotEmpty)
                Text(
                  extra,
                  style: const TextStyle(
                    color: Colors.lightBlue,
                    fontSize: 13,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}


