import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../dialogs/add_appointment_dialog.dart';
import '../dialogs/appointment_details_page.dart';

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? '' : this[0].toUpperCase() + substring(1);
  }
}

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final Map<int, bool> _hoveredIndices = {};
  bool _isLoading = true;
  String? _errorMessage;
  List<Appointment> _appointments = [];
  String _filter = 'all'; // 'all', 'upcoming', 'completed', 'cancelled'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _fetchAppointments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use GetOptions to explicitly set the source and help with threading issues
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .get(const GetOptions(source: Source.serverAndCache));
      
      final List<Appointment> appointments = querySnapshot.docs.map((doc) {
        return Appointment.fromFirestore(doc.data(), doc.id);
      }).toList();
      
      // Sort appointments: upcoming first, then by date
      appointments.sort((a, b) {
        // First sort by status
        if (a.status == 'Upcoming' && b.status != 'Upcoming') {
          return -1;
        } else if (a.status != 'Upcoming' && b.status == 'Upcoming') {
          return 1;
        }
        
        // Then sort by date
        return a.date.compareTo(b.date);
      });
      
      // Extract customer and car IDs for preloading
      final customerIds = appointments
          .where((a) => a.customerId != null && a.customerId!.isNotEmpty)
          .map((a) => a.customerId!)
          .toList();
      
      final carIds = appointments
          .where((a) => a.carId != null && a.carId!.isNotEmpty)
          .map((a) => a.carId!)
          .toList();
      
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
      
      print('Fetched ${appointments.length} appointments from Firestore');
      
      // Preload customer and car data in batches to avoid UI blocking
      // This runs after UI update, so it won't block the initial display
      _preloadCustomerAndCarData(customerIds, carIds);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error occurred while fetching data: ${e.toString()}';
      });
      print('Error fetching appointments: $e');
    }
  }
  
  // Preload customer and car data in the background
  Future<void> _preloadCustomerAndCarData(List<String> customerIds, List<String> carIds) async {
    try {
      // Run these in sequence to avoid too many parallel operations
      await Appointment.preloadCustomerData(customerIds);
      await Appointment.preloadCarData(carIds);
      
      // Force a refresh to display the preloaded data
      if (mounted) {
        setState(() {
          // Just refresh the UI with cached data
        });
      }
    } catch (e) {
      print('Error preloading data: $e');
    }
  }

  List<Appointment> get _filteredAppointments {
    List<Appointment> filtered = _appointments;
    
    // Apply status filter
    if (_filter != 'all') {
      filtered = filtered.where((appointment) => 
        appointment.status == _filterToStatus(_filter)
      ).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((appointment) => 
        appointment.customerName.toLowerCase().contains(query) ||
        appointment.service.toLowerCase().contains(query) ||
        (appointment.carModel?.toLowerCase().contains(query) ?? false) ||
        (appointment.customerPhone?.toLowerCase().contains(query) ?? false) ||
        (appointment.center?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    return filtered;
  }

  String _filterToStatus(String filter) {
    switch (filter) {
      case 'upcoming':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return const Color(0xFF1976D2); // Deeper blue
      case 'Completed':
        return const Color(0xFF2E7D32); // Deeper green
      case 'Cancelled':
        return const Color(0xFFD32F2F); // Deeper red
      default:
        return const Color(0xFFED6C02); // Deeper orange
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Upcoming':
        return Icons.schedule;
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.error;
    }
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String newStatus) async {
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
      final DocumentReference appointmentRef = FirebaseFirestore.instance.collection('appointment').doc(appointmentId);
      
      // Use direct update instead of transaction to avoid threading issues
      await appointmentRef.update({
        'status': firestoreStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Debug log
      print('Appointment status updated in Firebase: $appointmentId -> $firestoreStatus');
      
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
      
      // Refetch appointments to update the UI
      _fetchAppointments();
    } catch (e) {
      print('Error updating status: $e');
      
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

  Widget _buildAppointmentCard(Appointment appointment, int index) {
    final isHovered = _hoveredIndices[index] ?? false;
    final isUpcoming = appointment.status == 'Upcoming';
    final statusColor = _getStatusColor(appointment.status);
    final statusIcon = _getStatusIcon(appointment.status);
    
    // Local state for customer name
    String displayName = appointment.customerName.isEmpty ? 'Loading...' : appointment.customerName;
    
    // Fetch real customer name if needed
    if (appointment.customerId != null && appointment.customerId!.isNotEmpty && 
        appointment.customerName.isEmpty) {
      appointment.getCustomerName().then((name) {
        if (mounted && name != displayName) {
                  setState(() {
            // This will only update this specific card
            // We're not modifying the actual appointment object
          });
        }
      });
      
      // Try to fetch immediately for this card
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          appointment.getCustomerName().then((name) {
            if (mounted && name != displayName) {
                  setState(() {
                // Force refresh with new name
              });
            }
          });
        }
      });
    }
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndices[index] = true),
      onExit: (_) => setState(() => _hoveredIndices[index] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? statusColor.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isHovered ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isHovered ? statusColor.withOpacity(0.3) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await AppointmentDetailsPage.show(
              context,
              appointment
            );
            
            // If we get a true result, refresh appointments as status might have changed
            if (result == true) {
              _fetchAppointments();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            appointment.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('yyyy-MM-dd').format(appointment.date),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Customer name with icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: appointment.getCustomerName(),
                              initialData: appointment.customerName.isEmpty 
                                  ? "Loading..." 
                                  : appointment.customerName,
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? "Unknown Customer",
                  style: const TextStyle(
                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                                );
                              }
                            ),
                            if (appointment.customerPhone != null && appointment.customerPhone!.isNotEmpty)
                              Text(
                                appointment.customerPhone!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Service
                Row(
                  children: [
                    Icon(Icons.build, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.service,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Car info (now using the getVehicleInfo method)
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: appointment.getCarDetails(),
                        initialData: appointment.getVehicleInfo(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Not specified',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                          );
                        }
                      ),
                    ),
                  ],
                ),
                
                // Location
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (appointment.serviceCenter != null || appointment.center != null) ...[
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appointment.serviceCenter ?? appointment.center ?? 'Not specified',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Time, price and phone in a compact row
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      appointment.time,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    
                    if (appointment.estimatedCost != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${appointment.estimatedCost!.toStringAsFixed(2)} ',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    
                    if (appointment.customerPhone != null) ...[
                      const Spacer(),
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        appointment.customerPhone!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                
                if (isUpcoming) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _updateAppointmentStatus(appointment.id, 'Cancelled');
                        },
                        icon: const Icon(Icons.cancel, size: 14),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _updateAppointmentStatus(appointment.id, 'Completed');
                        },
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text(
                          'Complete',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 30),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAppointmentDialog(
        onAppointmentAdded: () {
          _fetchAppointments();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page header with title, search, filters and add button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 28, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text(
                          'Appointments Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 300,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search appointments...',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddAppointmentDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Appointment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 12),
                        _buildFilterChip('Upcoming', 'upcoming'),
                        const SizedBox(width: 12),
                        _buildFilterChip('Completed', 'completed'),
                        const SizedBox(width: 12),
                        _buildFilterChip('Cancelled', 'cancelled'),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Main content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Loading appointments...',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red[100]!),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading data',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _fetchAppointments,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Try Again'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _filteredAppointments.isEmpty
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue[100]!),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 64,
                                        color: Colors.blue[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No search results found'
                                            : _filter != 'all'
                                                ? 'No appointments with this status'
                                                : 'No appointments found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _showAddAppointmentDialog,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add New Appointment'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.05,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _filteredAppointments.length,
                                itemBuilder: (context, index) {
                                  return _buildAppointmentCard(_filteredAppointments[index], index);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAppointments,
        tooltip: 'Refresh Appointments',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _filter == filterValue;
    final Color chipColor;
    final IconData iconData;
    
    switch (filterValue) {
      case 'upcoming':
        chipColor = Colors.blue;
        iconData = Icons.schedule;
        break;
      case 'completed':
        chipColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        iconData = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey;
        iconData = Icons.filter_list;
    }
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 16,
            color: isSelected ? Colors.white : chipColor,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = filterValue;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? chipColor : Colors.grey.shade300,
        ),
      ),
      elevation: isSelected ? 1 : 0,
      pressElevation: 2,
    );
  }
} 