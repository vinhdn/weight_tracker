import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:weight_tracker/logic/constants.dart';
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
//  ScrollController _scrollViewController;
  TabController _tabController;
  double _top = 0;
  TopUpdateListener _topUpdateListener;

  Widget appBarTitle = new Text("Search Sample", style: new TextStyle(color: Colors.white),);
  Icon actionIcon = new Icon(Icons.search, color: Colors.white,);

  @override
  void initState() {
    super.initState();
//    _scrollViewController = new ScrollController();
    _tabController = new TabController(vsync: this, length: 1);
    _topUpdateListener = (top) {
      _top = top;
//      _scrollViewController.jumpTo(_top);
    };
//    _scrollViewController.addListener(listener)
  }

  @override
  void dispose() {
//    _scrollViewController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBar(context),
      body: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child:  new Stack(
          children: <Widget>[
            new Positioned.fill(
              left: 0.0,
              right: 0.0,
              child: new ChannelScheduleWidget(_topUpdateListener),
            ),
//            GestureDetector(
//          behavior: HitTestBehavior.translucent,
//            child:
//            Container(
//              width: CHANNEL_WIDTH.toDouble(),
//              margin: EdgeInsets.only(top: cons.TIME_HEADER_HEIGHT),
//              color: cons.ColorList.colorBg,
//                  child: ListView.builder(
//                itemBuilder: (context, index) {
//                  return new Container(
//                    width: CHANNEL_WIDTH.toDouble(),
//                    height: CHANNEL_SCHEDULE_HEIGHT.toDouble(),
//                    margin: const EdgeInsets.only(bottom: 7, right: 0, left: 10),
//                    decoration: BoxDecoration(
//                      color: general.hexToColor('#C3C4C5'),
//                      borderRadius: general.borderLeft(radius: 2.0),
//                      boxShadow: general.boxShadow,
//                    ),
//                    child: Image.network(
//                      'https://upload.wikimedia.org/wikipedia/commons/f/fc/Logo_VTV1_HD.png',
//                      width: CHANNEL_WIDTH.toDouble(),
//                      height: CHANNEL_SCHEDULE_HEIGHT.toDouble(),
//                    ),
//                  );
//                },
//                itemCount: 20,
//                shrinkWrap: false,
//                controller: _scrollViewController,
//              )),)
          ],
        ),
      ),
    );
  }

  Widget buildBar(BuildContext context) {
    return new AppBar(
        centerTitle: true,
        title: appBarTitle,
        actions: <Widget>[
          new IconButton(icon: actionIcon, onPressed: () {
            setState(() {
              if (this.actionIcon.icon == Icons.search) {
                this.actionIcon = new Icon(Icons.close, color: Colors.white,);
                this.appBarTitle = new TextField(
//                  controller: _searchQuery,
                  style: new TextStyle(
                    color: Colors.white,

                  ),
                  decoration: new InputDecoration(
                      prefixIcon: new Icon(Icons.search, color: Colors.white),
                      hintText: "Search...",
                      hintStyle: new TextStyle(color: Colors.white)
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
      this.actionIcon = new Icon(Icons.search, color: Colors.white,);
      this.appBarTitle =
      new Text("Search Sample", style: new TextStyle(color: Colors.white),);
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
