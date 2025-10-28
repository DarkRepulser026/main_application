import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/weather_data.dart';
import '../../data/services/preferences_service.dart';
import '../../data/services/weather_service.dart';

class Rain15MinuteChart extends StatelessWidget {
  final WeatherData data;

  const Rain15MinuteChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.minutely15Precip != null && data.minutely15Precip!.text != "") {
      String text = "Next ${data.minutely15Precip!.timeTo} minutes";

      return Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 30, top: 10),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.umbrella, size: 18, color: Theme.of(context).colorScheme.primary)
                ),
                const SizedBox(width: 10,),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        unitConversion(data.minutely15Precip!.precipSumMm,
                            context.select((SettingsProvider p) => p.getPrecipUnit), decimals: 1).toString(),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, height: 1.2),
                      ),
                      Text(
                        context.select((SettingsProvider p) => p.getPrecipUnit),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary,
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Text(
                              text,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, height: 1.44),
                            )
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10, left: 10, right: 10),
              child: SizedBox(
                height: 41,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List<Widget>.generate(data.minutely15Precip!.precipListMm.length, (int index)  {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 1, right: 1),
                          child: Container(
                            //i'm doing this because otherwise you wouldn't be
                            // able to tell the 0mm rain apart from the 0.1mm, or just low values in general
                            height: data.minutely15Precip!.precipListMm[index] == 0 ?
                            5 : 6.0 + data.minutely15Precip!.precipListMm[index] * 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: data.minutely15Precip!.precipListMm[index] == 0 ?
                              Theme.of(context).colorScheme.outlineVariant : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }
                    )
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Now",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),),
                  Text('3h',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),),
                  Text('6h',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),)
                ],
              ),
            )
          ],
        ),
      );
    }
    return Container();
  }
}