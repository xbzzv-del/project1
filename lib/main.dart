import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

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
      body: Column(
        children: [
          Expanded(
            child: _buildCanvas(),
          ),
          Container(
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
        ],
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
          case 'quit':
            _quitApp();
            break;
        }
      },
    );
  }
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
