import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:videoplayer/screens/widget/texthighlight.dart';

import '../model/transcript_model.dart';
import 'widget/controloverlay.dart';

class VideoPLayerScreen extends StatefulWidget {
  const VideoPLayerScreen({Key? key}) : super(key: key);

  @override
  State<VideoPLayerScreen> createState() => _VideoPLayerScreenState();
}

class _VideoPLayerScreenState extends State<VideoPLayerScreen> {
  late VideoPlayerController controller;
  String transcript = '';
  String currentHighlightedText = '';
  List<TranscriptModel> transcripts = [];
  ScrollController _scrollController = new ScrollController();
  double scrollOffset = 0.0;
  double additionalOffset = 0.0;
  @override
  void initState() {
    super.initState();
    readTranscriptFromJson();
    controller = VideoPlayerController.asset("assets/video/displaynow.mp4");

    controller.addListener(() async {
      print(
          'addListener():: MilliSeconds:: ${controller.value.position.inMilliseconds}/${controller.value.duration.inMilliseconds}');
      if (controller.value.isPlaying) {
        await _updateTranscriptHighlight(
            controller.value.position.inMilliseconds);
      } else if (controller.value.position.inMilliseconds ==
          controller.value.duration.inMilliseconds) {
        scrollOffset = 0.0;
      }
      setState(() {});
    });
    controller.setLooping(false);
    controller.initialize().then((_) => setState(() {}));
    controller.play();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> readTranscriptFromJson() async {
    final String response =
        await rootBundle.loadString('assets/video_transcript.json');
    final data = await json.decode(response);
    if (data != null) {
      data.map((transcriptItem) {
        transcript = transcript + transcriptItem['text'];
        transcripts.add(TranscriptModel(
            timeStart: transcriptItem['time_start'],
            timeEnd: transcriptItem['time_end'],
            text: transcriptItem['text'],
            isHighlighted: false));
      }).toList();

      log('Transcript:: ${json.encode(transcripts)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 20,
            ),
            child: headerVideoSection()),
        videoTranscriptSection(),
      ]),
    );
  }

  Widget headerVideoSection() {
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          VideoPlayer(controller),
          ControlsOverlay(controller: controller),
          VideoProgressIndicator(controller, allowScrubbing: true),
        ],
      ),
    );
  }

  Widget videoTranscriptSection() {
    return Expanded(
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  right: 18.0,
                  left: 18,
                ),
                child: _buildTranscriptDetailWidget(
                    transcript != null ? transcript : '',
                    currentHighlightedText != null &&
                            currentHighlightedText.trim().length > 0
                        ? [currentHighlightedText]
                        : []),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptDetailWidget(String text, List<String> highlights) {
    return TextHighlighting(
      text: text,
      highlights: highlights,
      highlightColor: Colors.red, //AppColor.textColor2,
      textDirection: TextDirection.ltr,

      style: TextStyle(
        color: Colors.black, //AppColor.blackColor,
        fontFamily: 'SFProText',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      caseSensitive: false,
    );
  }

  _updateTranscriptHighlight(int currentMilliSecond) async {
    int? itemIndex = 0;
    TranscriptModel? currentTranscript;

    transcripts.map((transcript) {
      if (currentMilliSecond >= transcript.timeStart!.toInt() &&
          currentMilliSecond <= transcript.timeEnd!.toInt()) {
        if (!(transcript.isHighlighted ?? false)) {
          transcript.isHighlighted = true;
          currentTranscript = transcript;
          print('Highlighted:: >>>>>> ${transcript.text}');
          currentHighlightedText = transcript.text!.trim();
        }
        //return;
      } else {
        transcript.isHighlighted = false;
      }
    }).toList();

    if (currentTranscript != null) {
      itemIndex = transcripts.indexOf(currentTranscript!);
      currentHighlightedText = currentTranscript!.text!;
      currentHighlightedText = currentHighlightedText.trim();
    } else {}
    //for scroll
    if (scrollOffset == 0.0) {
      scrollOffset = additionalOffset;
    }
    int lineCount = currentHighlightedText.length ~/ 50;
    if (lineCount == 0) lineCount = 1;

    _scrollController.animateTo(scrollOffset,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    if (itemIndex! > 0) {
      scrollOffset = 0 + scrollOffset + (lineCount * 25).toDouble();
    }
    //scroll end
  }
}
