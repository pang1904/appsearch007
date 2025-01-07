import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  String _fileContent = ''; // สำหรับเก็บเนื้อหาของไฟล์
  String _searchTerm = ''; // สำหรับเก็บคำค้นหา
  List<String> _searchResults = []; // ผลลัพธ์จากการค้นหา

  // ฟังก์ชันในการเลือกไฟล์ .log
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['log'],
    );

    if (result != null) {
      String filePath = result.files.single.path!;
      File file = File(filePath);

      // อ่านไฟล์ .log
      String content = await file.readAsString();
      setState(() {
        _fileContent = content;
      });
    }
  }

  // ฟังก์ชันการค้นหาภายในไฟล์ (นับจำนวนคำทั้งหมด)
  void _searchInFile() {
    List<String> results = [];
    List<String> lines = _fileContent.split('\n'); // แบ่งเนื้อหาเป็นบรรทัด
    int matchCount = 0; // ตัวแปรนับจำนวนคำที่ตรงกับคำค้นหา

    for (var line in lines) {
      if (line.toLowerCase().contains(_searchTerm.toLowerCase())) {
        // นับจำนวนครั้งที่คำปรากฏในบรรทัด
        int countInLine = _countOccurrences(line, _searchTerm);
        matchCount += countInLine;

        // เพิ่มบรรทัดที่ตรงกับคำค้นหาในผลลัพธ์
        results.add(line);
      }
    }

    setState(() {
      _searchResults = results;
    });

    // แสดงจำนวนคำที่ตรงกันทั้งหมด
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

  // ฟังก์ชันนับจำนวนคำที่ตรงกันในแต่ละบรรทัด
  int _countOccurrences(String line, String term) {
    final lowerLine = line.toLowerCase();
    final lowerTerm = term.toLowerCase();
    int count = 0;
    int index = lowerLine.indexOf(lowerTerm);

    // วนลูปเพื่อหาคำที่ปรากฏในบรรทัด
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
        title: Text('แอพค้นหาคำ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ช่องค้นหา
            TextField(
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
                itemCount: _searchResults.isEmpty ? _fileContent.split('\n').length : _searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_searchResults.isEmpty ? _fileContent.split('\n')[index] : _searchResults[index]),
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
