import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/appointment_model.dart';
import '../../models/car.dart';
import '../../constants/colors.dart';
import '../../services/appointment_service.dart';
import 'service_centers_screen.dart'; // Import ServiceCentersScreen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../appointments/my_appointments_screen.dart'; // Import for MyAppointmentsScreen

class BookingScreen extends StatefulWidget {
  final AppointmentModel? appointment;

  const BookingScreen({super.key, this.appointment});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late List<String> _services = [
    'Regular Maintenance',
    'Oil Change',
    'Comprehensive Inspection',
    'Electrical Inspection',
    'Air Filter Replacement',
    'Periodic Inspection'
  ];

  final List<String> _timeSlots = [
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
    '08:00 PM',
  ];

  // User cars list
  late List<Car> _userCars = [];

  // Service centers list from ServiceCentersScreen
  late final List<Map<String, dynamic>> _serviceCenters =
      ServiceCentersScreen.serviceCenters;

  DateTime _selectedDate = DateTime.now();
  String? _selectedService;
  String? _selectedTime;
  String? _selectedVehicleId; // Changed variable type to store car ID
  int _selectedServiceCenter =
      0; // Changed to integer index similar to ac_service.dart
  final TextEditingController _noteController = TextEditingController();

  String? _appointmentId;
  bool _isLoading = false; // Added loading state variable

  @override
  void initState() {
    super.initState();

    // Initialize date formatting for English
    initializeDateFormatting('en', null).then((_) {
      // Ensure initialization completes
      setState(() {});
    });

    // Remove duplicate services more comprehensively
    final List<String> uniqueServices = [];
    final Set<String> serviceSet = {};

    for (final service in _services) {
      if (!serviceSet.contains(service)) {
        serviceSet.add(service);
        uniqueServices.add(service);
      }
    }

    _services = uniqueServices;

    // Load user cars
    _loadUserCars();

    if (widget.appointment != null) {
      _loadAppointmentData();

      // Make sure selected service is in the list
      if (_selectedService != null && !_services.contains(_selectedService)) {
        // If value not found, add it to the list
        _services.add(_selectedService!);
      }
    }
  }

  // Load user cars
  Future<void> _loadUserCars() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must login first')),
          );
        }
        setState(() {
          _userCars = [];
          _isLoading = false;
        });
        return;
      }

      print('====== Start loading cars ======');
      print('Customer ID: $userId');

      final carsSnapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('customerId', isEqualTo: userId)
          .get();

      print('Query result: ${carsSnapshot.docs.length} cars');

      if (carsSnapshot.docs.isEmpty) {
        print('No cars found for user: $userId');
        if (mounted) {
          setState(() {
            _userCars = [];
            _isLoading = false;
          });
        }
        return;
      }

      final cars = carsSnapshot.docs.map((doc) {
        final data = doc.data();

        // Parse the model year value - handle both string and int formats
        int modelYear;
        if (data['modelYear'] is int) {
          modelYear = data['modelYear'];
        } else if (data['modelYear'] is String) {
          modelYear = int.tryParse(data['modelYear'] ?? '0') ?? 0;
        } else {
          modelYear = 0;
        }

        return Car(
          id: doc.id,
          brand: data['brand'] ?? '',
          model: data['model'],
          trim: data['trim'],
          engine: data['engine'],
          version: data['version'],
          modelYear: modelYear,
          carNumber: data['carNumber'] ?? '',
          carLicense: data['carLicense'] ?? '',
          imageUrl: data['imageUrl'],
          customerId: data['customerId'] ?? userId,
          color: data['color'],
        );
      }).toList();

      print('Found ${cars.length} cars for the user');

      if (mounted) {
        setState(() {
          _userCars = cars;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cars: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cars: $e')),
        );
        setState(() {
          _userCars = [];
          _isLoading = false;
        });
      }
    }
  }

  void _loadAppointmentData() {
    final appointment = widget.appointment!;
    _appointmentId = appointment.id;
    _selectedDate = appointment.date;
    _selectedService = appointment.service;
    _selectedTime = appointment.time;
    _selectedVehicleId = appointment.carId;

    // Find the service center ID by matching the center name
    for (var center in _serviceCenters) {
      if (center['name'] == appointment.center) {
        _selectedServiceCenter = _serviceCenters.indexOf(center);
        break;
      }
    }

    if (appointment.notes != null) {
      _noteController.text = appointment.notes!;
    }

    if (_selectedService != null && !_services.contains(_selectedService)) {
      _services.add(_selectedService!);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Get car description by ID

  Future<void> _selectDate(BuildContext context) async {
    // Use manual date picker directly
    _showManualDatePicker(context);
  }

  // Simplified date picker
  void _showManualDatePicker(BuildContext context) {
    // Current date shown in calendar
    DateTime viewDate = DateTime(_selectedDate.year, _selectedDate.month, 1);

    // Calculate first day of current month
    final DateTime firstDayOfMonth = DateTime(viewDate.year, viewDate.month, 1);

    // Calculate number of days in month
    final DateTime nextMonth = DateTime(viewDate.year, viewDate.month + 1, 1);
    final int daysInMonth = nextMonth.difference(firstDayOfMonth).inDays;

    // Calculate first day of week (0 = Sunday, 1 = Monday, etc.)
    final int firstWeekday = firstDayOfMonth.weekday;

    // Calculate number of rows needed to display full month
    final int weeksCount = ((firstWeekday - 1 + daysInMonth) / 7).ceil();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          // Function to go to previous month
          void previousMonth() {
            setState(() {
              viewDate = DateTime(viewDate.year, viewDate.month - 1, 1);
            });
          }

          // Function to go to next month
          void nextMonth() {
            setState(() {
              viewDate = DateTime(viewDate.year, viewDate.month + 1, 1);
            });
          }

          // Display month and year
          String monthYearText =
              '${_getMonthName(viewDate.month)} ${viewDate.year}';

          // Ensure calculating first day of currently displayed month
          final DateTime firstDay = DateTime(viewDate.year, viewDate.month, 1);
          final DateTime nextMonthDate =
              DateTime(viewDate.year, viewDate.month + 1, 1);
          final int daysCount = nextMonthDate.difference(firstDay).inDays;
          final int firstWeekdayOfMonth = firstDay.weekday;

          // Create weekday list
          final List<String> weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

          // Current date
          final now = DateTime.now();

          // Allowed date range (today + 30 days)
          final DateTime maxAllowedDate = now.add(Duration(days: 30));

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Calendar header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: previousMonth,
                        tooltip: 'Previous Month',
                      ),
                      Text(
                        monthYearText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: nextMonth,
                        tooltip: 'Next Month',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Weekdays
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weekdays.map((day) {
                      return Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 8),

                  // Calendar grid
                  SizedBox(
                    height: 250,
                    child: Column(
                      children: List.generate(weeksCount, (weekIndex) {
                        return Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(7, (dayIndex) {
                              // Calculate actual day in month
                              final int day = weekIndex * 7 +
                                  dayIndex -
                                  firstWeekdayOfMonth +
                                  2;

                              // Check if day is within current month
                              if (day < 1 || day > daysCount) {
                                return SizedBox(width: 30, height: 30);
                              }

                              // Create date object for this day
                              final date =
                                  DateTime(viewDate.year, viewDate.month, day);

                              // Check if date is within allowed range
                              final bool isInAllowedRange =
                                  !date.isBefore(now) &&
                                      !date.isAfter(maxAllowedDate);

                              // Check if date is today
                              final bool isToday = date.year == now.year &&
                                  date.month == now.month &&
                                  date.day == now.day;

                              // Check if date is selected date
                              final bool isSelected =
                                  _isSameDay(date, _selectedDate);

                              // Check if date is in past (unavailable)
                              final bool isPastDate =
                                  date.isBefore(now) && !isToday;

                              return GestureDetector(
                                onTap: isInAllowedRange
                                    ? () {
                                        // Update selected date and close dialog
                                        this.setState(() {
                                          _selectedDate = date;
                                        });
                                        Navigator.pop(context);
                                      }
                                    : null,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : isToday
                                            ? Colors.grey.shade200
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isToday || isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : isPastDate
                                                ? Colors.grey.shade400
                                                : Colors.black87,
                                        fontWeight: isSelected || isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Set selected date and close dialog
                          Navigator.pop(context);
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Get day name
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  // Get month name
  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    Directionality.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.appointment != null
              ? 'Edit Appointment'
              : 'Book New Appointment'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Service',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedService != null
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedService,
                  isExpanded: true,
                  hint: const Text('Choose a service'),
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: _selectedService != null
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                  items: _services.map((service) {
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Text(
                        service,
                        style: TextStyle(
                          fontWeight: _selectedService == service
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedService = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Select Vehicle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _isLoading
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ),
                    )
                  : _userCars.isEmpty
                      ? Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/add-car')
                                  .then((_) {
                                _loadUserCars();
                              });
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                      'No vehicles found, add a new car'),
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedVehicleId != null
                                  ? AppColors.primary.withOpacity(0.3)
                                  : Colors.grey.shade300,
                              width: 1.0,
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedVehicleId,
                            isExpanded: true,
                            hint: const Text('Select a vehicle'),
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: _selectedVehicleId != null
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),
                            items: _userCars.map((car) {
                              return DropdownMenuItem<String>(
                                value: car.id,
                                child: Text(
                                  '${car.brand} ${car.modelYear} - ${car.carNumber}',
                                  style: TextStyle(
                                    fontWeight: _selectedVehicleId == car.id
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVehicleId = value;
                              });
                            },
                          ),
                        ),

              // Add service center selection field
              const SizedBox(height: 24),
              const Text(
                'Select Service Center',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: DropdownButton<int>(
                  value: _selectedServiceCenter,
                  isExpanded: true,
                  hint: const Text('Choose a service center'),
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primary,
                  ),
                  items: _serviceCenters.map((center) {
                    return DropdownMenuItem<int>(
                      value: _serviceCenters.indexOf(center),
                      child: Text(
                        center['name'],
                        style: TextStyle(
                          fontWeight: _selectedServiceCenter ==
                                  _serviceCenters.indexOf(center)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      if (value != null) {
                        _selectedServiceCenter = value;
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            _selectDate(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${_getDayName(_selectedDate.weekday)} ${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Available Times',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Display available times in a simpler way
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _timeSlots.map((time) {
                  return ChoiceChip(
                    label: Text(time),
                    selected: _selectedTime == time,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTime = selected ? time : null;
                      });
                    },
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedTime == time
                          ? AppColors.primary
                          : AppColors.black,
                      fontWeight: _selectedTime == time
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              const Text(
                'Additional Notes (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter any special requirements or notes...',
                ),
              ),

              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Saving...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(widget.appointment != null
                                  ? Icons.save
                                  : Icons.check),
                              const SizedBox(width: 8),
                              Text(
                                widget.appointment != null
                                    ? 'Save Changes'
                                    : 'Confirm Booking',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAppointment() async {
    // Form validation
    if (_selectedService == null ||
        _selectedTime == null ||
        _selectedVehicleId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user information - retrieve before any async operations
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to book an appointment'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Find car by ID - retrieve before any async operations
      final selectedCar = _userCars.firstWhere(
        (car) => car.id == _selectedVehicleId,
        orElse: () => Car(
          id: '',
          brand: 'Unknown',
          modelYear: 0,
          carNumber: '',
          carLicense: '',
        ),
      );

      // Store all needed values safely before async operations
      final carDescription = '${selectedCar.brand} ${selectedCar.modelYear}';
      final selectedCenterName =
          _serviceCenters[_selectedServiceCenter]['name'];
      final appointmentId = 'APT-${DateTime.now().millisecondsSinceEpoch}';
      final notes = _noteController.text.isEmpty ? null : _noteController.text;
      final serviceValue = _selectedService!;
      final timeValue = _selectedTime!;
      final dateValue = _selectedDate;
      final vehicleIdValue = _selectedVehicleId!;

      // Prepare data for Firestore using standardized structure
      final appointmentData = {
        // Basic information
        'id': appointmentId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Customer information
        'customerId': userId,

        // Vehicle information (basic only)
        'carId': vehicleIdValue,
        // Service information
        'serviceCategory': 'Booking-Service',

        // Service center information
        'serviceCenter': {
          'id': _serviceCenters[_selectedServiceCenter]['id'],
          'name': selectedCenterName,
          'address': _serviceCenters[_selectedServiceCenter]['address'],
          'phone': _serviceCenters[_selectedServiceCenter]['phone'] ?? 'N/A'
        },

        // Appointment information
        'date': Timestamp.fromDate(dateValue),
        'time': timeValue,
        'appointmentDate':
            '${dateValue.day}/${dateValue.month}/${dateValue.year}',
        'appointmentTime': timeValue,

        // Issue details and requirements
        'issue': {
          'type': serviceValue,
          'description': notes ?? '',
          'urgencyLevel': 'normal',
          'needsPickup': false,
        },
        // Service specific data
        'serviceDetails': {}
      };

      print('Saving appointment data: $appointmentData');

      String resultId = appointmentId;

      // Save to Firebase
      try {
        if (_appointmentId != null) {
          // Update existing appointment
          await FirebaseFirestore.instance
              .collection('appointment')
              .doc(_appointmentId)
              .update(appointmentData);

          print('Updated appointment in Firestore: $_appointmentId');
        } else {
          // Add new appointment with direct method
          await FirebaseFirestore.instance
              .collection('appointment')
              .doc(appointmentId)
              .set(appointmentData);

          print('Appointment added to Firestore: $appointmentId');
        }
      } catch (firestoreError) {
        print('Error in Firestore save operation: $firestoreError');
        rethrow; // Re-throw to be caught by the outer try-catch
      }

      // Create the appointment model
      final appointment = AppointmentModel(
        id: resultId,
        service: serviceValue,
        date: dateValue,
        time: timeValue,
        carModel: carDescription,
        carId: vehicleIdValue,
        center: selectedCenterName,
        notes: notes,
        status: 'Upcoming',
      );

      // Add appointment directly to local appointment service
      final appointmentService = AppointmentService();
      appointmentService.addAppointment(appointment);

      // Check if widget is still mounted before using context
      if (mounted) {
        // Show success dialog instead of snackbar
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Appointment Confirmed', textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Service appointment has been successfully booked\nReference Number: ${_appointmentId ?? appointmentId}\nDate: ${dateValue.day}/${dateValue.month}/${dateValue.year}\nTime: $timeValue\nService: $serviceValue',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Standard Service',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Thank you for choosing our service.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Reset loading state
                  setState(() {
                    _isLoading = false;
                  });
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pop(context, appointment); // Return to previous screen with appointment
                },
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Reset loading state
                  setState(() {
                    _isLoading = false;
                  });
                  Navigator.of(context).pop(); // Close dialog
                  // Navigate to appointments page
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const MyAppointmentsScreen(),
                    ),
                    (route) => route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('View Appointments'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error saving appointment: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
