import 'package:flutter/foundation.dart';
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
  bool isBackgroundLocked = false;
  bool isScreenLocked = true;
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
      _addLog('please unlock the app');
      setState(() {
        isLocked = true;
      });
    });
    _appSecurityLockPlugin.setOnEnterForegroundCallback(() {
      _addLog('App is foregrounded');
    });
    _appSecurityLockPlugin.setOnEnterBackgroundCallback(() {
      _addLog('App is backgrounded');
    });
    _appSecurityLockPlugin.init(
      isScreenLockEnabled: isScreenLocked,
      isBackgroundLockEnabled: isBackgroundLocked,
      backgroundTimeout: 5.0,
      isTouchTimeoutEnabled: false,
      touchTimeout: 10.0, // 30 seconds of inactivity
      debug: kDebugMode,
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
        body: SingleChildScrollView(
          child: Padding(
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
                // Touch Timeout Controls
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Touch Timeout Settings:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: ElevatedButton(
                                    onPressed: () => _appSecurityLockPlugin
                                        .restartTouchTimer(),
                                    child: const Text('restart'))),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _appSecurityLockPlugin
                                      .setTouchTimeoutEnabled(true);
                                  _addLog('Touch timeout enabled');
                                },
                                child: const Text('Enable Touch Timeout'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _appSecurityLockPlugin
                                      .setTouchTimeoutEnabled(false);
                                  _addLog('Touch timeout disabled');
                                },
                                child: const Text('Disable Touch Timeout'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _appSecurityLockPlugin.setTouchTimeout(10.0);
                                  _addLog('Touch timeout set to 10 seconds');
                                },
                                child: const Text('10s Timeout'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _appSecurityLockPlugin.setTouchTimeout(30.0);
                                  _addLog('Touch timeout set to 30 seconds');
                                },
                                child: const Text('30s Timeout'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Background Timer Controls:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Background Lock:'),
                            Switch(
                                value: isBackgroundLocked,
                                onChanged: (value) {
                                  setState(() {
                                    isBackgroundLocked = value;
                                  });
                                  _appSecurityLockPlugin
                                      .setBackgroundLockEnabled(value);
                                }),
                          ],
                        ),
                        Wrap(
                          spacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _appSecurityLockPlugin
                                    .setBackgroundLockEnabled(false);
                                _addLog('Background timer restarted');
                              },
                              child: const Text('30s Timer'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _appSecurityLockPlugin
                                    .setBackgroundTimeout(60.0);
                                _addLog('Background timer restarted');
                              },
                              child: const Text('60s Timer'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _appSecurityLockPlugin
                                    .setBackgroundTimeout(30.0);
                                _addLog('Background timer restarted');
                              },
                              child: const Text('30s Timer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Screen Timer Controls:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Screen Lock:'),
                            Switch(
                                value: isScreenLocked,
                                onChanged: (value) {
                                  setState(() {
                                    isScreenLocked = value;
                                  });
                                  _appSecurityLockPlugin
                                      .setScreenLockEnabled(value);
                                }),
                          ],
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
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  height: 200,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
