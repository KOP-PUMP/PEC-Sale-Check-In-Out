import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kop_checkin/model/user_model.dart';
// import 'package:kop_checkin/model/agenda.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:multiselect/multiselect.dart';

class Planner extends StatefulWidget {
  const Planner({super.key});

  @override
  State<Planner> createState() => _PlannerState();
}

class _PlannerState extends State<Planner> {
  final List<Appointment> _appointmentDetails = <Appointment>[];
  final List<String> freq = <String>['WEEKLY', 'MONTHLY'];
  final List<String> interval = <String>['1', '2', '3','4'];
  final List<String> count = <String>[
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12'
  ];
  final List<Appointment> appointments = <Appointment>[];
  final List<String> day = <String>['MO', 'TU', 'WE', 'TH', 'SA', 'SU'];
  List<String> selectedDay = [];

  late _DataSource dataSource;
  late Color screenPickerColor; // Color for picker shown in Card on the screen.
  late Color dialogPickerColor; // Color for picker in dialog using onChanged
  late Color dialogSelectColor; // Color for picker using color select dialog.
  late bool isDark;
  String customer = '';
  String check = 'WEEKLY';

  final TextEditingController _controller = new TextEditingController();
  String text = ""; // empty string to carry what was there before it

  int maxLength = 10;

  static const Color guidePrimary = Color(0xFF6200EE);
  static const Color guidePrimaryVariant = Color(0xFF3700B3);
  static const Color guideSecondary = Color(0xFF03DAC6);
  static const Color guideSecondaryVariant = Color(0xFF018786);
  static const Color guideError = Color(0xFFB00020);
  static const Color guideErrorDark = Color(0xFFCF6679);
  static const Color blueBlues = Color(0xFF174378);

  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color.fromRGBO(12, 45, 92, 1);
  String _date = DateFormat('dd MMMM yyyy').format(DateTime.now());
  String _enddate = DateFormat('MMMM yyyy').format(DateTime.now());
  String byuntil = DateFormat('yyyyMM').format(DateTime.now());
  String _day = DateFormat('dd').format(DateTime.now());
  String bydate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String typeFreq = 'WEEKLY';
  String intervalRe = '1';
  String countRe = '1';
  String byDayRe = 'MO';
  final CalendarController _calendarController = CalendarController();

  var concatenate = StringBuffer();

  final Map<ColorSwatch<Object>, String> colorsNameMap =
      <ColorSwatch<Object>, String>{
    ColorTools.createPrimarySwatch(guidePrimary): 'Guide Purple',
    ColorTools.createPrimarySwatch(guidePrimaryVariant): 'Guide Purple Variant',
    ColorTools.createAccentSwatch(guideSecondary): 'Guide Teal',
    ColorTools.createAccentSwatch(guideSecondaryVariant): 'Guide Teal Variant',
    ColorTools.createPrimarySwatch(guideError): 'Guide Error',
    ColorTools.createPrimarySwatch(guideErrorDark): 'Guide Error Dark',
    ColorTools.createPrimarySwatch(blueBlues): 'Blue blues',
  };

  @override
  void initState() {
    super.initState();
    dataSource = getCalendarDataSource();
    screenPickerColor = Colors.blue;
    dialogPickerColor = Colors.red;
    dialogSelectColor = const Color(0xFFA239CA);
    isDark = false;
  }

  void calendarViewChanged(ViewChangedDetails viewChangedDetails) {
    SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
      _calendarController.selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    String dropdownValue = freq.first;
    String dropdownValueCount = count.first;
    String dropdownValueInterval = interval.first;
    String dropdownValueDay = day.first;

    return (Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              height: 300,
              child: SfCalendar(
                view: CalendarView.month,
                dataSource: dataSource,
                initialSelectedDate:
                    DateTime.now().add(const Duration(days: -1)),
                onSelectionChanged: selectionChanged,
              ),
            ),
            Expanded(
              child: Container(
                color: const Color.fromARGB(255, 255, 252, 252),
                child: ListView.separated(
                  padding: const EdgeInsets.all(2),
                  itemCount: _appointmentDetails.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      padding: const EdgeInsets.all(2),
                      height: 50,
                      color: _appointmentDetails[index].color,
                      child: ListTile(
                        leading: Column(
                          children: <Widget>[
                            Text(
                              _appointmentDetails[index].isAllDay
                                  ? ''
                                  : DateFormat('hh:mm a').format(
                                      _appointmentDetails[index].startTime),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.5),
                            ),
                            Text(
                              _appointmentDetails[index].isAllDay
                                  ? 'All day'
                                  : '',
                              style: const TextStyle(
                                  height: 0.5, color: Colors.white),
                            ),
                            Text(
                              _appointmentDetails[index].isAllDay
                                  ? ''
                                  : DateFormat('hh:mm a').format(
                                      _appointmentDetails[index].endTime),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          getIcon(_appointmentDetails[index].subject),
                          size: 30,
                          color: Colors.white,
                        ),
                        title: Text(
                          _appointmentDetails[index].subject,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 12),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(
                    height: 10,
                  ),
                ),
              ),
            ),
            Container(
              height: 300,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        // margin: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Start : ' + _date,
                          style: TextStyle(
                              color: Colors.black54,
                              fontFamily: 'NexaBold',
                              fontSize: screenWidth / 27),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        // margin: const EdgeInsets.only(top: 5),
                        child: GestureDetector(
                          onTap: () async {
                            int nowyear = DateTime.now().year.toInt();
                            final month = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(nowyear),
                              lastDate: DateTime(2099),
                              builder: (context, child) {
                                return Theme(
                                    data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                            primary: primary,
                                            secondary: primary,
                                            onSecondary: Colors.white),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                              foregroundColor: primary),
                                        ),
                                        textTheme: const TextTheme(
                                          headlineMedium: TextStyle(
                                              fontFamily: 'NexaRegular'),
                                          labelSmall: TextStyle(
                                              fontFamily: 'NexaRegular'),
                                          labelLarge: TextStyle(
                                              fontFamily: 'NexaRegular'),
                                        )),
                                    child: child!);
                              },
                            );
                            if (month != null) {
                              setState(() {
                                _date =
                                    DateFormat('dd MMMM yyyy').format(month);
                                bydate = DateFormat('yyyy-MM-dd').format(month);
                                _day = DateFormat('dd').format(month);
                              });
                            }
                            print(_day);
                          },
                          child: Text(
                            'Pick Date',
                            style: TextStyle(
                                // backgroundColor: Colors.blue,
                                color: Colors.black,
                                fontFamily: 'NexaBold',
                                fontSize: screenWidth / 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ColorIndicator(
                        width: 44,
                        height: 44,
                        borderRadius: 4,
                        color: dialogPickerColor,
                        onSelectFocus: false,
                        onSelect: () async {
                          // Store current color before we open the dialog.
                          final Color colorBeforeDialog = dialogPickerColor;
                          // Wait for the picker to close, if dialog was dismissed,
                          // then restore the color we had before it was opened.
                          if (!(await colorPickerDialog())) {
                            setState(() {
                              dialogPickerColor = colorBeforeDialog;
                            });
                          }
                          print(dialogPickerColor);
                        },
                      ),
                      Expanded(
                        child: Container(
                          // margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 5),
                          alignment: Alignment.centerLeft,
                          child: DropdownSearch<UserModel>(
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: "Customer",
                                filled: true,
                              ),
                            ),
                            onChanged: (UserModel? data) => setState(() {
                              customer = data!.name.toString();
                            }),
                            asyncItems: (filter) => getData(filter),
                            compareFn: (i, s) => i.isEqual(s),
                            popupProps:
                                PopupPropsMultiSelection.modalBottomSheet(
                              showSearchBox: true,
                              itemBuilder: _customPopupItemBuilderExample2,
                              favoriteItemProps: FavoriteItemProps(
                                showFavoriteItems: true,
                                favoriteItems: (us) {
                                  return us
                                      .where((e) => e.name.contains("O-0019"))
                                      .toList();
                                },
                                favoriteItemBuilder:
                                    (context, item, isSelected) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[100]),
                                    child: Row(
                                      children: [
                                        Text(
                                          item.name,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.indigo),
                                        ),
                                        const Padding(
                                            padding: EdgeInsets.only(left: 8)),
                                        isSelected
                                            ? const Icon(
                                                Icons.check_box_outlined)
                                            : const SizedBox.shrink(),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 5),
                          // padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          child: DropdownMenu<String>(
                            label: const Text('Freq'),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontFamily: 'NexaBold',
                            ),
                            initialSelection: dropdownValue,
                            dropdownMenuEntries: freq
                                .map<DropdownMenuEntry<String>>((String value) {
                              return DropdownMenuEntry<String>(
                                  value: value, label: value);
                            }).toList(),
                            onSelected: (String? value) {
                              setState(() {
                                dropdownValue = value!;
                                check = value!;
                                typeFreq = value!;
                              });

                              // This is called when the user selects an item.
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          child: DropdownMenu<String>(
                            label: const Text('Interval'),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontFamily: 'NexaBold',
                            ),
                            initialSelection: dropdownValueInterval,
                            dropdownMenuEntries: interval
                                .map<DropdownMenuEntry<String>>((String value) {
                              return DropdownMenuEntry<String>(
                                  value: value, label: value);
                            }).toList(),
                            onSelected: (String? value) {
                              setState(() {
                                dropdownValueInterval = value!;
                                intervalRe = value!;
                              });
                              // This is called when the user selects an item.
                            },
                          ),
                        ),
                      ),

                      // TextFormField(
                      //   controller: _controller,
                      //   cursorColor: Colors.black54,
                      //   maxLines: 1,
                      //   decoration: const InputDecoration(
                      //     hintText: "Interval",
                      //     hintStyle: TextStyle(
                      //       color: Colors.black54,
                      //       fontFamily: "NexaBold",
                      //       fontSize: 14,
                      //     ),
                      //     enabledBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(
                      //         color: Colors.black54,
                      //       ),
                      //     ),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(
                      //         color: Colors.black54,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  Row(
                    children: [
                      check == 'WEEKLY'
                          ? Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.only(right: 27),
                                alignment: Alignment.centerLeft,
                                child: DropDownMultiSelect(
                                  options: day,
                                  selectedValues: selectedDay,
                                  onChanged: (value) {
                                    print('selected fruit $value');
                                    setState(() {
                                      selectedDay = value;
                                    });
                                    print(
                                        'you have selected $selectedDay fruits.');
                                  },
                                  whenEmpty: 'Select your Day (MO = Monday)',
                                ),
                              ),
                            )
                          : check == "MONTHLY"
                              ? const SizedBox()
                              : const SizedBox(),
                      // Expanded(
                      //   child: Container(
                      //     margin: const EdgeInsets.only(top: 10),
                      //     // padding: const EdgeInsets.symmetric(horizontal: 20),
                      //     alignment: Alignment.centerLeft,
                      //     child: DropdownMenu<String>(
                      //       label: const Text('Count'),
                      //       textStyle: const TextStyle(
                      //         fontSize: 14,
                      //         color: Colors.black54,
                      //         fontFamily: 'NexaBold',
                      //       ),
                      //       initialSelection: dropdownValueCount,
                      //       dropdownMenuEntries: count
                      //           .map<DropdownMenuEntry<String>>((String value) {
                      //         return DropdownMenuEntry<String>(
                      //             value: value, label: value);
                      //       }).toList(),
                      //       onSelected: (String? value) {
                      //         setState(() {
                      //           dropdownValueCount = value!;
                      //           countRe = value!;
                      //         });
                      //         // This is called when the user selects an item.
                      //       },
                      //     ),
                      //   ),
                      // )
                    ],
                  ),
                  Stack(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(top: 10),
                        child: Text(
                          'End : ' + _enddate,
                          style: TextStyle(
                              color: Colors.black54,
                              fontFamily: 'NexaBold',
                              fontSize: screenWidth / 27),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: () async {
                            int nowyear = DateTime.now().year.toInt();
                            final month = await showMonthYearPicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(nowyear),
                              lastDate: DateTime(2099),
                              builder: (context, child) {
                                return Theme(
                                    data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                            primary: primary,
                                            secondary: primary,
                                            onSecondary: Colors.white),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                              foregroundColor: primary),
                                        ),
                                        textTheme: const TextTheme(
                                          headlineMedium: TextStyle(
                                              fontFamily: 'NexaRegular'),
                                          labelSmall: TextStyle(
                                              fontFamily: 'NexaRegular'),
                                          labelLarge: TextStyle(
                                              fontFamily: 'NexaRegular'),
                                        )),
                                    child: child!);
                              },
                            );

                            if (month != null) {
                              setState(() {
                                _enddate =
                                    DateFormat('MMMM yyyy').format(month);
                                byuntil = DateFormat('yyyyMM').format(month);
                              });
                            }
                          },
                          child: Text(
                            'Pick Month',
                            style: TextStyle(
                                // backgroundColor: Colors.blue,
                                color: Colors.black,
                                fontFamily: 'NexaBold',
                                fontSize: screenWidth / 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
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
                          color: Colors.black,
                          shape: CircleBorder(),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.circleLeft,
                            size: 30,
                          ),
                          color: Colors.white,
                          onPressed: () {
                            Navigator.pop(context);
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
                          color: Colors.grey,
                          shape: CircleBorder(),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.trashCan,
                            size: 30,
                          ),
                          color: Colors.white,
                          onPressed: () {
                            // _appointmentDetails.clear();
                            setState(() {
                              // dataSource.appointments?.remove('head');
                              //  _appointmentDetails.clear();
                               dataSource.appointments?.clear();
                            });
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
                            FontAwesomeIcons.penNib,
                            size: 30,
                          ),
                          color: Colors.white,
                          onPressed: () {
                            if (typeFreq == 'WEEKLY') {
                              // selectedDay.forEach((item) {
                              //   concatenate.write(','+item);
                              // });

                              if (selectedDay.isEmpty) {
                                showSnackBar('Please Select Day');
                              } else {
                                setState(() {
                                  appointments.add(Appointment(
                                      startTime: DateTime.parse(bydate),
                                      endTime: DateTime.parse(bydate),
                                      subject: customer,
                                      color: dialogPickerColor,
                                      isAllDay: true,
                                      recurrenceRule:
                                          'FREQ=WEEKLY;INTERVAL=$intervalRe;BYDAY=${selectedDay.join(",")};UNTIL=${byuntil}31'));
                                });
                              }
                            } else if (typeFreq == 'MONTHLY') {
                              setState(() {
                                appointments.add(Appointment(
                                    startTime: DateTime.parse(bydate),
                                    endTime: DateTime.parse(bydate),
                                    subject: customer,
                                    color: dialogPickerColor,
                                    isAllDay: true,
                                    recurrenceRule:
                                        'FREQ=MONTHLY;BYMONTHDAY=$_day;INTERVAL=$intervalRe;UNTIL=${byuntil}31'));
                              });
                            } else {
                              setState(() {
                                appointments.add(Appointment(
                                    startTime: DateTime.parse(bydate),
                                    endTime: DateTime.parse(bydate),
                                    subject: customer,
                                    color: dialogPickerColor,
                                    isAllDay: true,
                                    recurrenceRule:
                                        'FREQ=DAILY;INTERVAL=$intervalRe;UNTIL=${byuntil}31'));
                              });
                            }
                            dataSource = _DataSource(appointments);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }

  void selectionChanged(CalendarSelectionDetails calendarSelectionDetails) {
    getSelectedDateAppointments(calendarSelectionDetails.date);
  }

  void getSelectedDateAppointments(DateTime? selectedDate) {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      setState(() {
        _appointmentDetails.clear();
      });

      if (dataSource.appointments!.isEmpty) {
        return;
      }

      for (int i = 0; i < dataSource.appointments!.length; i++) {
        Appointment appointment = dataSource.appointments![i] as Appointment;

        /// It return the occurrence appointment for the given pattern appointment at the selected date.
        final Appointment? occurrenceAppointment =
            dataSource.getOccurrenceAppointment(appointment, selectedDate!, '');
        if ((DateTime(appointment.startTime.year, appointment.startTime.month,
                    appointment.startTime.day) ==
                DateTime(
                    selectedDate.year, selectedDate.month, selectedDate.day)) ||
            occurrenceAppointment != null) {
          setState(() {
            _appointmentDetails.add(appointment);
          });
        }
      }
    });
  }

  _DataSource getCalendarDataSource() {
    // appointments.add(Appointment(
    //     startTime: DateTime.now(),
    //     endTime: DateTime.now(),
    //     isAllDay: true,
    //     subject: 'Recurrence',
    //     color: Colors.red,
    //     recurrenceRule: 'FREQ=DAILY;INTERVAL=3;UNTIL=20240230'));
    // appointments.add(Appointment(
    //     startTime: DateTime.now(),
    //     endTime: DateTime.now(),
    //     isAllDay: true,
    //     subject: 'Recurrence',
    //     color: Colors.red,
    //     recurrenceRule: 'FREQ=DAILY;INTERVAL=3;UNTIL=20240230'));

    // appointments.add(Appointment(
    //     startTime: DateTime.parse('2024-01-15'),
    //     endTime: DateTime.parse('2024-01-15'),
    //     subject: 'Release Meeting',
    //     color: Colors.red,
    //     isAllDay: true,
    //     recurrenceRule: 'FREQ=MONTHLY;BYMONTHDAY=16;INTERVAL=1;UNTIL=20240230'));

    // appointments.add(Appointment(
    //     startTime: DateTime.now().add(const Duration(hours: 4, days: -1)),
    //     endTime: DateTime.now().add(const Duration(hours: 5, days: -1)),
    //     subject: 'Release Meeting',
    //     color: Colors.lightBlueAccent,
    //     isAllDay: true));

    // appointments.add(Appointment(
    //   startTime: DateTime.now(),
    //   endTime: DateTime.now().add(const Duration(hours: 1)),
    //   subject: 'Meeting',
    //   color: const Color(0xFFfb21f66),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(days: -2, hours: 4)),
    //   endTime: DateTime.now().add(const Duration(days: -2, hours: 5)),
    //   subject: 'Development Meeting   New York, U.S.A',
    //   color: const Color(0xFFf527318),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.parse('2024-01-03 20:18:04Z'),
    //   endTime: DateTime.parse('2024-01-03 21:18:04Z'),
    //   subject: 'Development Meeting   New York, U.S.A',
    //   color: const Color(0xFFf527318),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(days: -2, hours: 4)),
    //   endTime: DateTime.now().add(const Duration(days: -2, hours: 5)),
    //   subject: 'Development Meeting   New York, U.S.A',
    //   color: const Color(0xFFf527318),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(days: -2, hours: 4)),
    //   endTime: DateTime.now().add(const Duration(days: -2, hours: 5)),
    //   subject: 'Development Meeting   New York, U.S.A',
    //   color: const Color(0xFFf527318),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(days: -2, hours: 4)),
    //   endTime: DateTime.now().add(const Duration(days: -2, hours: 5)),
    //   subject: 'Development Meeting   New York, U.S.A',
    //   color: const Color(0xFFf527318),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(days: -2, hours: 4)),
    //   endTime: DateTime.now().add(const Duration(days: -2, hours: 5)),
    //   subject: 'Development Meeting   New York, U.S.A',
    //   color: const Color(0xFFf527318),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(days: -2, hours: 4)),
    //   endTime: DateTime.now().add(const Duration(days: -2, hours: 5)),
    //   subject: 'Development Meeting   New York, U.S.A',
    //   color: const Color(0xFFf527318),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(days: -2, hours: 4)),
    //   endTime: DateTime.now().add(const Duration(days: -2, hours: 5)),
    //   subject: 'Development Meeting   New York, U.S.A',
    //   color: const Color(0xFFf527318),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(days: -2, hours: 3)),
    //   endTime: DateTime.now().add(const Duration(days: -2, hours: 4)),
    //   subject: 'Project Plan Meeting   Kuala Lumpur, Malaysia',
    //   color: const Color(0xFFfb21f66),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(days: -2, hours: 2)),
    //   endTime: DateTime.now().add(const Duration(days: -2, hours: 3)),
    //   subject: 'Support - Web Meeting   Dubai, UAE',
    //   color: const Color(0xFFf3282b8),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(days: -2, hours: 1)),
    //   endTime: DateTime.now().add(const Duration(days: -2, hours: 2)),
    //   subject: 'Project Release Meeting   Istanbul, Turkey',
    //   color: const Color(0xFFf2a7886),
    // ));

    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(hours: 2, days: -4)),
    //   endTime: DateTime.now().add(const Duration(hours: 4, days: -4)),
    //   subject: 'Performance check',
    //   color: Colors.amber,
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(hours: 11, days: -2)),
    //   endTime: DateTime.now().add(const Duration(hours: 12, days: -2)),
    //   subject: 'Customer Meeting   Tokyo, Japan',
    //   color: const Color(0xFFffb8d62),
    // ));
    // appointments.add(Appointment(
    //   startTime: DateTime.now().add(const Duration(hours: 6, days: 2)),
    //   endTime: DateTime.now().add(const Duration(hours: 7, days: 2)),
    //   subject: 'Retrospective',
    //   color: Colors.purple,
    // ));

    return _DataSource(appointments);
  }

  IconData getIcon(String subject) {
    if (subject == 'Planning') {
      return Icons.subject;
    } else if (subject == 'Development Meeting   New York, U.S.A') {
      return Icons.people;
    } else if (subject == 'Support - Web Meeting   Dubai, UAE') {
      return Icons.settings;
    } else if (subject == 'Project Plan Meeting   Kuala Lumpur, Malaysia') {
      return Icons.check_circle_outline;
    } else if (subject == 'Retrospective') {
      return Icons.people_outline;
    } else if (subject == 'Project Release Meeting   Istanbul, Turkey') {
      return Icons.people_outline;
    } else if (subject == 'Customer Meeting   Tokyo, Japan') {
      return Icons.settings_phone;
    } else if (subject == 'Release Meeting') {
      return Icons.view_day;
    } else {
      return Icons.beach_access;
    }
  }

  Future<bool> colorPickerDialog() async {
    return ColorPicker(
      color: dialogPickerColor,
      onColorChanged: (Color color) =>
          setState(() => dialogPickerColor = color),
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        'Select color',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subheading: Text(
        'Select color shade',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      wheelSubheading: Text(
        'Selected color and its shades',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodyMedium,
      colorCodePrefixStyle: Theme.of(context).textTheme.bodySmall,
      selectedPickerTypeColor: Theme.of(context).colorScheme.primary,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
      customColorSwatchesAndNames: colorsNameMap,
    ).showPickerDialog(
      context,
      actionsPadding: const EdgeInsets.all(16),
      constraints:
          const BoxConstraints(minHeight: 480, minWidth: 300, maxWidth: 320),
    );
  }

  Widget textField(
      String hint, String title, TextEditingController controller) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontFamily: "NexaBold",
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          margin: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            cursorColor: Colors.black54,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
                fontSize: 14,
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.black54,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

 Widget _customPopupItemBuilderExample2(
      BuildContext context, UserModel item, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: !isSelected
          ? null
          : BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(5),
              color: Colors.white,
            ),
      child: ListTile(
        selected: isSelected,
        title: Text('${item.name} ${item.nameEN}'),
      ),
    );
  }

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(text),
      ),
    );
  }

  Future<List<UserModel>> getData(filter) async {
    //  var res = await http.post(Uri.parse(API.getRowCheck), body: {
    //   'user_code': Users.id,
    // });
    var response = await Dio().get(
      "https://www.project1.ts2337.com/checkin_App/api_sql/user/getCustomer.php",
      queryParameters: {"filter": filter},
    );

    final data = jsonDecode(response.data);
    //  print('date' + response.data);
    if (data != null) {
      return UserModel.fromJsonList(data);
    }

    return [];
  }
}

class _DataSource extends CalendarDataSource {
  _DataSource(List<Appointment> source) {
    appointments = source;
  }
}
