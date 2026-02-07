/// Direction of a missed putt relative to the basket center
enum MissDirection {
  /// Disc went high (over the basket)
  high,

  /// Disc went low (under the chains/cage)
  low,

  /// Disc went left of the basket
  left,

  /// Disc went right of the basket
  right,

  /// Close miss near center (within tolerance but still missed)
  center,
}

/// Extension methods for MissDirection
extension MissDirectionExtension on MissDirection {
  /// Human-readable label for the miss direction
  String get label {
    switch (this) {
      case MissDirection.high:
        return 'High';
      case MissDirection.low:
        return 'Low';
      case MissDirection.left:
        return 'Left';
      case MissDirection.right:
        return 'Right';
      case MissDirection.center:
        return 'Center';
    }
  }

  /// Short code for compact display
  String get code {
    switch (this) {
      case MissDirection.high:
        return 'H';
      case MissDirection.low:
        return 'L';
      case MissDirection.left:
        return 'L';
      case MissDirection.right:
        return 'R';
      case MissDirection.center:
        return 'C';
    }
  }
}
