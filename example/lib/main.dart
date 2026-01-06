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
  late final AppSecurityLock _appSecurityLock;
  // 当前是否锁定
  bool isLocked = false;
  bool isBackgroundLocked = false;
  bool isScreenLocked = true;
  bool isScreenRecordingProtected = false;
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
  }

  @override
  void initState() {
    super.initState();

    // 使用链式调用设置所有回调
    _appSecurityLock = AppSecurityLock()
      ..onLock((reason) {
        _addLog('应用已锁定，原因: ${reason.name}');
        setState(() => isLocked = true);
      })
      ..onUnlock(() {
        _addLog('应用已解锁');
        // Unlock callback when calling setLocked(false)
        setState(() => isLocked = false);
      })
      ..onForeground(() {
        _addLog('应用进入前台');
      })
      ..onBackground(() {
        _addLog('应用进入后台');
      });

    // 初始化插件
    _appSecurityLock.init(
      isScreenLockEnabled: isScreenLocked,
      isBackgroundLockEnabled: isBackgroundLocked,
      backgroundTimeout: 5.0,
      isTouchTimeoutEnabled: false,
      touchTimeout: 10.0,
      debug: true,
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
                          onChanged: (value) async {
                            setState(() => isLocked = value);
                            await _appSecurityLock.setLocked(value);
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
                                    onPressed: () =>
                                        _appSecurityLock.resetTouchTimer(),
                                    child: const Text('restart'))),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _appSecurityLock
                                      .touchTimeoutEnabled(true);
                                  _addLog('Touch timeout enabled');
                                },
                                child: const Text('Enable Touch Timeout'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _appSecurityLock
                                      .touchTimeoutEnabled(false);
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
                                onPressed: () async {
                                  await _appSecurityLock.touchTimeout(10.0);
                                  _addLog('Touch timeout set to 10 seconds');
                                },
                                child: const Text('10s Timeout'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _appSecurityLock.touchTimeout(30.0);
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
                                  setState(() => isBackgroundLocked = value);
                                  _appSecurityLock.backgroundLockEnabled(value);
                                }),
                          ],
                        ),
                        Wrap(
                          spacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _appSecurityLock.backgroundLockEnabled(false);
                                _addLog('Background lock disabled');
                              },
                              child: const Text('Disable'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await _appSecurityLock.backgroundTimeout(60.0);
                                _addLog('Background timeout set to 60s');
                              },
                              child: const Text('60s Timer'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await _appSecurityLock.backgroundTimeout(30.0);
                                _addLog('Background timeout set to 30s');
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
                                  setState(() => isScreenLocked = value);
                                  _appSecurityLock.screenLockEnabled(value);
                                }),
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
                          'Screen Recording Protection:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('禁止录屏:'),
                            Switch(
                                value: isScreenRecordingProtected,
                                onChanged: (value) async {
                                  setState(
                                      () => isScreenRecordingProtected = value);
                                  await _appSecurityLock
                                      .screenRecordingProtectionEnabled(
                                    value,
                                    warningMessage: '⚠️ 检测到屏幕录制，该操作已被阻止',
                                  );
                                  _addLog('录屏防护已${value ? '启用' : '禁用'}');
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
