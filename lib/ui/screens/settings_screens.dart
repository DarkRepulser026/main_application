import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../data/services/color_service.dart';
import '../../data/services/preferences_service.dart';
import 'settings_page.dart';
import 'package:provider/provider.dart';


class MainSettingEntry extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Widget? pushTo;

  const MainSettingEntry({super.key, required this.title, required this.desc, required this.icon, this.pushTo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, top: 5, bottom: 5),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          HapticFeedback.selectionClick();
          if (pushTo != null) {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => pushTo!)
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 13, bottom: 13),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              circleBorderIcon(icon, context),
              const SizedBox(width: 20,),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 21, height: 1.2),),
                    Text(desc, style: TextStyle(color: Theme.of(context).colorScheme.outline,
                        fontSize: 15, height: 1.2),)
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {

    String colorSource = context.select((ThemeProvider p) => p.getColorSource);
    String customColorHex = context.select((ThemeProvider p) => p.getThemeSeedColorHex);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                }),
            title: Text('Appearance',
              style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 80.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 1, bottom: 14, top: 30),
                        child: Text("app theme", style: TextStyle(fontSize: 17),)
                      ),

                      SegmentedButton(
                        selected: <String>{context.watch<ThemeProvider>().getBrightness},
                        onSelectionChanged: (Set<String> newSelection) {
                          HapticFeedback.mediumImpact();
                          context.read<ThemeProvider>().setBrightness(newSelection.first);
                        },
                        segments: const [
                          ButtonSegment(
                            icon: Icon(Icons.light_mode_outlined),
                            value: "light",
                            label: Text("light", style: TextStyle(fontSize: 18),),
                          ),
                          ButtonSegment(
                            icon: Icon(Icons.dark_mode_outlined),
                            value: "dark",
                            label: Text("dark", style: TextStyle(fontSize: 18),),
                          ),
                          ButtonSegment(
                            icon: Icon(Icons.brightness_6_outlined),
                            value: "auto",
                            label: Text("auto", style: TextStyle(fontSize: 18),),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      SettingsEntry(
                        icon: Icons.download_for_offline_outlined,
                        text: 'Image source',
                        rawText: 'Image source',
                        selected: context.select((SettingsProvider p) => p.getImageSource),
                        update: context.read<SettingsProvider>().setImageSource,
                      ),

                      SettingsEntry(
                        icon: Icons.colorize,
                        text: 'Color source',
                        rawText: 'Color source',
                        selected: colorSource,
                        update: context.read<ThemeProvider>().setColorSource,
                      ),

                      const SizedBox(height: 30,),

                      if (colorSource == "custom") SizedBox(
                        height: 65,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: settingSwitches["Custom color"]!.length,
                          itemBuilder: (BuildContext context, int index) {
                            String name = settingSwitches["Custom color"]![index];
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                context.read<ThemeProvider>().setCustomColorScheme(name);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Color(getColorFromHex(name)),
                                            borderRadius: BorderRadius.circular(33)
                                        ),
                                      ),
                                      if (customColorHex == name) const Center(
                                          child: Icon(Icons.check, color: Colors.white,))
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 70,),
                    ],
                  )
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }

}

class UnitsPage extends StatelessWidget {
  const UnitsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                }),
            title: Text('Units',
              style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 80.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                    children: [

                      SettingsEntry(
                          icon: Icons.ac_unit,
                          text: 'Temperature',
                          rawText: 'Temperature',
                          selected: context.select((SettingsProvider p) => p.getTempUnit),
                          update: context.read<SettingsProvider>().setTempUnit,
                      ),
                      SettingsEntry(
                        icon: Icons.water_drop_outlined,
                        text: 'Precipitation',
                        rawText: 'Precipitation',
                        selected: context.select((SettingsProvider p) => p.getPrecipUnit),
                        update: context.read<SettingsProvider>().setPrecipUnit,
                      ),
                      SettingsEntry(
                        icon: Icons.air,
                        text: 'Wind',
                        rawText: 'Wind',
                        selected: context.select((SettingsProvider p) => p.getWindUnit),
                        update: context.read<SettingsProvider>().setWindUnit,
                      ),
                    ],
                  )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[

          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              }),
            title: Text('General',
              style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 80.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                    children: [

                      SettingsEntry(
                        icon: Icons.access_time_outlined,
                        text: 'Time mode',
                        rawText: 'Time mode',
                        selected: context.select((SettingsProvider p) => p.getTimeMode),
                        update: context.read<SettingsProvider>().setTimeMode,
                      ),

                      SettingsEntry(
                        icon: Icons.date_range,
                        text: 'Date format',
                        rawText: 'Date format',
                        selected: context.select((SettingsProvider p) => p.getDateFormat),
                        update: context.read<SettingsProvider>().setDateFormat,
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 14),
                        child: Row(
                          children: [
                            circleBorderIcon(Icons.format_size_rounded, context),
                            const SizedBox(width: 20,),
                            Expanded(child: Text('Font size',
                              style: const TextStyle(fontSize: 20, height: 1.2),),),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 19,
                                thumbColor: Theme.of(context).colorScheme.secondary,
                                activeTrackColor: Theme.of(context).colorScheme.secondary,

                                year2023: false,
                              ),
                              child: Slider(
                                min: 0.7,
                                max: 1.3,
                                divisions: 10,
                                value: context.select((SettingsProvider p) => p.getTextScale),
                                  onChanged: (double value) {
                                    context.read<SettingsProvider>().setTextScale(value);
                                  }
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LayoutPage extends StatelessWidget {
  const LayoutPage({super.key});

  //also the default order
  static const allNames = ["sunstatus", "rain indicator", "hourly", "alerts", "daily", "air quality"];

  @override
  Widget build(BuildContext context) {

    List<String> _items = context.watch<SettingsProvider>().getLayout;

    List<String> removed = [];
    for (int i = 0; i < allNames.length; i++) {
      if (!_items.contains(allNames[i])) {
        removed.add(allNames[i]);
      }
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: Icon(Icons.restore, color: Theme.of(context).colorScheme.primary, size: 26,),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    context.read<SettingsProvider>().setLayoutOrder(allNames);
                  },
                ),
              ),
            ],
            title: Text('Layout', style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableListView(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  proxyDecorator: (child, index, animation) => Material(
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  ),
                  padding: const EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 50),
                  children: <Widget>[
                    for (int index = 0; index < _items.length; index += 1)
                      Container(
                        key: Key(_items[index]),
                        color: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(33),
                          ),
                          height: 67,
                          padding: const EdgeInsets.only(top: 6, bottom: 6, left: 20, right: 10),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(Icons.drag_indicator, color: Theme.of(context).colorScheme.outline,),
                              ),
                              Expanded(
                                child: Text(_items[index], style: const TextStyle(fontSize: 19),),
                              ),
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.heavyImpact();
                                  final List<String> newOrder = List.from(_items);
                                  newOrder.removeAt(index);
                                  context.read<SettingsProvider>().setLayoutOrder(newOrder);
                                },
                                icon: Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: Theme.of(context).colorScheme.tertiary, size: 23,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                  onReorder: (int oldIndex, int newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final List<String> newOrder = List.from(_items);
                    final String item = newOrder.removeAt(oldIndex);
                    newOrder.insert(newIndex, item);
                    context.read<SettingsProvider>().setLayoutOrder(newOrder);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top:0, left: 20, right: 20),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(removed.length, (i) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          final List<String> newOrder = List.from(_items);
                          newOrder.add(removed[i]);
                          context.read<SettingsProvider>().setLayoutOrder(newOrder);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(width: 2, color: Theme.of(context).colorScheme.outlineVariant)
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.primary, size: 22,),
                              Padding(
                                padding: const EdgeInsets.only(left: 3, right: 3),
                                child: Text(removed[i], style: const TextStyle(fontSize: 17),),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            title: Text('About', style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather App',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Version: 1.0.0',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'DarkRepulser026',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}