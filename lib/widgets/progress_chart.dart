import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/constants.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/model/weight_entry.dart';
import 'package:weight_tracker/widgets/progress_chart_dropdown.dart';
import 'package:weight_tracker/widgets/progress_chart_utils.dart' as utils;
import 'package:weight_tracker/widgets/progress_chart_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as im;

class ScheduleConfig {
    static const int padding = 7;
}

class ProgressChartViewModel {
    final List<WeightEntry> allEntries;
    final String unit;

    ProgressChartViewModel({
        this.allEntries,
        this.unit,
    });
}

class ProgressChart extends StatefulWidget {
    @override
    ProgressChartState createState() {
        return new ProgressChartState();
    }
}

class ProgressChartState extends State<ProgressChart> {
    DateTime startDate;
    DateTime snapShotStartDate;
    double startTouch;
    double _startTouchTop;
    double left = 0.0;
    double lastLeft = 0.0;
    double top = 0.0;
    double lastTop = 0.0;
    Offset touchDown;

    Schedule _touchSchedule;
    bool _isVerticalDrag = true;

    ProgressChartState() {
        _createData();
        var now = DateTime.now();
        var timeNow = now.hour * 60 * 2 + now.minute * 2.0;
        if(left == 0 && timeNow > 60) {
            left = timeNow - 60;
        }
    }

    @override
    Widget build(BuildContext context) {
        return new StoreConnector<ReduxState, ProgressChartViewModel>(
            converter: (store) {
                return new ProgressChartViewModel(
                    allEntries: store.state.entries,
                    unit: store.state.unit,
                );
            },
            onInit: (store) {
                this.startDate = store.state.progressChartStartDate ??
                    DateTime.now().subtract(Duration(days: 30));
            },
            onDispose: (store) {
                store.dispatch(ChangeProgressChartStartDate(this.startDate));
            },
            builder: _buildChartWithDropdown,
        );
    }

    Widget _buildChart(ProgressChartViewModel viewModel) {
        return GestureDetector(
            onHorizontalDragStart: (DragStartDetails start) =>
                _onDragStart(context, start, false),
            onHorizontalDragUpdate: (DragUpdateDetails update) =>
                _onDragUpdate(context, update, false),
            onVerticalDragUpdate: (DragUpdateDetails update) =>
                _onDragUpdate(context, update, true),
            onVerticalDragStart: (DragStartDetails start) => {
                _onDragStart(context, start, true),
            },
            onTapDown: (tab) => {
                setState(() {
                    _touchSchedule = null;
                    touchDown = tab.localPosition;
                })
            },
            onTapUp: (tab) {
                if (touchDown != null && _touchSchedule != null) {
                    showDialog<void>(
                        context: context,
                        barrierDismissible: true,
                        // false = user must tap button, true = tap outside dialog
                        builder: (BuildContext dialogContext) {
                            return AlertDialog(
                                title: Text('Clicked'),
                                content: Text(_touchSchedule.name),
                                actions: <Widget>[
                                    FlatButton(
                                        child: Text('OK'),
                                        onPressed: () {
                                            Navigator.of(dialogContext).pop(); // Dismiss alert dialog
                                        },
                                    ),
                                ],
                            );
                        },
                    );
                }
                setState(() {
                    touchDown = null;
                });
            },
            onTapCancel: () {
                setState(() {
                    touchDown = null;
                    _touchSchedule = null;
                });
            },
            child: CustomPaint(
                painter: ChartPainter(
                    left,
                    top,
                    _channels,
                    utils.prepareEntryList(viewModel.allEntries, startDate),
                    daysToDraw(startDate),
                    viewModel.unit == "lbs",
                    touchDown,
                        (schedule) => {_touchSchedule = schedule}),
            ),
        );
    }

    Widget _buildChartWithDropdown(
        BuildContext context, ProgressChartViewModel viewModel) {
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
                new Expanded(child: _buildChart(viewModel)),
            ],
        );
    }

    _onDragStart(BuildContext context, DragStartDetails start, bool isVerticalDrag) {
        _isVerticalDrag = isVerticalDrag;
        print(start.globalPosition.toString());
        RenderBox getBox = context.findRenderObject();
        var local = getBox.globalToLocal(start.globalPosition);
        print("StartTouch:"
            " " +
            local.dx.toString() +
            "|" +
            local.dy.toString());
        setState(() {
            lastLeft = left;
            startTouch = local.dx;
            lastTop = top;
            _startTouchTop = local.dy;
        });
    }

    _onDragUpdate(BuildContext context, DragUpdateDetails update, bool isVerticalDrag) {
        if(_isVerticalDrag != isVerticalDrag) return;
        RenderBox getBox = context.findRenderObject();
        var local = getBox.globalToLocal(update.globalPosition);
        print(left.toString() +
            " | " +
            local.dx.toString() +
            "|" +
            local.dy.toString());
        double newLeft = (startTouch - local.dx);
        double newTop = (_startTouchTop - local.dy);
        setState(() {
            touchDown = null;
            _touchSchedule = null;
            if(!_isVerticalDrag) {
                if (lastLeft + newLeft > 0) {
                    left = lastLeft + newLeft;
                } else {
                    left = 0;
                }
            } else {
                if (lastTop + newTop > 0) {
                    top = lastTop + newTop;
                } else {
                    top = 0;
                }
            }
        });
    }

    int daysToDraw(DateTime date) {
        DateTime now = copyDateWithoutTime(new DateTime.now());
        DateTime start = copyDateWithoutTime(date);
        return now.difference(start).inDays + 1;
    }

    List<Channel> _channels = new List();

    _createData() {
        double currentWidth = 0;
        final maxWidth = 24 * (60.0 * 2);
        _channels.clear();
        for (int i = 0; i < 20; i++) {
            currentWidth = 0;
            List<Schedule> _schedules = List();
            while (currentWidth < maxWidth) {
                double w = 15 * 2.0 + math.Random().nextInt(120 * 2); //Min 15m ,max 120m
                if (currentWidth < maxWidth - ScheduleConfig.padding && currentWidth + w > maxWidth - ScheduleConfig.padding) {
                    w = maxWidth - currentWidth;
                }
                _schedules.add(Schedule(i * i + _schedules.length,
                    "Schedule ${_schedules.length}", currentWidth, currentWidth + w));
                currentWidth += w;
            }
            _channels.add(Channel(i, "Channel ${i + 1}", _schedules));
        }
        _renderImage(0);
    }

    _loadImage(String url, callback) async {
        final bytes = await http.readBytes(url);
        im.Image image = im.decodeImage(bytes);
        double newWidth = image.width.toDouble();
        double newHeight = image.height.toDouble();
        if(newWidth > 100.0) {
            newWidth = 100;
            newHeight = image.height * newWidth / image.width;
        }
        if(newHeight > 50) {
            newHeight = 50;
            newWidth = image.width * newHeight / image.height;
        }
        var imageResized = im.copyResize(image, width: newWidth.toInt(), height: newHeight.toInt());
        ui.decodeImageFromList(imageResized.getBytes(), callback);
//        final frame = await bg.getNextFrame();
//        callback(frame);
    }

    _renderImage(id) {
        this._loadImage('https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/VTV6_logo_2013_final.svg/1200px-VTV6_logo_2013_final.svg.png', (image) {
            for(Channel channel in _channels) {
                channel.image = image;
                setState(() {
                    this._channels = _channels;
                });
//                if(channel.id == id) {
//                    break;
//                }
            }
        });
    }
}

class ChartPainter extends CustomPainter {
    final List<WeightEntry> entries;
    final int numberOfDays;
    final bool isLbs;
    final List<Channel> channels;
    double left;
    final double top;
    final Offset touchDown;
    final int padding = ScheduleConfig.padding;
    double _now = 0;
    final Function(Schedule) _scheduleClickListener;

    ChartPainter(
        this.left,
        this.top,
        this.channels,
        this.entries,
        this.numberOfDays,
        this.isLbs,
        this.touchDown,
        this._scheduleClickListener) {
        var now = DateTime.now();
       _now = now.hour * 60 * 2 + now.minute * 2.0;
    }

    double leftOffsetStart;
    double topOffsetEnd;
    double drawingWidth;
    double drawingHeight;

    static const int NUMBER_OF_HORIZONTAL_LINES = 5;
    static const double headerHeight = 50.0;
    static const double channelWidth = 100.0;

    @override
    void paint(Canvas canvas, Size size) {
        leftOffsetStart = size.width * 0.07;
        topOffsetEnd = size.height * 0.9;
        drawingWidth = size.width * 0.93;
        drawingHeight = topOffsetEnd;

        _drawSchedules(canvas, size);
        _drawChannelsTitle(canvas, size);
        _drawTimes(canvas, size);
        _drawCurrentTimeLine(canvas, _now, size);
    }

    @override
    bool shouldRepaint(ChartPainter old) => true;

    void _drawSchedules(ui.Canvas canvas, ui.Size size) {
        final paint = new Paint()
            ..color = Colors.blue[400]
            ..strokeWidth = 3.0;
        int i = 0;
        double height = 50.0;
        for (Channel channel in channels) {
            for (Schedule schedule in channel.schedules) {
                double rWidth = schedule.end - schedule.start - padding;
                double rLeft = schedule.start + padding - left + channelWidth;
                double rTop = i * height + i * padding - top + headerHeight;
                print(rWidth.toString() + " | " + rLeft.toString() + " | " + rTop.toString() + " | ");
                if (schedule.start - left + channelWidth > size.width) continue;
                if (schedule.end - left + channelWidth < 0) continue;
                if (rTop > size.height) continue;
                if (rTop < 0) continue;
                bool _isTouch = false;
                if (touchDown != null) {
                    if (touchDown.dx > rLeft &&
                        touchDown.dx < rLeft + rWidth &&
                        touchDown.dy > rTop &&
                        touchDown.dy < rTop + height) {
                        _isTouch = true;
                        _scheduleClickListener(schedule);
                    }
                }
                TextSpan span = new TextSpan(
                    style: new TextStyle(
                        color: _isTouch ? Colors.black : Colors.white,
                        fontSize: 15.0,
                        fontFamily: 'Roboto'),
                    text: schedule.name);
                TextPainter tp = new TextPainter(
                    maxLines: 1,
                    ellipsis: "..",
                    textDirection: prefix0.TextDirection.ltr,
                    text: span,
                    textAlign: TextAlign.start);
                tp.layout(maxWidth: rWidth - 3);
                ui.Rect rect = new ui.Rect.fromLTWH(
                    rLeft,
                    rTop,
                    rWidth,
                    height);
                ui.RRect rRect =
                new ui.RRect.fromRectAndRadius(rect, new Radius.circular(5));
                paint.color = _isTouch ? Colors.blueGrey : Colors.blue[400];
                ui.Path path = ui.Path();
                path.addRRect(rRect);
                canvas.drawShadow(path, Colors.black87 , 2, true);
                canvas.drawRRect(rRect, paint);
                tp.paint(
                    canvas,
                    new Offset(schedule.start + (padding + 5) - left + channelWidth,
                        i * height + i * padding + height / 4.0 - top + headerHeight));
            }
            i++;
        }
    }

    void _drawChannelsTitle(ui.Canvas canvas, ui.Size size) {
        canvas.drawRect(Rect.fromLTWH(0, 0, channelWidth, size.height), new Paint()..color = Colors.white);
        final paint = new Paint()
            ..color = Colors.grey[300]
            ..strokeWidth = 3.0;
        int i = 0;
        double height = 50.0;
        for(Channel channel in channels) {
            double rTop = i * height + i * padding - top + headerHeight;
            if (rTop > size.height) {i++;continue;}
            if (rTop < 0) {i++;continue;}
            ui.Rect rect = new ui.Rect.fromLTWH(
                0,
                rTop,
                channelWidth - 3,
                height);
            ui.RRect rRect =
            new ui.RRect.fromRectAndRadius(rect, new Radius.circular(5));
            _drawRRectShadow(canvas, rRect);
            canvas.drawRRect(rRect, paint);
            TextSpan span = new TextSpan(
                style: new TextStyle(
                    color: Colors.black,
                    fontSize: 15.0,
                    fontFamily: 'Roboto'),
                text: channel.name);
            TextPainter tp = new TextPainter(
                maxLines: 1,
                ellipsis: "..",
                textDirection: prefix0.TextDirection.ltr,
                text: span,
                textAlign: TextAlign.start);
            tp.layout(maxWidth: channelWidth - 5 * 2);
//            tp.paint(
//                canvas,
//                new Offset(5,
//                    rTop + height / 4.0));
            if(channel.image != null) {
                int iWidth = channel.image.width;
                int iHeight = channel.image.height;
                int lOffset = (channelWidth.toInt() - iWidth - 3) >> 1;
                int tOffset = (height.toInt() - iHeight) >> 1;
                canvas.drawImage(channel.image, Offset(lOffset.toDouble(), rTop + tOffset), paint);
            }
            i++;
        }
    }

    void _drawCurrentTimeLine(ui.Canvas canvas, double currentTime, ui.Size size) {
        final paint = new Paint()
            ..color = Colors.black
            ..strokeWidth = 3.0;
        if(currentTime - left <= 0) return;
        canvas.drawLine(new Offset(currentTime - left + channelWidth, headerHeight),
            new Offset(currentTime - left + channelWidth, size.height), paint);
        canvas.drawCircle(new Offset(currentTime - left + channelWidth, headerHeight), 5.0 , paint);
    }

    void _drawTimes(ui.Canvas canvas, ui.Size size) {
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, headerHeight), new Paint()..color = Colors.white);
        final paint = new Paint()
            ..color = Colors.black
            ..strokeWidth = 3.0;
        final maxWidth = 24 * 60.0 * 2;
        double currentDrawTime = (left + channelWidth/2 - (left + channelWidth/2) % (30 * 2));
        while (currentDrawTime <= maxWidth) {
            int hour = currentDrawTime ~/ (60 * 2);
            int minute = (currentDrawTime - hour * 60 * 2) ~/ 2;
            TextSpan span = new TextSpan(
                style: new TextStyle(
                    color: Colors.black,
                    fontSize: 15.0,
                    fontFamily: 'Roboto'),
                text: "${(hour > 9) ? "$hour" : "0$hour"}:${(minute > 9) ? "$minute" : "0$minute"}");
            TextPainter tp = new TextPainter(
                maxLines: 1,
                ellipsis: "..",
                textDirection: prefix0.TextDirection.ltr,
                text: span,
                textAlign: TextAlign.center);
            tp.layout(maxWidth: channelWidth);
            tp.paint(
                canvas,
                new Offset(currentDrawTime - left + channelWidth, headerHeight / 2));
            currentDrawTime += 30 * 2;
        }
    }

    ///draws actual chart
    void _drawLines(
        ui.Canvas canvas, int minLineValue, int maxLineValue, bool isLbs) {
        final paint = new Paint()
            ..color = Colors.blue[400]
            ..strokeWidth = 3.0;
        DateTime beginningOfChart =
        utils.getStartDateOfChart(new DateTime.now(), numberOfDays);
        for (int i = 0; i < entries.length - 1; i++) {
            Offset startEntryOffset = _getEntryOffset(
                entries[i], beginningOfChart, minLineValue, maxLineValue, isLbs);
            Offset endEntryOffset = _getEntryOffset(
                entries[i + 1], beginningOfChart, minLineValue, maxLineValue, isLbs);
            canvas.drawLine(startEntryOffset, endEntryOffset, paint);
            canvas.drawCircle(endEntryOffset, 3.0, paint);
        }
        canvas.drawCircle(
            _getEntryOffset(
                entries.first, beginningOfChart, minLineValue, maxLineValue, isLbs),
            5.0,
            paint);
    }

    /// Draws horizontal lines and labels informing about weight values attached to those lines
    void _drawHorizontalLinesAndLabels(
        Canvas canvas, Size size, int minLineValue, int maxLineValue) {
        final paint = new Paint()..color = Colors.grey[300];
        int lineStep = _calculateHorizontalLineStep(maxLineValue, minLineValue);
        double offsetStep = _calculateHorizontalOffsetStep;
        for (int line = 0; line < NUMBER_OF_HORIZONTAL_LINES; line++) {
            double yOffset = line * offsetStep;
            _drawHorizontalLabel(maxLineValue, line, lineStep, canvas, yOffset);
            _drawHorizontalLine(canvas, yOffset, size, paint);
        }
    }

    void _drawHorizontalLine(
        ui.Canvas canvas, double yOffset, ui.Size size, ui.Paint paint) {
        canvas.drawLine(
            new Offset(leftOffsetStart, 5 + yOffset),
            new Offset(size.width, 5 + yOffset),
            paint,
        );
    }

    void _drawHorizontalLabel(int maxLineValue, int line, int lineStep,
        ui.Canvas canvas, double yOffset) {
        ui.Paragraph paragraph =
        _buildParagraphForLeftLabel(maxLineValue, line, lineStep);
        canvas.drawParagraph(
            paragraph,
            new Offset(0.0, yOffset),
        );
    }

    void _drawRectShadow(ui.Canvas canvas, ui.Rect rect) {
        canvas.drawShadow(Path()..addRect(rect), Colors.black87 , 2, true);
    }

    void _drawRRectShadow(ui.Canvas canvas, ui.RRect rect) {
        canvas.drawShadow(Path()..addRRect(rect), Colors.black87 , 2, true);
    }

    void _drawHoriontalShape(ui.Canvas canvas, ui.Rect rect, ui.Paint paint) {
        canvas.drawRect(rect, paint);
    }

    /// Calculates offset difference between horizontal lines.
    ///
    /// e.g. between every line should be 100px space.
    double get _calculateHorizontalOffsetStep {
        return drawingHeight / (NUMBER_OF_HORIZONTAL_LINES - 1);
    }

    /// Calculates weight difference between horizontal lines.
    ///
    /// e.g. every line should increment weight by 5
    int _calculateHorizontalLineStep(int maxLineValue, int minLineValue) {
        return (maxLineValue - minLineValue) ~/ (NUMBER_OF_HORIZONTAL_LINES - 1);
    }

    void _drawBottomLabels(Canvas canvas, Size size) {
        for (int daysFromStart = numberOfDays;
        daysFromStart > 0;
        daysFromStart = (daysFromStart - (numberOfDays / 4)).round()) {
            double offsetXbyDay = drawingWidth / numberOfDays;
            double offsetX = leftOffsetStart + offsetXbyDay * daysFromStart;
            ui.Paragraph paragraph = _buildParagraphForBottomLabel(daysFromStart);
            canvas.drawParagraph(
                paragraph,
                new Offset(offsetX - 50.0, 10.0 + drawingHeight),
            );
        }
    }

    ///Builds paragraph for label placed on the bottom (dates)
    ui.Paragraph _buildParagraphForBottomLabel(int daysFromStart) {
        ui.ParagraphBuilder builder = new ui.ParagraphBuilder(
            new ui.ParagraphStyle(fontSize: 10.0, textAlign: TextAlign.right))
            ..pushStyle(new ui.TextStyle(color: Colors.black))
            ..addText(new DateFormat('d MMM').format(new DateTime.now()
                .subtract(new Duration(days: numberOfDays - daysFromStart))));
        final ui.Paragraph paragraph = builder.build()
            ..layout(new ui.ParagraphConstraints(width: 50.0));
        return paragraph;
    }

    ///Builds text paragraph for label placed on the left side of a chart (weights)
    ui.Paragraph _buildParagraphForLeftLabel(
        int maxLineValue, int line, int lineStep) {
        ui.ParagraphBuilder builder = new ui.ParagraphBuilder(
            new ui.ParagraphStyle(
                fontSize: 10.0,
                textAlign: TextAlign.right,
            ),
        )
            ..pushStyle(new ui.TextStyle(color: Colors.black))
            ..addText((maxLineValue - line * lineStep).toString());
        final ui.Paragraph paragraph = builder.build()
            ..layout(new ui.ParagraphConstraints(width: leftOffsetStart - 4));
        return paragraph;
    }

    ///Produces minimal and maximal value of horizontal line that will be displayed
    Tuple2<int, int> _getMinAndMaxValues(List<WeightEntry> entries, bool isLbs) {
        double maxWeight = entries.map((entry) => entry.weight).reduce(math.max);
        double minWeight = entries.map((entry) => entry.weight).reduce(math.min);

        if (isLbs) {
            maxWeight *= KG_LBS_RATIO;
            minWeight *= KG_LBS_RATIO;
        }
        int maxLineValue;
        int minLineValue;

        if (maxWeight == minWeight) {
            maxLineValue = maxWeight.ceil() + 1;
            minLineValue = maxLineValue - 4;
        } else {
            maxLineValue = maxWeight.ceil();
            int difference = maxLineValue - minWeight.floor();
            int toSubtract = (NUMBER_OF_HORIZONTAL_LINES - 1) -
                (difference % (NUMBER_OF_HORIZONTAL_LINES - 1));
            if (toSubtract == NUMBER_OF_HORIZONTAL_LINES - 1) {
                toSubtract = 0;
            }
            minLineValue = minWeight.floor() - toSubtract;
        }
        return new Tuple2(minLineValue, maxLineValue);
    }

    /// Calculates offset at which given entry should be painted
    Offset _getEntryOffset(WeightEntry entry, DateTime beginningOfChart,
        int minLineValue, int maxLineValue, bool isLbs) {
        double entryWeightToShow =
        isLbs ? entry.weight * KG_LBS_RATIO : entry.weight;
        int daysFromBeginning = entry.dateTime.difference(beginningOfChart).inDays;
        double relativeXposition = daysFromBeginning / (numberOfDays - 1);
        double xOffset = leftOffsetStart + relativeXposition * drawingWidth;
        double relativeYposition =
            (entryWeightToShow - minLineValue) / (maxLineValue - minLineValue);
        double yOffset = 5 + drawingHeight - relativeYposition * drawingHeight;
        return new Offset(xOffset, yOffset);
    }

    _drawParagraphInsteadOfChart(ui.Canvas canvas, ui.Size size, String text) {
        double fontSize = 14.0;
        ui.ParagraphBuilder builder = new ui.ParagraphBuilder(
            new ui.ParagraphStyle(
                fontSize: fontSize,
                textAlign: TextAlign.center,
            ),
        )
            ..pushStyle(new ui.TextStyle(color: Colors.black))
            ..addText(text);
        final ui.Paragraph paragraph = builder.build()
            ..layout(new ui.ParagraphConstraints(width: size.width));

        canvas.drawParagraph(
            paragraph, new Offset(0.0, size.height / 2 - fontSize));
    }
}

class Schedule {
    int id;
    String name;
    double start;
    double end;

    Schedule(this.id, this.name, this.start, this.end);
}

class Channel {
    int id;
    String name;
    List<Schedule> schedules;
    ui.Image image;
    Channel(this.id, this.name, this.schedules);
}
