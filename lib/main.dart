import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';  // นำเข้าเพื่อใช้ UTF-8

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
    try {
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
          _searchResults.clear(); // ล้างผลการค้นหาเก่าทุกครั้งที่อัปโหลดไฟล์ใหม่
        });
      } else {
        _showSnackBar('การเลือกไฟล์ถูกยกเลิก');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการอัพโหลดไฟล์: $e');
    }
  }

  void _searchInFile() {
    if (_fileContent.isEmpty) {
      _showSnackBar('กรุณาอัพโหลดไฟล์ก่อนทำการค้นหา');
      return;
    }
    if (_searchTerm.isEmpty) {
      _showSnackBar('กรุณากรอกคำค้นหา');
      return;
    }

    List<String> results = [];
    List<String> lines = _fileContent.split('\n');
    Map<String, int> termCounts = {};
    int totalMatchCount = 0;

    List<String> searchTerms = _searchTerm.split('"').map((e) => e.trim()).toList();
    

    for (var line in lines) {
      bool isMatched = false;

      for (var term in searchTerms) {
        final regex = RegExp(term, caseSensitive: false);
        final matches = regex.allMatches(line);
        int countInLine = matches.length;

        if (countInLine > 0) {
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
  }

  Future<void> _saveSearchResultsToCSV() async {
    if (_searchResults.isEmpty) {
      _showSnackBar('ไม่มีผลการค้นหาให้บันทึก');
      return;
    }

    try {
      // สร้างข้อมูลสำหรับบันทึกผลการค้นหา
      List<List<dynamic>> rows = [
        ['คำค้นหา',  'จำนวนครั้งที่พบ'], // หัวคอลัมน์ผลการค้นหา
      ];

      // เพิ่มข้อมูลคำค้นหาและจำนวนครั้งที่พบ
      Map<String, int> termCounts = {};
      List<String> searchTerms = _searchTerm.split(',').map((e) => e.trim()).toList();

      for (var term in searchTerms) {
        int totalCount = 0;

        // ค้นหาคำในบรรทัด
        for (var line in _searchResults) {
          final regex = RegExp(term, caseSensitive: false);
          totalCount += regex.allMatches(line).length;
        }

        if (totalCount > 0) {
          rows.add([term, totalCount, 'พบคำที่ตรงกัน $totalCount ครั้ง']);  // เพิ่มผลการค้นหา
        }
      }

      // สร้างไฟล์ .csv
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/searchlog.csv'; // ที่อยู่ของไฟล์
      File file = File(path);

      // เขียนข้อมูลลงไฟล์ด้วยการเข้ารหัส UTF-8 และแทรก BOM
      String csvData = const ListToCsvConverter().convert(rows);
      List<int> csvBytes = utf8.encode('\uFEFF' + csvData); // แทรก BOM (\uFEFF) ในข้อมูล CSV

      await file.writeAsBytes(csvBytes);

      setState(() {
        _csvFilePath = path;
      });

      _showSnackBar('บันทึกผลการค้นหาลงไฟล์: $path');
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการบันทึกไฟล์: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                itemCount: _searchResults.isNotEmpty
                    ? _searchResults.length
                    : _fileContent.split('\n').length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_searchResults.isNotEmpty
                        ? _searchResults[index]
                        : _fileContent.split('\n')[index]),
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
