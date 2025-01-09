// file_search_page2.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FileSearchPage2 extends StatefulWidget {
  @override
  _FileSearchPage2State createState() => _FileSearchPage2State();
}

class _FileSearchPage2State extends State<FileSearchPage2> {
  String _fileContent = '';
  String _searchTerm = '';
  List<String> _searchResults = [];
  String _selectedItem = 'Item1'; // ค่าเริ่มต้นของ Dropdown
  final List<String> _items = ['Item1', 'Item2'];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['log'],
    );

    if (result != null) {
      String filePath = result.files.single.path!;
      File file = File(filePath);

      String content = await file.readAsString();
      setState(() {
        _fileContent = content;
      });
    }
  }

  void _searchInFile() {
    List<String> results = [];
    List<String> lines = _fileContent.split('\n');
    int matchCount = 0;

    for (var line in lines) {
      if (line.toLowerCase().contains(_searchTerm.toLowerCase())) {
        int countInLine = _countOccurrences(line, _searchTerm);
        matchCount += countInLine;
        results.add(line);
      }
    }

    setState(() {
      _searchResults = results;
    });

    if (_searchTerm.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('ผลการค้นหา'),
            content: Text('พบ $matchCount คำที่ตรงกับ "$_searchTerm".'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('ตกลง'),
              ),
            ],
          );
        },
      );
    }
  }

  int _countOccurrences(String line, String term) {
    final lowerLine = line.toLowerCase();
    final lowerTerm = term.toLowerCase();
    int count = 0;
    int index = lowerLine.indexOf(lowerTerm);

    while (index != -1) {
      count++;
      index = lowerLine.indexOf(lowerTerm, index + lowerTerm.length);
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แอพค้นหาคำ (หน้าที่สอง)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 150,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedItem,
                    items: _items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedItem = newValue!;
                      });
                    },
                    isExpanded: true,
                    icon: Icon(Icons.arrow_downward, color: Colors.black),
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    underline: SizedBox(),
                  ),
                ),
                SizedBox(width: 16),

                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'พิมพ์คำที่ต้องการค้นหา',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            ElevatedButton(
              onPressed: _pickFile,
              child: Text('อัพโหลดไฟล์ .log'),
            ),
            SizedBox(height: 16),

            ElevatedButton(
              onPressed: _searchInFile,
              child: Text('ค้นหาในไฟล์'),
            ),
            SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.isEmpty
                    ? _fileContent.split('\n').length
                    : _searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_searchResults.isEmpty
                        ? _fileContent.split('\n')[index]
                        : _searchResults[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
