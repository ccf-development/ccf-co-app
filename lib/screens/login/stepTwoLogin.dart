import 'dart:convert';

import 'package:chokchey_finance/providers/manageService.dart';
import 'package:chokchey_finance/screens/login/firstChangePassword.dart';
import 'package:chokchey_finance/utils/storages/colors.dart';
import 'package:chokchey_finance/utils/storages/const.dart';
import 'package:chokchey_finance/providers/login.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart';
import 'dart:async';

import 'package:provider/provider.dart';

import '../../app/module/home_new/screen/new_homescreen.dart';

class StepTwoLogin extends StatefulWidget {
  final storeUser;
  final valuePassword;

  // final ImageProvider chokchey;
  StepTwoLogin({
    this.storeUser,
    this.valuePassword,
    // this.chokchey = const AssetImage('assets/images/chokchey-logo.png'),
  });
  _LoginState createState() =>
      _LoginState(storeUser: storeUser, valuePassword: valuePassword);
}

class _LoginState extends State<StepTwoLogin> {
  final storeUser;
  final valuePassword;
  _LoginState({this.storeUser, this.valuePassword});
  final storage = new FlutterSecureStorage();

  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  final TextEditingController id = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController firstLogin = TextEditingController();

  bool firstLogIn = false;
  bool isLoading = false;
  bool autofocus = false;

  final focusPassword = FocusNode();
  final focusFirstLogin = FocusNode();
  var chokchey;

  // @override
  // void didChangeDependencies() {

  //   getStore();
  //   chokchey = const AssetImage('assets/images/chokchey-logo.png');
  //   super.didChangeDependencies();
  // }

  Future<void> getStore() async {
    String? ids = await storage.read(key: 'user_id');
    String? passwords = await storage.read(key: 'password');
    if (mounted) {
      setState(() {
        id.text = ids!;
        password.text = passwords!;
      });
    }
  }

  // var _login;
  // var _roles;

  onClickFirst() {
    FocusScope.of(context).requestFocus(focusFirstLogin);
    setState(() {
      firstLogIn = true;
    });
  }

// Create storage StepTwoLogin
  Future<void> onClickLogin(context) async {
    setState(() {
      isLoading = true;
    });
    try {
      await Provider.of<LoginProvider>(context, listen: false)
          .postLoginChangePassword(firstLogin.text)
          .then((value) async => {
                if (value[0]['changePassword'] == 'Y')
                  {
                    await storage.write(
                        key: "user_id", value: storeUser[0]['uid']),
                    await storage.write(key: "password", value: valuePassword),
                    await storage.write(
                        key: "user_name", value: storeUser[0]['uname']),
                    await storage.write(
                        key: "user_token", value: storeUser[0]['token']),
                    await storage.write(
                        key: "user_ucode", value: storeUser[0]['ucode']),
                    await storage.write(
                        key: "branch", value: storeUser[0]['branch']),
                    await storage.write(
                        key: "level", value: value[0]['level'].toString()),
                    await storage.write(
                        key: "isapprover",
                        value: value[0]['isapprover'].toString()),
                    // navigator to home screen
                    FirebaseMessaging.instance.getToken().then((String? token) {
                      assert(token != null);
                      postTokenPushNotification(token);
                    }),
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => NewHomeScreen()
                            //Home(),
                            ),
                        ModalRoute.withName("/login"))
                  }
                else
                  {
                    Navigator.pop(context),
                  }
              });
    } catch (error) {
      print('error: $error');
    }
  }

  postTokenPushNotification(tokens) async {
    var token = await storage.read(key: 'user_token');
    var userUcode = await storage.read(key: "user_ucode");

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    };
    final Map<String, dynamic> bodyRow = {"mtoken": "$tokens"};
    try {
      await api().post(
          Uri.parse(baseURLInternal + 'users/' + "$userUcode" + '/mtoken'),
          headers: headers,
          body: json.encode(bodyRow));
    } catch (error) {
      print('error:: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                width: 300.0,
                height: 250.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(42.0),
                  image: DecorationImage(
                    image: AssetImage('assets/images/chokchey-logo.png'),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Text(
                'Welcome',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: fontSizeLg,
                  color: logolightGreen,
                  fontWeight: fontWeight700,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 5),
              ),
              Text(
                ' CHOK CHEY Finance',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: fontSizeLg,
                  color: logolightGreen,
                  fontWeight: fontWeight700,
                ),
              ),
              FirstChangePassword(
                controller: firstLogin,
                focusNode: focusFirstLogin,
                hintText: firstLogin.text,
                onSubmitted: (v) async {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: logolightGreen,
                        ),
                      );
                    },
                  );
                  await onClickLogin(context);
                },
              ),
              Container(
                width: 320,
                height: 45,
                margin: EdgeInsets.only(top: 40, bottom: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: logolightGreen,
                      padding: const EdgeInsets.all(8.0),
                      textStyle: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: logolightGreen,
                          ),
                        );
                      },
                    );

                    await onClickLogin(context);
                  },
                  child: Text(
                    "Log In",
                  ),
                ),
              ),
              Text(
                'Forgot passwrod',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 12,
                  color: const Color(0xff39a5ef),
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
