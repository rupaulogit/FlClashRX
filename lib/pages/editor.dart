import 'package:flutter/material.dart';

class EditorPage extends StatefulWidget {
  final String? title;
  final String content;
  final void Function(BuildContext context, String? title, String content) onSave;
  final Future<bool> Function(BuildContext context, String? title, String content)? onPop;

  const EditorPage({
    super.key,
    this.title,
    required this.content,
    required this.onSave,
    this.onPop,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (widget.onPop != null) {
      return await widget.onPop!(context, widget.title, _controller.text);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'Редактор'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                widget.onSave(context, widget.title, _controller.text);
                Navigator.of(context).pop(_controller.text);
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
      ),
    );
  }
}
