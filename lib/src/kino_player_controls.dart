import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'kino_player_control.dart';
import 'kino_player_controller.dart';
import 'kino_player_event.dart';
import 'kino_player_event_type.dart';

class KinoPlayerControls extends StatefulWidget {
  @override
  _KinoPlayerControlsState createState() => _KinoPlayerControlsState();
}

class _KinoPlayerControlsState extends State<KinoPlayerControls> {
  KinoPlayerController _kinoPlayerController;
  bool _hideControlls = false;
  Timer _hideTimer;
  Timer _timeUpdateTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    print("DID CHANGE DEPS!!!");
    _kinoPlayerController = KinoPlayerController.of(context);
    _kinoPlayerController.addListener(_updateListener);
    if (_kinoPlayerController.videoPlayerController.value.isPlaying) {
      print("Setup hide timer");
      _setupTimers();
    }
    super.didChangeDependencies();
  }

  VideoPlayerController getVideoPlayerController() {
    return _kinoPlayerController.videoPlayerController;
  }

  void _updateListener() {
    print("Kino player controller updated!");
    var event = _kinoPlayerController.value;
    if (event != null && event.eventType == KinoPlayerEventType.SHOW_CONTROLS) {
      _cancelTimers();
      setState(() {
        print("Show controls");
        _hideControlls = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        opacity: _hideControlls ? 0.0 : 1.0,
        duration: Duration(milliseconds: 500),
        child: AspectRatio(
            aspectRatio: getVideoPlayerController().value.aspectRatio,
            child: Stack(
              children: [
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(children: _buildProgressRowWidgets()),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _buildBottomRowControlWidgets())
                        ])),
                Align(
                    alignment: Alignment.center, child: _getMiddlePlayWidget())
              ],
            )));

    /* child: Align(
                alignment: Alignment.bottomCenter,
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Row(children: _buildProgressRowWidgets()),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _buildBottomRowControlWidgets())
                ]))));*/
  }

  void _onPauseClicked() {
    if (!_hideControlls) {
      print("On pause clicked");
      _cancelTimers();
      getVideoPlayerController().pause();
      setState(() {});
    }
  }

  void _onPlayClicked() {
    if (!_hideControlls) {
      print("On play clicked");
      _setupTimers();
      getVideoPlayerController().play();
      setState(() {});
    }
  }

  void _onReplayClicked() {
    _kinoPlayerController.setPositionToStart();
    Timer(Duration(milliseconds: 2000), () {
      _onPlayClicked();
    });
    //_onPlayClicked();
  }

  Widget _getMiddlePlayWidget() {
    if (_kinoPlayerController.isVideoFinished()) {
      return _getControlButton(Icons.replay, () {
        _onReplayClicked();
      }, height: 80, width: 80, iconSize: 60);
    }

    if (!_kinoPlayerController.videoPlayerController.value.isPlaying) {
      return _getControlButton(Icons.play_circle_outline, () {
        _onPlayClicked();
      }, height: 80, width: 80, iconSize: 60);
    }

    return null;
  }

  List<Widget> _buildProgressRowWidgets() {
    List<KinoPlayerControl> controls =
        _kinoPlayerController.kinoPlayerConfiguration.playerControls;
    List<Widget> widgets = List();
    if (controls.contains(KinoPlayerControl.PROGRESS)) {
      widgets.add(Padding(
        padding: EdgeInsets.only(left: 10),
      ));
      widgets.add(_getProgressIndicatorWidget());
      widgets.add(Padding(
        padding: EdgeInsets.only(right: 10),
      ));
    }
    if (controls.contains(KinoPlayerControl.TIME)) {
      widgets.add(_getTimeWidget());
    }
    if (widgets.length > 0) {
      widgets.insert(
          0,
          Padding(
            padding: EdgeInsets.only(left: 10),
          ));
    }

    return widgets;
  }

  List<Widget> _buildBottomRowControlWidgets() {
    List<KinoPlayerControl> controls =
        _kinoPlayerController.kinoPlayerConfiguration.playerControls;
    List<Widget> widgets = List();
    if (controls.contains(KinoPlayerControl.VOLUME)) {
      widgets.add(_getVolumeWidget());
    }
    if (controls.contains(KinoPlayerControl.SKIP_PREVIOUS)) {
      widgets.add(_getSkipPreviousWidget());
    }
    if (controls.contains(KinoPlayerControl.REWIND)) {
      widgets.add(_getRewindWidget());
    }

    if (controls.contains(KinoPlayerControl.PLAY_AND_PAUSE)) {
      widgets.add(_getPlayPauseWidget());
    }
    if (controls.contains(KinoPlayerControl.FORWARD)) {
      widgets.add(_getForwardWidget());
    }
    if (controls.contains(KinoPlayerControl.SKIP_NEXT)) {
      widgets.add(_getSkipNextWidget());
    }
    if (controls.contains(KinoPlayerControl.FULLSCREEN)) {
      widgets.add(_getFullscreenWidget());
    }

    return widgets;
  }

  Widget _getProgressIndicatorWidget() {
    return Expanded(
        child: VideoProgressIndicator(
      getVideoPlayerController(),
      allowScrubbing: true,
    ));
  }

  Widget _getTimeWidget() {
    return Padding(
        padding: EdgeInsets.all(5),
        child: Text(
          _getTimeLeft(),
          style: TextStyle(color: Colors.blue),
        ));
  }

  Widget _getVolumeWidget() {
    return _getControlButton(Icons.volume_up, () {
      print("Click!");
      _kinoPlayerController
          .setEvent(KinoPlayerEvent(KinoPlayerEventType.OPEN_VOLUME_PICKER));
    });
  }

  Widget _getPlayPauseWidget() {
    if (getVideoPlayerController().value.isPlaying) {
      return _getControlButton(Icons.pause, () {
        _onPauseClicked();
      });
    } else {
      return _getControlButton(Icons.play_arrow, () {
        _onPlayClicked();
      });
    }
  }

  _getFullscreenWidget() {
    if (_kinoPlayerController.fullScreen) {
      return _getControlButton(Icons.fullscreen_exit, () {
        _cancelTimers();
        _kinoPlayerController.setFullscreen(false);
        Navigator.of(context).pop();
      });
    } else {
      return _getControlButton(Icons.fullscreen, () {
        _cancelTimers();
        _kinoPlayerController.setFullscreen(true);
        setState(() {});
      });
    }
  }

  _cancelTimers() {
    print("Cancel timers");
    if (_timeUpdateTimer != null && _timeUpdateTimer.isActive) {
      print("Time update timer cancelled");
      _timeUpdateTimer.cancel();
      _timeUpdateTimer = null;
    }
    if (_hideTimer != null && _hideTimer.isActive) {
      print("Hide timer cancelled");
      _hideTimer.cancel();
      _hideTimer = null;
    }
  }

  _getRewindWidget() {
    return _getControlButton(Icons.fast_rewind, () {
      bool timersSet = _areTimersSet();
      if (timersSet) {
        _cancelTimers();
        _kinoPlayerController.rewind();
        _setupTimers();
      } else {
        _kinoPlayerController.rewind();
      }
    });
  }

  bool _areTimersSet() {
    return _hideTimer != null && _timeUpdateTimer != null;
  }

  _getForwardWidget() {
    return _getControlButton(Icons.fast_forward, () {
      bool timersSet = _areTimersSet();
      if (timersSet) {
        _cancelTimers();
        _kinoPlayerController.forward();
        _setupTimers();
      } else {
        _kinoPlayerController.forward();
      }
    });
  }

  _getSkipPreviousWidget() {
    return _getControlButton(Icons.skip_previous, () {
      setState(() {});
    });
  }

  _getSkipNextWidget() {
    return _getControlButton(Icons.skip_next, () {
      setState(() {});
    });
  }

  _getSettingsWidget() {
    return _getControlButton(Icons.settings, () {
      setState(() {});
    });
  }

  String _getTimeLeft() {
    print("GET TIME LEFT!!");
    Duration currentDuration = getVideoPlayerController().value.position;
    Duration videoDuration = getVideoPlayerController().value.duration;
    if (currentDuration != null && videoDuration != null) {
      Duration remainingDuration = videoDuration - currentDuration;
      int minutes = remainingDuration.inMinutes;
      int seconds = remainingDuration.inSeconds - 60 * minutes;
      String secondsFormatted = "$seconds";
      if (seconds < 10) {
        secondsFormatted = "0$secondsFormatted";
      }
      return "-$minutes:$secondsFormatted";
    }

    return "-0:00";
  }

  void _setupTimers() {
    _cancelTimers();

    _timeUpdateTimer =
        Timer.periodic(Duration(milliseconds: 900), (Timer timer) {
      print("TIMER INVOKED FROM " + hashCode.toString());

      if (this.mounted && timer.isActive) {
        print("Refresh state!");
        setState(() {});
      } else {
        print("Not mounted and not active");
      }
    });
    _hideTimer = Timer(Duration(milliseconds: 5000), () {
      print("HIDE HIDE HIDE HIDE!!!");
      _cancelTimers();
      setState(() {
        _hideControlls = true;
      });
    });
  }

  Widget _getControlButton(IconData icon, Function onPressedAction,
      {double height = 35, double width = 35, double iconSize = 25}) {
    return Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: CircleBorder(),
          child: Container(
              width: width,
              height: height,
              child: Icon(
                icon,
                size: iconSize,
                color: Colors.blue,
              )),
          onTap: () {
            onPressedAction();
          },
        ));
  }
}
