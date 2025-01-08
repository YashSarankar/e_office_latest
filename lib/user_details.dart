import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider_android/path_provider_android.dart';

import 'salary_R/services/notification_service.dart';

class UserDetailView extends StatefulWidget {
  @override
  _UserDetailViewState createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  String? _userId; // For dynamic user ID
  String? _pdfUrl; // For API-generated PDF URL
  bool _isLoading = true; // For loading state

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  // Fetch user ID from SharedPreferences and construct the API URL
  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    if (userId != null && userId.isNotEmpty) {
      setState(() {
        _userId = userId;
        _pdfUrl = 'https://eofficess.com/api/user-details/$userId/pdf';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
    }
  }

  // Download the PDF and save it to the device
Future<void> _downloadPdf() async {
  if (_pdfUrl == null) return;

  try {
    // Request permission to access external storage
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Storage permission is required to download files'),
        ),
      );
      return;
    }

    // Get the Downloads directory path
    final downloadsDirectory = Directory('/storage/emulated/0/Download');
    if (!downloadsDirectory.existsSync()) {
      downloadsDirectory.createSync();
    }

    final filePath = '${downloadsDirectory.path}/user_details.pdf';

    // Download the file
    await Dio().download(_pdfUrl!, filePath);

    ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
          ),
        );

    // Trigger a notification after successful download
    await NotificationService.showNotification(
      title: 'Download Complete',
      body: 'Your PDF has been downloaded to $filePath.',
    );

    // Open the file after download
    OpenFile.open(filePath);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to download PDF: $e')),
    );
  }
}

//________________________________________________________________

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title: const Text('User Details',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: const Color(0xFF4769B2),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading indicator
          : _pdfUrl == null
              ? const Center(child: Text('Unable to fetch user details'))
              : Column(
                  children: [
                    // PDF Viewer in center
                    Expanded(
                      child: SfPdfViewer.network(_pdfUrl!),
                    ),

                    // Download Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _downloadPdf, // Logic for downloading PDF
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4769B2),
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Download Data",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
