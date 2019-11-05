import 'package:flutter/material.dart';
import 'package:weight_tracker/widgets/general.dart';

const double KG_LBS_RATIO = 2.2;
const int ONE_MINUTE_TO_DRAW = 4;
const int MAX_KG_VALUE = 200;
const int MIN_KG_VALUE = 5;
const double TIME_HEADER_HEIGHT = 35;
const double CHANNEL_SCHEDULE_HEIGHT = 60;
const double CHANNEL_WIDTH = 100;
const double DATE_HEIGHT = 65;

class ColorList {
    static const Color colorBlue = Color(0xFF4678EE);
    static const Color colorBg = Color(0xFFF1F3F5);
    static const Color white = Color(0xFFFFFFFF);
}

class DatePickerColor {
    static const Color defaultDateColor = Colors.black;
    static const Color defaultDayColor = Colors.black;
    static const Color defaultMonthColor = Colors.black;
    static const Color defaultSelectionColor = ColorList.colorBlue;
    static const Color defaultTextSelectionColor = Colors.white;
}

class DatePickerDimen {
    DatePickerDimen._();

    static const double dateTextSize = 18;
    static const double dayTextSize = 11;
    static const double monthTextSize = 11;
}

const TextStyle defaultMonthTextStyle = TextStyle(
    color: DatePickerColor.defaultMonthColor,
    fontSize: DatePickerDimen.monthTextSize,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
);

const TextStyle defaultDateTextStyle = TextStyle(
    color: DatePickerColor.defaultDateColor,
    fontSize: DatePickerDimen.dateTextSize,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
);

const TextStyle defaultDayTextStyle = TextStyle(
    color: DatePickerColor.defaultDayColor,
    fontSize: DatePickerDimen.dayTextSize,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w200,
);
