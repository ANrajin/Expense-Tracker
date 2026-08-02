import 'package:intl/intl.dart';

/// Formats an amount as BDT (৳) using standard Bangladeshi digit grouping
/// (last 3 digits, then groups of 2): 1234567 -> ৳12,34,567
String fmtBDT(num n) {
  final sign = n < 0 ? '-' : '';
  final value = n.abs().round();
  final s = value.toString();
  if (s.length <= 3) return '$sign৳$s';

  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  var i = rest.length;
  while (i > 2) {
    parts.insert(0, rest.substring(i - 2, i));
    i -= 2;
  }
  if (i > 0) parts.insert(0, rest.substring(0, i));

  return '$sign৳${parts.join(',')},$last3';
}

String toIsoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

DateTime parseIsoDate(String s) => DateTime.parse(s);

String monthLabel(int year, int month) =>
    DateFormat('MMMM yyyy').format(DateTime(year, month));

String shortMonthLabel(int year, int month) =>
    DateFormat('MMM').format(DateTime(year, month));

String todayLongLabel(DateTime d) => DateFormat('EEEE, MMMM d').format(d);

String shortDateLabel(DateTime d) => DateFormat('MMM d').format(d);

String dayGroupLabel(DateTime d) => DateFormat('EEE, MMM d').format(d);
