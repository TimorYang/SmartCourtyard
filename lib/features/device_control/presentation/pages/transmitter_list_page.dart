import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';

class TransmitterListPage extends StatefulWidget {
  const TransmitterListPage({required this.deviceId, super.key});
  static const routeName = 'transmitter-list';
  static const routePath = '/device-settings/transmitters/list';
  final String deviceId;
  @override
  State<TransmitterListPage> createState() => _TransmitterListPageState();
}

class _TransmitterListPageState extends State<TransmitterListPage> {
  final _names = [
    'Warehouse-01-Daniel',
    'Warehouse-02-Danyl',
    'Warehouse-03-Turk',
    'Workshop-03-Airly',
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Management',
              style: AppTextTokens.deviceSettingsTitle(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: 42),
            Expanded(
              child: ListView.separated(
                itemCount: _names.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) => ListTile(
                  title: Text(_names[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.drive_file_rename_outline),
                        onPressed: () => _edit(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(index),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FloatingActionButton(
              onPressed: () => _edit(null),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> _edit(int? index) async {
    final controller = TextEditingController(
      text: index == null ? '' : _names[index],
    );
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Transmitter info'),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Input transmitter name',
              ),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  if (index == null)
                    _names.add(controller.text);
                  else
                    _names[index] = controller.text;
                });
                context.pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(int index) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Prompt'),
            const Text(
              'Please confirm whether you want to delete the transmitter',
            ),
            FilledButton(
              onPressed: () {
                setState(() => _names.removeAt(index));
                context.pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
