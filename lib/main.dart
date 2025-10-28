import 'dart:async';

import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'data/services/preferences_service.dart';
import 'data/services/weather_provider.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PreferenceUtils.init();

  final data = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
  final ratio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  final commonProviders = [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => WeatherProvider()),
  ];

  if (data.shortestSide / ratio < 600) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
        .then((value) => runApp(
          MultiProvider(
            providers: commonProviders,
            child: const MyApp(),
          ),
        )
    );
  } else {
    runApp(
      MultiProvider(
        providers: commonProviders,
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = context.watch<ThemeProvider>().getThemeMode;
    final ColorScheme? lightColorScheme = context.watch<ThemeProvider>().getColorSchemeLight;
    final ColorScheme? darkColorScheme = context.watch<ThemeProvider>().getColorSchemeDark;

    final textScaleFactor = context.watch<SettingsProvider>().getTextScale;

    final EdgeInsets systemGestureInsets = MediaQuery.of(context).systemGestureInsets;
    if (systemGestureInsets.left > 0) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme dynamicLightColorScheme;
        ColorScheme dynamicDarkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          dynamicLightColorScheme = lightDynamic.harmonized();
          dynamicDarkColorScheme = darkDynamic.harmonized();
        } else {
          dynamicLightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light);
          dynamicDarkColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);
        }

        return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,

            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScaleFactor),
                ),
                child: child!,
              );
            },

            theme: ThemeData(
                colorScheme: lightColorScheme ?? dynamicLightColorScheme,
                useMaterial3: true,
                fontFamily: GoogleFonts.outfit().fontFamily,
                fontFamilyFallback: const ['NotoSans',],
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: FadeForwardsPageTransitionsBuilder()
                  }
                )
            ),
            darkTheme: ThemeData(
                colorScheme: darkColorScheme ?? dynamicDarkColorScheme,
                useMaterial3: true,
                fontFamily: GoogleFonts.outfit().fontFamily,
                fontFamilyFallback: const ['NotoSans',],
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: FadeForwardsPageTransitionsBuilder()
                  }
                )
            ),
            home: const HomeScreen()
        );
      },
    );
  }
}
