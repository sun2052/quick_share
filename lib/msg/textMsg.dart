class TextMsg {
  String id;
  int time;
  String content;

  TextMsg(this.id, this.time, this.content);

  TextMsg.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        time = json['time'],
        content = json['content'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'content': content,
      };
}
