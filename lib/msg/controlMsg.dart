class ControlMsg {
  int type;
  String id;
  String name;
  int device;

  ControlMsg(this.type, this.id, this.name, this.device);

  ControlMsg.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        id = json['id'],
        name = json['name'],
        device = json['device'];

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'name': name,
        'device': device,
      };
}
