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
      home: const MainWindow(),
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
        _dataCardTypes = [];
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

  Future<void> _addCard() async {
    if (_dataCardTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please define DataCard types in Settings first'),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    DataCard? selectedType;

    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
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
                      selected: selectedType == type,
                      onTap: () {
                        selectedType = type;
                        Navigator.of(context).pop();
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
              onPressed: () {
                if (selectedType != null) {
                  Navigator.of(context).pop(nameController.text);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (name != null && selectedType != null) {
      final newCard = DataCard(
        typeName: selectedType!.typeName,
        width: selectedType!.width,
        height: selectedType!.height,
        name: name,
        dataWidgetList: selectedType!.dataWidgetList.map((dw) => dw.copyWith()).toList(),
      );
      setState(() {
        _cardList.add(newCard);
        _selectedCard = newCard;
      });
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

  Future<void> _showCardProperties() async {
    if (_selectedCard == null) return;

    await showDialog(
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

  Widget _buildLeftPane() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
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

    return Container(
      color: const Color(0xFF808080),
      child: CustomPaint(
        painter: DataCardPainter(
          card: _selectedCard!,
          backgroundColor: _parseColor(_layoutSettings.backgroundColor),
        ),
        size: Size.infinite,
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      if (hexColor.startsWith('#') && hexColor.length == 7) {
        return Color(int.parse(hexColor.substring(1), radix: 16) | 0xFF000000);
      }
    } catch (e) {}
    return Colors.black;
  }

  Widget _buildRightPane() {
    return const SizedBox(
      width: 200,
      child: Placeholder(),
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

  const DataCardPainter({
    required this.card,
    required this.backgroundColor,
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
  }

  @override
  bool shouldRepaint(DataCardPainter oldDelegate) =>
      oldDelegate.card != card || oldDelegate.backgroundColor != backgroundColor;
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
