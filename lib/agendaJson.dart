// ignore_for_file: file_names, non_constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
/*import 'package:kop_checkin/addcustomer.dart';*/
import 'package:kop_checkin/api/api.dart';
import 'package:kop_checkin/login.dart';
import 'package:kop_checkin/model/user.dart';
/*import 'package:kop_checkin/planner.dart';*/
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class CalendarExample extends StatefulWidget {
  const CalendarExample({super.key});

  @override
  CalendarExampleState createState() => CalendarExampleState();
}

class CalendarExampleState extends State<CalendarExample> {
  final List<Color> _colorCollection = <Color>[];
  String? _networkStatusMsg;
  final Connectivity _internetConnectivity = Connectivity();
  String _currentMonth = DateFormat('MM').format(DateTime.now());
  String _currentYear = DateFormat('yyyy').format(DateTime.now());
  String _day = DateFormat('dd MMMM yyyy').format(DateTime.now());
  String? _lastFetchedTimestamp;
  Timer? _agendaTimer;
  Timer? _inactivityTimer;
  final List<dynamic> _agendaList = [];

  @override
  void initState() {
    super.initState();
    _initializeEventColor();
    _checkNetworkStatus();
    _fetchAgendaData(_currentYear, _currentMonth);
    _startAgendaTimer(); // Start the agenda timer
    _startInactivityTimer(); // Start inactivity timer
  }

  void _fetchAgendaData(String year, String month,
      {bool forceFetch = false}) async {
    // Prepare request body with user ID, year, month, and optionally last fetched timestamp
    var body = {
      'user_code': Users.id,
      'year': year,
      'month': month,
      if (_lastFetchedTimestamp != null)
        'lastFetchedTimestamp': _lastFetchedTimestamp
    };

    try {
      // Make the API request
      var res = await http.post(Uri.parse(API.getAgenda), body: body);

      // Parse the response
      var responseBody = jsonDecode(res.body);

      // Check if the response is a map (error) or a list (valid agenda data)
      if (responseBody is Map<String, dynamic>) {
        // Handle error response (e.g., { "success": false })
        if (responseBody.containsKey('success') &&
            responseBody['success'] == false) {
          if (kDebugMode) {
            print("No new agenda data to fetch.");
          }
        } else {
          // print("Unexpected map response: $responseBody");
        }
      } else if (responseBody is List) {
        // Valid agenda list, append new records
        setState(() {
          _agendaList.addAll(responseBody);

          // Update the last fetched timestamp with the timestamp of the latest record
          _lastFetchedTimestamp = responseBody.last['timestamp'];

        });
      } else {
        // print("Unexpected response format: $responseBody");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching agenda: $e");
      }
    }
  }

  // Method to fetch agenda data externally
  void fetchData() {
    _fetchAgendaData(_currentYear, _currentMonth,
        forceFetch: true); // Force fetching on button press
  }

  void stopFetching() {
    // print("Stopping fetching in CalendarExample");
    _stopAgendaTimer(); // Stop the timer
  }

  void _startAgendaTimer() {
    if (_agendaTimer == null || !_agendaTimer!.isActive) {
      // print("Starting agenda timer...");
      _agendaTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
        // print("Timer fetching agenda data...");
        _fetchAgendaData(_currentYear, _currentMonth);
      });
    }
  }

  void _stopAgendaTimer() {
    if (_agendaTimer != null) {
      // print("Stopping agenda timer...");
      _agendaTimer?.cancel();
    }
  }

  // Start or restart the inactivity timer
  void _startInactivityTimer() {
    // print("Starting inactivity timer...");
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      // print("No interaction detected. Stopping agenda timer...");
      _stopAgendaTimer(); // Stop fetching when inactive
    });
  }

  // Reset inactivity timer on interaction
  void _resetInactivityTimer() {
    // print("Interaction detected. Resetting inactivity timer...");
    _startInactivityTimer();
    // Ensure fetching is running if there was interaction
    if (_agendaTimer == null || !_agendaTimer!.isActive) {
      _startAgendaTimer();
    }
  }

  // Use onViewChanged to detect month and year changes
  void _onViewChanged(ViewChangedDetails viewChangedDetails) {
    DateTime middleVisibleDate = viewChangedDetails
        .visibleDates[(viewChangedDetails.visibleDates.length / 2).floor()];
    String month = middleVisibleDate.month.toString().padLeft(2, '0');
    String year = DateFormat('yyyy').format(middleVisibleDate);

    if (month != _currentMonth || year != _currentYear) {
      _currentMonth = month;
      _currentYear = year;
      _fetchAgendaData(
          _currentYear, _currentMonth); // Fetch only if new month/year
    }
  }

  @override
  void dispose() {
    // Cancel both timers when the widget is disposed
    _agendaTimer?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  Future getAgendar(String year, String month) async {
    var res = await http.post(Uri.parse(API.getAgenda), body: {
      'user_code': Users.id,
      'year': year, // Send year as parameter
      'month': month // Send month as parameter
    });
    // print("Status code: ${res.statusCode}");
    // print("Response body: ${res.body}");

    try {
      return jsonDecode(res.body);
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching agenda: $e");
      }
      return null;
    }
  }

  void selectionChanged(CalendarSelectionDetails calendarSelectionDetails) {
    getSelectedDateAppointments(calendarSelectionDetails.date);
  }

  void getSelectedDateAppointments(DateTime? selectedDate) {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      setState(() {
        _day = DateFormat('dd MMMM yyyy').format(selectedDate!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetInactivityTimer, // Reset timer on interaction
      onPanDown: (details) => _resetInactivityTimer(), // Reset on any gesture
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SfCalendar(
                  view: CalendarView.month,
                  dataSource: MeetingDataSource(_agendaList.map((data) {
                    return Meeting(
                      eventName: data['customer'],
                      from: _convertDateFromString(data['timestamp']),
                      to: _convertDateFromString(data['timestamp']),
                      all_day: true,
                    );
                  }).toList()),
                  onViewChanged: _onViewChanged,
                  initialSelectedDate: DateTime.now(),
                  onSelectionChanged: selectionChanged,
                ),
              ),
              Expanded(
                child: _agendaList.isNotEmpty
                    ? ListView.builder(
                        itemCount: _agendaList.length,
                        itemBuilder: (context, index) {
                          if (_agendaList[index]['docdate'] == _day) {
                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(0),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  height: 60,
                                  color: Colors.blue,
                                  child: ListTile(
                                    leading: Column(
                                      children: <Widget>[
                                        const SizedBox(height: 10),
                                        Text(
                                          _agendaList[index]['location_index'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              height: 1.5),
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      _agendaList[index]['customer']
                                                  ?.isNotEmpty ==
                                              true
                                          ? _agendaList[index]['customer']
                                          : _agendaList[index]['remark'],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              Container(
                margin: const EdgeInsets.all(20),
                child:   SizedBox(
                    width: double.infinity, // Full width of the screen
                    child: MaterialButton(
                      onPressed: () async {
                        SharedPreferences preferences =
                        await SharedPreferences.getInstance();
                        await preferences.clear();
                        Navigator.push(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (context) => const KeyboardVisibilityProvider(
                              child: LoginScreen(),
                            ),
                          ),
                        );
                      },
                      color: Colors.red,
                      textColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder( // make it rectangle with small radius
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout,
                        size: 40,
                      ),
                    ),
                  )
                // child: Row(
                //   mainAxisAlignment: MainAxisAlignment.end,
                //   children: [
                //     /*Material(
                //       color: Colors.white,
                //       child: Center(
                //         child: Ink(
                //           height: 75,
                //           width: 75,
                //           decoration: const ShapeDecoration(
                //             color: Colors.green,
                //             shape: CircleBorder(),
                //           ),
                //           child: IconButton(
                //             icon: const Icon(
                //               FontAwesomeIcons.personCirclePlus,
                //               size: 30,
                //             ),
                //             color: Colors.white,
                //             onPressed: () {
                //               Navigator.push(
                //                 context,
                //                 MaterialPageRoute(
                //                   builder: (context) => const AddCustomer(),
                //                 ),
                //               );
                //             },
                //           ),
                //         ),
                //       ),
                //     ),*/
                //     /*Material(
                //       color: Colors.white,
                //       child: Center(
                //         child: Ink(
                //           height: 75,
                //           width: 75,
                //           decoration: const ShapeDecoration(
                //             color: Colors.lightBlue,
                //             shape: CircleBorder(),
                //           ),
                //           child: IconButton(
                //             icon: const Icon(
                //               FontAwesomeIcons.fileSignature,
                //               size: 30,
                //             ),
                //             color: Colors.white,
                //             onPressed: () {
                //               Navigator.push(
                //                 context,
                //                 MaterialPageRoute(
                //                   builder: (context) => const Planner(),
                //                 ),
                //               );
                //             },
                //           ),
                //         ),
                //       ),
                //     ),*/
                //     MaterialButton(
                //       onPressed: () async {
                //         SharedPreferences preferences =
                //             await SharedPreferences.getInstance();
                //         await preferences.clear();
                //         Navigator.push(
                //           // ignore: use_build_context_synchronously
                //           context,
                //           MaterialPageRoute(
                //             builder: (context) =>
                //                 const KeyboardVisibilityProvider(
                //               child: LoginScreen(),
                //             ),
                //           ),
                //         );
                //       },
                //       color: Colors.red,
                //       textColor: Colors.white,
                //       padding: const EdgeInsets.all(16),
                //       shape: const CircleBorder(),
                //       child: const Icon(
                //         Icons.logout,
                //         size: 40,
                //       ),
                //     ),
                //   ],
                // ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _convertDateFromString(String date) {
    return DateTime.parse(date);
  }

  void _initializeEventColor() {
    _colorCollection.add(const Color(0xFF0F8644));
    _colorCollection.add(const Color(0xFF8B1FA9));
    _colorCollection.add(const Color(0xFFD20100));
    _colorCollection.add(const Color(0xFFFC571D));
    _colorCollection.add(const Color(0xFF36B37B));
    _colorCollection.add(const Color(0xFF01A1EF));
    _colorCollection.add(const Color(0xFF3D4FB5));
    _colorCollection.add(const Color(0xFFE47C73));
    _colorCollection.add(const Color(0xFF636363));
    _colorCollection.add(const Color(0xFF0A8043));
  }

  void _checkNetworkStatus() {
  _internetConnectivity.onConnectivityChanged
      .listen((List<ConnectivityResult> results) {
    setState(() {
      if (results.contains(ConnectivityResult.mobile)) {
        _networkStatusMsg =
            "You are connected to mobile network, loading calendar data ....";
      } else if (results.contains(ConnectivityResult.wifi)) {
        _networkStatusMsg =
            "You are connected to wifi network, loading calendar data ....";
      } else {
        _networkStatusMsg =
            "Internet connection may not be available. Connect to another network";
      }
    });
  });
}

}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  bool isAll_day(int index) {
    return appointments![index].all_day;
  }
}

class Meeting {
  Meeting({this.eventName, this.from, this.to, this.all_day = true});

  String? eventName;
  DateTime? from;
  DateTime? to;
  bool? all_day;
}
