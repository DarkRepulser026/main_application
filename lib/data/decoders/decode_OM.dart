import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../services/caching_service.dart';
import '../models/weather_data.dart';

const Map<int, String> oMCodes = {
  0: 'Clear Sky',
  1: 'Mainly Clear',
  2: 'Partly Cloudy',
  3: 'Overcast',
  45: 'Fog',
  48: 'Depositing Rime Fog',
  51: 'Light Drizzle',
  53: 'Moderate Drizzle',
  55: 'Dense Drizzle',
  56: 'Light Freezing Drizzle',
  57: 'Dense Freezing Drizzle',
  61: 'Slight Rain',
  63: 'Moderate Rain',
  65: 'Heavy Rain',
  66: 'Light Freezing Rain',
  67: 'Heavy Freezing Rain',
  71: 'Slight Snow Fall',
  73: 'Moderate Snow Fall',
  75: 'Heavy Snow Fall',
  77: 'Snow Grains',
  80: 'Slight Rain Showers',
  81: 'Moderate Rain Showers',
  82: 'Violent Rain Showers',
  85: 'Slight Snow Showers',
  86: 'Heavy Snow Showers',
  95: 'Thunderstorm',
  96: 'Thunderstorm with Slight Hail',
  99: 'Thunderstorm with Heavy Hail',
};

int aqiIndexCorrection(int aqi) {
  if (aqi <= 20) {
    return 1;
  }
  if (aqi <= 40) {
    return 2;
  }
  if (aqi <= 60) {
    return 3;
  }
  if (aqi <= 80) {
    return 4;
  }
  if (aqi <= 100) {
    return 5;
  }
  return 6;
}

DateTime oMGetLocalTime(item) {
  DateTime localTime = DateTime.now().toUtc().add(Duration(seconds: item["utc_offset_seconds"]));
  return localTime;
}

double oMGetSunStatus(item) {
  DateTime localtime = oMGetLocalTime(item);

  List<String> splitted1 = item["daily"]["sunrise"][0].split("T")[1].split(":");
  DateTime sunrise = localtime.copyWith(hour: int.parse(splitted1[0]), minute: int.parse(splitted1[1]));

  List<String> splitted2 = item["daily"]["sunset"][0].split("T")[1].split(":");
  DateTime sunset = localtime.copyWith(hour: int.parse(splitted2[0]), minute: int.parse(splitted2[1]));

  int total = sunset.difference(sunrise).inMinutes;
  int passed = localtime.difference(sunrise).inMinutes;

  return min(1, max(passed / total, 0));
}

Future<List<dynamic>> oMRequestData(double lat, double lng, String place) async {
  final oMParams = {
    "latitude": lat.toString(),
    "longitude": lng.toString(),
    "minutely_15" : ["precipitation"],
    "current": ["temperature_2m", "weather_code", "relative_humidity_2m", "apparent_temperature"],
    "hourly": ["temperature_2m", "precipitation", "weather_code", "wind_speed_10m", "wind_direction_10m", "uv_index", "precipitation_probability", "wind_gusts_10m"],
    "daily": ["weather_code", "temperature_2m_max", "temperature_2m_min", "uv_index_max", "precipitation_sum", "precipitation_probability_max", "wind_speed_10m_max", "wind_direction_10m_dominant", "sunrise", "sunset"],
    "timezone": "auto",
    "forecast_days": "14",
    "forecast_minutely_15" : "24",
  };

  final oMUrl = Uri.https("api.open-meteo.com", 'v1/forecast', oMParams);

  print('Requesting: $oMUrl');

  var response = await http.get(oMUrl).timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw Exception('Failed to load weather data: ${response.statusCode}');
  }

  final oMData = jsonDecode(response.body);

  DateTime fetch_datetime = DateTime.now();
  bool isonline = true;

  return [oMData, fetch_datetime, isonline];
}

String oMTextCorrection(int code) {
  return oMCodes[code] ?? 'Clear Sky';
}

String oMCurrentTextCorrection(int code, WeatherSunStatus sunStatus, DateTime time) {
  if (time.difference(sunStatus.sunrise).isNegative || sunStatus.sunset.difference(time).isNegative) {
    if (code == 0 || code == 1) {
      return 'Clear Night';
    }
    else if (code == 2 || code == 3) {
      return 'Cloudy Night';
    }
    return oMCodes[code] ?? 'Clear Sky';
  }
  else {
    return oMCodes[code] ?? 'Clear Sky';
  }
}

WeatherCurrent oMWeatherCurrentFromJson(item, WeatherSunStatus sunstatus, DateTime timenow, start, dayDif, isonline) {
  String currentCondition = oMCurrentTextCorrection(item["current"]["weather_code"], sunstatus, timenow);

  //offline mode
  if (!isonline) {
    currentCondition = oMCurrentTextCorrection(item["hourly"]["weather_code"][start], sunstatus, timenow);
  }

  return WeatherCurrent(
    condition: currentCondition,
    uv: item["daily"]["uv_index_max"][dayDif].round(),
    feelsLikeC: item["current"]["apparent_temperature"],
    precipMm: item["daily"]["precipitation_sum"][dayDif],
    windKph: item["hourly"]["wind_speed_10m"][start],
    humidity: item["current"]["relative_humidity_2m"],
    tempC: isonline ? item["current"]["temperature_2m"] : item["hourly"]["temperature_2m"][start],
    windDirA: item["hourly"]["wind_direction_10m"][start],
  );
}

WeatherDay oMWeatherDayFromJson(item, index, WeatherSunStatus sunStatus, approximateLocal, dayDif) {
  return WeatherDay(
    date: DateTime.parse(item["daily"]["time"][index]),
    condition: oMTextCorrection(item["daily"]["weather_code"][index]),
    minTempC: item["daily"]["temperature_2m_min"][index],
    maxTempC: item["daily"]["temperature_2m_max"][index],
    totalPrecipMm: item["daily"]["precipitation_sum"][index],
    precipProb: item["daily"]["precipitation_probability_max"][index] ?? 0,
    uv: item["daily"]["uv_index_max"][index].round(),
    windKph: item["daily"]["wind_speed_10m_max"][index],
    windDirA: item["daily"]["wind_direction_10m_dominant"][index] ?? 0,
    hourly: oMBuildWeatherHourList(index, item, sunStatus, approximateLocal),
  );
}

List<WeatherHour> oMBuildWeatherHourList(index, item, WeatherSunStatus sunStatus, approximateLocal) {
  List<WeatherHour> hourly = [];

  int l = item["hourly"]["weather_code"].length;

  for (var i = 0; i < 24; i++) {
    int j = index * 24 + i;
    DateTime hour = DateTime.parse(item["hourly"]["time"][j]);
    if (approximateLocal.difference(hour).inMinutes <= 0 && l > j) {
      hourly.add(oMWeatherHourFromJson(item, j, sunStatus));
    }
  }
  return hourly;
}

WeatherHour oMWeatherHourFromJson(item, index, WeatherSunStatus sunStatus) {
  DateTime time = DateTime.parse(item["hourly"]["time"][index]);
  String condition = oMCurrentTextCorrection(item["hourly"]["weather_code"][index], sunStatus, time);

  return WeatherHour(
    time: time,
    tempC: item["hourly"]["temperature_2m"][index],
    condition: condition,
    precipMm: item["hourly"]["precipitation"][index],
    precipProb: item["hourly"]["precipitation_probability"][index] ?? 0,
    windKph: item["hourly"]["wind_speed_10m"][index],
    windGustKph: item["hourly"]["wind_gusts_10m"][index],
    windDirA: item["hourly"]["wind_direction_10m"][index],
    uv: item["hourly"]["uv_index"][index].round(),
  );
}

WeatherRain15Minutes oMWeatherRain15MinutesFromJson(item, minuteOffset) {
  int closest = 100;
  int end = -1;
  double sum = 0;

  List<double> precips = [];

  int offset15 = minuteOffset ~/ 15;

  for (int i = offset15; i < item["minutely_15"]["precipitation"].length; i++) {
    double x = item["minutely_15"]["precipitation"][i];
    if (x > 0.0) {
      if (closest == 100) {
        closest = i;
      }
      if (i > end) {
        end = i;
      }
    }
    sum += x;

    precips.add(x);
  }

  //make it still be the same length so it doesn't mess up the labeling
  for (int i = 0; i < offset15; i++) {
    precips.add(0);
  }

  sum = max(sum, 0.1); //if there is rain then it shouldn't write 0

  String text = "";
  int time = 0;
  if (closest != 100) {
    if (closest <= 1) {
      if (end == 1) {
        text = "rainInHalfHour";
      }
      else if (end <= 2) {
        time = [15, 30, 45][end];
        text = "rainInMinutes";
      }
      else if (end ~/ 4 == 1) {
        text = "rainInOneHour";
      }
      else {
        time = (end + 2) ~/ 4;
        text = "rainInHours";
      }
    }
    else if (closest < 4) {
      time = [15, 30, 45][closest - 1];
      text = "rainExpectedInMinutes";
    }
    else if ((closest + 2) ~/ 4 == 1) {
      text = "rainExpectedInOneHour";
    }
    else {
      time = (closest + 2) ~/ 4;
      text = "rainExpectedInHours";
    }
  }

  return WeatherRain15Minutes(
    text: text,
    timeTo: time,
    precipSumMm: sum,
    precipListMm: precips,
  );
}

WeatherSunStatus oMWeatherSunStatusFromJson(item) {
  return WeatherSunStatus(
    sunrise: DateTime.parse(item["daily"]["sunrise"][0] + "Z"), //tell it to parse it to utc
    sunset: DateTime.parse(item["daily"]["sunset"][0] + "Z"),
    sunstatus: oMGetSunStatus(item)
  );
}

Future<WeatherAqi> oMGetWeatherAqi(lat, lon) async {
  final params = {
    "latitude": lat.toString(),
    "longitude": lon.toString(),
    "current": ["european_aqi"],
  };
  final url = Uri.https("air-quality-api.open-meteo.com", 'v1/air-quality', params);

  try {
    var file = await XCustomCacheManager.fetchData(url.toString(), "$lat, $lon, aqi open-meteo");
    var response = await file[0].readAsString();
    final item = jsonDecode(response)["current"];

    int index = aqiIndexCorrection(item["european_aqi"]);

    return WeatherAqi(
      aqiIndex: index,
    );
  } catch (e) {
    // If AQI cannot be fetched (no internet / cache), return a default empty AQI
    // so the rest of the UI can continue displaying weather data.
    if (kDebugMode) {
      print('AQI fetch failed: $e');
    }
    return WeatherAqi(aqiIndex: -1);
  }
}

List<WeatherMinMaxTemp> weatherGetMaxMinTempForDaily(List<WeatherDay> days) {
  return days.map((day) => WeatherMinMaxTemp(minTempC: day.minTempC, maxTempC: day.maxTempC)).toList();
}

Future<WeatherData> oMGetWeatherData(double lat, double lng, String place) async {
  var oM = await oMRequestData(lat, lng, place);
  var oMBody = oM[0];

  DateTime fetch_datetime = oM[1];
  bool isonline = oM[2];

  DateTime localtime = oMGetLocalTime(oMBody);

  DateTime lastKnowTime = DateTime.parse(oMBody["current"]["time"]);

  //get hour diff
  DateTime approximateLocal = DateTime(localtime.year, localtime.month, localtime.day, localtime.hour);
  int start = approximateLocal.difference(DateTime(lastKnowTime.year,
      lastKnowTime.month, lastKnowTime.day)).inHours;

  //get day diff
  int dayDif = DateTime(localtime.year, localtime.month, localtime.day).difference(
      DateTime(lastKnowTime.year, lastKnowTime.month, lastKnowTime.day)).inDays;

  //make sure that there is data left
  if (dayDif >= oMBody["daily"]["weather_code"].length) {
    throw const SocketException("Cached data expired");
  }

  WeatherSunStatus sunstatus = oMWeatherSunStatusFromJson(oMBody);

  List<WeatherDay> days = [];
  List<dynamic> hourly72 = [];

  for (int n = 0; n < oMBody["daily"]["weather_code"].length; n++) {
    WeatherDay day = oMWeatherDayFromJson(oMBody, n, sunstatus, approximateLocal, dayDif);
    days.add(day);
    if (hourly72.length < 72) {
      if (n != 0) {
        hourly72.add(day.date);
      }
      for (int z = 0; z < day.hourly.length; z++) {
        if (hourly72.length < 72) {
          hourly72.add(day.hourly[z]);
        }
      }
    }
  }

  return WeatherData(
    aqi: await oMGetWeatherAqi(lat, lng),
    sunStatus: sunstatus,
    minutely15Precip: oMWeatherRain15MinutesFromJson(oMBody,
        DateTime(localtime.year, localtime.month, localtime.day, localtime.hour, localtime.minute).
        difference(lastKnowTime).inMinutes),
    
    alerts: [],

    dailyMinMaxTemp: weatherGetMaxMinTempForDaily(days),

    hourly72: hourly72,

    current: oMWeatherCurrentFromJson(oMBody, sunstatus, localtime, start, dayDif, isonline),
    days: days,

    lat: lat,
    lng: lng,

    place: place,
    provider: "open-meteo",

    fetchDatetime: fetch_datetime,
    updatedTime: DateTime.now(),
    localTime: localtime,
    isOnline: isonline,
  );
}