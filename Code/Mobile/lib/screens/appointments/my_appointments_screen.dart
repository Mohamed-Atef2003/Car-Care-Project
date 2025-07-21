import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/colors.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_application_1/screens/services/booking_screen.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../providers/user_provider.dart';
import '../../services/appointment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Upcoming', 'Completed', 'Canceled'];
  
  // Using appointment service
  final AppointmentService _appointmentService = AppointmentService();
  
  // Appointment lists
  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _completedAppointments = [];
  List<AppointmentModel> _canceledAppointments = [];

  // Loading states
  bool _isLoading = false;
  bool _isRefreshing = false;
  // Error state
  String? _errorMessage;

  // Car cache to avoid repeated fetches
  final Map<String, Map<String, dynamic>> _carCache = {};
  
  // Debounce timer for refresh
  Timer? _refreshDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Initialize date formatting for English
    initializeDateFormatting('en', null);
    
    // Load appointments when app starts
    _loadAppointmentsFromProvider();
    
    // Listen for tab changes to update UI
    _tabController.addListener(_handleTabChange);
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }
  
  // Get current user ID
  String _getCurrentUserId() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null || user.id == null || user.id!.isEmpty) {
      print('WARNING: User is not logged in or ID is empty');
      return '';
    }
    return user.id!;
  }

  // Load appointments from provider
  Future<void> _loadAppointmentsFromProvider() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String userId = _getCurrentUserId();
      if (userId.isEmpty) {
        setState(() {
          _errorMessage = 'User not logged in. Please log in to view appointments.';
          _isLoading = false;
        });
        return;
      }

      await _appointmentService.fetchUserAppointments(userId);
      
      if (mounted) {
        setState(() {
          _upcomingAppointments = _appointmentService.getUpcomingAppointments();
          _completedAppointments = _appointmentService.getCompletedAppointments();
          _canceledAppointments = _appointmentService.getCanceledAppointments();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading appointments: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _refreshDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Appointments'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isRefreshing 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                )
              : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshAppointments,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showBookAppointmentDialog();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Book'),
        elevation: 3,
      ),
      body: _errorMessage != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [
                // Upcoming
                _buildTabContent(0),
                // Completed
                _buildTabContent(1),
                // Canceled
                _buildTabContent(2),
              ],
            ),
    );
  }

  // Build tab content with pull-to-refresh
  Widget _buildTabContent(int index) {
    List<AppointmentModel> appointments = _getAppointmentsForTab(index);
    bool showActions = index == 0; // Only show actions for upcoming appointments
    
    return RefreshIndicator(
      onRefresh: _refreshAppointments,
      color: AppColors.primary,
      child: _buildAppointmentsList(appointments, showActions),
    );
  }
  
  List<AppointmentModel> _getAppointmentsForTab(int index) {
    switch (index) {
      case 0:
        return _upcomingAppointments;
      case 1:
        return _completedAppointments;
      case 2:
        return _canceledAppointments;
      default:
        return [];
    }
  }
  
  // Refresh appointments with debounce
  Future<void> _refreshAppointments() async {
    // Prevent multiple refreshes
    if (_isRefreshing) return;
    
    // Cancel any pending refreshes
    _refreshDebounce?.cancel();
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      await _loadAppointmentsFromProvider();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointments updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Build appointments list
  Widget _buildAppointmentsList(List<AppointmentModel> appointments, bool showActions) {
    if (_isLoading) {
      return _buildLoadingView();
    }
    
    if (appointments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment, showActions);
      },
      physics: const AlwaysScrollableScrollPhysics(), // Allow refresh even when empty
    );
  }

  // Show loading state
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading appointments...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Show error message
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 70,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadAppointmentsFromProvider,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show no appointments message
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No ${_tabs[_tabController.index]} Appointments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getEmptyStateMessage(_tabController.index),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_tabController.index == 0) // Only show book button on upcoming tab
              ElevatedButton.icon(
                onPressed: () {
                  _showBookAppointmentDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('Book New Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _getEmptyStateMessage(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'You have no upcoming appointments. Book one now!';
      case 1:
        return 'You haven\'t completed any appointments yet.';
      case 2:
        return 'You haven\'t canceled any appointments.';
      default:
        return 'No appointments to display.';
    }
  }

  // Fetch car details from Firebase using carId with caching
  Future<Map<String, dynamic>> _fetchCarDetails(String carId) async {
    // Check cache first
    if (_carCache.containsKey(carId)) {
      return _carCache[carId]!;
    }
    
    try {
      // Skip if invalid car ID
      if (carId.isEmpty || carId == 'Not specified') {
        return {'brand': 'Unknown', 'model': 'Unknown'};
      }
      
      // Query cars collection directly
      DocumentSnapshot carDoc = await FirebaseFirestore.instance
          .collection('cars')
          .doc(carId)
          .get();
      
      if (!carDoc.exists) {
        return {'brand': 'Unknown', 'model': 'Unknown'};
      }
      
      Map<String, dynamic> carData = carDoc.data() as Map<String, dynamic>;
      
      // Store in cache
      _carCache[carId] = {
        'brand': carData['brand'] ?? 'Unknown',
        'model': carData['model'] ?? 'Unknown',
        'year': carData['year']?.toString() ?? '',
      };
      
      return _carCache[carId]!;
    } catch (e) {
      return {'brand': 'Unknown', 'model': 'Unknown'};
    }
  }
  
  // Build appointment card
  Widget _buildAppointmentCard(AppointmentModel appointment, bool showActions) {
    String formattedDate = '';
    try {
      formattedDate = DateFormat('EEEE, d MMMM yyyy', 'en').format(appointment.date);
    } catch (e) {
      formattedDate = DateFormat('yyyy/MM/dd').format(appointment.date);
    }
    
    // Map status to display text
    String displayStatus;
    switch (appointment.status) {
      case 'pending':
        displayStatus = 'Upcoming';
        break;
      case 'completed':
        displayStatus = 'Completed';
        break;
      case 'canceled':
        displayStatus = 'Canceled';
        break;
      default:
        displayStatus = appointment.status;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(appointment.status).withOpacity(0.1),
                border: Border(
                  left: BorderSide(
                    color: _getStatusColor(appointment.status),
                    width: 5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(appointment.status),
                      size: 22,
                      color: _getStatusColor(appointment.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.time,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      displayStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Appointment #${appointment.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Service', appointment.service),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _fetchCarDetails(appointment.carId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildInfoRow('Car', 'Loading...');
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData) {
                        return _buildInfoRow('Car', appointment.carModel);
                      }
                      
                      final carData = snapshot.data!;
                      final brand = carData['brand'] ?? 'Unknown';
                      final model = carData['model'] ?? 'Unknown';
                      final year = carData['year'] ?? '';
                      
                      String carInfo = '$brand $model';
                      if (year.isNotEmpty) {
                        carInfo += ' $year';
                      }
                      
                      return _buildInfoRow('Car', carInfo);
                    },
                  ),
                  _buildInfoRow(
                    'Center', 
                    appointment.serviceCenter?['name']?.toString() ?? appointment.center
                  ),
                  if (appointment.notes != null && appointment.notes!.isNotEmpty)
                    _buildInfoRow('Notes', appointment.notes!),
                  
                  if (showActions && appointment.status == 'pending') ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              _showCancelConfirmationDialog(appointment);
                            },
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel Appointment'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.red.shade200),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build info row in appointment card
  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) {
      value = 'Not specified';
    }
    
    // For center information, try to extract just the name if it's JSON
    if (label == 'Center' && value.contains('{') && value.contains('}')) {
      try {
        // If the center value is a stringified JSON object
        if (value.contains('"name"')) {
          // Use simple string manipulation to extract name
          final nameStartIndex = value.indexOf('"name"') + 8; // 8 is the length of "name":"
          final nameEndIndex = value.indexOf('"', nameStartIndex);
          if (nameStartIndex > 8 && nameEndIndex > nameStartIndex) {
            value = value.substring(nameStartIndex, nameEndIndex);
          }
        }
      } catch (e) {
        print('Error extracting center name: $e');
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForLabel(label),
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get icon based on label
  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Service':
        return Icons.miscellaneous_services;
      case 'Car':
        return Icons.directions_car;
      case 'Center':
        return Icons.location_on;
      case 'Notes':
        return Icons.note;
      default:
        return Icons.info;
    }
  }
  
  // Get icon for appointment status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'completed':
        return Icons.check_circle;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Show book appointment dialog
  void _showBookAppointmentDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookingScreen(),
      ),
    ).then((_) {
      // Reload appointments after returning from booking screen
      _loadAppointmentsFromProvider();
    });
  }

  // Show cancel confirmation dialog
  void _showCancelConfirmationDialog(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to cancel this appointment?'),
              const SizedBox(height: 16),
              _buildConfirmationDetails('Service', appointment.service),
              _buildConfirmationDetails('Date', DateFormat('d MMMM yyyy', 'en').format(appointment.date)),
              _buildConfirmationDetails('Time', appointment.time),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No, Keep It'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelAppointment(appointment.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildConfirmationDetails(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Cancel appointment
  void _cancelAppointment(String id) {
    setState(() {
      _isLoading = true;
    });
    
    _appointmentService.cancelAppointment(id).then((_) {
      if (mounted) {
        setState(() {
          _upcomingAppointments = _appointmentService.getUpcomingAppointments();
          _completedAppointments = _appointmentService.getCompletedAppointments();
          _canceledAppointments = _appointmentService.getCanceledAppointments();
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Appointment canceled successfully'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error canceling appointment: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }


  // ignore: unused_element
  void _showDebugInfo() {
    String userId = _getCurrentUserId();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Debug Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('User ID: $userId'),
                const SizedBox(height: 8),
                Text('Upcoming appointments: ${_upcomingAppointments.length}'),
                Text('Completed appointments: ${_completedAppointments.length}'),
                Text('Canceled appointments: ${_canceledAppointments.length}'),
                const SizedBox(height: 8),
                Text('Loading state: ${_isLoading ? 'Loading' : 'Loaded'}'),
                if (_errorMessage != null) Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                Text('Current collection: ${_appointmentService.getCurrentCollection()}'),
                ElevatedButton(
                  onPressed: () {
                    _appointmentService.toggleCollection();
                    setState(() {});
                    Navigator.of(context).pop();
                    _showDebugInfo(); // Reopen dialog to show updated info
                  },
                  child: const Text('Toggle Collection'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _refreshAppointments();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }
} 