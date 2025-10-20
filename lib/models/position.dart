class Position {
  int? id;
  String name;
  int time;
  int rest;
  bool isFinished;


  Position({required this.name, required this.time, required this.rest, required this.isFinished, this.id});

  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
        id : map['id'] ?? null,
        name : map['name'],
        time : map['time'],
        rest : map['rest'],
        isFinished : map['isFinished'],
    );


  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      "name": name,
      "time": time,
      "rest": rest,
      "isFinished": isFinished
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}