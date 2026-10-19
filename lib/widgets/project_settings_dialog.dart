import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/data_card.dart';
import '../models/layout_settings.dart';

class ProjectSettingsDialog extends StatefulWidget {
  final List<DataCard> dataCardTypes;
  final LayoutSettings layoutSettings;
  final Function(List<DataCard>) onDataCardTypesChanged;
  final Function(LayoutSettings) onLayoutSettingsChanged;

  const ProjectSettingsDialog({
    super.key,
    required this.dataCardTypes,
    required this.layoutSettings,
    required this.onDataCardTypesChanged,
    required this.onLayoutSettingsChanged,
  });

  @override
  State<ProjectSettingsDialog> createState() => _ProjectSettingsDialogState();
}

class _ProjectSettingsDialogState extends State<ProjectSettingsDialog> {
  late List<DataCard> _dataCardTypes;
  late LayoutSettings _layoutSettings;
  DataCard? _selectedDataCard;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _bgColorController = TextEditingController();
  final TextEditingController _buttonFgColorController = TextEditingController();
  final TextEditingController _buttonBgColorController = TextEditingController();
  final TextEditingController _text1ColorController = TextEditingController();
  final TextEditingController _text2ColorController = TextEditingController();
  final TextEditingController _text1FontController = TextEditingController();
  final TextEditingController _text2FontController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataCardTypes = List.from(widget.dataCardTypes);
    _layoutSettings = widget.layoutSettings;
    if (_dataCardTypes.isNotEmpty) {
      _selectedDataCard = _dataCardTypes.first;
      _updateDataCardControllers();
    }
    _updateLayoutControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _bgColorController.dispose();
    _buttonFgColorController.dispose();
    _buttonBgColorController.dispose();
    _text1ColorController.dispose();
    _text2ColorController.dispose();
    _text1FontController.dispose();
    _text2FontController.dispose();
    super.dispose();
  }

  void _updateDataCardControllers() {
    if (_selectedDataCard != null) {
      _nameController.text = _selectedDataCard!.typeName;
      _widthController.text = _selectedDataCard!.width.toString();
      _heightController.text = _selectedDataCard!.height.toString();
    } else {
      _nameController.clear();
      _widthController.clear();
      _heightController.clear();
    }
  }

  void _updateLayoutControllers() {
    _bgColorController.text = _layoutSettings.backgroundColor;
    _buttonFgColorController.text = _layoutSettings.buttonFgColor;
    _buttonBgColorController.text = _layoutSettings.buttonBgColor;
    _text1ColorController.text = _layoutSettings.text1Color;
    _text2ColorController.text = _layoutSettings.text2Color;
    _text1FontController.text = _layoutSettings.text1FontFamily;
    _text2FontController.text = _layoutSettings.text2FontFamily;
  }

  void _selectDataCard(DataCard? dataCard) {
    setState(() {
      _selectedDataCard = dataCard;
      _updateDataCardControllers();
    });
  }

  Color _parseColor(String hexColor) {
    try {
      if (hexColor.startsWith('#') && hexColor.length == 7) {
        return Color(int.parse(hexColor.substring(1), radix: 16) | 0xFF000000);
      }
    } catch (e) {}
    return Colors.black;
  }

  String _colorToHex(Color color) {
    return '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'.toLowerCase();
  }

  Future<void> _pickColor(String propertyName) async {
    Color currentColor;
    switch (propertyName) {
      case 'background':
        currentColor = _parseColor(_layoutSettings.backgroundColor);
        break;
      case 'button_fg':
        currentColor = _parseColor(_layoutSettings.buttonFgColor);
        break;
      case 'button_bg':
        currentColor = _parseColor(_layoutSettings.buttonBgColor);
        break;
      case 'text1':
        currentColor = _parseColor(_layoutSettings.text1Color);
        break;
      case 'text2':
        currentColor = _parseColor(_layoutSettings.text2Color);
        break;
      default:
        currentColor = Colors.black;
    }

    final pickedColor = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                Navigator.of(context).pop(color);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(currentColor),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (pickedColor != null) {
      final hexColor = _colorToHex(pickedColor);
      setState(() {
        switch (propertyName) {
          case 'background':
            _layoutSettings = _layoutSettings.copyWith(backgroundColor: hexColor);
            _bgColorController.text = hexColor;
            break;
          case 'button_fg':
            _layoutSettings = _layoutSettings.copyWith(buttonFgColor: hexColor);
            _buttonFgColorController.text = hexColor;
            break;
          case 'button_bg':
            _layoutSettings = _layoutSettings.copyWith(buttonBgColor: hexColor);
            _buttonBgColorController.text = hexColor;
            break;
          case 'text1':
            _layoutSettings = _layoutSettings.copyWith(text1Color: hexColor);
            _text1ColorController.text = hexColor;
            break;
          case 'text2':
            _layoutSettings = _layoutSettings.copyWith(text2Color: hexColor);
            _text2ColorController.text = hexColor;
            break;
        }
      });
    }
  }

  Future<void> _pickFont(String propertyName) async {
    final availableFonts = [
      'Arial',
      'Times New Roman',
      'Courier New',
      'Georgia',
      'Verdana',
      'Helvetica',
      'Tahoma',
      'Trebuchet MS',
      'Comic Sans MS',
      'Impact',
      'Lucida Console',
    ];

    String currentFont;
    switch (propertyName) {
      case 'text1':
        currentFont = _layoutSettings.text1FontFamily;
        break;
      case 'text2':
        currentFont = _layoutSettings.text2FontFamily;
        break;
      default:
        currentFont = 'Arial';
    }

    final selectedFont = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Font'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableFonts.length,
              itemBuilder: (context, index) {
                final font = availableFonts[index];
                return ListTile(
                  title: Text(
                    font,
                    style: TextStyle(fontFamily: font),
                  ),
                  selected: font == currentFont,
                  onTap: () => Navigator.of(context).pop(font),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(currentFont),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedFont != null) {
      setState(() {
        switch (propertyName) {
          case 'text1':
            _layoutSettings = _layoutSettings.copyWith(text1FontFamily: selectedFont);
            _text1FontController.text = selectedFont;
            break;
          case 'text2':
            _layoutSettings = _layoutSettings.copyWith(text2FontFamily: selectedFont);
            _text2FontController.text = selectedFont;
            break;
        }
      });
    }
  }

  Future<void> _addDataCard() async {
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add DataCard Type'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter DataCard type name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      final nameTrimmed = name.trim();
      if (nameTrimmed.isNotEmpty && 
          !_dataCardTypes.any((dc) => dc.typeName == nameTrimmed)) {
        setState(() {
          final newDataCard = DataCard(typeName: nameTrimmed);
          _dataCardTypes.add(newDataCard);
          _selectedDataCard = newDataCard;
          _updateDataCardControllers();
        });
      } else if (_dataCardTypes.any((dc) => dc.typeName == nameTrimmed)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A DataCard with this name already exists')),
        );
      }
    }
  }

  void _removeDataCard() {
    if (_selectedDataCard != null) {
      setState(() {
        _dataCardTypes.remove(_selectedDataCard!);
        if (_dataCardTypes.isNotEmpty) {
          _selectedDataCard = _dataCardTypes.first;
        } else {
          _selectedDataCard = null;
        }
        _updateDataCardControllers();
      });
    }
  }

  void _updateDataCard() {
    if (_selectedDataCard != null) {
      final name = _nameController.text.trim();
      final width = int.tryParse(_widthController.text) ?? 100;
      final height = int.tryParse(_heightController.text) ?? 100;

      if (name.isNotEmpty) {
        final index = _dataCardTypes.indexOf(_selectedDataCard!);
        if (index != -1) {
          final existingNames = _dataCardTypes
              .where((dc) => dc != _selectedDataCard)
              .map((dc) => dc.typeName)
              .toList();
          
          if (!existingNames.contains(name)) {
            setState(() {
              _dataCardTypes[index] = DataCard(
                typeName: name,
                width: width,
                height: height,
              );
              _selectedDataCard = _dataCardTypes[index];
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A DataCard with this name already exists')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Project Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'DataCard'),
                      Tab(text: 'Layout'),
                    ],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildDataCardTab(),
                        _buildLayoutTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onDataCardTypesChanged(_dataCardTypes);
                      widget.onLayoutSettingsChanged(_layoutSettings);
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCardTab() {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addDataCard,
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
                        onPressed: _selectedDataCard != null ? _removeDataCard : null,
                        icon: const Icon(Icons.remove),
                        label: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _dataCardTypes.length,
                  itemBuilder: (context, index) {
                    final dataCard = _dataCardTypes[index];
                    return ListTile(
                      title: Text(dataCard.typeName),
                      selected: _selectedDataCard == dataCard,
                      onTap: () => _selectDataCard(dataCard),
                      selectedTileColor: Colors.blue.withOpacity(0.1),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _selectedDataCard?.typeName ?? 'No DataCard selected',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Type Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _updateDataCard(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _widthController,
                  decoration: const InputDecoration(
                    labelText: 'Width (pixels)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateDataCard(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (pixels)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateDataCard(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Layout Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildColorProperty(
            label: 'Background Color',
            colorController: _bgColorController,
            color: _parseColor(_layoutSettings.backgroundColor),
            onColorTap: () => _pickColor('background'),
          ),
          const SizedBox(height: 16),
          _buildColorProperty(
            label: 'Button Foreground Color',
            colorController: _buttonFgColorController,
            color: _parseColor(_layoutSettings.buttonFgColor),
            onColorTap: () => _pickColor('button_fg'),
          ),
          const SizedBox(height: 16),
          _buildColorProperty(
            label: 'Button Background Color',
            colorController: _buttonBgColorController,
            color: _parseColor(_layoutSettings.buttonBgColor),
            onColorTap: () => _pickColor('button_bg'),
          ),
          const SizedBox(height: 16),
          _buildColorProperty(
            label: 'Text1 Color',
            colorController: _text1ColorController,
            color: _parseColor(_layoutSettings.text1Color),
            onColorTap: () => _pickColor('text1'),
          ),
          const SizedBox(height: 16),
          _buildColorProperty(
            label: 'Text2 Color',
            colorController: _text2ColorController,
            color: _parseColor(_layoutSettings.text2Color),
            onColorTap: () => _pickColor('text2'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildFontProperty(
            label: 'Text1 Font Family',
            controller: _text1FontController,
            onTap: () => _pickFont('text1'),
          ),
          const SizedBox(height: 16),
          _buildFontProperty(
            label: 'Text2 Font Family',
            controller: _text2FontController,
            onTap: () => _pickFont('text2'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorProperty({
    required String label,
    required TextEditingController colorController,
    required Color color,
    required VoidCallback onColorTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              onTap: onColorTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: colorController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  if (value.length == 7 && value.startsWith('#')) {
                    setState(() {
                      colorController.text = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontProperty({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                readOnly: true,
                onTap: onTap,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down),
              onPressed: onTap,
            ),
          ],
        ),
      ],
    );
  }
}
