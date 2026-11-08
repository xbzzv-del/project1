import 'data_widget.dart';

class DataCard {
  String typeName;
  int width;
  int height;
  String name;
  bool startup;
  List<DataWidget> dataWidgetList;

  DataCard({
    required this.typeName,
    this.width = 100,
    this.height = 100,
    this.name = '',
    this.startup = false,
    this.dataWidgetList = const [],
  });

  Map<String, dynamic> toJson() => {
    'type_name': typeName,
    'width': width,
    'height': height,
    'name': name,
    'startup': startup,
    'dataWidgetList': dataWidgetList.map((dw) => dw.toJson()).toList(),
  };

  factory DataCard.fromJson(Map<String, dynamic> json) => DataCard(
    typeName: json['type_name'] as String,
    width: json['width'] as int? ?? 100,
    height: json['height'] as int? ?? 100,
    name: json['name'] as String? ?? '',
    startup: json['startup'] as bool? ?? false,
    dataWidgetList: (json['dataWidgetList'] as List<dynamic>? ?? [])
        .map((dw) => DataWidget.fromJson(dw as Map<String, dynamic>))
        .toList(),
  );

  DataCard copyWith({
    String? typeName,
    int? width,
    int? height,
    String? name,
    bool? startup,
    List<DataWidget>? dataWidgetList,
  }) => DataCard(
    typeName: typeName ?? this.typeName,
    width: width ?? this.width,
    height: height ?? this.height,
    name: name ?? this.name,
    startup: startup ?? this.startup,
    dataWidgetList: dataWidgetList ?? this.dataWidgetList,
  );

  static List<DataCard> getDefaultTypes() => [
    DataCard(
      typeName: 'tablet',
      width: 1280,
      height: 800,
      name: 'tablet',
    ),
    DataCard(
      typeName: 'phone',
      width: 375,
      height: 667,
      name: 'phone',
    ),
  ];
}
