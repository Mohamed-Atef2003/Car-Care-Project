import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, FieldValue;
import 'package:flutter/material.dart';
import 'package:car_care/models/employee.dart';
import 'package:flutter/services.dart';

class AddEmployeeDialog extends StatefulWidget {
  final Employee? employee;
  final Function(Employee)? onEmployeeAdded;
  final Function(Employee)? onEmployeeEdited;

  const AddEmployeeDialog({
    super.key,
    this.employee,
    this.onEmployeeAdded,
    this.onEmployeeEdited,
  });

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStation;
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _ssnController = TextEditingController();
  final _salaryController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _nameController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final List<String> _stations = [
    'Downtown Auto Service',
    'Alexandria Car Clinic',
    'Giza Auto Repair Hub',
    'Nasr City Motor Works',
    'El Obour Auto Fix',
    'Heliopolis Auto Tech',
    'Smart Auto Center',
    'Mansoura Auto Experts',
    'Sharqia Auto Care Center',
    'Sinai Auto Service',
    'Port Said Car Clinic',
    'Aswan Service Hub',
    'Damietta Auto Solutions',
    'Luxor Car Care',
    'New Cairo Advanced Auto',
    'Suez Auto Repair',
    'Fayoum Car Service',
    'Beni Suef Auto Clinic',
    'Minya Auto Solutions',
    'Sohag Car Care',
    'Red Sea Auto Repair',
    'Sharm El Sheikh Car Clinic',
    'Hurghada Auto Hub',
    'El-Mahalla Auto Experts',
    'Zagazig Advanced Service',
    'Cairo Elite Auto',
    'Alexandria Premier Auto',
    'Giza Pro Auto Care',
    'Port Said Motor Clinic',
    'Damietta Car Solutions',
    'Obour Auto Center',
  ];

  final List<String> _commonWorkingHours = [
    '8 hours',
    '6 hours',
    '4 hours',
    'Part-time (20h/week)',
    'Full-time (40h/week)',
  ];

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }

    final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number (10-15 digits)';
    }
    return null;
  }

  String? _validateSSN(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter SSN';
    }

    final RegExp ssnRegex = RegExp(r'^(\d{14}|\d{3}-\d{3}-\d{4}-\d{4}|\d{3}-\d{3}-\d{8})$');
    if (!ssnRegex.hasMatch(value)) {
      return 'Enter a valid SSN (14 digits)';
    }
    return null;
  }

  String? _validateSalary(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter salary';
    }

    final salary = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (salary == null) {
      return 'Enter a valid salary amount';
    }

    if (salary < 1000 || salary > 100000) {
      return 'Salary should be between 1,000 and 100,000';
    }
    return null;
  }

  String? _validateID(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter ID';
    }

    final RegExp idRegex = RegExp(r'^\d{5,12}$');
    if (!idRegex.hasMatch(value)) {
      return 'Enter a valid ID (5-12 digits)';
    }
    return null;
  }

  void _formatPhoneNumber(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^\d+]'), '');

    if (digitsOnly.startsWith('+')) {
      _phoneController.value = TextEditingValue(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
    } else if (digitsOnly.isNotEmpty) {
      if (digitsOnly.length >= 10) {
        final formattedValue = '+${digitsOnly.substring(0, digitsOnly.length)}';
        _phoneController.value = TextEditingValue(
          text: formattedValue,
          selection: TextSelection.collapsed(offset: formattedValue.length),
        );
      } else {
        _phoneController.value = TextEditingValue(
          text: digitsOnly,
          selection: TextSelection.collapsed(offset: digitsOnly.length),
        );
      }
    }
  }

  void _formatSSN(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length <= 14) {
      String formattedValue = digitsOnly;

      // Format as XXX-XXX-XXXX-XXXX or XXX-XXX-XXXXXXXX
      if (digitsOnly.length > 10) {
        formattedValue =
            '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6, 10)}-${digitsOnly.substring(10)}';
      } else if (digitsOnly.length > 6) {
        formattedValue =
            '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
      } else if (digitsOnly.length > 3) {
        formattedValue =
            '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
      }

      _ssnController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }
  }

  void _formatID(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length <= 12) {
      _idController.value = TextEditingValue(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
    }
  }

  Future<void> _Add_employee(
      String name,
      String station,
      String salary,
      String phone,
      String workingHours,
      String id,
      String birthDate,
      String ssn,
      String imageUrl) async {
    // Create search index - lowercase tokens for better searching
    List<String> searchTokens = [
      name.toLowerCase(),
      station.toLowerCase(),
      phone.toLowerCase(),
      id.toLowerCase(),
      birthDate.toLowerCase(),
      ssn.toLowerCase(),
      salary.toLowerCase(),
      workingHours.toLowerCase(),
    ];

    // Add individual words from name for better search
    searchTokens.addAll(name.toLowerCase().split(' '));

    // Remove duplicates
    searchTokens = searchTokens.toSet().toList();

    if (widget.employee != null && widget.employee!.docId != null) {
      // Update existing employee
      await FirebaseFirestore.instance
          .collection('Employee')
          .doc(widget.employee!.docId)
          .update({
        'name': _nameController.text,
        'station': _selectedStation,
        'salary': _salaryController.text,
        'phone': _phoneController.text,
        'phoneNumber':
            _phoneController.text, // For compatibility with Employee model
        'workingHours': _workingHoursController.text,
        'id': _idController.text,
        'birthDate': _birthDateController.text,
        'ssn': _ssnController.text,
        'imageUrl': _imageUrlController.text,
        'avatarUrl':
            _imageUrlController.text, // For compatibility with Employee model
        'searchIndex': searchTokens,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      // Add new employee
      await FirebaseFirestore.instance.collection('Employee').add({
        'name': _nameController.text,
        'station': _selectedStation,
        'salary': _salaryController.text,
        'phone': _phoneController.text,
        'phoneNumber':
            _phoneController.text, // For compatibility with Employee model
        'workingHours': _workingHoursController.text,
        'id': _idController.text,
        'birthDate': _birthDateController.text,
        'ssn': _ssnController.text,
        'imageUrl': _imageUrlController.text,
        'avatarUrl':
            _imageUrlController.text, // For compatibility with Employee model
        'searchIndex': searchTokens,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _phoneController.addListener(() {
      final currentValue = _phoneController.text;
      if (currentValue.isNotEmpty && !currentValue.startsWith('+')) {
        _formatPhoneNumber(currentValue);
      }
    });

    _ssnController.addListener(() {
      final currentValue = _ssnController.text;
      if (currentValue.isNotEmpty &&
          !currentValue.contains('-') &&
          currentValue.length > 3) {
        _formatSSN(currentValue);
      }
    });

    _idController.addListener(() {
      final currentValue = _idController.text;
      if (currentValue.isNotEmpty && currentValue.contains(RegExp(r'[^\d]'))) {
        _formatID(currentValue);
      }
    });

    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      
      // Check if the employee's station exists in the current station list
      if (_stations.contains(widget.employee!.station)) {
        _selectedStation = widget.employee!.station;
      } else {
        // If not in the list, set to the first station as default
        _selectedStation = _stations[0];
        // We could also add it dynamically if needed:
        // _stations.add(widget.employee!.station);
        // _selectedStation = widget.employee!.station;
      }
      
      _phoneController.text = widget.employee!.phoneNumber;
      _idController.text = widget.employee!.id;
      _birthDateController.text = widget.employee!.birthDate;
      _imageUrlController.text = widget.employee!.avatarUrl;

      // Fetch additional fields from Firestore if we have a docId
      if (widget.employee!.docId != null) {
        FirebaseFirestore.instance
            .collection('Employee')
            .doc(widget.employee!.docId)
            .get()
            .then((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            setState(() {
              _salaryController.text = data['salary'] ?? '';
              _workingHoursController.text = data['workingHours'] ?? '';
              _ssnController.text = data['ssn'] ?? '';

              // Update image URL if available
              if (data['imageUrl'] != null &&
                  data['imageUrl'].toString().isNotEmpty) {
                _imageUrlController.text = data['imageUrl'];
              } else if (data['avatarUrl'] != null &&
                  data['avatarUrl'].toString().isNotEmpty) {
                _imageUrlController.text = data['avatarUrl'];
              }
            });
          }
        }).catchError((error) {
          print('Error fetching complete employee data: $error');
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _idController.dispose();
    _birthDateController.dispose();
    _ssnController.dispose();
    _salaryController.dispose();
    _workingHoursController.dispose();
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // Function to calculate employee age from birth date
  String _calculateAge(String birthDateStr) {
    try {
      // Convert text to date
      final parts = birthDateStr.split('/');
      if (parts.length != 3) return '';

      final birthDate = DateTime(
          int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
      final today = DateTime.now();

      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age.toString();
    } catch (e) {
      return '';
    }
  }

  // Improved date picker function
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDateController.text.isNotEmpty
          ? _parseDate(_birthDateController.text) ??
              DateTime.now()
                  .subtract(const Duration(days: 365 * 25)) // Default 25 years
          : DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Select Birth Date',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
      errorFormatText: 'Enter a valid date',
      errorInvalidText: 'Enter a valid date range',
      fieldLabelText: 'Birth Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
            "${picked.month}/${picked.day}/${picked.year}";
      });
    }
  }

  // Convert text to date
  DateTime? _parseDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        return DateTime(
            int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Variable to track save state
  bool _isSaving = false;

  // Improved form submission function
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Activate loading state
      setState(() {
        _isSaving = true;
      });

      try {
        // Check for required field
        if (_selectedStation == null) {
          throw Exception('Please select a station');
        }

        final employee = Employee(
          name: _nameController.text,
          station: _selectedStation!,
          phoneNumber: _phoneController.text,
          id: _idController.text,
          birthDate: _birthDateController.text,
          avatarUrl: _imageUrlController.text.isNotEmpty
              ? _imageUrlController.text
              : 'assets/image/profile.png',
          docId: widget.employee?.docId,
        );

        // Save data to Firestore
        await _Add_employee(
            _nameController.text,
            _selectedStation!,
            _salaryController.text,
            _phoneController.text,
            _workingHoursController.text,
            _idController.text,
            _birthDateController.text,
            _ssnController.text,
            _imageUrlController.text);

        // Notify parent of changes
        if (widget.employee != null) {
          widget.onEmployeeEdited?.call(employee);
        } else {
          widget.onEmployeeAdded?.call(employee);
        }

        // Close form
        Navigator.pop(context);

        // Display success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.employee != null ? 'Updated' : 'Added'} employee successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error saving employee: $e');
        
        // Reset button to normal state
        setState(() {
          _isSaving = false;
        });

        // Display error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    widget.employee != null ? 'Edit Employee' : 'Add Employee',
                    style: const TextStyle(
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
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Employee Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
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
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedStation,
                            decoration: InputDecoration(
                              hintText: 'Select Station',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            items: _stations.map((String station) {
                              return DropdownMenuItem<String>(
                                value: station,
                                child: Text(
                                  station,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStation = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a station';
                              }
                              return null;
                            },
                          ),
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
                          TextFormField(
                            controller: _salaryController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixIcon:
                                  const Icon(Icons.monetization_on_outlined),
                              hintText: '5000',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            validator: _validateSalary,
                            onChanged: (value) {
                              // Optional: Format the number during typing
                              if (value.isNotEmpty) {
                                // Remove non-numeric characters except period
                                final cleanValue =
                                    value.replaceAll(RegExp(r'[^\d.]'), '');
                                if (cleanValue != value) {
                                  _salaryController.value = TextEditingValue(
                                    text: cleanValue,
                                    selection: TextSelection.collapsed(
                                        offset: cleanValue.length),
                                  );
                                }
                              }
                            },
                          ),
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
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: '+20 120 123 4567',
                                    prefixIcon:
                                        const Icon(Icons.phone_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Colors.grey, width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Colors.grey, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.blue.shade700,
                                          width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.red.shade700, width: 1),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  validator: _validatePhoneNumber,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9+\s]')),
                                    LengthLimitingTextInputFormatter(20),
                                  ],
                                  onChanged: (value) {
                                    // Check if the number already contains + at the beginning
                                    if (value.isNotEmpty &&
                                        !value.startsWith('+')) {
                                      // Automatically format Palestinian numbers
                                      if ((value.startsWith('059') ||
                                              value.startsWith('056')) &&
                                          value.length >= 3) {
                                        final digitsOnly = value.replaceAll(
                                            RegExp(r'[^\d]'), '');
                                        _phoneController.value =
                                            TextEditingValue(
                                          text:
                                              '+970 ${digitsOnly.substring(0, 2)} ${digitsOnly.substring(2)}',
                                          selection: TextSelection.collapsed(
                                              offset: digitsOnly.length + 6),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
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
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _workingHoursController.text.isNotEmpty
                                ? _workingHoursController.text
                                : null,
                            decoration: InputDecoration(
                              hintText: 'Select Hours',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            items: _commonWorkingHours.map((String hours) {
                              return DropdownMenuItem<String>(
                                value: hours,
                                child: Text(
                                  hours,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _workingHoursController.text = newValue;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select working hours';
                              }
                              return null;
                            },
                          ),
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
                TextFormField(
                  controller: _idController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Example: 123456789',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Enter a valid ID number consisting of 5-12 digits'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.red.shade700, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  validator: _validateID,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                ),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _birthDateController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          hintText: 'MM/DD/YYYY',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.blue.shade700, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select birth date';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_birthDateController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Age',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _calculateAge(_birthDateController.text),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
               
                // SSN field
                const Text(
                  'SSN',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ssnController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'XXX-XXX-XXXX-XXXX',
                    prefixIcon: const Icon(Icons.credit_card_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.red.shade700, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  validator: _validateSSN,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
                    LengthLimitingTextInputFormatter(
                        17), // 14 digits + 3 dashes = 17
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text;
                      if (text.isEmpty) return newValue;

                      // Only format if we don't already have dashes
                      if (!text.contains('-')) {
                        final digitsOnly =
                            text.replaceAll(RegExp(r'[^\d]'), '');
                        if (digitsOnly.length <= 14) {
                          String formattedText = digitsOnly;
                          if (digitsOnly.length > 10) {
                            formattedText =
                                '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6, 10)}-${digitsOnly.substring(10)}';
                          } else if (digitsOnly.length > 6) {
                            formattedText =
                                '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
                          } else if (digitsOnly.length > 3) {
                            formattedText =
                                '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
                          }

                          return TextEditingValue(
                            text: formattedText,
                            selection: TextSelection.collapsed(
                                offset: formattedText.length),
                          );
                        }
                      }
                      return newValue;
                    }),
                  ],
                ),
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
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Preview image
                            if (_imageUrlController.text.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(75),
                                child:
                                    _imageUrlController.text.startsWith('http')
                                        ? Image.network(
                                            _imageUrlController.text,
                                            height: 120,
                                            width: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                height: 120,
                                                width: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(60),
                                                ),
                                                child: Icon(
                                                  Icons.error_outline,
                                                  size: 40,
                                                  color: Colors.red.shade400,
                                                ),
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            _imageUrlController.text,
                                            height: 120,
                                            width: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                height: 120,
                                                width: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(60),
                                                ),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: Colors.grey.shade400,
                                                ),
                                              );
                                            },
                                          ),
                              )
                            else
                              // Default person icon
                              Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Image URL field
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Image link',
                        hintText: 'Enter image link here',
                        prefixIcon: const Icon(Icons.link),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {
                              // Update preview
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        helperText:
                            'Enter a valid image link in http:// or https:// format',
                      ),
                      onChanged: (value) {
                        // Update preview when text changes
                        setState(() {
                        });
                      },
                      onFieldSubmitted: (value) {
                        // Update preview when Enter is pressed
                        setState(() {
                        });
                      },
                    ),
                    if (_imageUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear link'),
                              onPressed: () {
                                setState(() {
                                  _imageUrlController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text(
                        'cancel',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        foregroundColor: Colors.black87,
                        disabledForegroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submitForm,
                      icon: _isSaving
                          ? Container(
                              width: 20,
                              height: 20,
                              padding: const EdgeInsets.all(2),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              widget.employee != null
                                  ? Icons.save_outlined
                                  : Icons.add_circle_outline,
                            ),
                      label: Text(
                        widget.employee != null
                            ? 'Save changes'
                            : 'Add Employee',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.blue.shade300,
                        disabledForegroundColor: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
