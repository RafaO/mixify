/// A sealed class to represent the filter range
abstract class TimeRange {
  const TimeRange();

  /// Factory constructors for specific time ranges
  factory TimeRange.oneMonth() => const OneMonth();
  factory TimeRange.threeMonths() => const ThreeMonths();
  factory TimeRange.oneYear() => const OneYear();
  factory TimeRange.forever() => const Forever();

  /// Method to calculate the start date based on the range
  DateTime getStartDate() {
    final now = DateTime.now();
    if (this is OneMonth) {
      return now.subtract(const Duration(days: 30));
    } else if (this is ThreeMonths) {
      return now.subtract(const Duration(days: 90));
    } else if (this is OneYear) {
      return now.subtract(const Duration(days: 365));
    } else if (this is Forever) {
      return DateTime.fromMillisecondsSinceEpoch(0); // Beginning of time
    }
    throw UnsupportedError('Unsupported time range');
  }

  /// Convert the object to JSON
  String toJson() {
    if (this is OneMonth) return 'oneMonth';
    if (this is ThreeMonths) return 'threeMonths';
    if (this is OneYear) return 'oneYear';
    if (this is Forever) return 'forever';
    throw UnsupportedError('Unsupported time range');
  }

  /// Create a TimeRange from JSON
  factory TimeRange.fromJson(String json) {
    switch (json) {
      case 'oneMonth':
        return TimeRange.oneMonth();
      case 'threeMonths':
        return TimeRange.threeMonths();
      case 'oneYear':
        return TimeRange.oneYear();
      case 'forever':
        return TimeRange.forever();
      default:
        throw ArgumentError('Invalid TimeRange value: $json');
    }
  }
}

class OneMonth extends TimeRange {
  const OneMonth();
}

class ThreeMonths extends TimeRange {
  const ThreeMonths();
}

class OneYear extends TimeRange {
  const OneYear();
}

class Forever extends TimeRange {
  const Forever();
}
