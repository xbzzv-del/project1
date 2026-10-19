import 'package:flutter/material.dart';
import '../models/data_card.dart';

class ProjectSettingsDialog extends StatefulWidget {
  final List<DataCard> dataCardTypes;
  final Function(List<DataCard>) onDataCardTypesChanged;

  const ProjectSettingsDialog({
    super.key,
    required this.dataCardTypes,
    required this.onDataCardTypesChanged,
  });

  @override
  State<ProjectSettingsDialog> createState() => _ProjectSettingsDialogState();
}

class _ProjectSettingsDialogState extends State<ProjectSettingsDialog> {
  late List<DataCard> _dataCardTypes;
  DataCard? _selectedDataCard;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataCardTypes = List.from(widget.dataCardTypes);
    if (_dataCardTypes.isNotEmpty) {
      _selectedDataCard = _dataCardTypes.first;
      _updateControllers();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _updateControllers() {
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

  void _selectDataCard(DataCard? dataCard) {
    setState(() {
      _selectedDataCard = dataCard;
      _updateControllers();
    });
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
          _updateControllers();
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
        _updateControllers();
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
              length: 1,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'DataCard'),
                    ],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildDataCardTab(),
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
}
