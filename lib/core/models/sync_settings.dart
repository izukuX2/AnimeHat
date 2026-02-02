enum SyncSpeed {
  slow,
  normal,
  fast;

  int get delaySeconds {
    switch (this) {
      case SyncSpeed.slow:
        return 5;
      case SyncSpeed.normal:
        return 2;
      case SyncSpeed.fast:
        return 0;
    }
  }

  String get label {
    switch (this) {
      case SyncSpeed.slow:
        return 'Slow';
      case SyncSpeed.normal:
        return 'Normal';
      case SyncSpeed.fast:
        return 'Fast';
    }
  }
}

class SyncSettings {
  final bool isEnabled;
  final SyncSpeed speed;

  SyncSettings({this.isEnabled = true, this.speed = SyncSpeed.normal});

  SyncSettings copyWith({bool? isEnabled, SyncSpeed? speed}) {
    return SyncSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      speed: speed ?? this.speed,
    );
  }
}
