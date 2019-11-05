import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weight_tracker/widgets/general.dart';
import 'callback/callback.dart';

class DateWidget extends StatelessWidget {
    final DateTime date;
    final TextStyle monthTextStyle, dayTextStyle, dateTextStyle;
    final Color selectionColor;
    final Color textSelectionColor;
    final Color textDefaultColor;
    final DateSelectionCallback onDateSelected;
    final String locale;
    final List<BoxShadow> boxShadow;

    DateWidget(
        {@required this.date,
            @required this.monthTextStyle,
            @required this.dayTextStyle,
            @required this.dateTextStyle,
            @required this.selectionColor,
            @required this.textSelectionColor,
            @required this.textDefaultColor,
            this.boxShadow,
            this.onDateSelected,
            this.locale,
        });

    @override
    Widget build(BuildContext context) {
        return InkWell(
            child: Container(
                margin: EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                child: Padding(
                    padding:
                    const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 15, right: 15),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                            Text(new DateFormat("E", locale).format(date).toUpperCase(), // Month
                                style: monthTextStyle.copyWith(color: textDefaultColor)),
                Container(
                    width: 30,
                    height: 30,
                    padding: EdgeInsets.all(3.0),
                    margin: EdgeInsets.only(top: 5.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        color: selectionColor,
                        boxShadow: boxShadow
                    ),child: Center(child:
                            Text(date.day.toString(), // Date
                                style: dateTextStyle.copyWith(color: textSelectionColor)),)
                )],
                    ),
                ),
            ),
            onTap: () {
                // Check if onDateSelected is not null
                if (onDateSelected != null) {
                    // Call the onDateSelected Function
                    onDateSelected(this.date);
                }
            },
        );
    }
}