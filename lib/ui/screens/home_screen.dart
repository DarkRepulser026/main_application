import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stretchy_header/stretchy_header.dart';

import '../../data/models/weather_data.dart';
import '../../data/services/image_service.dart';
import '../../data/services/weather_provider.dart';
import '../../data/services/preferences_service.dart';
import '../../data/services/weather_service.dart';
import '../widgets/circles.dart';
import '../widgets/hourly_widget.dart';
import '../widgets/daily_widget.dart';
import '../widgets/fading_widget.dart';
import '../widgets/sun_status_widget.dart';
import '../widgets/aqi_widget.dart';
import '../widgets/search_widget.dart';
import '../widgets/rain_chart_widget.dart';
import '../widgets/alert_widget.dart';
import '../widgets/temp_and_condition_text_widget.dart';
import '../widgets/provider_selector_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: weatherProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : weatherProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weatherProvider.error!,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.read<WeatherProvider>().fetchWeather(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : weatherProvider.weatherData != null
                  ? _buildMainUI(weatherProvider.weatherData!, weatherProvider)
                  : const Center(child: Text('No weather data')),
    );
  }

  Widget _buildMainUI(WeatherData data, WeatherProvider weatherProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return PhoneLayout(data: data, updateLocation: (latLng, place) {
            context.read<WeatherProvider>().updateLocation(latLng, place);
            context.read<SettingsProvider>().setLocationAndLatLon(place, latLng);
          }, imageService: weatherProvider.imageService);
        }
        return TabletLayout(data: data, updateLocation: (latLng, place) {
          context.read<WeatherProvider>().updateLocation(latLng, place);
          context.read<SettingsProvider>().setLocationAndLatLon(place, latLng);
        }, imageService: weatherProvider.imageService);
      }
    );
  }
}

class PhoneLayout extends StatelessWidget {
  final WeatherData data;
  final Function updateLocation;
  final ImageService? imageService;

  const PhoneLayout({super.key, required this.data, required this.updateLocation, required this.imageService});

  @override
  Widget build(BuildContext context) {
    final FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    final Size size = (view.physicalSize) / view.devicePixelRatio;

    final Map<String, Widget> widgetsMap = {
      'sunstatus': SunStatusWidget(data: data, width: size.width,),
      'rain indicator': Rain15MinuteChart(data: data),
      'hourly': HourlyWidget(hours: data.hourly72, elevated: false,),
      'alerts' : AlertWidget(data: data),
      'daily': DailyWidget(data: data),
      'air quality': AqiWidget(data: data)
    };

    final List<String> order = context.select((SettingsProvider p) => p.getLayout);
    List<Widget> orderedWidgets = [];
    if (order.isNotEmpty && order[0] != "") {
      orderedWidgets = order.where((name) => widgetsMap.containsKey(name)).map((name) => widgetsMap[name]!).toList();
    }

    return Stack(
      children: [
        StretchyHeader.listView(
          displacement: 130,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await updateLocation("${data.lat}, ${data.lng}", data.place);
          },
          headerData: HeaderData(
            blurContent: false,
            headerHeight: (size.height ) * 0.495,
            header: FadingImageWidget(
              image: imageService?.image,
            ),
            overlay: Stack(
              children: [
                Padding(
                    padding: const EdgeInsets.only(left: 26, right: 26, bottom: 26),
                    child: TempAndConditionText(data: data, textRegionColor: imageService?.textRegionColor,)
                ),
                MySearchWidget(place: data.place, updateLocation: updateLocation, isTabletMode: false,),
              ],
            )
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Circles(data: data),
            ),

            Column(
              children: orderedWidgets.map((widget) {
                return widget;
              }).toList(),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: FadingWidget(data: data, time: data.updatedTime, imageService: imageService, key: Key(data.updatedTime.toString())),
          ),
        ),
      ],
    );
  }
}

class TabletLayout extends StatelessWidget {
  final WeatherData data;
  final Function updateLocation;
  final ImageService? imageService;

  const TabletLayout({super.key, required this.data, required this.updateLocation, required this.imageService});

  @override
  Widget build(BuildContext context) {

    final currentSize = MediaQuery.of(context).size;
    final currentWidth = currentSize.width;
    final currentHeight = currentSize.height;
    final showPanel = currentWidth > 1000;

    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (showPanel) SizedBox(
              width: currentWidth * 0.3,
              child: MySearchWidget(place: data.place, updateLocation: updateLocation, isTabletMode: true)
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return StretchyHeader.listView(
                    displacement: 130,
                    onRefresh: () async {
                      await updateLocation(
                          "${data.lat}, ${data.lng}", data.place);
                    },
                    headerData: HeaderData(
                        blurContent: false,
                        headerHeight: min(currentHeight * 0.49, 500),
                        header: FadingImageWidget(
                          image: imageService?.image,
                        ),
                        overlay: !showPanel
                            ? MySearchWidget(place: data.place, updateLocation: updateLocation, isTabletMode: false,)
                            : Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.inverseSurface,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                margin: const EdgeInsets.only(left: 25, top: 25),
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.place_outlined, color: Theme.of(context).colorScheme.onInverseSurface, size: 22,),
                                    const SizedBox(width: 4,),
                                    Text(data.place, style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 22),)
                                  ],
                                ),
                              ),
                            ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Column(
                          children: [
                            Align(
                                alignment: Alignment.centerRight,
                                child: FadingWidget(data: data, time: data.updatedTime, imageService: imageService, key: Key(data.updatedTime.toString())),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 7, left: 30),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SmoothTempTransition(target: unitConversion(data.current.tempC,
                                            context.select((SettingsProvider p) => p.getTempUnit), decimals: 1) * 1.0,
                                          color: Theme.of(context).colorScheme.tertiary, fontSize: 68,),
                                        Text(
                                          data.current.condition,
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontSize: 30, height: 1.05
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                      width: 397,
                                      child: Circles(data : data)
                                  ),
                                ],
                              ),
                            ),

                            SunStatusWidget(data: data, width: constraints.maxWidth,),
                            HourlyWidget(hours: data.hourly72, elevated: false,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Rain15MinuteChart(data: data),
                                      AqiWidget(data: data),
                                      ProviderSelector(updateLocation: updateLocation, loc: data.place, latLon: "${data.lat}, ${data.lng}",),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      AlertWidget(data: data),
                                      DailyWidget(data: data),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  );
                }
              ),
            ),
          ],
        )
    );
  }
}