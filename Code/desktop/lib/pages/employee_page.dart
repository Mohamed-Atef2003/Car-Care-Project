import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import '../dialogs/add_employee_dialog.dart';
import 'dart:async';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Load employees from Firestore
  Future<void> _loadEmployees() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final QuerySnapshot employeesSnapshot = await _firestore.collection('Employee').get();
      
      if (!mounted) return;
      
      final loadedEmployees = employeesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Add the document ID to the data for future reference
        data['docId'] = doc.id;
        return Employee.fromJson(data);
      }).toList();
      
      setState(() {
        _employees = loadedEmployees;
        _filteredEmployees = loadedEmployees;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading employees from Firestore: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load employee data: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // More advanced search from Firestore for complex queries
  Future<void> _performAdvancedSearch(String query) async {
    if (!mounted) return;
    
    // Only perform advanced search for queries with 3 or more characters
    if (query.length < 3) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First, try local search
      _onSearchChanged();
      
      // If we found some results locally, don't bother with server search
      if (_filteredEmployees.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // If no local results, try server search
      // We'll search for fields that might not be in our local model
      QuerySnapshot employeeSnapshot = await _firestore.collection('Employee')
          .where('searchIndex', arrayContains: query)
          .limit(20)
          .get();
      
      if (!mounted) return;
      
      // If no results with array search, try with regular field searches
      if (employeeSnapshot.docs.isEmpty) {
        // Search by salary (if query is a number)
        if (double.tryParse(query) != null) {
          employeeSnapshot = await _firestore.collection('Employee')
              .where('salary', isEqualTo: query)
              .limit(20)
              .get();
        }
        
        // Search by SSN (if no results yet)
        if (employeeSnapshot.docs.isEmpty) {
          employeeSnapshot = await _firestore.collection('Employee')
              .where('ssn', isGreaterThanOrEqualTo: query)
              .where('ssn', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(20)
              .get();
        }
      }
      
      if (!mounted) return;
      
      // Process results
      if (employeeSnapshot.docs.isNotEmpty) {
        final serverResults = employeeSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          return Employee.fromJson(data);
        }).toList();
        
        setState(() {
          // Merge with any existing results, avoiding duplicates
          final existingIds = _filteredEmployees.map((e) => e.docId).toSet();
          final newEmployees = serverResults.where((e) => !existingIds.contains(e.docId)).toList();
          _filteredEmployees = [..._filteredEmployees, ...newEmployees];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error performing advanced search: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() {
        _filteredEmployees = _employees;
        _currentPage = 1;
      });
      return;
    }
    
    // Perform local search immediately
    setState(() {
      _filteredEmployees = _employees
          .where((employee) =>
              employee.name.toLowerCase().contains(query) ||
              employee.station.toLowerCase().contains(query) ||
              employee.phoneNumber.toLowerCase().contains(query) ||
              employee.id.toLowerCase().contains(query) ||
              employee.birthDate.toLowerCase().contains(query))
          .toList();
      _currentPage = 1; // Reset to first page when searching
    });
    
    // Also queue up an advanced server-side search for more comprehensive results
    // Use a debounce to avoid too many Firestore calls
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performAdvancedSearch(query);
    });
  }

  // Handle adding employee and refreshing the list
  void _addEmployee(Employee employee) {
    setState(() {
      _isLoading = true; // Show loading spinner
    });
    _loadEmployees(); // Refresh the list after adding
    
    // Show success message if not already shown by dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Employee added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Handle editing employee and refreshing the list
  void _editEmployee(Employee oldEmployee, Employee newEmployee) {
    setState(() {
      _isLoading = true; // Show loading spinner
    });
    _loadEmployees(); // Refresh the list after editing
    
    // Show success message if not already shown by dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Employee updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Employee'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Close the dialog first
              Navigator.pop(dialogContext);
              
              // Then perform the delete operation
              _performDeleteEmployee(employee);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );
  }
  
  // Separate method to perform the actual deletion
  Future<void> _performDeleteEmployee(Employee employee) async {
    if (!mounted) return;
    
    try {
      // Get the document ID from the employee object
      final String? docId = employee.docId;
      if (docId != null) {
        await _firestore.collection('Employee').doc(docId).delete();
        
        if (!mounted) return;
        
        _loadEmployees(); // Refresh the list
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting employee: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete employee: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewEmployee(Employee employee) {
    // First fetch the complete employee data from Firestore including salary, working hours, and SSN
    if (!mounted) return;
    
    _firestore.collection('Employee').doc(employee.docId).get().then((docSnapshot) {
      if (!mounted) return;
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final salary = data['salary'] ?? '₪ 5000';
        final workingHours = data['workingHours'] ?? '8 hours';
        final ssn = data['ssn'] ?? '123-45-6789';
        
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(
                      child: Text(
                        'Employee Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Name field
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(employee.name),
                    const SizedBox(height: 16),
                    // Station and Salary row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Station',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildReadOnlyField(employee.station),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Salary',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildReadOnlyField('\$ $salary'), // Use dynamic salary
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Phone and Working Hours row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phone number',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildReadOnlyField(employee.phoneNumber),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Working Hours',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildReadOnlyField(workingHours), // Use dynamic working hours
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ID field
                    const Text(
                      'ID',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(employee.id),
                    const SizedBox(height: 16),
                    // Birth date field
                    const Text(
                      'Birth date',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(employee.birthDate),
                    const SizedBox(height: 16),
                    // SSN field
                    const Text(
                      'SSN',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(ssn), // Use dynamic SSN
                    const SizedBox(height: 16),
                    // Employee Photo
                    const Text(
                      'Employee Photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: employee.avatarUrl.startsWith('assets/')
                                ? Image.asset(
                                    employee.avatarUrl,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 100,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey.shade400,
                                        ),
                                      );
                                    },
                                  )
                                : Image.network(
                                    employee.avatarUrl,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 100,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey.shade400,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: Text(
                            employee.avatarUrl,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        // Document doesn't exist
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee data not found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }).catchError((error) {
      print('Error fetching employee details: $error');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load employee details: $error'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Still show the dialog with basic information
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Employee Details'),
                const SizedBox(height: 16),
                Text('Name: ${employee.name}'),
                Text('Station: ${employee.station}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildReadOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  List<Employee> get _paginatedEmployees {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex >= _filteredEmployees.length) return [];
    return _filteredEmployees.sublist(
      startIndex,
      endIndex > _filteredEmployees.length
          ? _filteredEmployees.length
          : endIndex,
    );
  }

  int get _totalPages => (_filteredEmployees.length / _itemsPerPage).ceil();

  // Clear all employees data
  Future<void> _clearAllEmployees() async {
    // No hacer nada si ya está cargando o las listas están vacías
    if (_isLoading || _employees.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear All Employees'),
          content: const Text('Are you sure you want to delete all employee data? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog first
                Navigator.of(dialogContext).pop();
                
                // Then perform the delete operation
                _performClearAllEmployees();
              },
              child: Text('Clear All', style: TextStyle(color: Colors.red[600])),
            ),
          ],
        );
      },
    );
  }
  
  // Separate method to perform the actual deletion
  Future<void> _performClearAllEmployees() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all documents in the Employee collection
      final QuerySnapshot snapshot = await _firestore.collection('Employee').get();
      
      // Delete each document in a batch
      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      if (!mounted) return;
      
      setState(() {
        _employees = [];
        _filteredEmployees = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All employee data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with search and add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Employee',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // Search field
                  Container(
                    width: 300,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by name, station, phone, ID, or date',
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.grey[600], size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (_) => _onSearchChanged(),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          ),
                        // Show loading indicator during search
                        if (_isLoading && _searchController.text.isNotEmpty)
                          Container(
                            width: 30,
                            height: 30,
                            padding: const EdgeInsets.all(6),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Clear All button
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: TextButton(
                      onPressed: (_isLoading || _employees.isEmpty) ? null : _clearAllEmployees,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        disabledForegroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add Employee button
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddEmployeeDialog(
                            onEmployeeAdded: _addEmployee,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text('Add Employee'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Table or Loading indicator
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _employees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No employees found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a new employee to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // Table header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius:
                                    const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 24),
                                  const Expanded(
                                    flex: 3,
                                    child: Text(
                                      'User Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Station',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Phone Number',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'ID',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Birth date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 60), // For action menu
                                ],
                              ),
                            ),
                            // Table content
                            Expanded(
                              child: _filteredEmployees.isEmpty
                                ? Center(
                                    child: Text(
                                      'No matching employees found',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _paginatedEmployees.length,
                                    itemBuilder: (context, index) {
                                      final employee = _paginatedEmployees[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(color: Colors.grey[200]!),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 24),
                                          child: Row(
                                            children: [
                                              // User info with avatar
                                              Expanded(
                                                flex: 3,
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundImage:
                                                          employee.avatarUrl.startsWith('assets/')
                                                          ? AssetImage(employee.avatarUrl)
                                                          : NetworkImage(employee.avatarUrl) as ImageProvider,
                                                      radius: 20,
                                                      onBackgroundImageError: (_, __) {
                                                        // Handle error silently
                                                      },
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      employee.name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Station
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  employee.station,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              // Phone
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  employee.phoneNumber,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ),
                                              // ID
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  employee.id,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ),
                                              // Birth date
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  employee.birthDate,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ),
                                              // Action menu
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert),
                                                onSelected: (value) {
                                                  switch (value) {
                                                    case 'view':
                                                      _viewEmployee(employee);
                                                      break;
                                                    case 'edit':
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            AddEmployeeDialog(
                                                          employee: employee,
                                                          onEmployeeEdited: (newEmployee) =>
                                                              _editEmployee(
                                                                  employee, newEmployee),
                                                        ),
                                                      );
                                                      break;
                                                    case 'delete':
                                                      _deleteEmployee(employee);
                                                      break;
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'view',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.visibility_outlined,
                                                            color: Colors.blue[600],
                                                            size: 20),
                                                        const SizedBox(width: 8),
                                                        const Text('View'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_outlined,
                                                            color: Colors.green[600],
                                                            size: 20),
                                                        const SizedBox(width: 8),
                                                        const Text('Edit'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_outline,
                                                            color: Colors.red[600], size: 20),
                                                        const SizedBox(width: 8),
                                                        const Text('Delete'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                            // Pagination
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: _currentPage > 1
                                        ? () => setState(() => _currentPage--)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Page $_currentPage of $_totalPages',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: _currentPage < _totalPages
                                        ? () => setState(() => _currentPage++)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
