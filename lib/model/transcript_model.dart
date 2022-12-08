class TranscriptModel {
  TranscriptModel({
    this.timeStart,
    this.timeEnd,
    this.text,
    this.isHighlighted = false,
  });

  TranscriptModel.fromJson(dynamic json) {
    timeStart = json['time_start'];
    timeEnd = json['time_end'];
    text = json['text'];
  }

  int? timeStart;
  int? timeEnd;
  String? text;
  bool? isHighlighted;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['time_start'] = timeStart;
    map['time_end'] = timeEnd;
    map['text'] = text;
    return map;
  }
}
