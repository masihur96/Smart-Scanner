import 'package:smart_qr/features/scanner/result_screen.dart';

class ScanModel {
  final int? id;
  final String rawValue;
  final QrType type;
  final DateTime timestamp;
  final bool isFavorite;

  ScanModel({
    this.id,
    required this.rawValue,
    required this.type,
    required this.timestamp,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rawValue': rawValue,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory ScanModel.fromMap(Map<String, dynamic> map) {
    return ScanModel(
      id: map['id'],
      rawValue: map['rawValue'],
      type: QrType.values[map['type']],
      timestamp: DateTime.parse(map['timestamp']),
      isFavorite: map['isFavorite'] == 1,
    );
  }
}
