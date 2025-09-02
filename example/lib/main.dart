import 'package:flutter/material.dart';
import 'package:app_security_lock/app_security_lock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appSecurityLockPlugin = AppSecurityLock();
  // 当前是否锁定
  bool isLocked = false;

  @override
  void initState() {
    super.initState();

    _appSecurityLockPlugin.setOnAppLockedCallback(() {
      print('App is locked');
      setState(() {
        isLocked = true;
      });
    });
    _appSecurityLockPlugin.setOnAppUnlockedCallback(() {
      print('App is unlocked');
      setState(() {
        isLocked = false;
      });
    });
    _appSecurityLockPlugin.setOnEnterForegroundCallback(() {
      print('App is foregrounded');
    });
    _appSecurityLockPlugin.setOnEnterBackgroundCallback(() {
      print('App is backgrounded');
    });
    _appSecurityLockPlugin.setOnAppUnlockedCallback(() {
      print('App is locked  ,please lock it');
    });
    _appSecurityLockPlugin.init(
      isScreenLockEnabled: true,
      isBackgroundLockEnabled: true,
      backgroundTimeout: 5.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('App Security Lock Example'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Switch(
            value: isLocked,
            onChanged: (value) {
              setState(() {
                isLocked = value;
                _appSecurityLockPlugin.setLockEnabled(value);
              });
            },
          ),
        ),
      ),
    );
  }
}
