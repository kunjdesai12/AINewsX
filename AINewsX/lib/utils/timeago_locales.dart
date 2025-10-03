import 'package:timeago/timeago.dart' as timeago;

class HindiMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => 'अब से';
  @override
  String suffixAgo() => 'पहले';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => 'अभी';
  @override
  String aboutAMinute(int minutes) => '1 मिनट';
  @override
  String minutes(int minutes) => '$minutes मिनट';
  @override
  String aboutAnHour(int minutes) => '1 घंटा';
  @override
  String hours(int hours) => '$hours घंटे';
  @override
  String aDay(int hours) => '1 दिन';
  @override
  String days(int days) => '$days दिन';
  @override
  String aboutAMonth(int days) => '1 महीना';
  @override
  String months(int months) => '$months महीने';
  @override
  String aboutAYear(int year) => '1 साल';
  @override
  String years(int years) => '$years साल';
  @override
  String wordSeparator() => ' ';
}

class GujaratiMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => 'હવે થી';
  @override
  String suffixAgo() => 'પહેલાં';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => 'હમણાં';
  @override
  String aboutAMinute(int minutes) => '1 મિનિટ';
  @override
  String minutes(int minutes) => '$minutes મિનિટ';
  @override
  String aboutAnHour(int minutes) => '1 કલાક';
  @override
  String hours(int hours) => '$hours કલાક';
  @override
  String aDay(int hours) => '1 દિવસ';
  @override
  String days(int days) => '$days દિવસ';
  @override
  String aboutAMonth(int days) => '1 મહિનો';
  @override
  String months(int months) => '$months મહિના';
  @override
  String aboutAYear(int year) => '1 વર્ષ';
  @override
  String years(int years) => '$years વર્ષ';
  @override
  String wordSeparator() => ' ';
}