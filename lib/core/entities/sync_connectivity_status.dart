import '../enums/sync_connectivity_type.dart';

class SyncConnectivityStatus {
  final bool isConnected;
  final SyncConnectivityType type;
  final String? networkName;
  final double? signalStrength;

  const SyncConnectivityStatus({
    required this.isConnected,
    required this.type,
    this.networkName,
    this.signalStrength,
  });

  bool get isWifi => type == SyncConnectivityType.wifi;
  bool get isMobile => type == SyncConnectivityType.mobile;
  bool get isEthernet => type == SyncConnectivityType.ethernet;
  bool get hasStrongSignal => signalStrength != null && signalStrength! > 0.7;

  @override
  String toString() {
    return 'SyncConnectivityStatus(isConnected: $isConnected, type: $type, networkName: $networkName, signalStrength: $signalStrength)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncConnectivityStatus &&
        other.isConnected == isConnected &&
        other.type == type &&
        other.networkName == networkName &&
        other.signalStrength == signalStrength;
  }

  @override
  int get hashCode {
    return Object.hash(isConnected, type, networkName, signalStrength);
  }
}
