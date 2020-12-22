import 'dart:convert';

import 'package:firebase_remote_config_platform_interface/firebase_remote_config_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

class MethodChannelFirebaseRemoteConfig extends FirebaseRemoteConfigPlatform {

  static int _methodChannelHandleId = 0;

  static int get nextMethodChannelHandleId => _methodChannelHandleId++;

  static const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/firebase_remote_config'
  );

  static Map<String, MethodChannelFirebaseRemoteConfig>
      _methodChannelFirebaseRemoteConfigInstances =
      <String, MethodChannelFirebaseRemoteConfig>{};

  static MethodChannelFirebaseRemoteConfig get instance {
    return MethodChannelFirebaseRemoteConfig._();
  }

  MethodChannelFirebaseRemoteConfig._() : super(appInstance: null);

  MethodChannelFirebaseRemoteConfig({FirebaseApp app}) : super(appInstance: app);

  Map<String, RemoteConfigValue> _activeParameters;
  RemoteConfigSettings _settings;
  DateTime _lastFetchTime;
  RemoteConfigFetchStatus _lastFetchStatus;

  @override
  FirebaseRemoteConfigPlatform delegateFor({FirebaseApp app}) {
    if (_methodChannelFirebaseRemoteConfigInstances.containsKey(app.name)) {
      return _methodChannelFirebaseRemoteConfigInstances[app.name];
    }

    _methodChannelFirebaseRemoteConfigInstances[app.name] =
        MethodChannelFirebaseRemoteConfig(app: app);
    return _methodChannelFirebaseRemoteConfigInstances[app.name];
  }

  @override
  FirebaseRemoteConfigPlatform setInitialValues(
      {Map<String, dynamic> remoteConfigValues}) {
    final fetchTimeout = remoteConfigValues['fetchTimeout'];
    final minimumFetchInterval = remoteConfigValues['minimumFetchInterval'];
    final lastFetchMillis = remoteConfigValues['lastFetchTime'];

    _settings = RemoteConfigSettings(fetchTimeout, minimumFetchInterval);
    _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetchMillis);
    _activeParameters = remoteConfigValues['parameters'];
    return this;
  }


  @override
  DateTime get lastFetchTime => _lastFetchTime;

  @override
  RemoteConfigFetchStatus get lastFetchStatus => _lastFetchStatus;

  @override
  RemoteConfigSettings get settings => _settings;

  @override
  set settings(RemoteConfigSettings remoteConfigSettings) {
    _settings = remoteConfigSettings;
  }

  @override
  Future<void> ensureInitialized() async {
    await channel.invokeMethod<void>('RemoteConfig#ensureInitialized', <String, dynamic>{
      'appName': app.name,
    });
  }

  @override
  Future<bool> activate() async {
    bool configChanged = await channel.invokeMethod<bool>('RemoteConfig#activate', <String, dynamic>{
      'appName': app.name,
    });
    if (configChanged) {
      await _updateConfigValues();
    }
    return configChanged;
  }

  Future<void> _updateConfigValues() async {
    Map<dynamic, dynamic> parameters = await channel.invokeMapMethod<String, dynamic>('RemoteConfig#getAll', <String, dynamic>{
      'appName': app.name,
    });
    _activeParameters = FirebaseRemoteConfigPlatform.parseParameters(parameters);
  }

  @override
  Future<void> fetch() async {
    await channel.invokeMethod<void>('RemoteConfig#fetch', <String, dynamic>{
      'appName': app.name,
    });
  }

  @override
  Future<bool> fetchAndActivate() async {
    bool configChanged = await channel.invokeMethod<bool>('RemoteConfig#fetchAndActivate', <String, dynamic>{
      'appName': app.name,
    });
    if (configChanged) {
      await _updateConfigValues();
    }
    return configChanged;
  }

  @override
  Map<String, RemoteConfigValue> getAll() {
    return _activeParameters;
  }

  @override
  bool getBool(String key) {
    if (!_activeParameters.containsKey(key)) {
      return RemoteConfigValue.defaultValueForBool;
    }
    return _activeParameters[key].asBool();
  }

  @override
  int getInt(String key) {
    if (!_activeParameters.containsKey(key)) {
      return RemoteConfigValue.defaultValueForInt;
    }
    return _activeParameters[key].asInt();
  }

  @override
  double getDouble(String key) {
    if (!_activeParameters.containsKey(key)) {
      return RemoteConfigValue.defaultValueForDouble;
    }
    return _activeParameters[key].asDouble();
  }

  @override
  String getString(String key) {
    if (!_activeParameters.containsKey(key)) {
      return RemoteConfigValue.defaultValueForString;
    }
    return _activeParameters[key].asString();
  }

  @override
  RemoteConfigValue getValue(String key) {
    if (!_activeParameters.containsKey(key)) {
      return RemoteConfigValue(null, ValueSource.valueStatic);
    }
    return _activeParameters[key];
  }

  @override
  Future<void> setConfigSettings(RemoteConfigSettings remoteConfigSettings) async {
    await channel.invokeMethod('RemoteConfig#setConfigSettings', <String, dynamic>{
      'appName': app.name,
      'fetchTimeout': remoteConfigSettings.fetchTimeout.inSeconds,
      'minimumFetchInterval': remoteConfigSettings.minimumFetchInterval.inSeconds,
    });
  }

  @override
  Future<void> setDefaults(Map<String, dynamic> defaultParameters) async {
    await channel.invokeMethod('RemoteConfig#setDefaults', <String, dynamic>{
      'appName': app.name,
      'defaults': defaultParameters
    });
    await _updateConfigValues();
  }
}
