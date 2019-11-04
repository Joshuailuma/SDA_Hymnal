import 'package:flutter/material.dart';
import 'package:sda_hymnal/db/dbConnection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HymScreen extends StatefulWidget {
  final String title;
  final int number;
  final String content;

  HymScreen({this.title, this.number, this.content});

  @override
  _HymScreenState createState() => _HymScreenState();
}

class _HymScreenState extends State<HymScreen> {
  TextEditingController numberController;
  bool _loading;
  double globalFontRatio;
  // Color favColor;
  bool isAFavorite;

  @override
  void initState() {
    super.initState();
    numberController = TextEditingController();
    _loading = false;
    globalFontRatio = 1;
    isAFavorite = false;

//since isFAvorite is async it will be executed after initState
    isFavorite(widget.number).then((value) {
      print("favorite is $value");

      setState(() {
        isAFavorite = value;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    numberController.dispose();
  }

//the sharedpreferences enable us to remember if a hym is favorite or not and based on its value we can set the color
//of the favorite icon
  setFavorite(number) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(number.toString(), number);
  }

  removeFavorite(number) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.remove(number.toString());
  }

  Future<bool> isFavorite(number) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(number.toString())) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primarySwatch: Colors.green,
          primaryIconTheme: IconThemeData(color: Colors.white),
          appBarTheme: AppBarTheme(
              textTheme: TextTheme(
                  title: TextStyle(color: Colors.white, fontSize: 20)))),
      title: 'Hym Screen',
      home: Scaffold(
        drawer: Drawer(),
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          automaticallyImplyLeading: true,
        ),
        body: SingleChildScrollView(
          child: Container(
              child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    color: Colors.green,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        NavigateButton(
                            icon: Icons.arrow_back,
                            tooltip: "previous",
                            onClick: () async {
                              loadHym(widget.number - 1);
                            }),
                        NavigateButton(
                          tooltip: "zoom out",
                          icon: Icons.zoom_out,
                          onClick: () {
                            //decrease font size
                            if (globalFontRatio > 1) {
                              setState(() {
                                globalFontRatio -= 0.2;
                              });
                            }
                          },
                        ),
                        NavigateButton(
                          icon: Icons.favorite,
                          tooltip: "add to favorites",
                          color: isAFavorite ? Colors.pink[600] : Colors.white,
                          onClick: () async {
                            setState(() {
                              _loading = true;
                            });
                            if (!isAFavorite) {
                              //add to favorite
                              await DBConnect().addFavorite(widget.number);
                              setState(() {
                                isAFavorite = true;
                              });

                              await setFavorite(widget.number);

                              setState(() {
                                _loading = false;
                              });
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return SimpleDialog(
                                      title: Text(
                                        "Added Favorite",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      children: <Widget>[
                                        Text(
                                          "Hym ${widget.number.toString()} was succesfully added to favorites",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    );
                                  });
                            } else {
                              await DBConnect().removeFavorite(widget.number);
                              setState(() {
                                isAFavorite = false;
                              });

                              await removeFavorite(widget.number);

                              setState(() {
                                _loading = false;
                              });
                            }
                          },
                        ),
                        NavigateButton(
                          icon: Icons.zoom_in,
                          tooltip: "zoom in",
                          onClick: () {
                            //increase font size
                            if (globalFontRatio < 2) {
                              setState(() {
                                globalFontRatio += 0.2;
                              });
                            }
                          },
                        ),
                        NavigateButton(
                            icon: Icons.arrow_forward,
                            tooltip: "next",
                            onClick: () async {
                              //go to next hym
                              loadHym(widget.number + 1);
                            }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                        //numerical search bar here
                        children: [
                          Row(children: [
                            Expanded(
                              child: TextField(
                                controller: numberController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    hintText: "#",
                                    filled: true,
                                    fillColor: Colors.grey[300],
                                    contentPadding: EdgeInsets.all(10),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]))),
                              ),
                            ),
                            Padding(padding: EdgeInsets.only(left: 10)),
                            RaisedButton(
                              color: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    "Go",
                                    style: TextStyle(
                                        fontSize: 18 * globalFontRatio,
                                        color: Colors.white),
                                  ),
                                  Icon(
                                    Icons.navigate_next,
                                    size: 25,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              onPressed: () async {
                                if (numberController.text.isNotEmpty) {
                                  setState(() {
                                    _loading = true;
                                  });

                                  await DBConnect()
                                      .getHym(int.parse(numberController.text))
                                      .then((hym) {
                                    setState(() {
                                      _loading = false;
                                    });
                                    if (hym == null) {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return SimpleDialog(
                                              title: Text(
                                                "Hym not Found",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              children: <Widget>[
                                                Text(
                                                  "Sorry Hym ${numberController.text} was not found",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              ],
                                            );
                                          });
                                    } else {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) {
                                        return HymScreen(
                                            title: hym['title'],
                                            number: hym['number'],
                                            content: hym['verses']);
                                      }));
                                    }
                                  });
                                }
                              },
                            )
                          ]),
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Column(children: [
                              Text(
                                "${widget.number} - ${widget.title}",
                                style: TextStyle(
                                    fontSize: 22 * globalFontRatio,
                                    fontWeight: FontWeight.w900),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 20),
                              ),
                              Text(
                                widget.content,
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 17 * globalFontRatio),
                              )
                            ]),
                          )
                        ]),
                  )
                ],
              ),
              _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.green,
                        strokeWidth: 5,
                      ),
                    )
                  : Container()
            ],
          )),
        ),
      ),
    );
  }

  loadHym(int number) async {
    setState(() {
      _loading = true;
    });

    await DBConnect().getHym(number).then((hym) {
      setState(() {
        _loading = false;
      });
      if (hym == null) {
        showDialog(
            context: context,
            builder: (context) {
              return SimpleDialog(
                title: Text(
                  "Hym not Found",
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                children: <Widget>[
                  Text(
                    "Sorry Hym ${number.toString()} was not found",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  )
                ],
              );
            });
      } else {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return HymScreen(
              title: hym['title'],
              number: hym['number'],
              content: hym['verses']);
        }));
      }
    });
  }
}

class NavigateButton extends StatelessWidget {
  final IconData icon;
  final Function onClick;
  final Color color;
  final String tooltip;

  NavigateButton({this.icon, this.onClick, this.color, this.tooltip});
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Tooltip(
        decoration: BoxDecoration(color: Colors.green.withOpacity(.85)),
        message: this.tooltip ?? "",
        child: FlatButton(
            child: Icon(
              this.icon,
              color: this.color ?? Colors.white,
            ),
            color: Colors.green,
            // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            // padding: EdgeInsets.all(15),
            onPressed: this.onClick),
      ),
    );
  }
}
