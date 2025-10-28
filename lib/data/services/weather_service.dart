import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_data.dart';
import 'preferences_service.dart';

List<double> weatherGetMaxMinTempForDaily(List<WeatherDay> days) {
  double minTemp = 100;
  double maxTemp = -100;
  for (int i = 0; i < days.length; i++) {
    if (days[i].minTempC < minTemp) {
      minTemp = days[i].minTempC;
    }
    if (days[i].maxTempC > maxTemp) {
      maxTemp = days[i].maxTempC;
    }
  }
  return [minTemp, maxTemp];
}

String getDateStringFromLocalTime(DateTime localTime) {
  return DateFormat('EEEE, MMMM d').format(localTime);
}

num unitConversion(double value, String unit, {int decimals = 2}) {
  double result;
  switch (unit) {
    case '˚C':
      result = value;
      break;
    case '˚F':
      result = value * 9 / 5 + 32;
      break;
    case 'K':
      result = value + 273.15;
      break;
    case 'mm':
    case 'in':
      result = unit == 'in' ? value / 25.4 : value;
      break;
    case 'km/h':
    case 'mph':
    case 'm/s':
    case 'kn':
      // Simple conversion, may need to expand
      result = value; // Placeholder
      break;
    default:
      result = value;
  }
  if (decimals == 0) {
    return result.round();
  }
  return double.parse(result.toStringAsFixed(decimals));
}

String convertTime(DateTime time, BuildContext context) {
  if (context.select((SettingsProvider p) => p.getTimeMode) == "12 hour") {
    return DateFormat('h:mm a').format(time).toLowerCase();
  }
  return DateFormat('HH:mm').format(time);
}

String convertToShortTime(DateTime time, BuildContext context) {
  if (context.select((SettingsProvider p) => p.getTimeMode) == "12 hour") {
    return DateFormat('ha').format(time).toLowerCase();
  }
  return DateFormat('H:mm').format(time);
}

String convertToWeekDayTime(DateTime? time, BuildContext context) {
  if (time != null) {
    String weekName = getWeekName(time.weekday - 1);
    return "$weekName ${convertTime(time, context)}";
  }
  return "unknown";
}

String getWeekName(int index) {
  List<String> weeks = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun"
  ];
  return weeks[index];
}

String getDayName(DateTime day, BuildContext context) {
  String weekName = getWeekName(day.weekday - 1);
  final String format = context.select((SettingsProvider p) => p.getDateFormat) == "mm/dd" ? "M/dd" : "dd/MM";
  final String date = DateFormat(format).format(day);
  return "$weekName, $date";
}