import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';


// Cloudinary credentials
const String cloudinaryCloudName = 'your-cloud-name';
const String cloudinaryUploadPreset =
    'your-upload-preset'; // Optional if using unsigned uploads

class ApplicationScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const ApplicationScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final cloudinary = CloudinaryPublic('dbo1t0quj', 'pdfapplication', cache: false);

  File? _resumeFile;
  String _resumeFileName = '';
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  bool _firebaseAvailable = true;
  bool _cloudinaryAvailable = true;
  late DatabaseReference _databaseRef;
  late CloudinaryPublic _cloudinary;

  @override
  void initState() {
    super.initState();
    // Initialize Cloudinary client
    _cloudinary = CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset);

    // Initialize Firebase database reference
    _databaseRef = FirebaseDatabase.instance.ref();

    // Check if services are available
    _checkCloudinaryAvailability();
    _checkFirebaseConnection();
  }

  Future<void> _checkCloudinaryAvailability() async {
    try {
      // Test Cloudinary connection by making a simple ping request
      final response = await http
          .get(
            Uri.parse(
                'https://api.cloudinary.com/v1_1/dbo1t0quj/ping'),
          )
          .timeout(const Duration(seconds: 5));

      setState(() {
        _cloudinaryAvailable = response.statusCode == 200;
      });
      print('Cloudinary available: $_cloudinaryAvailable');
    } catch (e) {
      print('Cloudinary not available: $e');
      setState(() {
        _cloudinaryAvailable = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume upload service unavailable')),
        );
      }
    }
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      // Test Firebase connection with a timeout
      final connectivityTest = await _databaseRef
          .child('.info/connected')
          .get()
          .timeout(const Duration(seconds: 5));
      setState(() {
        _firebaseAvailable =
            connectivityTest.exists && connectivityTest.value == true;
      });
    } catch (e) {
      print('Firebase connection error: $e');
      setState(() {
        _firebaseAvailable = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    if (!_cloudinaryAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'File upload is currently unavailable. You can still submit your application without a resume.')),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      // Add debug print to check what's being returned
      print("FilePicker result: $result");

      if (result != null && result.files.single.path != null) {
        // Add debug print to check file path
        print("Selected file path: ${result.files.single.path}");

        setState(() {
          _resumeFile = File(result.files.single.path!);
          _resumeFileName = result.files.single.name;
        });

        // Verify file exists after setting
        print("File exists after setting: ${_resumeFile?.existsSync()}");
      }
    } catch (e) {
      print("Error picking file: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<String?> _uploadToCloudinary(File file) async {
  try {
    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Auto),
    );
    print('File uploaded: ${response.secureUrl}');
    return response.secureUrl;
  } catch (e) {
    print('Upload error: $e');
    return null;
  }
}

  Future<String?> _uploadToCloudinaryDirectApi(File file) async {
    try {
      print('Trying direct API upload to Cloudinary...');

      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/raw/upload');

      final uniqueFileName = const Uuid().v4();

      // Create multipart request
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..fields['folder'] = 'resumes'
        ..fields['public_id'] = uniqueFileName
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('application', 'pdf'),
        ));

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Direct API upload successful: ${responseData['secure_url']}');
        return responseData['secure_url'];
      } else {
        print(
            'Direct API upload failed: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to upload file: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Direct API upload error: $e');
      throw e;
    }
  }

  Future<void> _saveApplicationLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final applicationData = {
        'postId': widget.job['id'] ?? 'unknown',
        'jobTitle': widget.job['title'] ?? 'unknown',
        'fullName': _nameController.text,
        'email': _emailController.text,
        'summary': _summaryController.text,
        'resumeFileName': _resumeFileName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Save as JSON string
      final List<String> savedApplications =
          prefs.getStringList('savedApplications') ?? [];
      savedApplications.add(jsonEncode(applicationData));
      await prefs.setStringList('savedApplications', savedApplications);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Application saved locally. We\'ll upload it when the service is available.')),
      );

      setState(() {
        _hasSubmitted = true;
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving locally: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (_isSubmitting || _hasSubmitted) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print("Form validation failed");
      return;
    }

    print("Starting submission process");
    setState(() {
      _isSubmitting = true;
    });

    try {
      String? downloadUrl;

      // Only try to upload file if Cloudinary is available and we have a file
      if (_cloudinaryAvailable && _resumeFile != null) {
        try {
          print('Trying to upload resume file: ${_resumeFile!.path}');
          downloadUrl = await _uploadToCloudinary(_resumeFile!);
          print('Successfully uploaded: $downloadUrl');
        } catch (e) {
          print('File upload failed: $e');
          String errorMessage = 'Resume upload failed';

          errorMessage += ': ${e.toString()}';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        }
      }

      // Try to save to Firebase or save locally if Firebase is unavailable
      if (_firebaseAvailable) {
        try {
          print('Attempting to save to Firebase applications collection...');

          // Sanitize email for Firebase key (Firebase doesn't allow '.', '#', '$', '[', or ']' in keys)
          final String userKey = _emailController.text
              .replaceAll('.', '_')
              .replaceAll('@', '_')
              .replaceAll('#', '_')
              .replaceAll('[', '_')
              .replaceAll(']', '_');

          // Get a reference to the Firebase database applications collection
          final DatabaseReference applicationRef =
              _databaseRef.child('applications').push();

          // Prepare the application data
          Map<String, dynamic> applicationData = {
            'jobId': widget.job['id'] ?? 'unknown',
            'jobTitle': widget.job['title'] ?? 'unknown',
            'fullName': _nameController.text,
            'email': _emailController.text,
            'summary': _summaryController.text,
            'resumeUrl': downloadUrl,
            'hasResume': downloadUrl != null,
            'resumeFileName': _resumeFileName,
            'timestamp': ServerValue.timestamp,
            'storageProvider': downloadUrl != null ? 'cloudinary' : null,
          };

          print('Application data prepared: $applicationData');

          // Set the application data in Firebase
          await applicationRef.set(applicationData);
          print('Successfully saved to Firebase applications collection');

          // Show success message and mark as submitted
          if (mounted) {
            setState(() {
              _hasSubmitted = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Application submitted successfully!')),
            );
            Navigator.pop(context);
          }
        } catch (firebaseError) {
          print('Firebase save failed: $firebaseError');
          setState(() {
            _firebaseAvailable = false;
          });

          // Show dialog to save locally instead
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text("Connection Error"),
                content: const Text(
                    "We can't connect to our servers right now. Would you like to save your application locally instead?"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _isSubmitting = false;
                      });
                    },
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _saveApplicationLocally();
                    },
                    child: const Text("Save Locally"),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        // If Firebase is unavailable from the start, directly save locally
        _saveApplicationLocally();
      }
    } catch (e) {
      print('Overall submission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting application: $e')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    } finally {
      if (mounted && !_hasSubmitted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Job'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning banner if services are unavailable
                if (!_firebaseAvailable || !_cloudinaryAvailable)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.amber[700], size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Limited Connectivity',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                !_cloudinaryAvailable
                                    ? 'Resume upload is currently unavailable. You can still submit your application without a resume.'
                                    : !_firebaseAvailable
                                        ? 'Application will be saved locally and uploaded later.'
                                        : 'Some features may be unavailable.',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.amber[900]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Success message if submission was successful
                if (_hasSubmitted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green[700]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[800]),
                            const SizedBox(width: 8),
                            const Text(
                              'Application Submitted',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your application has been successfully submitted!',
                          style:
                              TextStyle(fontSize: 12, color: Colors.green[900]),
                        ),
                      ],
                    ),
                  ),
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  enabled: !_hasSubmitted, // Disable if already submitted
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Email',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  enabled: !_hasSubmitted, // Disable if already submitted
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload Resume',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Be sure to include an updated resume (PDF, DOC, or DOCX)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: (_cloudinaryAvailable && !_hasSubmitted)
                      ? _pickDocument
                      : null,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: (_cloudinaryAvailable && !_hasSubmitted)
                              ? Colors.blue[200]!
                              : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: (_cloudinaryAvailable && !_hasSubmitted)
                          ? Colors.blue[50]
                          : Colors.grey[100],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _resumeFile == null
                                ? Icons.upload_file
                                : Icons.description,
                            color: (_cloudinaryAvailable && !_hasSubmitted)
                                ? Colors.blue[700]
                                : Colors.grey[400],
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _resumeFile == null
                                ? (_cloudinaryAvailable && !_hasSubmitted)
                                    ? 'Tap to select resume file'
                                    : !_cloudinaryAvailable
                                        ? 'File upload unavailable'
                                        : 'Form already submitted'
                                : _resumeFileName,
                            style: TextStyle(
                              color: (_cloudinaryAvailable && !_hasSubmitted)
                                  ? Colors.blue[700]
                                  : Colors.grey[600],
                              fontWeight: _resumeFile != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                          if (!_cloudinaryAvailable)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'You can continue without a resume',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cover Letter / Additional Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _summaryController,
                  enabled: !_hasSubmitted, // Disable if already submitted
                  decoration: const InputDecoration(
                    hintText:
                        'Describe why you\'re a good fit for this position',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  maxLines: 6,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || _hasSubmitted)
                        ? null
                        : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _hasSubmitted ? Colors.green[300] : Colors.grey[300],
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : _hasSubmitted
                            ? const Text('Application Submitted')
                            : const Text('Submit Application'),
                  ),
                ),
                if (_hasSubmitted)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Return to Job Listing'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
