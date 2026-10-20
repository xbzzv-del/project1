import 'data_widget.dart';

class DataCard {
  String typeName;
  int width;
  int height;
  String name;
  List<DataWidget> dataWidgetList;

  DataCard({
    required this.typeName,
    this.width = 100,
    this.height = 100,
    this.name = '',
    this.dataWidgetList = const [],
  });

  Map<String, dynamic> toJson() => {
    'type_name': typeName,
    'width': width,
    'height': height,
    'name': name,
    'dataWidgetList': dataWidgetList.map((dw) => dw.toJson()).toList(),
  };

  factory DataCard.fromJson(Map<String, dynamic> json) => DataCard(
    typeName: json['type_name'] as String,
    width: json['width'] as int? ?? 100,
    height: json['height'] as int? ?? 100,
    name: json['name'] as String? ?? '',
    dataWidgetList: (json['dataWidgetList'] as List<dynamic>? ?? [])
        .map((dw) => DataWidget.fromJson(dw as Map<String, dynamic>))
        .toList(),
  );

  DataCard copyWith({
    String? typeName,
    int? width,
    int? height,
    String? name,
    List<DataWidget>? dataWidgetList,
  }) => DataCard(
    typeName: typeName ?? this.typeName,
    width: width ?? this.width,
    height: height ?? this.height,
    name: name ?? this.name,
    dataWidgetList: dataWidgetList ?? this.dataWidgetList,
  );

  DataCard copyFromType(DataCard typeCard, {String? name}) => DataCard(
    typeName: typeCard.typeName,
    width: typeCard.width,
    height: typeCard.height,
    name: name ?? this.name,
    dataWidgetList: typeCard.dataWidgetList.map((dw) => dw.copyWith()).toList(),
  );
}
