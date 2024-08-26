import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:kop_checkin/login.dart';
import 'package:kop_checkin/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProflieScreen extends StatefulWidget {
  const ProflieScreen({super.key});

  @override
  State<ProflieScreen> createState() => _ProflieScreenState();
}

class _ProflieScreenState extends State<ProflieScreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color.fromRGBO(12, 45, 92, 1);
  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(
            height: 50,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Profile',
              style: TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
                fontSize: screenWidth / 18,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(top: 20, bottom: 24),
              height: 120,
              width: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20), color: primary),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Username : ${Users.username}',
              style: TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
                fontSize: screenWidth / 20,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Name (TH) : ${Users.name_surname_th}',
              style: TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
                fontSize: screenWidth / 20,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Name (EN) : ${Users.name_surname_en}',
              style: TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
                fontSize: screenWidth / 20,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Position : ${Users.position}',
              style: TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
                fontSize: screenWidth / 20,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Pec Group : ${Users.pec_group}',
              style: TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
                fontSize: screenWidth / 20,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Department : ${Users.department}',
              style: TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
                fontSize: screenWidth / 20,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              child: MaterialButton(
                onPressed: () async {
                  SharedPreferences preferences =
                      await SharedPreferences.getInstance();
                  await preferences.clear();
                  // ignore: use_build_context_synchronously
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const KeyboardVisibilityProvider(
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
            ),
          ),
        ],
      ),
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

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(text),
      ),
    );
  }
}
