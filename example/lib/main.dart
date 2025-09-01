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

  String _biometricType = '检测中...';
  bool _isBiometricAvailable = false;
  bool _isLockEnabled = true; // 默认启用安全锁
  bool _isFaceIDEnabled = false;
  bool _isPasscodeEnabled = true; // 默认启用密码解锁
  String _lastAuthResult = '暂无';
  double _backgroundTimeout = 60.0; // 默认60秒
  bool _isBackgroundLockEnabled = false;
  bool _isScreenLockEnabled = false;

  @override
  void initState() {
    super.initState();
    setupLifecycleCallbacks();
    setupAuthenticationCallbacks();
    checkBiometricSupport();
  }

  // 设置生命周期回调
  void setupLifecycleCallbacks() {
    _appSecurityLockPlugin.setOnEnterForegroundCallback(() {
      setState(() {
        _lastAuthResult =
            '应用进入前台 - ${DateTime.now().toString().substring(11, 19)}';
      });
      print('Flutter: 应用进入前台');
    });

    _appSecurityLockPlugin.setOnEnterBackgroundCallback(() {
      setState(() {
        _lastAuthResult =
            '应用进入后台 - ${DateTime.now().toString().substring(11, 19)}';
      });
      print('Flutter: 应用进入后台');
    });

    // 初始化插件，使用配置参数
    _appSecurityLockPlugin.init(
      isFaceIDEnabled: _isFaceIDEnabled,
      isPasscodeEnabled: _isPasscodeEnabled,
      isScreenLockEnabled: _isScreenLockEnabled, // 启用屏幕锁定检测
      isBackgroundLockEnabled: _isBackgroundLockEnabled,
      backgroundTimeout: _backgroundTimeout,
    );
  }

  // 设置认证回调
  void setupAuthenticationCallbacks() {
    // 统一的认证回调 - 处理成功和失败情况
    _appSecurityLockPlugin.setOnAuthenticationCallback((success, message) {
      setState(() {
        if (success) {
          _lastAuthResult =
              '认证成功 ($message) - ${DateTime.now().toString().substring(11, 19)}';
        } else {
          _lastAuthResult =
              '认证失败: $message - ${DateTime.now().toString().substring(11, 19)}';
        }
      });
      print('Flutter: 认证${success ? "成功" : "失败"}: $message');
    });

    // 锁定回调
    _appSecurityLockPlugin.setOnAppLockedCallback(() {
      setState(() {
        _lastAuthResult =
            '应用被锁定 - ${DateTime.now().toString().substring(11, 19)}';
      });
      print('Flutter: 应用被锁定');
    });

    // 解锁回调
    _appSecurityLockPlugin.setOnAppUnlockedCallback(() {
      setState(() {
        _lastAuthResult =
            '应用解锁 - ${DateTime.now().toString().substring(11, 19)}';
      });
      print('Flutter: 应用解锁');
    });
  }

  // 检查生物识别支持
  Future<void> checkBiometricSupport() async {
    try {
      final isAvailable = await _appSecurityLockPlugin.isBiometricAvailable();
      final type = await _appSecurityLockPlugin.getBiometricType();

      setState(() {
        _isBiometricAvailable = isAvailable;
        _biometricType = type;
      });
    } catch (e) {
      setState(() {
        _biometricType = '检测失败';
        _isBiometricAvailable = false;
      });
    }
  }

  // 重新初始化插件配置
  Future<void> reinitializePlugin() async {
    try {
      await _appSecurityLockPlugin.init(
        isFaceIDEnabled: _isFaceIDEnabled,
        isPasscodeEnabled: _isPasscodeEnabled,
        isScreenLockEnabled: _isScreenLockEnabled,
        isBackgroundLockEnabled: _isBackgroundLockEnabled,
        backgroundTimeout: _backgroundTimeout,
      );
    } catch (e) {
      print('重新初始化插件失败: $e');
    }
  }

  // 测试生物识别
  Future<void> testBiometric() async {
    try {
      final result = await _appSecurityLockPlugin.authenticateWithBiometric();
      setState(() {
        _lastAuthResult = result ? '手动认证成功' : '手动认证失败';
      });
    } catch (e) {
      setState(() {
        _lastAuthResult = '认证错误: $e';
      });
    }
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
          child: ListView(
            children: [
              // 生物识别信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('生物识别信息',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('类型: $_biometricType'),
                      Text('可用: ${_isBiometricAvailable ? "是" : "否"}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 设置开关
              Card(
                color: _isLockEnabled ? null : Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isLockEnabled
                                ? Icons.security
                                : Icons.security_outlined,
                            color: _isLockEnabled ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text('安全设置',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SwitchListTile(
                        title: const Text('启用面容ID/指纹'),
                        subtitle: Text(_isBiometricAvailable
                            ? '支持 $_biometricType'
                            : '设备不支持生物识别'),
                        value: _isFaceIDEnabled,
                        onChanged: (_isBiometricAvailable && _isLockEnabled)
                            ? (value) {
                                setState(() {
                                  _isFaceIDEnabled = value;
                                });
                                _appSecurityLockPlugin.setFaceIDEnabled(value);
                                reinitializePlugin();
                              }
                            : null,
                      ),
                      SwitchListTile(
                        title: const Text('后台超时锁定'),
                        subtitle: const Text('应用进入后台后自动锁定'),
                        value: _isBackgroundLockEnabled,
                        onChanged: _isLockEnabled
                            ? (value) {
                                setState(() {
                                  _isBackgroundLockEnabled = value;
                                });
                                _appSecurityLockPlugin
                                    .setBackgroundLockEnabled(value);
                                reinitializePlugin();
                              }
                            : null,
                      ),
                      SwitchListTile(
                        title: const Text('屏幕锁定检测'),
                        subtitle: const Text('屏幕亮度为0时自动锁定'),
                        value: _isScreenLockEnabled,
                        onChanged: _isLockEnabled
                            ? (value) {
                                setState(() {
                                  _isScreenLockEnabled = value;
                                });
                                reinitializePlugin();
                              }
                            : null,
                      ),
                      SwitchListTile(
                        title: const Text('启用密码解锁'),
                        subtitle: const Text('使用设备密码作为备选方案'),
                        value: _isPasscodeEnabled,
                        onChanged: _isLockEnabled
                            ? (value) {
                                setState(() {
                                  _isPasscodeEnabled = value;
                                });
                                _appSecurityLockPlugin
                                    .setPasscodeEnabled(value);
                                reinitializePlugin();
                              }
                            : null,
                      ),
                      const Divider(),
                      const Text('后台超时时间',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('30秒'),
                          Expanded(
                            child: Slider(
                              value: _backgroundTimeout,
                              min: 30.0,
                              max: 300.0,
                              divisions: 9,
                              label: '${_backgroundTimeout.toInt()}秒',
                              onChanged:
                                  (_isLockEnabled && _isBackgroundLockEnabled)
                                      ? (value) {
                                          setState(() {
                                            _backgroundTimeout = value;
                                          });
                                          _appSecurityLockPlugin
                                              .setBackgroundTimeout(value);
                                          reinitializePlugin();
                                        }
                                      : null,
                            ),
                          ),
                          const Text('5分钟'),
                        ],
                      ),
                      Text(
                        '当前设置: ${_backgroundTimeout.toInt()}秒',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 测试按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isBiometricAvailable ? testBiometric : null,
                  child: const Text('测试生物识别'),
                ),
              ),

              const SizedBox(height: 16),

              // 状态显示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('最后状态',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_lastAuthResult),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              const Text(
                '切换到后台或返回前台来测试生命周期和认证功能',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
