import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';
import 'dart:async';

void main() =>runApp(Audiorecorder());

class Audiorecorder extends StatefulWidget {
  @override
  _AudiorecorderState createState() => _AudiorecorderState();
}

class _AudiorecorderState extends State<Audiorecorder> {
  bool _isRecording = false;
  bool _isPlaying = false;
  StreamSubscription _recorderSubscription;
  StreamSubscription _dbPeakSubscription;
  StreamSubscription _playerSubscription;
  // ignore: deprecated_member_use
  FlutterSound flutterSound;

  String _recorderTxt = '00:00:00';
  String _playerTxt = '00:00:00';
  double _dbLevel;

  double slider_current_position = 0.0;
  double max_duration = 1.0;

  @override
  void initState() {
    super.initState();
    flutterSound = new FlutterSound();
    flutterSound.setSubscriptionDuration(0.01);
    flutterSound.setDbPeakLevelUpdate(0.8);
    flutterSound.setDbLevelEnabled(true);
    initializeDateFormatting();
  }

  void startRecorder() async {
    try {
      String path = await flutterSound.startRecorder();
      print('startRecorder: $path');

      _recorderSubscription = flutterSound.onRecorderStateChanged.listen((e) {
        DateTime date = new DateTime.fromMillisecondsSinceEpoch(
            e.currentPosition.toInt(),
            isUtc: true);
        String txt = DateFormat('mm:ss:SS', 'pt_BR').format(date);

        this.setState(() {
          this._recorderTxt = txt.substring(0, 8);
        });
      });
      _dbPeakSubscription =
          flutterSound.onRecorderDbPeakChanged.listen((value) {
            print("got update -> $value");
            setState(() {
              this._dbLevel = value;
            });
          });

      this.setState(() {
        this._isRecording = true;
      });
    } catch (err) {
      print('startRecorder error: $err');
    }
  }

  void stopRecorder() async {
    try {
      String result = await flutterSound.stopRecorder();
      print('stopRecorder: $result');

      if (_recorderSubscription != null) {
        _recorderSubscription.cancel();
        _recorderSubscription = null;
      }
      if (_dbPeakSubscription != null) {
        _dbPeakSubscription.cancel();
        _dbPeakSubscription = null;
      }

      this.setState(() {
        this._isRecording = false;
      });
    } catch (err) {
      print('stopRecorder error: $err');
    }
  }

  void startPlayer() async {
    String path = await flutterSound.startPlayer('/data/user/0/com.example.flutterapp/cache/flauto.aac');
    await flutterSound.setVolume(1.0);
    print('startPlayer: $path');

    try {
      _playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
        if (e != null) {
          slider_current_position = e.currentPosition;
          max_duration = e.duration;

          DateTime date = new DateTime.fromMillisecondsSinceEpoch(
              e.currentPosition.toInt(),
              isUtc: true);
          String txt = DateFormat('mm:ss:SS', 'pt_BR').format(date);
          this.setState(() {
            this._isPlaying = true;
            this._playerTxt = txt.substring(0, 8);
          });
        }
      });
    } catch (err) {
      print('error: $err');
    }
  }

  void stopPlayer() async {
    try {
      String result = await flutterSound.stopPlayer();
      print('stopPlayer: $result');
      if (_playerSubscription != null) {
        _playerSubscription.cancel();
        _playerSubscription = null;
      }

      this.setState(() {
        this._isPlaying = false;
      });
    } catch (err) {
      print('error: $err');
    }
  }

  void pausePlayer() async {
    String result = await flutterSound.pausePlayer();
    print('pausePlayer: $result');
  }

  void resumePlayer() async {
    String result = await flutterSound.resumePlayer();
    print('resumePlayer: $result');
  }

  void seekToPlayer(int milliSecs) async {
    String result = await flutterSound.seekToPlayer(milliSecs);
    print('seekToPlayer: $result');
  }
  String selectedVoice = 'normal';
  List<String> voiceTypes= ['normal','lorie','terror','uncle','funny','vacant'];
  DropdownButton<String> androidDropdown() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (String voice in voiceTypes) {
      var newItem = DropdownMenuItem(
        child: Text(voice),
        value: voice,
      );
      dropdownItems.add(newItem);
    }

    return DropdownButton<String>(
      value: selectedVoice,
      items: dropdownItems,
      onChanged: (value) {
        setState(() {
          selectedVoice = value;
        });
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.pink),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Voice Changer'),
        ),
        body: ListView(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 24.0, bottom: 16.0),
                  child: Text(
                    this._recorderTxt,
                    style: TextStyle(
                      fontSize: 48.0,
                      color: Colors.black,
                    ),
                  ),
                ),
                _isRecording
                    ? LinearProgressIndicator(
                  value: 100.0 / 160.0 * (this._dbLevel ?? 1) / 100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  backgroundColor: Colors.red,
                )
                    : Container()
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  width: 56.0,
                  height: 56.0,
                  margin: EdgeInsets.all(10.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      if (!this._isRecording) {
                        return this.startRecorder();
                      }
                      this.stopRecorder();
                    },
                    child:
                    this._isRecording ? Icon(Icons.stop) : Icon(Icons.mic),
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 60.0, bottom: 16.0),
                  child: Text(
                    this._playerTxt,
                    style: TextStyle(
                      fontSize: 48.0,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  width: 56.0,
                  height: 56.0,
                  margin: EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      startPlayer();
                    },
                    child: Icon(Icons.play_arrow),
                  ),
                ),
                Container(
                  width: 56.0,
                  height: 56.0,
                  margin: EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      pausePlayer();
                    },
                    child: Icon(Icons.pause),
                  ),
                ),
                Container(
                  width: 56.0,
                  height: 56.0,
                  margin: EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      stopPlayer();
                    },
                    child: Icon(Icons.stop),
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            Container(
                height: 56.0,
                child: Slider(
                    value: slider_current_position,
                    min: 0.0,
                    max: max_duration,
                    onChanged: (double value) async {
                      await flutterSound.seekToPlayer(value.toInt());
                    },
                    divisions: max_duration.toInt())),
            Center(
              child: Container(
                width: 200,
                padding: EdgeInsets.all(15.0),
                margin: EdgeInsets.all(15.0),
                child: androidDropdown(),
                decoration: BoxDecoration(
                  color:Colors.pink,
                  borderRadius: BorderRadius.circular(10.0)

                )
              ),
            )
          ],
        ),
      ),
    );
  }
}


