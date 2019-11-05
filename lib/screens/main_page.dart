import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:weight_tracker/logic/constants.dart';
import 'package:weight_tracker/widgets/date_picker_timeline/date_picker_timeline.dart';
import 'package:weight_tracker/widgets/general.dart' as general;
import 'package:weight_tracker/widgets/channel_schedule.dart';
import 'package:weight_tracker/logic/constants.dart' as cons;

class MainPageViewModel {
    final double defaultWeight;
    final bool hasEntryBeenAdded;
    final String unit;
    final Function() openAddEntryDialog;
    final Function() acceptEntryAddedCallback;

    MainPageViewModel({
        this.openAddEntryDialog,
        this.defaultWeight,
        this.hasEntryBeenAdded,
        this.acceptEntryAddedCallback,
        this.unit,
    });
}

class MainPage extends StatefulWidget {
    MainPage({Key key, this.title}) : super(key: key);
    final String title;

    @override
    State<MainPage> createState() {
        return new MainPageState();
    }
}

class MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
    TabController _tabController;
    TopUpdateListener _topUpdateListener;

    Widget appBarTitle = new Text("TV Guide", style: new TextStyle(color: Colors.black),);
    Icon actionIcon = new Icon(Icons.search, color: Colors.black,);

    @override
    void initState() {
        super.initState();
        _tabController = new TabController(vsync: this, length: 1);
        _topUpdateListener = (top) {
        };
    }

    @override
    void dispose() {
//    _scrollViewController.dispose();
        _tabController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: ColorList.colorBg
        ));
        return Scaffold(
            appBar: buildBar(context),
            backgroundColor: ColorList.colorBg,
            body: ConstrainedBox(
                constraints: BoxConstraints.expand(),
                child:  new Stack(
                    children: <Widget>[
                        new Positioned.fill(
                            left: 0.0,
                            right: 0.0,
                            top: DATE_HEIGHT,
                            child: new ChannelScheduleWidget(_topUpdateListener),
                        ),
                        new Positioned(
                            left: 0.0,
                            right: 0.0,
                            height: DATE_HEIGHT,
                            child: Container(
                                color: ColorList.colorBg,
                                child: DatePickerTimeline(
                                    DateTime.now(),
                                    height: DATE_HEIGHT,
                                    onDateChange: (date) {
                                        // New date selected
                                        print(date.day.toString());
                                    },
                                ),)
                        ), new Positioned(
                            left: 10.0,
                            right: 10.0,
                            height: 0.5,
                            top: DATE_HEIGHT,
                            child: Container(
                                height: 0.5,
                                color: Colors.grey,
                            ))],
                ),
            ),
        );
    }

    Widget buildBar(BuildContext context) {
        return new AppBar(
            centerTitle: false,
            title: appBarTitle,
            elevation: 0.0,
            brightness: Brightness.light,
            backgroundColor: ColorList.colorBg,
            leading: new Icon(Icons.menu, color: Colors.black,),
            actions: <Widget>[
                new IconButton(icon: actionIcon, onPressed: () {
                    setState(() {
                        if (this.actionIcon.icon == Icons.search) {
                            this.actionIcon = new Icon(Icons.close, color: Colors.black,);
                            this.appBarTitle = new TextField(
                                style: new TextStyle(
                                    color: Colors.black,

                                ),
                                decoration: new InputDecoration(
                                    prefixIcon: new Icon(Icons.search, color: Colors.black),
                                    hintText: "Search...",
                                    hintStyle: new TextStyle(color: Colors.black)
                                ),
                            );
                            _handleSearchStart();
                        }
                        else {
                            _handleSearchEnd();
                        }
                    });
                },),
            ]
        );
    }

    bool _IsSearching;
    String _searchText = "";

    void _handleSearchStart() {
        setState(() {
            _IsSearching = true;
        });
    }

    void _handleSearchEnd() {
        setState(() {
            this.actionIcon = new Icon(Icons.search, color: Colors.black,);
            this.appBarTitle =
            new Text("TV Guide", style: new TextStyle(color: Colors.black),);
            _IsSearching = false;
//      _searchQuery.clear();
        });
    }

//  _scrollToTop() {
//    _scrollViewController.animateTo(
//      0.0,
//      duration: const Duration(microseconds: 1),
//      curve: new ElasticInCurve(0.01),
//    );
//  }
}

class ChildItem extends StatelessWidget {
    final String name;
    ChildItem(this.name);
    @override
    Widget build(BuildContext context) {
        return new ListTile(title: new Text(this.name));
    }

}
