enum DataWidgetType {
  label,
  button,
  indicator,
  temperature,
  fluid,
  voltage,
  current,
}

enum DataWidgetFontWeight {
  plain,
  bold,
  italic,
}

class DataWidget {
  String label;
  DataWidgetType type;
  int device;
  int instance;
  int id;
  int x;
  int y;
  int width;
  int height;
  int fontSize;
  DataWidgetFontWeight fontWeight;

  DataWidget({
    this.label = '',
    required this.type,
    this.device = 0,
    this.instance = 0,
    this.id = 0,
    this.x = 0,
    this.y = 0,
    this.width = 100,
    this.height = 50,
    this.fontSize = 12,
    this.fontWeight = DataWidgetFontWeight.plain,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'type': type.index,
    'device': device,
    'instance': instance,
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'font_size': fontSize,
    'font_weight': fontWeight.index,
  };

  factory DataWidget.fromJson(Map<String, dynamic> json) => DataWidget(
    label: json['label'] as String? ?? '',
    type: DataWidgetType.values[json['type'] as int? ?? 0],
    device: json['device'] as int? ?? 0,
    instance: json['instance'] as int? ?? 0,
    id: json['id'] as int? ?? 0,
    x: json['x'] as int? ?? 0,
    y: json['y'] as int? ?? 0,
    width: json['width'] as int? ?? 100,
    height: json['height'] as int? ?? 50,
    fontSize: json['font_size'] as int? ?? 12,
    fontWeight: DataWidgetFontWeight.values[json['font_weight'] as int? ?? 0],
  );

  DataWidget copyWith({
    String? label,
    DataWidgetType? type,
    int? device,
    int? instance,
    int? id,
    int? x,
    int? y,
    int? width,
    int? height,
    int? fontSize,
    DataWidgetFontWeight? fontWeight,
  }) => DataWidget(
    label: label ?? this.label,
    type: type ?? this.type,
    device: device ?? this.device,
    instance: instance ?? this.instance,
    id: id ?? this.id,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    fontSize: fontSize ?? this.fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
  );
}
