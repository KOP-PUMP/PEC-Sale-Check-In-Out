// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kop_checkin/agendaJson.dart';
import 'package:kop_checkin/calendar.dart';
import 'package:kop_checkin/checkinscreen.dart';
import 'package:kop_checkin/model/user.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class HomeScreeen extends StatefulWidget {
  const HomeScreeen({super.key});

  @override
  State<HomeScreeen> createState() => _HomeScreeenState();
}

class _HomeScreeenState extends State<HomeScreeen> {
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color.fromRGBO(12, 45, 92, 1);
  int currentIndex = 1;

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static bool _containsAny(String value, List<String> patterns) {
    for (final p in patterns) {
      if (value.contains(p)) return true;
    }
    return false;
  }

  void _showUpdateDialog(String storeVersion) {
    showDialog(
      context: context,
      barrierDismissible: false, // force update (cannot tap outside to close)
      builder: (_) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'A newer version ($storeVersion) of this app is available in the App Store. '
              'Please update to continue using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Use the App Store URL scheme to open the App Store app directly
              final url = Uri.parse('itms-apps://itunes.apple.com/app/6478572636');  // Open the App Store app directly

              // Check if the device can open the App Store URL scheme
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                // Fallback to opening the web App Store if App Store app is not available (though it's rare)
                final fallbackUrl = Uri.parse('https://apps.apple.com/us/app/pec-check-in/id6478572636');
                await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showVPNBlockDialog(String data) {
    showDialog(
      context: context,
      barrierDismissible: false, // force update (cannot tap outside to close)
      builder: (_) => AlertDialog(
        title: const Text('VPN Usage Detected'),
        //content: Text(
          //'VPN usage within this application is prohibited. Please turn off VPN and re-open this app in order to continue using. ',
        //),
        content: Text(data),
      ),
    );
  }

  /// Optional: dialog if you want to block emulator use
  void _showBlockedDialog(String deviceType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Unsupported Device'),
        content: Text(
          'This app cannot be used on $deviceType device. '
              'Please run it on a physical device or contact person in charge.',
        ),
      ),
    );
  }

  static Future<String?> getAppStoreVersion() async {
    final url = Uri.parse(
        "https://itunes.apple.com/lookup?id=6478572636");

    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body);

    if (json["resultCount"] == 0) return null;

    return json["results"][0]["version"];
  }

  static Future<String> getInstalledVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version; // e.g. "1.0.3"
  }

  static bool isLowerVersion(String current, String store) {
    final currentParts =
    current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final storeParts =
    store.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final a = currentParts.length > i ? currentParts[i] : 0;
      final b = storeParts.length > i ? storeParts[i] : 0;

      if (a < b) return true;
      if (a > b) return false;
    }

    return false;
  }

  Future<void> checkDevice() async {

    final List<String> reasons = [];
    bool isIOS = false;
    bool isEmu = false;
    String device_name = "";
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;

        // 1. Direct flag
        if (!info.isPhysicalDevice) {
          reasons.add('isPhysicalDevice is false');
        }

        final brand = info.brand.toLowerCase();
        final device = info.device.toLowerCase();
        final model = info.model.toLowerCase();
        final product = info.product.toLowerCase();
        final hardware = (info.hardware ?? '').toLowerCase();
        final fingerprint = info.fingerprint.toLowerCase();
        final manufacturer = info.manufacturer.toLowerCase();

        // 2. Common emulator brand/manufacturer
        if (brand.contains('generic') || brand.contains('unknown')) {
          reasons.add('brand is generic/unknown: $brand');
        }

        if (manufacturer.contains('genymotion') ||
            manufacturer.contains('unknown')) {
          reasons.add('manufacturer suspicious: $manufacturer');
        }

        // 3. Model / product / device hints
        final emulatorKeywords = [
          'google_sdk',
          'sdk_gphone',
          'sdk',
          'emulator',
          'android sdk built for x86',
          'x86',
          'vbox',
          'virtualbox',
        ];

        if (_containsAny(model, emulatorKeywords)) {
          reasons.add('model looks like emulator: ${info.model}');
        }
        if (_containsAny(device, emulatorKeywords)) {
          reasons.add('device looks like emulator: ${info.device}');
        }
        if (_containsAny(product, emulatorKeywords)) {
          reasons.add('product looks like emulator: ${info.product}');
        }

        // 4. Hardware / fingerprint hints
        final hardwareKeywords = [
          'goldfish', // classic Android emulator kernel
          'ranchu',
          'qcom', // not always emu, but sometimes interesting
          'vbox',
        ];
        if (_containsAny(hardware, hardwareKeywords)) {
          reasons.add('hardware indicates emulator: ${info.hardware}');
        }

        if (fingerprint.startsWith('generic') ||
            fingerprint.contains('test-keys')) {
          reasons.add('fingerprint suspicious: ${info.fingerprint}');
        }

        if(reasons.isNotEmpty) {
          // print({"Device" : "Android Simulator", "reason":"$reasons"});
          isEmu = true;
          device_name = "Android Emulator";
        } else {
          // print({"Device" : "Android", "reason":"$reasons"});
          device_name = "Android";
        }
      } else if (Platform.isIOS) {
        final info = await _deviceInfoPlugin.iosInfo;

        if (!info.isPhysicalDevice) {
          reasons.add('isPhysicalDevice is false (iOS simulator)');
        }

        // iOS simulators often have these machine names
        final machine = info.utsname.machine.toLowerCase();
        if (machine.contains('x86_64') || machine.contains('arm64')) {
          reasons.add('utsname.machine looks like simulator: ${info.utsname.machine}');
        }

        isIOS = true;

        if(reasons.isNotEmpty) {
          // print({"Device" : "IOS Simulator", "reason":"$reasons"});
          isEmu = true;
          device_name = "IOS Emulator";
        } else {
          // print({"Device" : "IOS", "reason":"$reasons"});
          device_name = "IOS";
        }
      } else {
        // Other platforms (web, desktop)
        reasons.add('non-mobile platform: ${Platform.operatingSystem}');
        // print({"Device": "Other", "reason": "$reasons"});
        device_name = "Other";
      }
    } catch (e) {
      // On error, you decide: treat as suspicious or ignore
      reasons.add('error while checking: $e');
      // print({"Error": "Error while checking for device", "reason" : "$reasons"});
      device_name = "Error";
    } finally {
      try{
        // if(isEmu || device_name.contains("Emu") || device_name.contains("Other") || device_name.contains("Error") ){
        //   _showBlockedDialog(device_name);
        // }else{
        //   final installed = await getInstalledVersion();
        //   final store = await getAppStoreVersion();
        //   debugPrint('Installed version: $installed, Store version: $store');
        //   if (store != installed) {
        //     // Version mismatch — prompt to update
        //     _showUpdateDialog(store.toString());
        //   }
        // }
        if (Platform.isIOS) {
          final installed = await getInstalledVersion();
          final store = await getAppStoreVersion();
          debugPrint('Installed version: $installed, Store version: $store');

          // Compare two version numbers
          bool compareVersion(String version1, String version2) {
            // Split versions into parts (major, minor, patch)
            List<int> v1Parts = version1.split('.').map((e) => int.parse(e)).toList();
            List<int> v2Parts = version2.split('.').map((e) => int.parse(e)).toList();

            // Compare each part of the version (major, minor, patch)
            for (int i = 0; i < 3; i++) {
              final v1 = i < v1Parts.length ? v1Parts[i] : 0;
              final v2 = i < v2Parts.length ? v2Parts[i] : 0;

              if (v1 < v2) return true;  // Version 1 is smaller
              if (v1 > v2) return false; // Version 1 is larger
            }

            return false; // Versions are equal
          }

          Future<bool> checkVPNActive() async {
            try {
              List<NetworkInterface> interfaces = await NetworkInterface.list(
                includeLoopback: false,
                type: InternetAddressType.any,
              );
              print(interfaces);
              bool isVPNActive = interfaces.any((interface)=>interface.name.contains("tun") ||
                  interface.name.contains("ppp") ||
                  interface.name.contains("pptp") ||
                  interface.name.contains("utun"));

              _showVPNBlockDialog(interfaces.toString());
              if (isVPNActive){
                return true;
              } else {
                return false;
              }
            }catch (e) {
              return false;
            }
          }

          bool isUpdateAvailable = compareVersion(installed, store.toString());
          //checkVPNActive();

          if (isUpdateAvailable) {
            // Version mismatch — prompt to update
            _showUpdateDialog(store.toString());
          }
        }
      }catch(e){
        debugPrint('Version check error : $e');
      }
    }
  }



  final GlobalKey<CalendarExampleState> calendarKey =
      GlobalKey<CalendarExampleState>(); // Key for CalendarExample
  final GlobalKey<CalendarScreenState> calendarScreenKey =
      GlobalKey<CalendarScreenState>();

  Timer? _inactivityTimer; // Timer for tracking inactivity

  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarDay,
    FontAwesomeIcons.check,
    FontAwesomeIcons.calendarXmark,
  ];

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer();
    checkDevice();
    // Start inactivity timer on app load
  }

  // Change the page and reset inactivity timer
void changePage(int newIndex) {
  setState(() {
    currentIndex = newIndex;
  });

  // Fetch data if the CalendarXmark icon is selected
  if (newIndex == 2) {
    // print("CalendarXmark button pressed. Attempting to fetch data...");
    calendarKey.currentState?.fetchData(); // Call fetchData from Agenda Pages
  }
  if (newIndex == 0) {
    // print("CalendarXmark button pressed. Attempting to fetch data...");
    calendarScreenKey.currentState?.getRowCheckin(); // Call fetchData from Agenda Pages
  }
    // Reset inactivity timer on page change
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel(); // Cancel the existing timer
    
    // Start a new inactivity timer that stops fetching after 10 seconds of inactivity
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      // print("No interaction detected. Stopping fetching...");
      calendarKey.currentState?.stopFetching(); // Stop fetching on inactivity
    });
  }

  // Track interaction for resetting the timer on any interaction in the app
  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _resetInactivityTimer, // Reset inactivity timer on any tap
      onPanDown: (details) => _resetInactivityTimer(), // Reset on any gesture
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: [
            CalendarScreen(key: calendarScreenKey),
            CheckinScreen(() {
              _getCurrentLocation().then((value) {
                debugPrint("Start checkin");
                setState(() {
                  Users.lat = value.latitude;
                  Users.long = value.longitude;
                });
              }
              );
              if (kDebugMode) {
                print('${Users.lat} ${Users.long}');
              }
            }),
            CalendarExample(key: calendarKey), // Pass the key here
          ],
        ),
        bottomNavigationBar: Container(
          height: 70,
          margin: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(40)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 2))
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(40)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < navigationIcons.length; i++) ...<Expanded>{
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        changePage(i);
                      },
                      child: Container(
                        height: screenHeight,
                        width: screenWidth,
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                navigationIcons[i],
                                color: i == currentIndex ? primary : Colors.black54,
                                size: i == currentIndex ? 30 : 26,
                              ),
                              i == currentIndex
                                  ? Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      height: 3,
                                      width: 22,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.all(Radius.circular(40)),
                                        color: primary,
                                      ),
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                }
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to get user's current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permission denied forever.');
    }

    return Geolocator.getCurrentPosition();
  }
}
