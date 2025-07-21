import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../theme/app_colors.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailsPage({super.key, required this.appointment});

  // Static method to show the dialog directly
  static Future<bool?> show(BuildContext context, Appointment appointment) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppointmentDetailsPage(appointment: appointment),
    );
  }

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _customerDetails;
  Map<String, dynamic>? _carDetails;
  late String _customerName;
  late String _carInfo;

  @override
  void initState() {
    super.initState();
    _customerName = widget.appointment.customerName;
    _carInfo = widget.appointment.getVehicleInfo();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      // Fetch both customer and car details in parallel
      final List<Future<Map<String, dynamic>?>> futures = [];
      
      if (widget.appointment.customerId != null && widget.appointment.customerId!.isNotEmpty) {
        futures.add(widget.appointment.fetchCustomerDetails());
      } else {
        futures.add(Future.value(null));
      }
      
      if (widget.appointment.carId != null && widget.appointment.carId!.isNotEmpty) {
        futures.add(widget.appointment.fetchCarDetails());
      } else {
        futures.add(Future.value(null));
      }
      
      // Wait for both futures to complete
      final results = await Future.wait(futures);
      
      // Update local variables with fetched data
      _customerDetails = results[0];
      _carDetails = results[1];
      
      // Process customer name
      if (_customerDetails != null) {
        final firstName = _customerDetails!['firstName']?.toString() ?? '';
        final lastName = _customerDetails!['lastName']?.toString() ?? '';
        
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          _customerName = '$firstName $lastName'.trim();
        } else if (_customerDetails!['name'] != null) {
          _customerName = _customerDetails!['name'].toString();
        } else if (_customerDetails!['mobile'] != null) {
          _customerName = 'Customer: ${_customerDetails!['mobile']}';
        } else if (_customerDetails!['phone'] != null) {
          _customerName = 'Customer: ${_customerDetails!['phone']}';
        }
      }
      
      // Process car info
      if (_carDetails != null) {
        List<String> parts = [];
        
        if (_carDetails!['brand'] != null && _carDetails!['brand'].toString().isNotEmpty) {
          parts.add(_carDetails!['brand'].toString());
        }
        
        if (_carDetails!['model'] != null && _carDetails!['model'].toString().isNotEmpty) {
          parts.add(_carDetails!['model'].toString());
        }
        
        if (_carDetails!['modelYear'] != null) {
          parts.add(_carDetails!['modelYear'].toString());
        } else if (_carDetails!['year'] != null) {
          parts.add(_carDetails!['year'].toString());
        }
        
        if (parts.isNotEmpty) {
          _carInfo = parts.join(' ');
        }
      }
      
      // Update state to stop loading and show data
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching details: $e');
      // Even on error, we should stop showing the loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAppointmentStatus(String newStatus) async {
    try {
      // Convert the status to the format expected by Firebase
      String firestoreStatus;
      switch (newStatus) {
        case 'Upcoming':
          firestoreStatus = 'pending';
          break;
        case 'Completed':
          firestoreStatus = 'completed';
          break;
        case 'Cancelled':
          firestoreStatus = 'cancelled';
          break;
        default:
          firestoreStatus = newStatus;
      }
      
      // Get document reference
      final DocumentReference appointmentRef = FirebaseFirestore.instance
        .collection('appointment')
        .doc(widget.appointment.id);
      
      // Update using set with merge option instead of transaction to avoid threading issues
      await appointmentRef.update({
          'status': firestoreStatus,
          'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Debug log
      print('Appointment status updated in Firebase: ${widget.appointment.id} -> $firestoreStatus');
      
      // Show success message
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
                const Text('Appointment status updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      }
      
      // Return to previous page with true as result to trigger refresh
      Navigator.pop(context, true);
    } catch (e) {
      print('Error updating appointment status: $e');
      
      // Show error message if still mounted
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
                Expanded(child: Text('Failed to update: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      }
    }
  }

  Widget _getStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'Upcoming':
      case 'pending':
        color = Colors.blue.shade700;
        icon = Icons.schedule;
        break;
      case 'Completed':
      case 'completed':
        color = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'Cancelled':
      case 'cancelled':
        color = AppColors.primary;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange.shade700;
        icon = Icons.error;
    }
    
    String displayStatus = status;
    // Normalize status for display
    switch (status.toLowerCase()) {
      case 'pending':
        displayStatus = 'Upcoming';
        break;
      case 'completed':
        displayStatus = 'Completed';
        break;
      case 'cancelled':
      case 'canceled':
        displayStatus = 'Cancelled';
        break;
    }
    
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            displayStatus,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // Helper method to format a service category name for display
  String _formatServiceCategory(String? category) {
    if (category == null || category.isEmpty) return '';
    
    // Replace dashes and underscores with spaces
    String formatted = category.replaceAll('-', ' ').replaceAll('_', ' ');
    
    // Capitalize each word
    formatted = formatted.split(' ').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
    
    return formatted;
  }

  // Creates a section header with consistent styling
  Widget _buildSectionHeader(String title, IconData icon, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Theme.of(context).primaryColor, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 17,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Creates a standardized card container for each section
  Widget _buildSectionCard(Widget content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract service center details for display
    String serviceCenterName = "Not specified";
    String serviceCenterAddress = "";
    String serviceCenterPhone = "";
    
    // Check if we have service center details
    if (widget.appointment.serviceCenterDetails != null) {
      serviceCenterName = widget.appointment.serviceCenterDetails!['name']?.toString() ?? "Not specified";
      serviceCenterAddress = widget.appointment.serviceCenterDetails!['address']?.toString() ?? "";
      serviceCenterPhone = widget.appointment.serviceCenterDetails!['phone']?.toString() ?? "";
    } else if (widget.appointment.serviceCenter != null) {
      serviceCenterName = widget.appointment.serviceCenter!;
    } else if (widget.appointment.center != null) {
      serviceCenterName = widget.appointment.center!;
    }
    
    // Extract service type and description
    String serviceType = widget.appointment.serviceType ?? 
                         widget.appointment.serviceCategory ?? 
                         widget.appointment.service;
    String serviceDescription = widget.appointment.problemDescription ?? "";
    
    // Check if we have issue details
    if (widget.appointment.issueDetails != null) {
      if ((serviceType.isEmpty || serviceType == "null") && widget.appointment.issueDetails!['type'] != null) {
        serviceType = widget.appointment.issueDetails!['type'].toString();
      }
      
      if (serviceDescription.isEmpty && widget.appointment.issueDetails!['description'] != null) {
        serviceDescription = widget.appointment.issueDetails!['description'].toString();
      }
    }
    
    // Format service type for better display
    serviceType = _formatServiceCategory(serviceType);
    
    // Format service category
    String serviceCategory = _formatServiceCategory(widget.appointment.serviceCategory);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: AppColors.background,
      elevation: 8,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog header with improved styling
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_month, size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                const Text(
                  'Appointment Details',
                  style: TextStyle(
                          fontSize: 22,
                    fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (serviceCategory.isNotEmpty && serviceCategory != "Null")
                        Text(
                          serviceCategory,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                _getStatusChip(widget.appointment.status),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            
            // Main content
            Expanded(
              child: _isLoading 
                ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Loading appointment details...',
                          style: TextStyle(fontSize: 16),
                        ),
              ],
            ),
          )
        : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        // Service Details Section
                        _buildSectionHeader(
                              'Service Details',
                          Icons.build,
                          iconColor: Colors.blue.shade700
                        ),
                        _buildSectionCard(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                        _buildInfoRow('Service:', serviceType.isNotEmpty ? serviceType : "Not specified", Icons.build),
                                        const SizedBox(height: 12),
                                        _buildInfoRow(
                                          'Category:', 
                                          serviceCategory.isNotEmpty ? serviceCategory : "Not specified", 
                                          Icons.category
                                        ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                        _buildInfoRow(
                                          'Date:', 
                                          DateFormat('EEEE, MMMM d, y').format(widget.appointment.date), 
                                          Icons.date_range
                                        ),
                                        const SizedBox(height: 12),
                                    _buildInfoRow('Time:', widget.appointment.time, Icons.access_time),
                                  ],
                                ),
                      ),
                    ],
                  ),
                              const Divider(height: 24),
                              _buildInfoRow('Center:', serviceCenterName, Icons.location_on),
                              if (serviceCenterAddress.isNotEmpty && serviceCenterAddress != "null") ...[
                                const SizedBox(height: 12),
                                _buildInfoRow('Address:', serviceCenterAddress, Icons.map),
                              ],
                              if (serviceCenterPhone.isNotEmpty && serviceCenterPhone != "null" && serviceCenterPhone != "N/A") ...[
                                const SizedBox(height: 12),
                                _buildInfoRow('Phone:', serviceCenterPhone, Icons.phone),
                              ],
                            ],
                          ),
                        ),
                
                // Customer Information
                        _buildSectionHeader(
                  'Customer Information',
                          Icons.person,
                          iconColor: Colors.blue.shade700
                        ),
                        _buildSectionCard(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Name:', _customerName, Icons.person),
                        if (_customerDetails != null) ...[
                                if (_customerDetails!['phone'] != null || _customerDetails!['mobile'] != null) ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    'Phone:',
                                    _customerDetails!['phone']?.toString() ?? 
                                    _customerDetails!['mobile']?.toString() ?? 
                                    'Not available',
                                    Icons.phone
                            ),
                                ],
                                if (_customerDetails!['email'] != null) ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow('Email:', _customerDetails!['email'].toString(), Icons.email),
                                ],
                        ],
                      ],
                    ),
                  ),
                
                // Vehicle Information
                        _buildSectionHeader(
                  'Vehicle Information',
                          Icons.directions_car,
                          iconColor: Colors.blue.shade700
                        ),
                        _buildSectionCard(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Vehicle:', _carInfo, Icons.directions_car),
                              if (widget.appointment.carId != null) ...[
                                const SizedBox(height: 12),
                                _buildInfoRow('Car ID:', widget.appointment.carId!, Icons.vpn_key),
                              ],
                        if (_carDetails != null) ...[
                                if (_carDetails!['licensePlate'] != null || _carDetails!['carNumber'] != null) ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    'License Plate:',
                                    _carDetails!['licensePlate']?.toString() ?? 
                                    _carDetails!['carNumber']?.toString() ?? 
                                    'Not available',
                                    Icons.confirmation_number
                            ),
                                ],
                                if (_carDetails!['color'] != null) ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow('Color:', _carDetails!['color'].toString(), Icons.color_lens),
                                ],
                              ],
                            ],
                          ),
                        ),
                        
                        // Issue Details and Requirements
                        if (widget.appointment.issueDetails != null) ...[
                          _buildSectionHeader(
                            'Issue Information', 
                            Icons.warning,
                            iconColor: Colors.orange.shade700
                          ),
                          _buildSectionCard(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display issue type if available
                                if (widget.appointment.issueDetails!['type'] != null && 
                                    widget.appointment.issueDetails!['type'].toString() != "null") ...[
                                  _buildInfoRow(
                                    'Issue Type:',
                                    _formatServiceCategory(widget.appointment.issueDetails!['type'].toString()),
                                    Icons.build
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                // Display description if available
                                if (serviceDescription.isNotEmpty) ...[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.description, size: 18, color: Colors.blue.shade700),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Description:',
                                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Text(
                                          serviceDescription,
                                          style: const TextStyle(fontSize: 14, height: 1.4),
                                      ),
                                  ),
                                ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                // Display service requirements in a more visual way
                                      Row(
                                        children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: widget.appointment.issueDetails!['urgencyLevel']?.toString().toLowerCase() == 'high'
                                            ? Colors.red.shade50
                                            : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: widget.appointment.issueDetails!['urgencyLevel']?.toString().toLowerCase() == 'high'
                                              ? Colors.red.shade200
                                              : Colors.blue.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              widget.appointment.issueDetails!['urgencyLevel']?.toString().toLowerCase() == 'high' 
                                                ? Icons.priority_high 
                                                : Icons.low_priority,
                                              size: 20,
                                              color: widget.appointment.issueDetails!['urgencyLevel']?.toString().toLowerCase() == 'high'
                                                ? Colors.red
                                                : Colors.blue,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Priority: ${widget.appointment.issueDetails!['urgencyLevel']?.toString().toLowerCase() == 'high' ? 'High' : 'Normal'}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: widget.appointment.issueDetails!['urgencyLevel']?.toString().toLowerCase() == 'high'
                                                  ? Colors.red.shade700
                                                  : Colors.blue.shade700,
                                              ),
                                          ),
                                        ],
                                      ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (widget.appointment.issueDetails!['needsPickup'] != null)
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: widget.appointment.issueDetails!['needsPickup'] == true
                                              ? Colors.green.shade50
                                              : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: widget.appointment.issueDetails!['needsPickup'] == true
                                                ? Colors.green.shade200
                                                : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                widget.appointment.issueDetails!['needsPickup'] == true
                                                  ? Icons.local_shipping
                                                  : Icons.no_transfer,
                                                size: 20,
                                                color: widget.appointment.issueDetails!['needsPickup'] == true
                                                  ? Colors.green
                                                  : Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Pickup: ${widget.appointment.issueDetails!['needsPickup'] == true ? 'Required' : 'Not Needed'}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: widget.appointment.issueDetails!['needsPickup'] == true
                                                    ? Colors.green.shade700
                                                    : Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Service Specific Details
                                if (widget.appointment.serviceDetails != null && 
                                    widget.appointment.serviceDetails!.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Service Specifications', 
                            Icons.miscellaneous_services,
                            iconColor: Colors.blue.shade700
                          ),
                          _buildSectionCard(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  ...widget.appointment.serviceDetails!.entries.map((entry) {
                                  // Skip null values and specific cost fields we don't want to show
                                  if (entry.value == null || 
                                      entry.value.toString() == "null" || 
                                      entry.key == "additionalServicesCost" || 
                                      entry.key == "subtotal") {
                                    return const SizedBox.shrink();
                                  }
                                  
                                    // Format the key to be more readable
                                    String key = entry.key.replaceAll('_', ' ').split(' ').map((word) => 
                                      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
                                    ).join(' ');
                                    
                                    // Format the value
                                    String value = '';
                                    if (entry.value is bool) {
                                      value = entry.value ? 'Yes' : 'No';
                                    } else if (entry.value is num) {
                                    value = entry.value.toString().contains('.')
                                        ? double.parse(entry.value.toString()).toStringAsFixed(2)
                                        : '${entry.value}';
                                    } else {
                                      value = entry.value.toString();
                                    }
                                  
                                  // Create icon based on key name
                                  IconData icon;
                                  if (key.toLowerCase().contains('wheel')) {
                                    icon = Icons.tire_repair;
                                  } else if (key.toLowerCase().contains('cost') || key.toLowerCase().contains('price') || key.toLowerCase().contains('subtotal')) {
                                    icon = Icons.attach_money;
                                  } else if (key.toLowerCase().contains('alignment')) {
                                    icon = Icons.align_horizontal_center;
                                  } else if (key.toLowerCase().contains('balancing')) {
                                    icon = Icons.balance;
                                  } else if (key.toLowerCase().contains('size')) {
                                    icon = Icons.straighten;
                                  } else if (key.toLowerCase().contains('type')) {
                                    icon = Icons.category;
                                  } else {
                                    icon = Icons.check_circle_outline;
                                  }
                                    
                                    return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: _buildInfoRow('$key:', value, icon),
                                    );
                                  }),
                                ],
                            ),
                          ),
                        ],
                        
                        // Additional Information (notes if not already displayed)
                        if (widget.appointment.notes != null && 
                            widget.appointment.notes!.isNotEmpty &&
                            widget.appointment.notes != serviceDescription) ...[
                          _buildSectionHeader(
                            'Additional Notes', 
                            Icons.note,
                            iconColor: Colors.blue.shade700
                          ),
                          _buildSectionCard(
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                widget.appointment.notes!,
                                style: const TextStyle(fontSize: 14, height: 1.4),
                              ),
                            ),
                          ),
                        ],

                        // Estimated cost if available
                        if (widget.appointment.estimatedCost != null) ...[
                          _buildSectionHeader(
                            'Cost Information', 
                            Icons.attach_money,
                            iconColor: Colors.green.shade700
                          ),
                          _buildSectionCard(
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.attach_money, color: Colors.green.shade700, size: 24),
                                  const SizedBox(width: 10),
                                      Text(
                                    'Estimated Cost: \$${widget.appointment.estimatedCost!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ),
                        ],
                        
                        // System Details
                        _buildSectionHeader(
                              'System Information',
                          Icons.history,
                          iconColor: Colors.blue.shade700
                        ),
                        _buildSectionCard(
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                                child: _buildInfoRow(
                                  'Created:',
                                  DateFormat('MMM d, y h:mm a').format(widget.appointment.createdAt),
                                  Icons.create
                                ),
                              ),
                                  ),
                                  const SizedBox(width: 10),
                              Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                child: _buildInfoRow(
                                  'Updated:',
                                  DateFormat('MMM d, y h:mm a').format(widget.appointment.updatedAt),
                                  Icons.update
                                      ),
                                ),
                              ),
                            ],
                          ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('Appointment ID:', widget.appointment.id, Icons.numbers),
                                    if (widget.appointment.reference != null) ...[
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Reference:', widget.appointment.reference!, Icons.label),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
            // Footer with action buttons
            if (widget.appointment.status == 'Upcoming' || widget.appointment.status == 'pending') ...[
              const Divider(thickness: 1, height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                  OutlinedButton.icon(
                        onPressed: () => _updateAppointmentStatus('Cancelled'),
                    icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel Appointment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _updateAppointmentStatus('Completed'),
                    icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Mark Completed'),
                        style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 18, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500, 
                  fontSize: 13,
                  color: Colors.grey.shade800,
              ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 