import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kop_checkin/addcustomer.dart';
import 'package:kop_checkin/api/api.dart';
import 'package:kop_checkin/login.dart';
import 'package:kop_checkin/model/user.dart';
import 'package:kop_checkin/planner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:connectivity/connectivity.dart';

class CalendarExample extends StatefulWidget {
  const CalendarExample({super.key});

  @override
  State<CalendarExample> createState() => _CalendarExampleState();
}

class _CalendarExampleState extends State<CalendarExample> {
  final List<Color> _colorCollection = <Color>[];
  String? _networkStatusMsg;
  final Connectivity _internetConnectivity = Connectivity();
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color.fromRGBO(12, 45, 92, 1);
  late List<Meeting> dataSource;
  String _day = DateFormat('yyyy').format(DateTime.now());
  Future getAgendar() async {
    var res = await http.post(Uri.parse(API.getAgenda), body: {
      'user_code': Users.id,
      'year': DateFormat('yyyy').format(DateTime.now())
    });
    try {
      return jsonDecode(res.body);
      // ignore: empty_catches
    } catch (e) {}
  }

  @override
  void initState() {
    _initializeEventColor();
    _checkNetworkStatus();

    super.initState();
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
    return Scaffold(
      body: FutureBuilder(
        future: getDataFromWeb(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data != null) {
            return SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: SfCalendar(
                      view: CalendarView.month,
                      dataSource: MeetingDataSource(snapshot.data),
                      initialSelectedDate: DateTime.now(),
                      onSelectionChanged: selectionChanged,
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder(
                        future: getAgendar(),
                        builder: (context, snapshot) {
                          return snapshot.hasData
                              ? ListView.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    List list = snapshot.data;
                                    if (list[index]['docdate'] == _day) {
                                      return Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(0),
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            height: 60,
                                            color: Colors.blue,
                                            child: ListTile(
                                              leading: Column(
                                                children: <Widget>[
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(
                                                    list[index]
                                                        ['location_index'],
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                        height: 1.5),
                                                  ),
                                                ],
                                              ),
                                              title: Text(
                                                list[index]['customer']
                                                            ?.isNotEmpty ==
                                                        true
                                                    ? list[index]['customer']
                                                    : list[index]['remark'],
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
                                  })
                              : const Center(
                                  child: CircularProgressIndicator(),
                                );
                        }),
                  ),
                  Container(
                      alignment: Alignment.centerRight,
                      margin: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Material(
                            color: Colors.white,
                            child: Center(
                              child: Ink(
                                height: 75,
                                width: 75,
                                decoration: const ShapeDecoration(
                                  color: Colors.green,
                                  shape: CircleBorder(),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    FontAwesomeIcons.personCirclePlus,
                                    size: 30,
                                  ),
                                  color: Colors.white,
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const AddCustomer()));
                                  },
                                ),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.white,
                            child: Center(
                              child: Ink(
                                height: 75,
                                width: 75,
                                decoration: const ShapeDecoration(
                                  color: Colors.lightBlue,
                                  shape: CircleBorder(),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    FontAwesomeIcons.fileSignature,
                                    size: 30,
                                  ),
                                  color: Colors.white,
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const Planner()));
                                  },
                                ),
                              ),
                            ),
                          ),
                          MaterialButton(
                            onPressed: () async {
                              SharedPreferences preferences =
                                  await SharedPreferences.getInstance();
                              await preferences.clear();
                              // ignore: use_build_context_synchronously
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const KeyboardVisibilityProvider(
                                          child: LoginScreen(),
                                        )),
                              );
                            },
                            color: Colors.red,
                            textColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                            shape: const CircleBorder(),
                            child: const Icon(
                              Icons.logout,
                              size: 40,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            );
          } else {
            return Center(
              child: Text('$_networkStatusMsg'),
            );
          }
        },
      ),
    );
  }

  Future<List<Meeting>> getDataFromWeb() async {
    var data = await http.post(
        Uri.parse(
            "https://www.project1.ts2337.com/checkin_App/api_sql/user/getAgenda.php"),
        body: {
          'user_code': Users.id,
          'year': DateFormat('yyyy').format(DateTime.now())
        });
    var jsonData = json.decode(data.body);

    final List<Meeting> appointmentData = [];
    // final Random random = new Random();
    try {
      for (var data in jsonData) {
        Meeting meetingData = Meeting(
            eventName: data['customer'],
            from: _convertDateFromString(
              data['timestamp'],
            ),
            to: _convertDateFromString(data['timestamp']),
            // background: _colorCollection[random.nextInt(9)],
            all_day: true);
        appointmentData.add(meetingData);
        setState(() {
          dataSource = appointmentData;
        });
      }
      // ignore: empty_catches
    } catch (e) {}

    return appointmentData;
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
        .listen((ConnectivityResult result) {
      setState(() {
        _networkStatusMsg = result.toString();
        if (_networkStatusMsg == "ConnectivityResult.mobile") {
          _networkStatusMsg =
              "You are connected to mobile network, loading calendar data ....";
        } else if (_networkStatusMsg == "ConnectivityResult.wifi") {
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

  // @override
  // Color getColor(int index) {
  //   // return appointments![index].background;
  // }

  @override
  bool isAll_day(int index) {
    return appointments![index].all_day;
  }
}

class Meeting {
  // ignore: non_constant_identifier_names
  Meeting({this.eventName, this.from, this.to, this.all_day = true});

  String? eventName;
  DateTime? from;
  DateTime? to;
  // ignore: non_constant_identifier_names
  bool? all_day;
}
