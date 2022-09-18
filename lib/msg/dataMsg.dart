class DataMsg {
  String id;
  int time;
  String name;
  int size;
  int modified;

  DataMsg(this.id, this.time, this.name, this.size, this.modified);

  DataMsg.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        time = json['time'],
        name = json['name'],
        size = json['size'],
        modified = json['modified'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'name': name,
        'size': size,
        'modified': modified,
      };
}
