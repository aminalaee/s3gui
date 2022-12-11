import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minio/models.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:s3gui/utils/utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:s3gui/s3.dart';
import 'package:s3gui/utils/filesize.dart';

class ObjectsPage extends StatefulWidget {
  const ObjectsPage({super.key, required this.bucket, required this.prefix});

  final String bucket;
  final String prefix;

  @override
  State<ObjectsPage> createState() => _ObjectsPageState();
}

class _ObjectsPageState extends State<ObjectsPage>
    with TickerProviderStateMixin {
  final _s3 = S3();
  final _newDirectoryController = TextEditingController();
  late AnimationController _progressController;

  @override
  void initState() {
    _s3.listObjects(widget.bucket, widget.prefix);
    _progressController = AnimationController(
      vsync: this,
      value: -1,
    )..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    _newDirectoryController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bucket),
        actions: [
          PopupMenuButton(
            tooltip: 'New',
            icon: const Icon(Icons.add),
            onSelected: (item) async {
              if (item == 1) {
                await handleFileUpload();
              } else if (item == 2) {
                showDialog(
                  context: context,
                  builder: ((context) => showCreateDirectoryDialog()),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Upload files'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('New Directory'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 15),
            buildBreadCrumbs(),
            const SizedBox(height: 25),
            Opacity(
              opacity: _progressController.value > 0 &&
                      _progressController.value != 1
                  ? 1
                  : 0,
              child: LinearProgressIndicator(
                value: _progressController.value,
                semanticsLabel: 'Loading',
              ),
            ),
            Observer(
              builder: (_) => StreamBuilder(
                stream: _s3.objects,
                builder: ((_, snapshot) {
                  if (snapshot.hasData) {
                    return buildTable(snapshot.data!);
                  }
                  return Container();
                }),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildTable(ListObjectsResult result) {
    return DataTable(
      columns: const [
        DataColumn(
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Name',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        DataColumn(
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Size',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        DataColumn(
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Last Modified',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        DataColumn(
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
      rows: buildRows(result),
    );
  }

  List<DataRow> buildRows(ListObjectsResult result) {
    final prefixRows = List<DataRow>.generate(result.prefixes.length,
        (index) => buildPrefixRow(result.prefixes[index]));
    final objects = result.objects.where((object) => object.size! > 0).toList();
    final objectRows = List<DataRow>.generate(
        objects.length, (index) => buildObjectRow(objects[index]));
    return prefixRows + objectRows;
  }

  DataRow buildPrefixRow(String prefix) {
    return DataRow(
      cells: [
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: ListTile(
              leading: Icon(Icons.folder, color: Colors.blue[400]),
              title: Text(
                normalizePath(prefix, widget.prefix),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ObjectsPage(
                  bucket: widget.bucket,
                  prefix: prefix,
                ),
              ),
            );
          },
        ),
        const DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '-',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '-',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        prefixActions(prefix),
      ],
    );
  }

  DataRow buildObjectRow(Object object) {
    return DataRow(
      cells: [
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: ListTile(
              leading: Icon(Icons.description, color: Colors.blue[400]),
              title: Text(
                normalizePath(object.key!, widget.prefix),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          onTap: () {},
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              filesize(object.size!),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              timeago.format(object.lastModified!),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        objectActions(object),
      ],
    );
  }

  Widget showCreateDirectoryDialog() {
    return AlertDialog(
      title: const Text('Choose directory name'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TextFormField(
              controller: _newDirectoryController,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Save'),
          onPressed: () async {
            await _s3.createNewDirectory(
                widget.bucket, widget.prefix, _newDirectoryController.text);
            await _s3.listObjects(widget.bucket, widget.prefix);
            Navigator.of(context).pop();
            _newDirectoryController.clear();
          },
        ),
      ],
    );
  }

  DataCell objectActions(Object object) {
    return DataCell(
      PopupMenuButton(
        tooltip: 'Manage',
        onSelected: (item) async {
          if (item == 1) {
            await _s3.deleteObject(widget.bucket, widget.prefix,
                normalizePath(object.key!, widget.prefix));
            await _s3.listObjects(widget.bucket, widget.prefix);
          } else if (item == 2) {
            final url = await _s3.getObjectURL(widget.bucket, object.key!);
            await Clipboard.setData(ClipboardData(text: url));
          }
        },
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem(
            value: 1,
            child: Text('Delete'),
          ),
          const PopupMenuItem(
            value: 2,
            child: Text('Copy Downlaod RURL'),
          ),
        ],
      ),
    );
  }

  DataCell prefixActions(String prefix) {
    return DataCell(
      PopupMenuButton(
        tooltip: 'Manage',
        onSelected: (item) async {
          if (item == 1) {
            await _s3.deleteDirectory(widget.bucket, widget.prefix,
                normalizePath(prefix, widget.prefix));
            await _s3.listObjects(widget.bucket, widget.prefix);
          }
        },
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem(
            value: 1,
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget buildBreadCrumbs() {
    final breadCrumbs = <Widget>[];
    for (var prefix in widget.prefix.split('/')) {
      if (prefix.isNotEmpty) {
        breadCrumbs.add(const SizedBox(width: 5));
        breadCrumbs.add(const Text('/'));
        breadCrumbs.add(const SizedBox(width: 5));
        breadCrumbs.add(Text(prefix));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.bucket),
        ...breadCrumbs,
      ],
    );
  }

  Future<void> handleFileUpload() async {
    final pick = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (pick != null) {
      for (var file in pick.files) {
        final path = widget.prefix + file.name;
        await _s3.uploadFile(widget.bucket, path, file, _progressController);
        await _s3.listObjects(widget.bucket, widget.prefix);
      }
    }
  }
}
