import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'models/data_card.dart';
import 'models/data_widget.dart';
import 'models/layout_settings.dart';
import 'widgets/project_settings_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DrawingApp());
}

class DrawingApp extends StatelessWidget {
  const DrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SizedBox(
        width: 1600,
        height: 1000,
        child: MainWindow(),
      ),
    );
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  final List<Offset?> _points = [];
  String _statusMessage = 'Ready';
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;
  String? _currentFilePath;
  List<DataCard> _dataCardTypes = [];
  LayoutSettings _layoutSettings = LayoutSettings();
  List<DataCard> _cardList = [];
  DataCard? _selectedCard;
  DataWidget? _selectedWidget;
  DataWidget? _draggingWidget;
  Offset? _dragStartOffset;
  Offset? _dragStartPosition;
  FocusNode _widgetListFocusNode = FocusNode();
  FocusNode _rightPaneFocusNode = FocusNode();
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataCardTypes = DataCard.getDefaultTypes();
    _widgetListFocusNode.addListener(() {
      if (!_widgetListFocusNode.hasFocus) {
        setState(() {
          _selectedWidget = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _widgetListFocusNode.dispose();
    _rightPaneFocusNode.dispose();
    _xController.dispose();
    _yController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
      _updateStatus('Canvas cleared');
    });
  }

  void _changeColor(Color color) {
    setState(() {
      _currentColor = color;
      _updateStatus('Color changed to ${color.toString().split('.').last}');
    });
  }

  void _changeStrokeWidth(double width) {
    setState(() {
      _strokeWidth = width;
      _updateStatus('Stroke width set to ${width.toStringAsFixed(1)}');
    });
  }

  void _quitApp() {
    SystemNavigator.pop();
  }

  void _showProjectSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProjectSettingsDialog(
          dataCardTypes: List.from(_dataCardTypes),
          layoutSettings: _layoutSettings,
          onDataCardTypesChanged: (List<DataCard> newDataCardTypes) {
            setState(() {
              _dataCardTypes = List.from(newDataCardTypes);
            });
          },
          onLayoutSettingsChanged: (LayoutSettings newLayoutSettings) {
            setState(() {
              _layoutSettings = newLayoutSettings;
            });
          },
        );
      },
    );
  }

  Map<String, dynamic> _pointsToJson() {
    final List<Map<String, dynamic>?> pointsList = [];
    for (final point in _points) {
      if (point != null) {
        pointsList.add({
          'x': point.dx,
          'y': point.dy,
        });
      } else {
        pointsList.add(null);
      }
    }
    return {
      'Points': pointsList,
      'color': _currentColor.value.toRadixString(16),
      'strokeWidth': _strokeWidth,
      'DataCardTypes': _dataCardTypes.map((dc) => dc.toJson()).toList(),
      'Layout': _layoutSettings.toJson(),
      'CardList': _cardList.map((c) => c.toJson()).toList(),
    };
  }

  void _pointsFromJson(Map<String, dynamic> json) {
    setState(() {
      _points.clear();
      final List<dynamic> pointsList = json['Points'] as List<dynamic>? ?? [];
      for (final item in pointsList) {
        if (item == null) {
          _points.add(null);
        } else {
          _points.add(Offset(
            (item['x'] as num).toDouble(),
            (item['y'] as num).toDouble(),
          ));
        }
      }
      if (json.containsKey('color')) {
        _currentColor = Color(int.parse(json['color'] as String, radix: 16));
      }
      if (json.containsKey('strokeWidth')) {
        _strokeWidth = (json['strokeWidth'] as num).toDouble();
      }
      if (json.containsKey('DataCardTypes')) {
        final List<dynamic> dataCardTypesList = json['DataCardTypes'] as List<dynamic>;
        _dataCardTypes = dataCardTypesList
            .map((dc) => DataCard.fromJson(dc as Map<String, dynamic>))
            .toList();
      } else {
        _dataCardTypes = DataCard.getDefaultTypes();
      }
      if (json.containsKey('Layout')) {
        _layoutSettings = LayoutSettings.fromJson(json['Layout'] as Map<String, dynamic>);
      } else {
        _layoutSettings = LayoutSettings();
      }
      if (json.containsKey('CardList')) {
        final List<dynamic> cardListData = json['CardList'] as List<dynamic>;
        _cardList = cardListData
            .map((c) => DataCard.fromJson(c as Map<String, dynamic>))
            .toList();
      } else {
        _cardList = [];
      }
      _selectedCard = null;
      _updateStatus('Loaded ${_points.where((p) => p != null).length} points');
    });
  }

  Future<void> _saveAs() async {
    try {
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Drawing',
        fileName: 'drawing.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (path != null && path.isNotEmpty) {
        await _saveToFile(path);
        _currentFilePath = path;
        _updateStatus('Saved to $path');
      }
    } catch (e) {
      _updateStatus('Error saving file: $e');
    }
  }

  Future<void> _save() async {
    if (_currentFilePath != null && _currentFilePath!.isNotEmpty) {
      await _saveToFile(_currentFilePath!);
      _updateStatus('Saved to $_currentFilePath');
    } else {
      await _saveAs();
    }
  }

  Future<void> _saveToFile(String path) async {
    final json = _pointsToJson();
    final file = File(path);
    await file.writeAsString(jsonEncode(json));
  }

  Future<void> _open() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Open Drawing',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        _pointsFromJson(json);
        _currentFilePath = result.files.first.path;
        _updateStatus('Opened $_currentFilePath');
      }
    } catch (e) {
      _updateStatus('Error opening file: $e');
    }
  }

  void _showOptionsMenu(BuildContext context, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(position, ancestor: overlay);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        overlay.size.width - offset.dx,
        overlay.size.height - offset.dy,
      ),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'clear',
          child: Text('Clear Canvas'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'color_black',
          child: Text('Black'),
        ),
        const PopupMenuItem<String>(
          value: 'color_red',
          child: Text('Red'),
        ),
        const PopupMenuItem<String>(
          value: 'color_blue',
          child: Text('Blue'),
        ),
        const PopupMenuItem<String>(
          value: 'color_green',
          child: Text('Green'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'stroke_thin',
          child: Text('Thin (2px)'),
        ),
        const PopupMenuItem<String>(
          value: 'stroke_medium',
          child: Text('Medium (5px)'),
        ),
        const PopupMenuItem<String>(
          value: 'stroke_thick',
          child: Text('Thick (10px)'),
        ),
      ],
    ).then((String? value) {
      if (value != null) {
        _handleOptionsMenuSelected(value);
      }
    });
  }

  void _handleOptionsMenuSelected(String value) {
    switch (value) {
      case 'clear':
        _clearCanvas();
        break;
      case 'color_black':
        _changeColor(Colors.black);
        break;
      case 'color_red':
        _changeColor(Colors.red);
        break;
      case 'color_blue':
        _changeColor(Colors.blue);
        break;
      case 'color_green':
        _changeColor(Colors.green);
        break;
      case 'stroke_thin':
        _changeStrokeWidth(2.0);
        break;
      case 'stroke_medium':
        _changeStrokeWidth(5.0);
        break;
      case 'stroke_thick':
        _changeStrokeWidth(10.0);
        break;
    }
  }

  void _selectCard(DataCard? card) {
    setState(() {
      _selectedCard = card;
    });
  }

  void _setStartup(bool? value) {
    if (_selectedCard == null || value == null) return;

    setState(() {
      if (value) {
        for (final card in _cardList) {
          card.startup = false;
        }
      }
      _selectedCard!.startup = value;
    });
  }

  Future<void> _addCard() async {
    if (_dataCardTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please define DataCard types in Settings first'),
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        DataCard? localSelectedType;
        final nameController = TextEditingController();
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add New Card'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter card name',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Text('Select DataCard Type:'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: _dataCardTypes.length,
                      itemBuilder: (context, index) {
                        final type = _dataCardTypes[index];
                        return ListTile(
                          title: Text(type.typeName),
                          selected: localSelectedType == type,
                          onTap: () {
                            localSelectedType = type;
                            setState(() {});
                          },
                          selectedTileColor: Colors.blue.withOpacity(0.1),
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: localSelectedType != null
                      ? () => Navigator.of(context).pop({
                          'name': nameController.text,
                          'type': localSelectedType,
                        })
                      : null,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final name = result['name'] as String?;
      final selectedType = result['type'] as DataCard?;
      if (name != null && selectedType != null) {
        final newCard = DataCard(
          typeName: selectedType.typeName,
          width: selectedType.width,
          height: selectedType.height,
          name: name,
          startup: false,
          dataWidgetList: selectedType.dataWidgetList.map((dw) => dw.copyWith()).toList(),
        );
        setState(() {
          _cardList.add(newCard);
          _selectedCard = newCard;
        });
      }
    }
  }

  Future<void> _deleteCard() async {
    if (_selectedCard == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Card'),
          content: Text('Are you sure you want to delete "${_selectedCard!.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _cardList.remove(_selectedCard!);
        _selectedCard = null;
      });
    }
  }

  void _updateCardName(String newName) {
    if (_selectedCard == null) return;
    setState(() {
      _selectedCard = _selectedCard!.copyWith(name: newName);
    });
  }

  Future<void> _addWidget() async {
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a card first')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        DataWidgetType? selectedType = DataWidgetType.label;
        final labelController = TextEditingController();
        int? selectedFontIndex = 0;
        DataWidgetFontWeight? selectedFontWeight = DataWidgetFontWeight.plain;
        int? selectedFontSize = 12;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Widget'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<DataWidgetType>(
                      value: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                      items: DataWidgetType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.toString().split('.').last),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedFontIndex,
                      onChanged: (value) {
                        setState(() {
                          selectedFontIndex = value;
                        });
                      },
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Text1 (${_layoutSettings.text1FontFamily})'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Text2 (${_layoutSettings.text2FontFamily})'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Font',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<DataWidgetFontWeight>(
                      value: selectedFontWeight,
                      onChanged: (value) {
                        setState(() {
                          selectedFontWeight = value;
                        });
                      },
                      items: DataWidgetFontWeight.values
                          .map((fw) => DropdownMenuItem(
                                value: fw,
                                child: Text(fw.toString().split('.').last),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Font Weight',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedFontSize,
                      onChanged: (value) {
                        setState(() {
                          selectedFontSize = value;
                        });
                      },
                      items: List.generate(30, (index) => 6 + index * 2)
                          .map((size) => DropdownMenuItem(
                                value: size,
                                child: Text(size.toString()),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Font Size',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop({
                    'type': selectedType,
                    'label': labelController.text,
                    'font': selectedFontIndex,
                    'fontWeight': selectedFontWeight,
                    'fontSize': selectedFontSize,
                  }),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final cardWidth = _selectedCard!.width;
      final cardHeight = _selectedCard!.height;
      
      // Calculate centered position for the new widget
      int widgetX = 0;
      int widgetY = 0;
      int widgetWidth = 150;
      int widgetHeight = 0;
      
      if (result['type'] as DataWidgetType == DataWidgetType.label) {
        // For labels, center them on the card
        widgetX = (cardWidth - widgetWidth) ~/ 2;
        widgetY = (cardHeight - widgetHeight) ~/ 2;
        
        // Calculate actual height based on font size
        final fontSize = result['fontSize'] as int? ?? 12;
        widgetHeight = fontSize + 10; // Approximate height
      }
      
      final newWidget = DataWidget(
        label: result['label'] as String? ?? '',
        type: result['type'] as DataWidgetType,
        fontSize: result['fontSize'] as int? ?? 12,
        fontWeight: result['fontWeight'] as DataWidgetFontWeight? ?? DataWidgetFontWeight.plain,
        x: widgetX,
        y: widgetY,
        width: widgetWidth,
        height: widgetHeight,
      );
      setState(() {
        final cardIndex = _cardList.indexOf(_selectedCard!);
        if (cardIndex != -1) {
          final updatedCard = _selectedCard!.copyWith(
            dataWidgetList: [..._selectedCard!.dataWidgetList, newWidget],
          );
          _cardList[cardIndex] = updatedCard;
          _selectedCard = updatedCard;
          _selectedWidget = newWidget;
        }
      });
    }
  }


  void _updateWidgetProperty(DataWidget widget, String property, int value) {
    if (_selectedCard == null || _selectedWidget == null) return;
    
    final widgetIndex = _selectedCard!.dataWidgetList.indexOf(widget);
    if (widgetIndex != -1) {
      DataWidget updatedWidget;
      switch (property) {
        case 'x':
          updatedWidget = widget.copyWith(x: value);
          _xController.text = value.toString();
          break;
        case 'y':
          updatedWidget = widget.copyWith(y: value);
          _yController.text = value.toString();
          break;
        case 'width':
          updatedWidget = widget.copyWith(width: value);
          _widthController.text = value.toString();
          break;
        case 'height':
          updatedWidget = widget.copyWith(height: value);
          _heightController.text = value.toString();
          break;
        default:
          return;
      }
      
      final widgets = List<DataWidget>.from(_selectedCard!.dataWidgetList);
      widgets[widgetIndex] = updatedWidget;
      final updatedCard = _selectedCard!.copyWith(dataWidgetList: widgets);
      
      setState(() {
        _cardList[_cardList.indexOf(_selectedCard!)] = updatedCard;
        _selectedCard = updatedCard;
        _selectedWidget = updatedWidget;
      });
    }
  }


  void _applyWidgetProperties() {
    if (_selectedWidget == null || _selectedCard == null) return;
    
    final x = int.tryParse(_xController.text) ?? _selectedWidget!.x;
    final y = int.tryParse(_yController.text) ?? _selectedWidget!.y;
    final width = int.tryParse(_widthController.text) ?? _selectedWidget!.width;
    final height = int.tryParse(_heightController.text) ?? _selectedWidget!.height;
    
    final widgetIndex = _selectedCard!.dataWidgetList.indexOf(_selectedWidget!);
    if (widgetIndex != -1) {
      final updatedWidget = _selectedWidget!.copyWith(
        x: x,
        y: y,
        width: width,
        height: height,
      );
      
      final widgets = List<DataWidget>.from(_selectedCard!.dataWidgetList);
      widgets[widgetIndex] = updatedWidget;
      final updatedCard = _selectedCard!.copyWith(dataWidgetList: widgets);
      
      setState(() {
        _cardList[_cardList.indexOf(_selectedCard!)] = updatedCard;
        _selectedCard = updatedCard;
        _selectedWidget = updatedWidget;
      });
    }
  }

  Future<void> _editWidget(DataWidget widget, int widgetIndex) async {
    if (_selectedCard == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        DataWidgetType? selectedType = widget.type;
        final labelController = TextEditingController(text: widget.label);
        int? selectedFontIndex = 0;
        DataWidgetFontWeight? selectedFontWeight = widget.fontWeight;
        int? selectedFontSize = widget.fontSize;

        final propertyWidgets = _buildWidgetPropertyWidgets(widget);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Edit Widget'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<DataWidgetType>(
                      value: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                      items: DataWidgetType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.toString().split('.').last),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    ...propertyWidgets,
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedFontIndex,
                      onChanged: (value) {
                        setState(() {
                          selectedFontIndex = value;
                        });
                      },
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Text1 (${_layoutSettings.text1FontFamily})'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Text2 (${_layoutSettings.text2FontFamily})'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Font',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<DataWidgetFontWeight>(
                      value: selectedFontWeight,
                      onChanged: (value) {
                        setState(() {
                          selectedFontWeight = value;
                        });
                      },
                      items: DataWidgetFontWeight.values
                          .map((fw) => DropdownMenuItem(
                                value: fw,
                                child: Text(fw.toString().split('.').last),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Font Weight',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedFontSize,
                      onChanged: (value) {
                        setState(() {
                          selectedFontSize = value;
                        });
                      },
                      items: List.generate(30, (index) => 6 + index * 2)
                          .map((size) => DropdownMenuItem(
                                value: size,
                                child: Text(size.toString()),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Font Size',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop({
                    'type': selectedType,
                    'label': labelController.text,
                    'font': selectedFontIndex,
                    'fontWeight': selectedFontWeight,
                    'fontSize': selectedFontSize,
                  }),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final updatedWidget = widget.copyWith(
        label: result['label'] as String? ?? widget.label,
        type: result['type'] as DataWidgetType? ?? widget.type,
        fontSize: result['fontSize'] as int? ?? widget.fontSize,
        fontWeight: result['fontWeight'] as DataWidgetFontWeight? ?? widget.fontWeight,
      );
      setState(() {
        final cardIndex = _cardList.indexOf(_selectedCard!);
        if (cardIndex != -1) {
          final widgets = List<DataWidget>.from(_selectedCard!.dataWidgetList);
          widgets[widgetIndex] = updatedWidget;
          final updatedCard = _selectedCard!.copyWith(dataWidgetList: widgets);
          _cardList[cardIndex] = updatedCard;
          _selectedCard = updatedCard;
        }
      });
    }
  }

  Color _parseColor(String hexColor) {
    try {
      if (hexColor.startsWith('#') && hexColor.length == 7) {
        return Color(int.parse(hexColor.substring(1), radix: 16) | 0xFF000000);
      }
    } catch (e) {}
    return Colors.black;
  }

  void _handleCanvasTapDown(TapDownDetails details) {
    if (_selectedCard == null) return;

    final cardRect = Rect.fromLTWH(
      (MediaQuery.of(context).size.width - _selectedCard!.width) / 2,
      (MediaQuery.of(context).size.height - _selectedCard!.height) / 2,
      _selectedCard!.width.toDouble(),
      _selectedCard!.height.toDouble(),
    );

    final localPosition = details.localPosition;
    
    // Check if tap is inside any widget
    for (final widget in _selectedCard!.dataWidgetList) {
      if (widget.type == DataWidgetType.label) {
        final widgetX = cardRect.left + widget.x.toDouble();
        final widgetY = cardRect.top + widget.y.toDouble();
        final actualWidth = widget.width > 0 ? widget.width.toDouble() : 150.0;
        
        // Calculate text height
        final textStyle = TextStyle(
          fontFamily: _layoutSettings.text1FontFamily,
          fontSize: widget.fontSize.toDouble(),
          color: _parseColor(_layoutSettings.text1Color),
        );
        final textPainter = TextPainter(
          text: TextSpan(text: widget.label, style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final actualHeight = textPainter.height + 10;

        final widgetRect = Rect.fromLTWH(widgetX, widgetY, actualWidth, actualHeight);
        
        if (widgetRect.contains(localPosition)) {
          setState(() {
            _selectedWidget = widget;
          });
          return;
        }
      }
    }

    // If tap is not on a widget, deselect
    setState(() {
      _selectedWidget = null;
      _dragStartOffset = null;
      _dragStartPosition = null;
      _draggingWidget = null;
    });
  }

  void _handleCanvasPanStart(DragStartDetails details) {
    if (_selectedCard == null || _selectedWidget == null) return;

    final cardRect = Rect.fromLTWH(
      (MediaQuery.of(context).size.width - _selectedCard!.width) / 2,
      (MediaQuery.of(context).size.height - _selectedCard!.height) / 2,
      _selectedCard!.width.toDouble(),
      _selectedCard!.height.toDouble(),
    );

    final localPosition = details.localPosition;
    
    // Check if the drag started on the selected widget
    final widget = _selectedWidget!;
    if (widget.type == DataWidgetType.label) {
      final widgetX = cardRect.left + widget.x.toDouble();
      final widgetY = cardRect.top + widget.y.toDouble();
      final actualWidth = widget.width > 0 ? widget.width.toDouble() : 150.0;
      
      // Calculate text height
      final textStyle = TextStyle(
        fontFamily: _layoutSettings.text1FontFamily,
        fontSize: widget.fontSize.toDouble(),
        color: _parseColor(_layoutSettings.text1Color),
      );
      final textPainter = TextPainter(
        text: TextSpan(text: widget.label, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final actualHeight = textPainter.height + 10;

      final widgetRect = Rect.fromLTWH(widgetX, widgetY, actualWidth, actualHeight);
      
      if (widgetRect.contains(localPosition)) {
        setState(() {
          _draggingWidget = widget;
          _dragStartOffset = Offset(widgetX, widgetY);
          _dragStartPosition = localPosition;
        });
      }
    }
  }

  void _handleCanvasPanUpdate(DragUpdateDetails details) {
    if (_draggingWidget == null || _dragStartOffset == null || _dragStartPosition == null) return;

    final cardRect = Rect.fromLTWH(
      (MediaQuery.of(context).size.width - _selectedCard!.width) / 2,
      (MediaQuery.of(context).size.height - _selectedCard!.height) / 2,
      _selectedCard!.width.toDouble(),
      _selectedCard!.height.toDouble(),
    );

    final localPosition = details.localPosition;
    final delta = localPosition - _dragStartPosition!;
    
    // Calculate new position relative to card
    var newX = _dragStartOffset!.dx + delta.dx - cardRect.left;
    var newY = _dragStartOffset!.dy + delta.dy - cardRect.top;
    
    // Clamp to card boundaries
    newX = newX.clamp(0.0, cardRect.width - (_draggingWidget!.width > 0 ? _draggingWidget!.width.toDouble() : 150.0));
    
    // Calculate widget height for clamping
    final textStyle = TextStyle(
      fontFamily: _layoutSettings.text1FontFamily,
      fontSize: _draggingWidget!.fontSize.toDouble(),
      color: _parseColor(_layoutSettings.text1Color),
    );
    final textPainter = TextPainter(
      text: TextSpan(text: _draggingWidget!.label, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final widgetHeight = textPainter.height + 10;
    newY = newY.clamp(0.0, cardRect.height - widgetHeight);

    setState(() {
      _dragStartOffset = Offset(_dragStartOffset!.dx + delta.dx, _dragStartOffset!.dy + delta.dy);
    });
  }

  void _handleCanvasPanEnd(DragEndDetails details) {
    if (_draggingWidget == null || _dragStartOffset == null || _selectedCard == null) return;

    final cardRect = Rect.fromLTWH(
      (MediaQuery.of(context).size.width - _selectedCard!.width) / 2,
      (MediaQuery.of(context).size.height - _selectedCard!.height) / 2,
      _selectedCard!.width.toDouble(),
      _selectedCard!.height.toDouble(),
    );

    // Calculate new widget position relative to card
    final newX = (_dragStartOffset!.dx - cardRect.left).round();
    final newY = (_dragStartOffset!.dy - cardRect.top).round();

    // Update the widget position
    final widgetIndex = _selectedCard!.dataWidgetList.indexOf(_draggingWidget!);
    if (widgetIndex != -1) {
      final widgets = List<DataWidget>.from(_selectedCard!.dataWidgetList);
      widgets[widgetIndex] = _draggingWidget!.copyWith(x: newX, y: newY);
      
      setState(() {
        final updatedCard = _selectedCard!.copyWith(dataWidgetList: widgets);
        _cardList[_cardList.indexOf(_selectedCard!)] = updatedCard;
        _selectedCard = updatedCard;
        _selectedWidget = widgets[widgetIndex];
        _draggingWidget = null;
        _dragStartOffset = null;
        _dragStartPosition = null;
      });
    } else {
      setState(() {
        _draggingWidget = null;
        _dragStartOffset = null;
        _dragStartPosition = null;
      });
    }
  }

  void _selectWidget(DataWidget widget) {
    setState(() {
      _selectedWidget = widget;
      _xController.text = widget.x.toString();
      _yController.text = widget.y.toString();
      _widthController.text = widget.width.toString();
      _heightController.text = widget.height.toString();
    });
  }

  Future<void> _deleteWidget() async {
    if (_selectedWidget == null || _selectedCard == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Widget'),
          content: const Text('Are you sure you want to delete this widget?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        final cardIndex = _cardList.indexOf(_selectedCard!);
        if (cardIndex != -1) {
          final widgets = List<DataWidget>.from(_selectedCard!.dataWidgetList);
          widgets.remove(_selectedWidget!);
          final updatedCard = _selectedCard!.copyWith(dataWidgetList: widgets);
          _cardList[cardIndex] = updatedCard;
          _selectedCard = updatedCard;
          _selectedWidget = null;
        }
      });
    }
  }

  void _duplicateWidget() {
    if (_selectedWidget == null || _selectedCard == null) return;

    final duplicatedWidget = _selectedWidget!.copyWith(
      x: _selectedWidget!.x + 10,
      y: _selectedWidget!.y + 10,
    );

    setState(() {
      final cardIndex = _cardList.indexOf(_selectedCard!);
      if (cardIndex != -1) {
        final widgets = List<DataWidget>.from(_selectedCard!.dataWidgetList);
        widgets.add(duplicatedWidget);
        final updatedCard = _selectedCard!.copyWith(dataWidgetList: widgets);
        _cardList[cardIndex] = updatedCard;
        _selectedCard = updatedCard;
        _selectedWidget = duplicatedWidget;
      }
    });
  }

  void _showWidgetContextMenu(BuildContext context, DataWidget widget, Offset globalPosition) {
    final overlay = Overlay.of(context);
    final overlayContext = overlay.context;
    final RenderBox overlayBox = overlayContext.findRenderObject() as RenderBox;

    showMenu<String>(
      context: overlayContext,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlayBox.size.width - globalPosition.dx,
        overlayBox.size.height - globalPosition.dy,
      ),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete'),
        ),
        const PopupMenuItem<String>(
          value: 'duplicate',
          child: Text('Duplicate'),
        ),
      ],
    ).then((String? value) {
      if (value != null) {
        switch (value) {
          case 'delete':
            _selectWidget(widget);
            _deleteWidget();
            break;
          case 'duplicate':
            _selectWidget(widget);
            _duplicateWidget();
            break;
        }
      }
    });
  }

  Widget _buildLeftPane() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'CardList',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addCard,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedCard != null ? _deleteCard : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _cardList.length,
              itemBuilder: (context, index) {
                final card = _cardList[index];
                return GestureDetector(
                  onDoubleTap: () => _showCardProperties(),
                  child: ListTile(
                    title: Text('${card.name} (${card.typeName})'),
                    selected: _selectedCard == card,
                    onTap: () => _selectCard(card),
                    selectedTileColor: Colors.blue.withOpacity(0.1),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Card properties',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedCard != null) ...[
                  const SizedBox(height: 4),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: TextEditingController(text: _selectedCard!.name),
                    onChanged: _updateCardName,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _selectedCard!.startup,
                        onChanged: _setStartup,
                      ),
                      const Text('Startup'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Type: ${_selectedCard!.typeName}'),
                  const SizedBox(height: 4),
                  Text('Width: ${_selectedCard!.width}'),
                  const SizedBox(height: 4),
                  Text('Height: ${_selectedCard!.height}'),
                ] else ...[
                  const Text('No card selected'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddlePane() {
    if (_selectedCard == null) {
      return Center(
        child: Text(
          'Please select a card from the list to edit',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (details) => _handleCanvasTapDown(details),
        onPanStart: (details) => _handleCanvasPanStart(details),
        onPanUpdate: (details) => _handleCanvasPanUpdate(details),
        onPanEnd: (details) => _handleCanvasPanEnd(details),
        child: Container(
          color: const Color(0xFF808080),
          child: CustomPaint(
            painter: DataCardPainter(
              card: _selectedCard!,
              backgroundColor: _parseColor(_layoutSettings.backgroundColor),
              selectedWidget: _selectedWidget,
              layoutSettings: _layoutSettings,
              dragOffset: _dragStartOffset,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _buildRightPane() {
    return Focus(
      focusNode: _rightPaneFocusNode,
      onKey: (node, event) {
        if (event is RawKeyDownEvent && _selectedWidget != null && _selectedCard != null) {
          int step = 1;
          if (event.isControlPressed) {
            step = 5;
          } else if (event.isShiftPressed) {
            step = 10;
          }
          
          int newX = _selectedWidget!.x;
          int newY = _selectedWidget!.y;
          
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            newX -= step;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            newX += step;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            newY -= step;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            newY += step;
          } else {
            return KeyEventResult.ignored;
          }
          
          _updateWidgetProperty(_selectedWidget!, 'x', newX);
          _updateWidgetProperty(_selectedWidget!, 'y', newY);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        width: 200,
        child: Column(
          children: [
          // Widget List - Top half
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Widget List',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              onPressed: _addWidget,
              icon: const Icon(Icons.add),
              label: const Text('Add widget'),
            ),
          ),
          const Divider(),
          SizedBox(
            height: 200,
            child: Focus(
              focusNode: _widgetListFocusNode,
              onKey: (node, event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.delete ||
                      event.logicalKey == LogicalKeyboardKey.backspace) {
                    if (_selectedWidget != null) {
                      _deleteWidget();
                      return KeyEventResult.handled;
                    }
                  }
                }
                return KeyEventResult.ignored;
              },
              child: _selectedCard == null
                  ? const Center(child: Text('No card selected'))
                  : ListView.builder(
                      itemCount: _selectedCard!.dataWidgetList.length,
                      itemBuilder: (context, index) {
                        final widget = _selectedCard!.dataWidgetList[index];
                        return GestureDetector(
                          onTap: () => _selectWidget(widget),
                          onDoubleTap: () => _selectWidget(widget),
                          onSecondaryTapDown: (details) => _showWidgetContextMenu(context, widget, details.globalPosition),
                          child: ListTile(
                            title: Text(widget.label.isNotEmpty
                                ? widget.label
                                : widget.type.toString().split('.').last),
                            subtitle: Text('${widget.type.toString().split('.').last}'),
                            selected: _selectedWidget == widget,
                            selectedTileColor: Colors.blue.withOpacity(0.1),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Divider(height: 1),
          // Widget Properties - Bottom half
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Widget Properties',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _selectedWidget == null
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('No widget selected'),
                )
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 60,
                            child: Text('X:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _xController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              ),
                              keyboardType: TextInputType.number,
                              onSubmitted: (value) => _applyWidgetProperties(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 60,
                            child: Text('Y:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _yController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              ),
                              keyboardType: TextInputType.number,
                              onSubmitted: (value) => _applyWidgetProperties(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 60,
                            child: Text('Width:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _widthController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              ),
                              keyboardType: TextInputType.number,
                              onSubmitted: (value) => _applyWidgetProperties(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 60,
                            child: Text('Height:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              ),
                              keyboardType: TextInputType.number,
                              onSubmitted: (value) => _applyWidgetProperties(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _applyWidgetProperties,
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Apply'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _editWidget(_selectedWidget!, _selectedCard!.dataWidgetList.indexOf(_selectedWidget!)),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ],
      ),
    ));
  }

  void _showCardProperties() {
    if (_selectedCard == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nameController = TextEditingController(text: _selectedCard!.name);
        return AlertDialog(
          title: const Text('Card Properties'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Type: ${_selectedCard!.typeName}'),
              const SizedBox(height: 8),
              Text('Width: ${_selectedCard!.width}'),
              const SizedBox(height: 8),
              Text('Height: ${_selectedCard!.height}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCard = _selectedCard!.copyWith(name: nameController.text);
                });
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCanvas() {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        onPanStart: (DragStartDetails details) {
          setState(() {
            _points.add(details.localPosition);
            _updateStatus('Drawing...');
          });
        },
        onPanUpdate: (DragUpdateDetails details) {
          setState(() {
            _points.add(details.localPosition);
          });
        },
        onPanEnd: (DragEndDetails details) {
          _points.add(null);
          _updateStatus('${_points.where((p) => p != null).length} points drawn');
        },
        onSecondaryTapDown: (TapDownDetails details) {
          _showOptionsMenu(context, details.globalPosition);
        },
        child: Container(
          color: Colors.white,
          child: CustomPaint(
            painter: DrawingPainter(
              points: _points,
              color: _currentColor,
              strokeWidth: _strokeWidth,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing App'),
        actions: [
          _buildFileMenu(),
        ],
      ),
      body: Row(
        children: [
          _buildLeftPane(),
          const VerticalDivider(width: 1),
          Expanded(
            child: _buildMiddlePane(),
          ),
          const VerticalDivider(width: 1),
          _buildRightPane(),
        ],
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _currentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  'Stroke: ${_strokeWidth.toStringAsFixed(1)}px',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMenu() {
    return PopupMenuButton<String>(
      tooltip: 'File',
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'open',
          child: Text('Open'),
        ),
        const PopupMenuItem<String>(
          value: 'save',
          child: Text('Save'),
        ),
        const PopupMenuItem<String>(
          value: 'save_as',
          child: Text('Save as...'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'project_settings',
          child: Text('Project settings...'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'quit',
          child: Text('Quit'),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'open':
            _open();
            break;
          case 'save':
            _save();
            break;
          case 'save_as':
            _saveAs();
            break;
          case 'project_settings':
            _showProjectSettings();
            break;
          case 'quit':
            _quitApp();
            break;
        }
      },
    );
  }
}

class DataCardPainter extends CustomPainter {
  final DataCard card;
  final Color backgroundColor;
  final DataWidget? selectedWidget;
  final LayoutSettings layoutSettings;
  final Offset? dragOffset;

  const DataCardPainter({
    required this.card,
    required this.backgroundColor,
    this.selectedWidget,
    required this.layoutSettings,
    this.dragOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cardPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      text: TextSpan(
        text: card.name,
        style: const TextStyle(color: Colors.black, fontSize: 12, fontFamily: 'Arial'),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final cardRect = Rect.fromLTWH(
      (size.width - card.width) / 2,
      (size.height - card.height) / 2,
      card.width.toDouble(),
      card.height.toDouble(),
    );

    canvas.drawRect(cardRect, cardPaint);
    canvas.drawRect(cardRect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        cardRect.left + 4,
        cardRect.top + 4,
      ),
    );

    // Draw widgets
    for (final widget in card.dataWidgetList) {
      _drawWidget(canvas, cardRect, widget, widget == selectedWidget);
    }

    // Draw dragging widget if present
    if (dragOffset != null && selectedWidget != null) {
      _drawWidget(canvas, cardRect, selectedWidget!, true, dragOffset!);
    }
  }

  void _drawWidget(Canvas canvas, Rect cardRect, DataWidget widget, bool isSelected, [Offset? customOffset]) {
    if (widget.type != DataWidgetType.label) return;

    // Calculate widget position
    final widgetX = customOffset?.dx ?? cardRect.left + widget.x.toDouble();
    final widgetY = customOffset?.dy ?? cardRect.top + widget.y.toDouble();
    
    // For label widgets, use text1 settings
    final textStyle = TextStyle(
      fontFamily: layoutSettings.text1FontFamily,
      fontSize: widget.fontSize.toDouble(),
      fontWeight: _getFontWeight(widget.fontWeight),
      color: _parseColor(layoutSettings.text1Color),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: widget.label, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Calculate actual width and height
    final actualWidth = widget.width > 0 ? widget.width.toDouble() : 150.0;
    final actualHeight = textPainter.height + 10;

    final widgetRect = Rect.fromLTWH(
      widgetX,
      widgetY,
      actualWidth,
      actualHeight,
    );

    // Draw label text centered in the widget
    final textOffset = Offset(
      widgetX + (actualWidth - textPainter.width) / 2,
      widgetY + (actualHeight - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);

    // Draw dashed border if selected
    if (isSelected) {
      final dashPaint = Paint()
        ..color = _getContrastingColor(backgroundColor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final dashPath = Path();
      final dashWidth = 5.0;
      final dashSpace = 3.0;

      // Draw dashed rectangle
      final startX = widgetRect.left;
      final startY = widgetRect.top;
      final endX = widgetRect.right;
      final endY = widgetRect.bottom;

      // Top border
      double x = startX;
      while (x < endX) {
        dashPath.moveTo(x, startY);
        dashPath.lineTo(x + dashWidth, startY);
        x += dashWidth + dashSpace;
      }

      // Right border
      double y = startY;
      while (y < endY) {
        dashPath.moveTo(endX, y);
        dashPath.lineTo(endX, y + dashWidth);
        y += dashWidth + dashSpace;
      }

      // Bottom border
      x = startX;
      while (x < endX) {
        dashPath.moveTo(x, endY);
        dashPath.lineTo(x + dashWidth, endY);
        x += dashWidth + dashSpace;
      }

      // Left border
      y = startY;
      while (y < endY) {
        dashPath.moveTo(startX, y);
        dashPath.lineTo(startX, y + dashWidth);
        y += dashWidth + dashSpace;
      }

      canvas.drawPath(dashPath, dashPaint);
    }
  }

  FontWeight _getFontWeight(DataWidgetFontWeight fontWeight) {
    switch (fontWeight) {
      case DataWidgetFontWeight.bold:
        return FontWeight.bold;
      case DataWidgetFontWeight.italic:
        return FontWeight.normal;
      case DataWidgetFontWeight.plain:
      default:
        return FontWeight.normal;
    }
  }

  Color _parseColor(String hexColor) {
    try {
      if (hexColor.startsWith('#') && hexColor.length == 7) {
        return Color(int.parse(hexColor.substring(1), radix: 16) | 0xFF000000);
      }
    } catch (e) {}
    return Colors.black;
  }

  Color _getContrastingColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  bool shouldRepaint(DataCardPainter oldDelegate) =>
      oldDelegate.card != card ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.selectedWidget != selectedWidget ||
      oldDelegate.layoutSettings != layoutSettings ||
      oldDelegate.dragOffset != dragOffset;
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  const DrawingPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
