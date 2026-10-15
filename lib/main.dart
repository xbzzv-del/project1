import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing App'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
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
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
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

