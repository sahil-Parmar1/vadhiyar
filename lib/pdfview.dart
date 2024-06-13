import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
class PdfPreviewScreen extends StatefulWidget {
  final String filePath;

  const PdfPreviewScreen({required this.filePath});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Preview'),
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            onRender: (_pages) {
              setState(() {
                _isLoading = false;
              });
            },
            onError: (error) {
              setState(() {
                _isLoading = false;
              });
              print(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                _isLoading = false;
              });
              print('$page: ${error.toString()}');
            },
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Container(),
        ],
      ),
    );
  }
}



class PdfWebPreviewScreen extends StatefulWidget {
  final String url;

  const PdfWebPreviewScreen({required this.url});

  @override
  _PdfWebPreviewScreenState createState() => _PdfWebPreviewScreenState();
}

class _PdfWebPreviewScreenState extends State<PdfWebPreviewScreen> {
  String? localFilePath;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    final url = widget.url;
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(bytes);
      setState(() {
        localFilePath = file.path;
      });
    } else {
      // Handle error
      print('Failed to download PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Web Preview'),
      ),
      body: localFilePath != null
          ? PDFView(
        filePath: localFilePath!,
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
