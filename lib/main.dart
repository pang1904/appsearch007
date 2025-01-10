import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'แอพค้นหาคำ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FileSearchPage(),
    );
  }
}

class FileSearchPage extends StatefulWidget {
  @override
  _FileSearchPageState createState() => _FileSearchPageState();
}

class _FileSearchPageState extends State<FileSearchPage> {
  String _fileContent = '';
  String _searchTerm = '';
  List<String> _searchResults = [];
  String? _csvFilePath;

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
    Map<String, int> termCounts = {};
    int totalMatchCount = 0;

    List<String> searchTerms = _searchTerm.contains(',')
        ? _searchTerm.split(',').map((e) => e.trim()).toList()
        : [_searchTerm];

    for (var line in lines) {
      bool isMatched = false;

      for (var term in searchTerms) {
        if (line.toLowerCase().contains(term.toLowerCase())) {
          int countInLine = _countOccurrences(line, term);
          termCounts[term] = (termCounts[term] ?? 0) + countInLine;
          totalMatchCount += countInLine;
          isMatched = true;
        }
      }

      if (isMatched) {
        results.add(line);
      }
    }

    setState(() {
      _searchResults = results;
    });

    if (_searchTerm.isNotEmpty) {
      StringBuffer resultSummary = StringBuffer();

      termCounts.forEach((term, count) {
        resultSummary.writeln('คำ "$term" พบ $count ครั้ง');
      });
      resultSummary.writeln('\nรวมทั้งหมด $totalMatchCount ครั้ง');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('ผลการค้นหา'),
            content: Text(resultSummary.toString()),
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

      // แสดงปุ่มให้ผู้ใช้บันทึกไฟล์ .csv
      setState(() {
        _csvFilePath = null; // ล้างเส้นทางไฟล์เก่า
      });
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

  Future<void> _saveSearchResultsToCSV() async {
    if (_searchResults.isNotEmpty) {
      // แปลงผลการค้นหาเป็น list ของ list เพื่อใช้ใน CSV
      List<List<dynamic>> rows = [];
      rows.add(['ผลการค้นหา']); // หัวคอลัมน์ CSV

      for (var result in _searchResults) {
        rows.add([result]);
      }

      // บันทึกไฟล์ลงที่เก็บภายนอก (External Storage)
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/search_results.csv';
      File file = File(path);

      await file.writeAsString(const ListToCsvConverter().convert(rows));

      setState(() {
        _csvFilePath = path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกผลการค้นหาลงไฟล์: $path')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แอพค้นหาคำ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'พิมพ์คำที่ต้องการค้นหา (ใช้ , เพื่อค้นหาหลายคำ)',
                border: OutlineInputBorder(),
              ),
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

            if (_searchResults.isNotEmpty)
              ElevatedButton(
                onPressed: _saveSearchResultsToCSV,
                child: Text('บันทึกผลการค้นหาเป็นไฟล์ .csv'),
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
