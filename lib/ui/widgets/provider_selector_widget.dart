import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/services/preferences_service.dart';

class ProviderSelector extends StatelessWidget {
  final Function updateLocation;
  final String latLon;
  final String loc;

  const ProviderSelector({super.key, required this.loc, required this.latLon, required this.updateLocation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 80, top: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, top: 0),
            child: Text("Weather Provider", style: TextStyle(fontSize: 17),)
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 7, bottom: 7),
              child: DropdownButton(
                underline: Container(),
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                borderRadius: BorderRadius.circular(18),
                icon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.unfold_more, color: Theme.of(context).colorScheme.tertiary, size: 22,),
                ),
                value: context.select((SettingsProvider p) => p.getWeatherProvider),
                items: ["weatherapi", "open-meteo", "met-norway"].map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(item, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18),)
                    ),
                  );
                }).toList(),
                onChanged: (String? value) async {
                  if (value != null) {
                    HapticFeedback.mediumImpact();
                    context.read<SettingsProvider>().setWeatherProvider(value);
                    await updateLocation(latLon, loc);
                  }
                },
                itemHeight: 55,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}