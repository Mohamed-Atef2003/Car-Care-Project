import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddAppointmentDialog extends StatefulWidget {
  final Function onAppointmentAdded;

  const AddAppointmentDialog({
    super.key,
    required this.onAppointmentAdded,
  });

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _carModelController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedService = 'Car Inspection';
  String _selectedCenter = 'Downtown Auto Service';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;
  String? _errorMessage;

  // Customer and Car selection state
  String? _selectedCustomerId;
  String? _selectedCarId;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _customerCars = [];
  bool _loadingCustomers = false;

  final List<String> _availableServices = [
    'Car Inspection',
    'Oil Change',
    'AC Inspection',
    'Brake Repair',
    'Electrical Inspection',
    'Parts Replacement',
    'Tire Change',
    'Air Filter Change',
  ];

  final List<String> _availableCenters = [
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

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _carModelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _loadingCustomers = true;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('customer_account').get();
      setState(() {
        _customers = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'email': data['email'] ?? '',
            'mobile': data['mobile'] ?? '',
          };
        }).toList();
        _loadingCustomers = false;
      });
    } catch (e) {
      print('Error fetching customers: $e');
      setState(() {
        _loadingCustomers = false;
      });
    }
  }

  Future<void> _fetchCustomerCars(String customerId) async {
    setState(() {
      _customerCars = [];
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('customerId', isEqualTo: customerId)
          .get();

      setState(() {
        _customerCars = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'brand': data['brand'] ?? '',
            'model': data['model'] ?? '',
            'modelYear': data['modelYear'] ?? '',
            'carNumber': data['carNumber'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching customer cars: $e');
    }
  }

  void _onCustomerSelected(String? customerId) {
    if (customerId != null) {
      setState(() {
        _selectedCustomerId = customerId;
        _selectedCarId = null;
      });

      // Fill customer information
      final customer = _customers.firstWhere((c) => c['id'] == customerId);
      _customerNameController.text =
          '${customer['firstName']} ${customer['lastName']}';
      _customerPhoneController.text = customer['mobile'];
      _customerEmailController.text = customer['email'];

      // Fetch customer cars
      _fetchCustomerCars(customerId);
    }
  }

  void _onCarSelected(String? carId) {
    if (carId != null) {
      setState(() {
        _selectedCarId = carId;
      });

      // Fetch complete car information
      _fetchCarDetails(carId);
    }
  }

  Future<void> _fetchCarDetails(String carId) async {
    try {
      final carDoc =
          await FirebaseFirestore.instance.collection('cars').doc(carId).get();

      if (carDoc.exists && carDoc.data() != null) {
        final carData = carDoc.data()!;
        setState(() {
          _carModelController.text = [
            carData['brand'] ?? '',
            carData['model'] ?? '',
            carData['modelYear']?.toString() ?? '',
          ].where((s) => s.isNotEmpty).join(' ');
        });
      } else {
        // If car document doesn't exist, use the basic data already loaded
        setState(() {
          final car = _customerCars.firstWhere((c) => c['id'] == carId);
          _carModelController.text =
              '${car['brand']} ${car['model']} ${car['modelYear']}';
        });
      }
    } catch (e) {
      print('Error fetching car details: $e');
      setState(() {
        // Use the basic data if detailed fetch fails
        final car = _customerCars.firstWhere((c) => c['id'] == carId);
        _carModelController.text =
            '${car['brand']} ${car['model']} ${car['modelYear']}';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final bool isPM = timeOfDay.hour >= 12;
    final int hour12 = timeOfDay.hour > 12
        ? timeOfDay.hour - 12
        : (timeOfDay.hour == 0 ? 12 : timeOfDay.hour);
    final String minute = timeOfDay.minute.toString().padLeft(2, '0');
    final String period = isPM ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomerId == null) {
      setState(() {
        _errorMessage = 'Please select a customer first';
      });
      return;
    }

    if (_selectedCarId == null) {
      setState(() {
        _errorMessage = 'Please select a car first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First create a document with auto-generated ID
      final docRef = FirebaseFirestore.instance.collection('appointment').doc();
      final String appointmentId = docRef.id;

      // Car details from the selected car
      final selectedCar =
          _customerCars.firstWhere((car) => car['id'] == _selectedCarId);

      // Create appointment data with the new structured format
      final appointmentData = {
        // Basic information
        'id': appointmentId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Customer information
        'customerId': _selectedCustomerId,
        'customerName': _customerNameController.text.trim(),
        'customerPhone': _customerPhoneController.text.trim(),
        'customerEmail': _customerEmailController.text.trim(),

        // Vehicle information
        'carId': _selectedCarId,
        'carModel': selectedCar['model'],
        'carBrand': selectedCar['brand'],
        'carNumber': selectedCar['carNumber'],
        'carYear': selectedCar['modelYear'],

        // Service information
        'serviceCategory': _selectedService,

        // Service center information
        'serviceCenter': {
          'id': _selectedCenter,
          'name': _selectedCenter,
          'address': '',
          'phone': ''
        },

        // Appointment information
        'date': Timestamp.fromDate(_selectedDate),
        'time': _formatTimeOfDay(_selectedTime),
        'appointmentDate':
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        'appointmentTime': _formatTimeOfDay(_selectedTime),

        // Issue details and requirements
        'issue': {
          'type': _selectedService,
          'description': _notesController.text.trim().isEmpty
              ? ''
              : _notesController.text.trim(),
          'urgencyLevel': 'normal',
          'needsPickup': false
        },

        // Service specific data
        'serviceDetails': {}
      };

      // Save to Firestore using the auto-generated ID
      await docRef.set(appointmentData);

      // Notify parent component that an appointment was added
      widget.onAppointmentAdded();

      // Close dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error saving appointment: ${e.toString()}';
      });

      print('Error saving appointment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 24),
                  const SizedBox(width: 16),
                  const Text(
                    'Add New Appointment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Selection
                      const Text(
                        'Select Customer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _loadingCustomers
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: _selectedCustomerId,
                              decoration: const InputDecoration(
                                labelText: 'Customer',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              hint: const Text('Select Customer'),
                              items: _customers.map((customer) {
                                return DropdownMenuItem<String>(
                                  value: customer['id'],
                                  child: Text(
                                      '${customer['firstName']} ${customer['lastName']} (${customer['email']})'),
                                );
                              }).toList(),
                              onChanged: _onCustomerSelected,
                            ),

                      const SizedBox(height: 16),

                      // Car Selection
                      if (_selectedCustomerId != null) ...[
                        const Text(
                          'Select Car',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCarId,
                          decoration: const InputDecoration(
                            labelText: 'Car',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_car),
                          ),
                          hint: const Text('Select Car'),
                          items: _customerCars.map((car) {
                            return DropdownMenuItem<String>(
                              value: car['id'],
                              child: Text(
                                  '${car['brand']} ${car['model']} ${car['modelYear']} (${car['carNumber']})'),
                            );
                          }).toList(),
                          onChanged: _onCarSelected,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Customer Information Section
                      const Text(
                        'Customer Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a customer';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customerPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a customer';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _customerEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a customer';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Vehicle Information Section
                      const Text(
                        'Vehicle Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _carModelController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Model',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a car';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Appointment Details Section
                      const Text(
                        'Appointment Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedService,
                        decoration: const InputDecoration(
                          labelText: 'Service',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.build),
                        ),
                        items: _availableServices.map((service) {
                          return DropdownMenuItem<String>(
                            value: service,
                            child: Text(service),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedService = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a service';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCenter,
                        decoration: const InputDecoration(
                          labelText: 'Service Center',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        items: _availableCenters.map((center) {
                          return DropdownMenuItem<String>(
                            value: center,
                            child: Text(center),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCenter = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a service center';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat('yyyy-MM-dd')
                                      .format(_selectedDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Time',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _formatTimeOfDay(_selectedTime),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Appointment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
