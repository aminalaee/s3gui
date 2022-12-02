import 'package:flutter/material.dart';
import 'package:minio/models.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:s3gui/s3.dart';
import 'package:s3gui/filesize.dart';

class ObjectsPage extends StatefulWidget {
  const ObjectsPage({super.key, required this.bucket, required this.prefix});

  final String bucket;
  final String prefix;

  @override
  State<ObjectsPage> createState() => _ObjectsPageState();
}

class _ObjectsPageState extends State<ObjectsPage> {
  final _s3 = S3();

  @override
  void initState() {
    _s3.listObjects(widget.bucket, widget.prefix);
    super.initState();
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
                //
              } else if (item == 2) {
                _s3.createNewDirectory(widget.bucket, widget.prefix);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Upload files'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('New folder'),
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
                prefix.replaceAll(widget.prefix, ''),
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
                object.key!.replaceAll(widget.prefix, ''),
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
      ],
    );
  }
}
