class LayoutSettings {
  String backgroundColor;
  String buttonFgColor;
  String buttonBgColor;
  String text1Color;
  String text2Color;
  String text1FontFamily;
  String text2FontFamily;

  LayoutSettings({
    this.backgroundColor = '#ffffff',
    this.buttonFgColor = '#000000',
    this.buttonBgColor = '#cccccc',
    this.text1Color = '#000000',
    this.text2Color = '#000000',
    this.text1FontFamily = 'Arial',
    this.text2FontFamily = 'Arial',
  });

  Map<String, dynamic> toJson() => {
    'background_color': backgroundColor,
    'button_fg_color': buttonFgColor,
    'button_bg_color': buttonBgColor,
    'text1_color': text1Color,
    'text2_color': text2Color,
    'text1_font_family': text1FontFamily,
    'text2_font_family': text2FontFamily,
  };

  factory LayoutSettings.fromJson(Map<String, dynamic> json) => LayoutSettings(
    backgroundColor: json['background_color'] as String? ?? '#ffffff',
    buttonFgColor: json['button_fg_color'] as String? ?? '#000000',
    buttonBgColor: json['button_bg_color'] as String? ?? '#cccccc',
    text1Color: json['text1_color'] as String? ?? '#000000',
    text2Color: json['text2_color'] as String? ?? '#000000',
    text1FontFamily: json['text1_font_family'] as String? ?? 'Arial',
    text2FontFamily: json['text2_font_family'] as String? ?? 'Arial',
  );

  LayoutSettings copyWith({
    String? backgroundColor,
    String? buttonFgColor,
    String? buttonBgColor,
    String? text1Color,
    String? text2Color,
    String? text1FontFamily,
    String? text2FontFamily,
  }) => LayoutSettings(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    buttonFgColor: buttonFgColor ?? this.buttonFgColor,
    buttonBgColor: buttonBgColor ?? this.buttonBgColor,
    text1Color: text1Color ?? this.text1Color,
    text2Color: text2Color ?? this.text2Color,
    text1FontFamily: text1FontFamily ?? this.text1FontFamily,
    text2FontFamily: text2FontFamily ?? this.text2FontFamily,
  );
}
