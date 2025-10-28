import 'package:flutter/material.dart';

import '../../data/models/weather_data.dart';
import '../../data/services/weather_service.dart';

class AlertWidget extends StatelessWidget {
  final WeatherData data;

  const AlertWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.alerts.isNotEmpty) {
      return Padding(
          padding: const EdgeInsets.only(
              left: 25, right: 25, bottom: 25, top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 11),
                child: Text("Alerts",
                style: TextStyle(fontSize: 17),),
              ),
              Column(
                children: List.generate(data.alerts.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Container(
                      padding: const EdgeInsets.only(left: 25, top: 23, bottom: 23, right: 22),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.only(left: 7, right: 7, top: 6, bottom: 8),
                              child: Icon(Icons.warning_amber_rounded, size: 20, color: Theme.of(context).colorScheme.error)
                          ),
                          const SizedBox(width: 20,),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(data.alerts[index].event, style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface, fontSize: 18, height: 1.2
                                  ),),
                                ),
                                Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "${convertToWeekDayTime(data.alerts[index].start, context)} - ${convertToWeekDayTime(data.alerts[index].end, context)}",
                                      style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14),)
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          )
      );
    }
    return Container();
  }
}