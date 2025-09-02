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
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
  }

  @override
  void initState() {
    super.initState();

    _appSecurityLockPlugin.setOnAppLockedCallback(() {
      _addLog('App is locked');
      setState(() {
        isLocked = true;
      });
    });
    _appSecurityLockPlugin.setOnAppUnlockedCallback(() {
      _addLog('App is unlocked');
      setState(() {
        isLocked = false;
      });
    });
    _appSecurityLockPlugin.setOnEnterForegroundCallback(() {
      _addLog('App is foregrounded');
    });
    _appSecurityLockPlugin.setOnEnterBackgroundCallback(() {
      _addLog('App is backgrounded');
    });
    _appSecurityLockPlugin.setOnAppUnlockedCallback(() {
      _addLog('App is locked, please unlock it');
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Security Lock Status: ${isLocked ? "Locked" : "Unlocked"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Switch(
                        value: isLocked,
                        onChanged: (value) {
                          setState(() {
                            isLocked = value;
                            _appSecurityLockPlugin.setLockEnabled(value);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Event Logs:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
