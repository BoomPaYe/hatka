import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatka/user/Jobdetail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Internship Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const InternshipSearchScreen(),
    );
  }
}

class InternshipSearchScreen extends StatefulWidget {
  const InternshipSearchScreen({Key? key}) : super(key: key);

  @override
  _InternshipSearchScreenState createState() => _InternshipSearchScreenState();
}

class _InternshipSearchScreenState extends State<InternshipSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _internships = [];
  List<DocumentSnapshot> _filteredInternships = [];
  bool _isLoading = true;
  bool _showFilters = false;
  bool _isSearching = false; // Track if user is actively searching

  Map<String, Map<String, dynamic>> _userData = {};

  // Filter states
  Set<String> _selectedLocations = {};
  Set<String> _selectedJobTypes = {};
  Set<String> _selectedIndustries = {};

  // Options from your images
  final List<String> _locationOptions = [
    'Phnom Penh',
    'Tuol Kouk',
    'Chamkar Mon',
    'Chbar Ampov',
    'Daun Penh',
    'Mean Chey',
    'Sen Sok',
    'Por Senchey'
  ];

  final List<String> _jobTypeOptions = ['Full-Time', 'Part-Time'];

  final List<String> _industryOptions = [
    'Finance',
    'IT',
    'Telecommunications',
    'Creative Arts',
    'Health Care',
    'Education',
    'Fashion',
    'Entertainment',
    'Marketing'
  ];

  @override
  void initState() {
    super.initState();
    _fetchInternships();
  }

  Future<void> _fetchInternships() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('posts').get();

      setState(() {
        _internships = querySnapshot.docs;
        // Initially, only show active internships
        _filteredInternships = _filterActiveInternships(querySnapshot.docs);
      });

      // Fetch user data for each post
      await _fetchUserData();
    } catch (e) {
      print('Error fetching internships: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to filter only active internships
  List<DocumentSnapshot> _filterActiveInternships(List<DocumentSnapshot> internships) {
    return internships.where((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['isActive'] == true;
    }).toList();
  }

  Future<void> _fetchUserData() async {
    try {
      // Get unique user IDs from the posts
      Set<String> userIds = {};
      for (var doc in _internships) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['userId'] != null) {
          userIds.add(data['userId'].toString());
        }
      }

      // Fetch user data for each unique user ID
      for (String userId in userIds) {
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          
          if (userDoc.exists) {
            _userData[userId] = userDoc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          print('Error fetching user data for user $userId: $e');
        }
      }

      // Update state to trigger a rebuild with the user data
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error in _fetchUserData: $e');
    }
  }

  void _handleSearch(String value) {
  setState(() {
    _isSearching = value.isNotEmpty; // Set to true when searching
    
    // When searching, use all internships
    // When not searching, filter to active only
    _filteredInternships = _isSearching 
        ? _internships.where((internship) {
            Map<String, dynamic> data = internship.data() as Map<String, dynamic>;
            return (data['title'] ?? '')
                .toString()
                .toLowerCase()
                .contains(value.toLowerCase());
          }).toList() 
        : _filterActiveInternships(_internships);
        
    // Apply other filters
    _applyFilters();
  });
}

void _applyFilters() {
  setState(() {
    // Choose the appropriate base list based on whether user is searching
    List<DocumentSnapshot> baseList = _isSearching 
        ? _internships 
        : _filterActiveInternships(_internships);
    
    _filteredInternships = baseList.where((internship) {
      Map<String, dynamic> data = internship.data() as Map<String, dynamic>;

      // Apply location filter
      bool locationMatch = _selectedLocations.isEmpty ||
          (_selectedLocations
              .contains(data['location']?.toString().toLowerCase() ?? ''));

      // Apply job type filter
      bool jobTypeMatch = _selectedJobTypes.isEmpty ||
          (_selectedJobTypes.contains(
              data['internshipType']?.toString().toLowerCase() ?? ''));

      // Apply industry/category filter
      bool industryMatch = _selectedIndustries.isEmpty ||
          (_selectedIndustries
              .contains(data['category']?.toString().toLowerCase() ?? ''));

      // Apply search text if searching
      bool searchMatch = !_isSearching || _searchController.text.isEmpty ||
          (data['title'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());

      return locationMatch && jobTypeMatch && industryMatch && searchMatch;
    }).toList();

    _showFilters = false;
  });
}

  void _resetFilters() {
    setState(() {
      _selectedLocations = {};
      _selectedJobTypes = {};
      _selectedIndustries = {};
      _searchController.clear();
      _isSearching = false;
      
      // If not searching, only show active internships
      _filteredInternships = _filterActiveInternships(_internships);
      _showFilters = false;
    });
  }

  // Get count of active internships
  int get _activeInternshipsCount {
    return _internships.where((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['isActive'] == true;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _showFilters ? _buildFiltersScreen() : _buildSearchScreen(),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    if (timestamp is Timestamp) {
      return timeago.format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return timeago.format(timestamp);
    } else {
      return 'Today';
    }
  }

  Widget _buildSearchScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search your favorite\ninternships',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search the job',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: _handleSearch,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showFilters = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _isSearching
                    ? '${_filteredInternships.length} Internship Results'
                    : '$_activeInternshipsCount Active Internship Opportunities',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isSearching && _filteredInternships.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Note: Search results include both active and inactive internships',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredInternships.isEmpty
                  ? const Center(child: Text('No internships found'))
                  : ListView.builder(
                      itemCount: _filteredInternships.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot doc = _filteredInternships[index];
                        Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;
                        
                        // Add the document ID to the data map
                        Map<String, dynamic> jobWithId = {
                          ...data,
                          'id': doc.id,
                        };
                        
                        return _buildInternshipCard(jobWithId);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildInternshipCard(Map<String, dynamic> job) {
    // Extract user data
    String userId = job['userId'] ?? '';
    String userName = 'Unknown User';
    String profileImageUrl = '';
    String activeStatus = job['isActive'] == true ? 'Active' : 'Inactive';

    // Get user data if available
    if (userId.isNotEmpty && _userData.containsKey(userId)) {
      userName = _userData[userId]?['name'] ?? 'Unknown User';
      profileImageUrl = _userData[userId]?['profileImage'] ?? '';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserProfileImage(profileImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          job['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatDate(job['createdAt']),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (job.containsKey('isActive'))
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: activeStatus == 'Active'
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              activeStatus,
                              style: TextStyle(
                                fontSize: 10,
                                color: activeStatus == 'Active'
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: Colors.grey.shade500, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          job['location'] ?? 'Unknown Location',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChip(job['workspaceType'] ?? 'On-site'),
                        const SizedBox(width: 8),
                        _buildChip(job['internshipType'] ?? 'Full-Time'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileImage(String profileImageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        color: Colors.green.shade100,
        child: profileImageUrl.isNotEmpty
            ? Image.network(
                profileImageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultLogo(),
              )
            : _buildDefaultLogo(),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.green.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.work_outline,
        color: Colors.green.shade700,
        size: 20,
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade500,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

 Widget _buildFiltersScreen() {
  return Stack(
    children: [
      // Make this part scrollable
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showFilters = false;
                      });
                    },
                  ),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 40), // For balance
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Filter by:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Locations',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _locationOptions.map((location) {
                  bool isSelected =
                      _selectedLocations.contains(location.toLowerCase());
                  return FilterChip(
                    label: Text(location),
                    selected: isSelected,
                    backgroundColor: Colors.white,
                    selectedColor: Colors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLocations.add(location.toLowerCase());
                        } else {
                          _selectedLocations.remove(location.toLowerCase());
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Job types',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _jobTypeOptions.map((jobType) {
                  bool isSelected =
                      _selectedJobTypes.contains(jobType.toLowerCase());
                  return FilterChip(
                    label: Text(jobType),
                    selected: isSelected,
                    backgroundColor: Colors.white,
                    selectedColor: Colors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedJobTypes.add(jobType.toLowerCase());
                        } else {
                          _selectedJobTypes.remove(jobType.toLowerCase());
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Industries',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _industryOptions.map((industry) {
                  bool isSelected =
                      _selectedIndustries.contains(industry.toLowerCase());
                  return FilterChip(
                    label: Text(industry),
                    selected: isSelected,
                    backgroundColor: Colors.white,
                    selectedColor: Colors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedIndustries.add(industry.toLowerCase());
                        } else {
                          _selectedIndustries.remove(industry.toLowerCase());
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              // Add padding at the bottom to ensure space for the buttons
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      // Keep the buttons fixed at the bottom
      Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetFilters,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Reset Filter'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}