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

  final GlobalKey<CalendarExampleState> calendarKey =
      GlobalKey<CalendarExampleState>(); // Key for CalendarExample

  Timer? _inactivityTimer; // Timer for tracking inactivity

  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarDay,
    FontAwesomeIcons.check,
    FontAwesomeIcons.calendarXmark,
  ];

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer(); // Start inactivity timer on app load
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
            CalendarScreen(),
            CheckinScreen(() {
              _getCurrentLocation().then((value) {
                setState(() {
                  Users.lat = value.latitude;
                  Users.long = value.longitude;
                });
              });
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
