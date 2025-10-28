import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../data/models/weather_data.dart';
import '../../data/services/preferences_service.dart';
import '../../data/services/weather_service.dart';
import '../../weather_refact.dart';

class DailyWidget extends StatefulWidget {
  final WeatherData data;

  const DailyWidget({super.key, required this.data});

  @override
  State<DailyWidget> createState() => _DailyWidgetState();
}

class _DailyWidgetState extends State<DailyWidget> with AutomaticKeepAliveClientMixin {
  static const int maxToShow = 7;

  bool isExpanded = false;
  int dayCap = maxToShow;

  late List<bool> expand = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) { //there will never be more days than 20
      expand.add(false);
    }
  }

  void _onExpandTapped(int index) {
    setState(() {
      HapticFeedback.lightImpact();
      expand[index] = !expand[index];
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    int daysToShow = min(dayCap, widget.data.days.length);
    bool showButton = maxToShow < widget.data.days.length;

    return Padding(
      padding: const EdgeInsets.only(left: 23, right: 23, bottom: 25, top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 1, bottom: 14),
            child: Text("Daily", style: TextStyle(fontSize: 17),)
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ListView.builder(
              key: ValueKey(daysToShow),
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daysToShow,
              itemBuilder: (context, index) {
                final day = widget.data.days[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: index == 0 ? const Radius.circular(33) : const Radius.circular(6),
                            bottom: index == daysToShow - 1  && !showButton
                                ? const Radius.circular(33) : const Radius.circular(6),
                        ),
                        color: Theme.of(context).colorScheme.surfaceContainer
                      ),
                      child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: expand[index] ? DailyExpanded(day: day, onExpandTapped:  _onExpandTapped, index: index)
                            : DailyCollapsed(data: widget.data, day: day, index: index, onExpandTapped:  _onExpandTapped)
                      )
                  ),
                );
              }
            ),
          ),
          if (showButton) GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              HapticFeedback.mediumImpact();
              if (isExpanded) {
                setState(() {
                  dayCap = 7;
                  isExpanded = false;
                });
              }
              else {
                setState(() {
                  dayCap = 20;
                  isExpanded = true;
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(33))
              ),
              padding: const EdgeInsets.only(left: 22, right: 22, top: 11, bottom: 11),
              margin: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isExpanded ? "Show Less" : "Show More",
                    style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 16),
                  ),
                  const SizedBox(width: 4,),
                  Icon(
                    isExpanded ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Theme.of(context).colorScheme.onTertiaryContainer, size: 16,)
                ]
              ),
            ),
          )
        ],
      ),
    );
  }
}

class DailyCollapsed extends StatelessWidget {
  final Function onExpandTapped;
  final int index;
  final WeatherDay day;
  final WeatherData data;

  const DailyCollapsed({super.key, required this.onExpandTapped, required this.index, required this.day, required this.data});

  @override
  Widget build(BuildContext context) {
    String dateFormat = context.select((SettingsProvider p) => p.getDateFormat);
    String dayName = getDayName(day.date, context, dateFormat);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onExpandTapped(index),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(dayName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.5, fontWeight: FontWeight.w500),),
            ),
            const SizedBox(width: 10,),
            SvgPicture.asset(
              weatherIconPathMap[day.condition] ?? "assets/weather_icons/clear_sky.svg",
              colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn),
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 15,),
            Expanded(
              child: Text(day.condition, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.5),),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text("${unitConversion(day.minTempC, context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),),
                    const SizedBox(width: 8,),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8,),
                    Text("${unitConversion(day.maxTempC, context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°",
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w600),),
                  ],
                ),
                if (day.precipProb > 0) Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(Icons.umbrella, size: 14, color: Theme.of(context).colorScheme.tertiary,),
                      const SizedBox(width: 2,),
                      Text("${day.precipProb}%", style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 14),)
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(width: 10,),
            Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.outline, size: 20,)
          ],
        ),
      ),
    );
  }
}

class DailyExpanded extends StatelessWidget {
  final WeatherDay day;
  final Function onExpandTapped;
  final int index;

  const DailyExpanded({super.key, required this.day, required this.onExpandTapped, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onExpandTapped(index),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text("Details", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),),
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_up, color: Theme.of(context).colorScheme.outline, size: 20,)
              ],
            ),
            const SizedBox(height: 15,),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Precipitation", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),),
                      const SizedBox(height: 5,),
                      Text("${unitConversion(day.totalPrecipMm, context.select((SettingsProvider p) => p.getPrecipUnit), decimals: 1)} ${context.select((SettingsProvider p) => p.getPrecipUnit)}",
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w600),),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Chance", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),),
                      const SizedBox(height: 5,),
                      Text("${day.precipProb}%", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w600),),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15,),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Wind", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),),
                      const SizedBox(height: 5,),
                      Text("${unitConversion(day.windKph, context.select((SettingsProvider p) => p.getWindUnit), decimals: 0)} ${context.select((SettingsProvider p) => p.getWindUnit)}",
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w600),),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("UV Index", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),),
                      const SizedBox(height: 5,),
                      Text("${day.uv}", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w600),),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String getDayName(DateTime date, BuildContext context, String dateFormat) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final dateOnly = DateTime(date.year, date.month, date.day);

  if (dateOnly == today) {
    return "Today";
  } else if (dateOnly == tomorrow) {
    return "Tomorrow";
  } else {
    // Use the dateFormat from settings
    if (dateFormat == "DD/MM/YYYY") {
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${(date.year % 100).toString().padLeft(2, '0')}";
    } else {
      return "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${(date.year % 100).toString().padLeft(2, '0')}";
    }
  }
}