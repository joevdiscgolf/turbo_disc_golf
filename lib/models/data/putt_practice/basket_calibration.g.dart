// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basket_calibration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BasketCalibration _$BasketCalibrationFromJson(Map json) => BasketCalibration(
  left: (json['left'] as num).toDouble(),
  top: (json['top'] as num).toDouble(),
  right: (json['right'] as num).toDouble(),
  bottom: (json['bottom'] as num).toDouble(),
  centerX: (json['centerX'] as num).toDouble(),
  centerY: (json['centerY'] as num).toDouble(),
  basketWidthPixels: (json['basketWidthPixels'] as num).toDouble(),
  pixelsPerInch: (json['pixelsPerInch'] as num).toDouble(),
  confidence: (json['confidence'] as num).toDouble(),
  userConfirmed: json['userConfirmed'] as bool,
  calibratedAt: DateTime.parse(json['calibratedAt'] as String),
);

Map<String, dynamic> _$BasketCalibrationToJson(BasketCalibration instance) =>
    <String, dynamic>{
      'left': instance.left,
      'top': instance.top,
      'right': instance.right,
      'bottom': instance.bottom,
      'centerX': instance.centerX,
      'centerY': instance.centerY,
      'basketWidthPixels': instance.basketWidthPixels,
      'pixelsPerInch': instance.pixelsPerInch,
      'confidence': instance.confidence,
      'userConfirmed': instance.userConfirmed,
      'calibratedAt': instance.calibratedAt.toIso8601String(),
    };
