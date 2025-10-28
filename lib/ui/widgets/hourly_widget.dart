import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../data/models/weather_data.dart';
import '../../data/services/preferences_service.dart';
import '../../data/services/weather_service.dart';
import '../../weather_refact.dart';

class HourlyWidget extends StatefulWidget {
  final List<dynamic> hours;
  final bool elevated;

  const HourlyWidget({super.key, required this.hours, required this.elevated});

  @override
  State<HourlyWidget> createState() => _HourlyWidgetState();
}

class _HourlyWidgetState extends State<HourlyWidget> with AutomaticKeepAliveClientMixin {

  int _value = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    String dateFormat = context.select((SettingsProvider p) => p.getDateFormat);

    return Padding(
      padding: widget.elevated ? const EdgeInsets.all(0)
          : const EdgeInsets.only(left: 22, right: 22, top: 0, bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(
            height: 195,
            child: hourBoxes(widget.hours, _value, widget.elevated, context, dateFormat),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 0, left: 5),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(4, (int index) {
                    return Padding(
                      padding: EdgeInsets.only(right: index < 3 ? 5.0 : 0),
                      child: ChoiceChip(
                        elevation: 0.0,
                        side: BorderSide(
                            color: index == _value ? Theme.of(context).colorScheme.secondaryContainer
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: 1.6),
                        backgroundColor: widget.elevated ? Theme.of(context).colorScheme.surfaceContainer
                          : Theme.of(context).colorScheme.surface,
                        label: Text(["Summary", "Precipitation", "Wind", "UV"][index]),
                        selected: _value == index,
                        onSelected: (bool selected) {
                          setState(() {
                            _value = index;
                            HapticFeedback.selectionClick();
                          });
                        },
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget hourBoxes(List<dynamic> hours, int _value, bool elevated, BuildContext context, String dateFormat) {

  return AnimationLimiter(
    child: ListView.builder(
      itemCount: hours.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        var hour = hours[index];
        if (hour is DateTime) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              horizontalOffset: 100.0,
              child: FadeInAnimation(
                child: dividerWidget(getDayName(hour, context, dateFormat), context)
              ),
            ),
          );
        }

        List<Widget> childWidgets = [
          HourlySum(hour: hour),
          HourlyPrecip(hour: hour),
          HourlyWind(hour: hour),
          HourlyUv(hour: hour),
        ];

        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            horizontalOffset: 100.0,
            child: FadeInAnimation(
              child: hourlyDataBuilder(hour, elevated, childWidgets[_value], context)
            ),
          ),
        );
      },
    ),
  );
}

Widget hourlyDataBuilder(hour, elevated, childWidget, context) {
  return Padding(
    padding: const EdgeInsets.all(3),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.decelerate,
      transitionBuilder: (Widget child,
          Animation<double> animation) {
        final  offsetAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: const Offset(0.0, 0.0)).animate(animation);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SlideTransition(
            position: offsetAnimation,
            child: Container(
              padding: const EdgeInsets.only(top: 7, bottom: 5),
              width: 67,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: elevated ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainer,
              ),
              child: child,
            ),
          ),
        );
      },
      child: childWidget,
    ),
  );
}

Widget dividerWidget(String name, context) {
  return Padding(
    padding: const EdgeInsets.only(top: 3, bottom: 3, left: 6, right: 6),
    child: RotatedBox(
      quarterTurns: -1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 10),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: 17,
            ),
          )
        )
      ),
    ),
  );
}

class HourlySum extends StatelessWidget {
  final WeatherHour hour;

  const HourlySum({super.key, required this.hour});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("sum"),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              "${unitConversion(hour.tempC, context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600
              ),
            )
        ),

        SvgPicture.asset(
          weatherIconPathMap[hour.condition] ?? "assets/weather_icons/clear_sky.svg",
          colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn),
          width: 38,
          height: 38,
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Icon(Icons.umbrella, size: 14, color: Theme.of(context).colorScheme.tertiary),
            ),
            Text("${hour.precipProb}%",
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 13, fontWeight: FontWeight.w600),)
          ],
        ),

        Text(convertToShortTime(hour.time, context),
          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14, fontWeight: FontWeight.w600),),
      ],
    );
  }
}

class HourlyPrecip extends StatelessWidget {
  final WeatherHour hour;

  const HourlyPrecip({super.key, required this.hour});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("precip"),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              "${unitConversion(hour.precipMm, context.select((SettingsProvider p) => p.getPrecipUnit), decimals: 1)}",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600
              ),
            )
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Icon(Icons.umbrella, size: 38, color: Theme.of(context).colorScheme.secondary),
        ),

        Text("${hour.precipProb}%",
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 13, fontWeight: FontWeight.w600),),

        Text(convertToShortTime(hour.time, context),
          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14, fontWeight: FontWeight.w600),),
      ],
    );
  }
}

class HourlyWind extends StatelessWidget {
  final WeatherHour hour;

  const HourlyWind({super.key, required this.hour});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("wind"),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              "${unitConversion(hour.windKph, context.select((SettingsProvider p) => p.getWindUnit), decimals: 0)}",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600
              ),
            )
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Icon(Icons.air, size: 38, color: Theme.of(context).colorScheme.secondary),
        ),

        Text("${unitConversion(hour.windGustKph, context.select((SettingsProvider p) => p.getWindUnit), decimals: 0)}",
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 13, fontWeight: FontWeight.w600),),

        Text(convertToShortTime(hour.time, context),
          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14, fontWeight: FontWeight.w600),),
      ],
    );
  }
}

class HourlyUv extends StatelessWidget {
  final WeatherHour hour;

  const HourlyUv({super.key, required this.hour});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("uv"),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              "${hour.uv}",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600
              ),
            )
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Icon(Icons.wb_sunny, size: 38, color: Theme.of(context).colorScheme.secondary),
        ),

        Text(getUvDescription(hour.uv),
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 13, fontWeight: FontWeight.w600),),

        Text(convertToShortTime(hour.time, context),
          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14, fontWeight: FontWeight.w600),),
      ],
    );
  }
}

String getUvDescription(int uv) {
  if (uv <= 2) return "Low";
  if (uv <= 5) return "Moderate";
  if (uv <= 7) return "High";
  if (uv <= 10) return "Very High";
  return "Extreme";
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
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } else {
      return "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
    }
  }
}