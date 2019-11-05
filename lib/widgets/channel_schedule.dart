import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as sky;
import 'package:flutter/painting.dart' as sky;
import 'package:flutter/rendering.dart' as sky;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' as sky;
import 'package:flutter/widgets.dart' as sky;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:weight_tracker/logic/constants.dart';
import 'package:weight_tracker/widgets/general.dart';
import 'package:weight_tracker/widgets/progress_chart_utils.dart';

class ScheduleConfig {
    static const int padding = 7;
}

typedef void TopUpdateListener(double top);

class ChannelScheduleWidget extends StatefulWidget {
    final TopUpdateListener _topUpdateListener;

    ChannelScheduleWidget(this._topUpdateListener, {Key key}) : super(key: key);

    @override
    ChannelScheduleWidgetState createState() {
        return new ChannelScheduleWidgetState(_topUpdateListener);
    }
}

class ChannelScheduleWidgetState extends State<ChannelScheduleWidget>
    with SingleTickerProviderStateMixin {
    DateTime startDate;
    DateTime snapShotStartDate;
    double startTouch;
    double _startTouchTop;
    double left = 0.0;
    double lastLeft = 0.0;
    double top = 0.0;
    double lastTop = 0.0;
    double maxWidthDraw = 0.0;
    double maxHeightDraw = 0.0;
    Offset touchDown;
    final TopUpdateListener _topUpdateListener;
    AnimationController _animationController;
    Animation<double> animation;

    Schedule _touchSchedule;
    bool _isVerticalDrag = true;

    ChannelScheduleWidgetState(this._topUpdateListener) {
        _createData();
        var now = DateTime.now();
        var timeNow = now.hour * 60 * ONE_MINUTE_TO_DRAW +
            now.minute * ONE_MINUTE_TO_DRAW.toDouble();
        if (left == 0 && timeNow > 30 * ONE_MINUTE_TO_DRAW) {
            left = timeNow - 30 * ONE_MINUTE_TO_DRAW;
        }
        _animationController = AnimationController(
            duration: Duration(milliseconds: 1000), vsync: this);
    }

    @override
    Widget build(BuildContext context) {
        return _buildChart();
    }

    double panInitial = 0.0;
    double panTopInitial = 0.0;

    Widget _buildChart() {
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
            onTapDown: (tab) {
                _animationController?.stop(canceled: true);
                setState(() {
                    _touchSchedule = null;
                    touchDown = tab.localPosition;
                });
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
            onHorizontalDragCancel: () {},
            onVerticalDragCancel: () {},
            onHorizontalDragEnd: (detail) {
                if (detail.velocity.pixelsPerSecond.dy != 0 && !_isVerticalDrag) {
                    _startScrollAnimation(detail.velocity.pixelsPerSecond.dy, false);
                }
            },
            onVerticalDragEnd: (detail) {
                if (detail.velocity.pixelsPerSecond.dx != 0 && _isVerticalDrag) {
                    _startScrollAnimation(detail.velocity.pixelsPerSecond.dx, true);
                }
            },
            child: CustomPaint(
                key: _containerKey,
                painter: ChartPainter(
                    left,
                    top,
                    _channels,
                    touchDown,
                    this.maxHeightDraw,
                    this.maxWidthDraw,
                        (schedule) => {_touchSchedule = schedule}),
            ),
        );
    }

    _startScrollAnimation(velocity, bool _isVertical) {
        print("Start scoll Animation $_newScrollLeft  $_newScrollTop $velocity");

        lastLeft = left;
        lastTop = top;
        _animationController.stop(canceled: true);
        _animationController.duration = Duration(milliseconds: 500);
        _animationController.value = 0.0;
//        _animationController.fling(velocity: 1);
        if (animation != null) {
            animation.removeListener(_animationListener);
        }
        _animationListener = () {
            print("Anination value: ${animation.value} isVertical $_isVertical");
            setState(() {
                if (!_isVerticalDrag) {
                    var newLeft = (_newScrollLeft > 0 ? 1 : -1) * animation.value;
                    if (lastLeft + newLeft <= 0) {
                        left = 0;
                    } else if (lastLeft + newLeft >
                        maxWidthDraw - _getWidgetSize().width) {
                        left = maxWidthDraw - _getWidgetSize().width;
                    } else {
                        left = lastLeft + newLeft;
                    }
                } else {
                    var newTop = (_newScrollTop > 0 ? 1 : -1) * animation.value;
                    if (lastTop + newTop > 0) {
                        if (lastTop + newTop > maxHeightDraw - _getWidgetSize().height) {
                            top = maxHeightDraw - _getWidgetSize().height;
                        } else {
                            top = lastTop + newTop;
                        }
                    } else {
                        top = 0;
                    }
                }
            });
        };
        final double _end =
        (!_isVertical) ? _newScrollLeft + 0.0 : _newScrollTop + 0.0;
        animation = Tween<double>(begin: 0, end: _end.abs() * 10)
            .animate(_animationController)
            ..addListener(_animationListener);
        _animationController.forward();
    }

    VoidCallback _animationListener = () {};

    _onDragStart(
        BuildContext context, DragStartDetails start, bool isVerticalDrag) {
        _animationController?.stop(canceled: true);
        _isVerticalDrag = isVerticalDrag;
        print(start.globalPosition.toString());
        RenderBox getBox = context.findRenderObject();
        var local = getBox.globalToLocal(start.globalPosition);
        setState(() {
            lastLeft = left;
            startTouch = local.dx;
            _prvX = local.dx;
            lastTop = top;
            _startTouchTop = local.dy;
            _prvY = local.dy;
        });
    }

    double _newScrollLeft = 0.0;
    double _newScrollTop = 0.0;
    double _prvX = 0.0;
    double _prvY = 0.0;

    _onDragUpdate(
        BuildContext context, DragUpdateDetails update, bool isVerticalDrag) {
        if (_isVerticalDrag != isVerticalDrag) return;
        RenderBox getBox = context.findRenderObject();
        var local = getBox.globalToLocal(update.globalPosition);
        double newLeft = (startTouch - local.dx);
        double newTop = (_startTouchTop - local.dy);
        setState(() {
            touchDown = null;
            _touchSchedule = null;
            if (!_isVerticalDrag) {
                _newScrollTop = 0;
                _newScrollLeft = _prvX - local.dx;
                _prvX = local.dx;
                if (lastLeft + newLeft > 0) {
                    if (lastLeft + newLeft > maxWidthDraw - _getWidgetSize().width) {
                        left = maxWidthDraw - _getWidgetSize().width;
                    } else {
                        left = lastLeft + newLeft;
                    }
                } else {
                    left = 0;
                }
            } else {
                _newScrollLeft = 0;
                _newScrollTop = _prvY - local.dy;
                _prvY = local.dy;
                if (lastTop + newTop > 0) {
                    if (lastTop + newTop > maxHeightDraw - _getWidgetSize().height) {
                        top = maxHeightDraw - _getWidgetSize().height;
                    } else {
                        top = lastTop + newTop;
                    }
                } else {
                    top = 0;
                }
                if (_topUpdateListener != null) {
                    _topUpdateListener(top);
                }
            }
        });
    }

    GlobalKey _containerKey = GlobalKey();

    Size _getWidgetSize() {
        final RenderBox containerRenderBox =
        _containerKey.currentContext.findRenderObject();
        return containerRenderBox.size;
    }

    int daysToDraw(DateTime date) {
        DateTime now = copyDateWithoutTime(new DateTime.now());
        DateTime start = copyDateWithoutTime(date);
        return now.difference(start).inDays + 1;
    }

    List<Channel> _channels = new List();

    _createData() {
        double currentWidth = 0;
        final channelImageLoading = [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/VTV6_logo_2013_final.svg/1200px-VTV6_logo_2013_final.svg.png",
            'https://upload.wikimedia.org/wikipedia/commons/4/4d/ESPN_Films_logo.png',
            'https://upload.wikimedia.org/wikipedia/commons/d/dd/Espnhd.png',
            'https://upload.wikimedia.org/wikipedia/commons/b/ba/17WNCN.PNG',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/AXS_TV_Logo.png/180px-AXS_TV_Logo.png',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Bravo_logo_2002.png/180px-Bravo_logo_2002.png',
            'https://upload.wikimedia.org/wikipedia/commons/2/22/Corona_TV_Logo.png',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Discovery_Familia.png/180px-Discovery_Familia.png',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/HGTV_Logo.jpg/180px-HGTV_Logo.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/HBO_Family_logo.png/180px-HBO_Family_logo.png',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/NEP-Logo-FC-BLACK-RGB.png/180px-NEP-Logo-FC-BLACK-RGB.png',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/NSN.png/180px-NSN.png',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Oprah_Winfrey_Network.png/180px-Oprah_Winfrey_Network.png',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/LOGO_OF_LOGO.svg/180px-LOGO_OF_LOGO.svg.png',
            'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/LRW_logo_2012.png/180px-LRW_logo_2012.png'
        ];
        final numberOfChannel = 40;
        final maxWidth = 10 * 24 * (60.0 * ONE_MINUTE_TO_DRAW);
        maxHeightDraw =
            numberOfChannel * (CHANNEL_SCHEDULE_HEIGHT + ScheduleConfig.padding) +
                TIME_HEADER_HEIGHT;
        maxWidthDraw = 0.0;
        _channels.clear();
        for (int i = 0; i < numberOfChannel; i++) {
            currentWidth = 0;
            List<Schedule> _schedules = List();
            while (currentWidth < maxWidth) {
                double w = 15.0 * ONE_MINUTE_TO_DRAW +
                    math.Random()
                        .nextInt(60 * ONE_MINUTE_TO_DRAW * 2); //Min 15m ,max 120m
                if (currentWidth < maxWidth - ScheduleConfig.padding &&
                    currentWidth + w > maxWidth - ScheduleConfig.padding) {
                    w = maxWidth - currentWidth;
                }
                var _schedule = Schedule(i * i + _schedules.length,
                    "Schedule ${_schedules.length}", currentWidth, currentWidth + w);
                _schedules.add(_schedule);
                currentWidth += w;
                if (currentWidth > maxWidthDraw) {
                    maxWidthDraw = currentWidth;
                }
            }
            var channel = Channel(i, "Channel ${i + 1}", _schedules,
                channelImageLoading[i % channelImageLoading.length]);
            _channels.add(channel);
            _renderImage(channel);
        }
    }

    Future<ui.Image> _loadImage(String url) async {
        final _image = await http.readBytes(url);

        final bg = await ui.instantiateImageCodec(_image);
        final frame = await bg.getNextFrame();
        final img = frame.image;
        return img;
    }

    _renderImage(Channel channel) async {
        final recorder = new ui.PictureRecorder();
        final image = await this._loadImage(channel.imageUrl);
        double maxWidth = CHANNEL_WIDTH - 30;
        double maxHeight = CHANNEL_SCHEDULE_HEIGHT - 10;
        final canvas = new Canvas(
            recorder,
            Rect.fromPoints(
                Offset(0.0, 0.0), Offset(CHANNEL_WIDTH, CHANNEL_SCHEDULE_HEIGHT)));

        double newWidth = image.width.toDouble();
        double newHeight = image.height.toDouble();
        if (newWidth > maxWidth) {
            newWidth = maxWidth;
            newHeight = image.height * newWidth / image.width;
        }
        if (newHeight > maxHeight) {
            newHeight = maxHeight;
            newWidth = image.width * newHeight / image.height;
        }
        print("Size: $newHeight/$newWidth  ${image.height}/${image.width}");
        canvas.drawImageRect(
            image,
            Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(0, 0, newWidth, newHeight),
            Paint()
                ..filterQuality = FilterQuality.high
                ..colorFilter = ColorFilter.mode(Colors.white, BlendMode.srcATop));
        final picture = recorder.endRecording();
        final png = await picture.toImage(newWidth.toInt(), newHeight.toInt());
        for (Channel _channel in _channels) {
            if (_channel.id == channel.id) {
                _channel.image = png;
                setState(() {
                    this._channels = _channels;
                });
                break;
            }
        }
    }

    _onBuildCompleted(_) {
        _getWidgetSize();
    }

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addPostFrameCallback(_onBuildCompleted);
    }

    @override
    void dispose() {
        super.dispose();
        if (_animationController != null) {
            _animationController.dispose();
        }
    }
}

class ChartPainter extends CustomPainter {
    final List<Channel> channels;
    double left;
    final double top;
    final Offset touchDown;
    final int padding = ScheduleConfig.padding;
    double _now = 0;
    final Function(Schedule) _scheduleClickListener;
    double maxWidthDraw = 0.0;
    double maxHeightDraw = 0.0;

    ChartPainter(this.left, this.top, this.channels, this.touchDown,
        this.maxHeightDraw, this.maxWidthDraw, this._scheduleClickListener) {
        var now = DateTime.now();
        _now = now.hour * 60 * ONE_MINUTE_TO_DRAW +
            now.minute * ONE_MINUTE_TO_DRAW.toDouble();
    }

    double leftOffsetStart;
    double topOffsetEnd;
    double drawingWidth;
    double drawingHeight;

    static const int NUMBER_OF_HORIZONTAL_LINES = 5;
    static const double headerHeight = TIME_HEADER_HEIGHT;
    static const double channelWidth = CHANNEL_WIDTH;

    @override
    void paint(Canvas canvas, Size size) {
        leftOffsetStart = size.width * 0.07;
        topOffsetEnd = size.height * 0.9;
        drawingWidth = size.width * 0.93;
        drawingHeight = topOffsetEnd;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
            Paint()..color = hexToColor('#F1F3F5'));

        _drawSchedules(canvas, size);
        _drawChannelsTitle(canvas, size);
        _drawTimes(canvas, size);
        _drawCurrentTimeLine(canvas, _now, size);
    }

    @override
    bool shouldRepaint(ChartPainter old) => true;

    void _drawSchedules(ui.Canvas canvas, ui.Size size) {
        final paint = new Paint()
            ..color = Colors.white
            ..strokeWidth = 3.0;
        int i = 0;
        double height = CHANNEL_SCHEDULE_HEIGHT;
        final fontSize = 18.0;
        final marginLeft = 10.0;
        for (Channel channel in channels) {
            for (Schedule schedule in channel.schedules) {
                double rWidth = schedule.end - schedule.start - padding;
                double rLeft = schedule.start + padding - left + channelWidth;
                double rTop = i * height + i * padding - top + headerHeight;
                if (schedule.start - left + channelWidth > size.width) continue;
                if (schedule.end - left + channelWidth < 0) continue;
                if (rTop > size.height) continue;
                if (rTop + height < headerHeight) continue;
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
                        color: _isTouch ? Colors.white : hexToColor('#323639'),
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto'),
                    text: schedule.name);
                TextPainter tp = new TextPainter(
                    maxLines: 1,
                    ellipsis: "..",
                    textDirection: TextDirection.ltr,
                    text: span,
                    textAlign: TextAlign.start);
                tp.layout(maxWidth: rWidth - 3 - marginLeft);
                ui.Rect rect = new ui.Rect.fromLTWH(rLeft, rTop, rWidth, height);
                paint.color = _isTouch ? Colors.blueGrey : Colors.white;
                ui.Path path = ui.Path();
                path.addRect(rect);
                canvas.drawShadow(path, Colors.black54, 1.5, true);
                canvas.drawRect(rect, paint);
                tp.paint(canvas,
                    new Offset(rLeft + marginLeft, rTop + height / 2 - fontSize / 2));
            }
            i++;
        }
    }

    void _drawChannelsTitle(ui.Canvas canvas, ui.Size size) {
        canvas.drawRect(Rect.fromLTWH(0, 0, channelWidth, size.height),
            new Paint()..color = hexToColor('#F1F3F5'));
        final paint = new Paint()
            ..color = Color(0xFFC3C4C5)
            ..strokeWidth = 3.0;
        int i = 0;
        double height = CHANNEL_SCHEDULE_HEIGHT;
        for (Channel channel in channels) {
            double rTop = i * height + i * padding - top + headerHeight;
            if (rTop > size.height) {
                i++;
                continue;
            }
            if (rTop + height < 0) {
                i++;
                continue;
            }
            ui.Rect rect = new ui.Rect.fromLTWH(5, rTop, channelWidth, height);
            ui.RRect rRect = new ui.RRect.fromRectAndCorners(rect,
                topLeft: Radius.circular(5.0), bottomLeft: Radius.circular(5.0));
            _drawRRectShadow(canvas, rRect);
            canvas.drawRRect(rRect, paint);
            if (channel.image != null) {
                int iWidth = channel.image.width;
                int iHeight = channel.image.height;
                int lOffset = 5 + (channelWidth.toInt() - iWidth) >> 1;
                int tOffset = (height.toInt() - iHeight) >> 1;
                canvas.drawImage(
                    channel.image,
                    Offset(lOffset.toDouble(), rTop + tOffset),
                    Paint()..filterQuality = FilterQuality.high);
            }
            i++;
        }
    }

    void _drawCurrentTimeLine(
        ui.Canvas canvas, double currentTime, ui.Size size) {
        final paint = new Paint()
            ..color = ColorList.colorBlue
            ..strokeWidth = 3.0;
        if (currentTime - left <= 0) return;
        canvas.drawLine(new Offset(currentTime - left + channelWidth, headerHeight),
            new Offset(currentTime - left + channelWidth, size.height), paint);
//        canvas.drawCircle(
//            new Offset(currentTime - left + channelWidth, headerHeight),
//            5.0,
//            paint);
        var cX = currentTime - left + channelWidth;
        var cY = headerHeight + 2;
        ui.Path path = Path();
        path.moveTo(cX, cY);
        path.lineTo(cX - 7.5, cY - 8.5);
        path.lineTo(cX + 7.5, cY - 8.5);
        path.lineTo(cX, cY);
        path.close();
        canvas.drawPath(
            path,
            Paint()
                ..color = ColorList.colorBlue
                ..style = PaintingStyle.fill);
    }

    void _drawTimes(ui.Canvas canvas, ui.Size size) {
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, headerHeight),
            new Paint()..color = hexToColor('#F1F3F5'));
        final paint = new Paint()
            ..color = Colors.black
            ..strokeWidth = 3.0;
        final maxWidth = 24 * 60.0 * ONE_MINUTE_TO_DRAW;
        final fontSize = 14.0;
        double currentDrawTime = (left +
            channelWidth / 2 -
            (left + channelWidth / 2) % (30 * ONE_MINUTE_TO_DRAW));
        while (currentDrawTime <= maxWidth) {
            int hour = currentDrawTime ~/ (60 * ONE_MINUTE_TO_DRAW);
            int minute = (currentDrawTime - hour * 60 * ONE_MINUTE_TO_DRAW) ~/
                ONE_MINUTE_TO_DRAW;
            TextSpan span = new TextSpan(
                style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hexToColor('#B0B3BC'),
                    fontSize: fontSize,
                    fontFamily: 'Roboto'),
                text:
                "${(hour > 9) ? "$hour" : "0$hour"}:${(minute > 9) ? "$minute" : "0$minute"}");
            TextPainter tp = new TextPainter(
                maxLines: 1,
                ellipsis: "..",
                textDirection: TextDirection.ltr,
                text: span,
                textAlign: TextAlign.center);
            tp.layout(maxWidth: channelWidth);
            tp.paint(
                canvas,
                new Offset(currentDrawTime - left + channelWidth - 10,
                    headerHeight / 2 - fontSize / 2));
            currentDrawTime += 30 * ONE_MINUTE_TO_DRAW;
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

    void _drawRectShadow(ui.Canvas canvas, ui.Rect rect) {
        canvas.drawShadow(Path()..addRect(rect), Colors.black87, 2, true);
    }

    void _drawRRectShadow(ui.Canvas canvas, ui.RRect rect) {
        canvas.drawShadow(Path()..addRRect(rect), Colors.black87, 2, true);
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
    String imageUrl;

    Channel(this.id, this.name, this.schedules, this.imageUrl);
}

class ImageLoader {
    static sky.AssetBundle getAssetBundle() => (sky.rootBundle != null)
        ? sky.rootBundle
        : new sky.NetworkAssetBundle(new Uri.directory(Uri.base.origin));

    static Future<ui.Image> load(String url, {bool isNetwork = false}) async {
        sky.ImageStream stream = !isNetwork
            ? new sky.AssetImage(url, bundle: getAssetBundle())
            .resolve(sky.ImageConfiguration(size: Size(100, 50)))
            : sky.NetworkImage(url, scale: 5).resolve(sky.ImageConfiguration.empty);
        Completer<ui.Image> completer = new Completer<ui.Image>();
        final sky.ImageStreamListener listener =
        sky.ImageStreamListener((frame, synchronousCall) async {
            ui.Image _image1 = frame.image;
            var newFrame = ImageInfo(image: _image1, scale: 0.1);
            completer.complete(newFrame.image);
        });
        stream.addListener(listener);
        return completer.future;
    }
}
