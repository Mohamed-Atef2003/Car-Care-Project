import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/emergency.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Map<int, bool> _hoveredIndices = {};
  bool _isLoading = true;
  String? _errorMessage;
  List<Emergency> _emergencies = [];
// 'all', 'pending', 'inProgress', 'resolved'
  String _sortBy = 'date'; // 'date', 'priority'
  String _searchQuery = '';
  String _selectedFilter = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
    _fetchEmergencies();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchEmergencies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('emergency').get();
      
      final List<Emergency> emergencies = querySnapshot.docs.map((doc) {
        return Emergency.fromFirestore(doc.data(), doc.id);
      }).toList();
      
      setState(() {
        _emergencies = emergencies;
        _isLoading = false;
      });
      
      print('Fetched ${emergencies.length} emergencies from Firestore');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error occurred while fetching data: ${e.toString()}';
      });
      print('Error fetching emergencies: $e');
    }
  }

  List<Emergency> _filterEmergencies() {
    if (_searchQuery.isNotEmpty) {
      return _emergencies.where((emergency) {
        final query = _searchQuery.toLowerCase();
        return emergency.customerName.toLowerCase().contains(query) ||
               emergency.customerPhone.toLowerCase().contains(query) ||
               emergency.location.toLowerCase().contains(query) ||
               emergency.getVehicleInfo().toLowerCase().contains(query) ||
               emergency.serviceTitle.toLowerCase().contains(query) ||
               emergency.status.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedFilter.isEmpty) {
      return _emergencies;
    }

    return _emergencies.where((emergency) {
      if (_selectedFilter == 'high') {
        return emergency.isUrgent;
      } else if (_selectedFilter == 'low') {
        return !emergency.isUrgent;
      } else {
        return emergency.status == _filterToStatus(_selectedFilter);
      }
    }).toList();
  }

  List<Emergency> get _filteredEmergencies {
    List<Emergency> filtered = _filterEmergencies();
    
    // Apply sorting
    if (_sortBy == 'date') {
      filtered.sort((a, b) => b.requestTime.compareTo(a.requestTime));
    } else if (_sortBy == 'priority') {
      filtered.sort((a, b) {
        if (a.isUrgent && !b.isUrgent) return -1;
        if (!a.isUrgent && b.isUrgent) return 1;
        return 0;
      });
    }
    
    return filtered;
  }

  String _filterToStatus(String filter) {
    switch (filter) {
      case 'pending':
        return 'Pending';
      case 'inProgress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'cancelled':
        return 'Cancelled';
      default:
        return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      case 'true':
        return Colors.red;
      case 'false':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateEmergencyStatus(String emergencyId, String newStatus) async {
    try {
      String firestoreStatus = Emergency.getEnglishStatus(newStatus);
      
      // Add an update to the emergency updates list
      EmergencyUpdate update = EmergencyUpdate(
        message: 'Status changed to $newStatus',
        author: 'Admin',
        timestamp: DateTime.now(),
      );
      
      await FirebaseFirestore.instance.collection('emergency').doc(emergencyId).update({
        'status': firestoreStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updates': FieldValue.arrayUnion([update.toMap()]),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Emergency status updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      _fetchEmergencies();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to update emergency status: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      print('Error updating emergency status: $e');
    }
  }

  void _showEmergencyDetails(Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emergency, size: 24, color: Colors.red),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Emergency #${emergency.id}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(emergency.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      emergency.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(emergency.getPriorityText()),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Priority: ${emergency.getPriorityText()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Customer Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Customer Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Name', emergency.customerName),
                                const SizedBox(height: 8),
                                _buildInfoRow('Phone Number', emergency.customerPhone),
                                const SizedBox(height: 8),
                                _buildInfoRow('Location', emergency.location),
                                if (emergency.customerEmail != null) ...[
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Email', emergency.customerEmail!),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // Right column - Vehicle Info & Emergency Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vehicle Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Vehicle', emergency.getVehicleInfo()),
                                if (emergency.vehicleLicense != null) ...[
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Vehicle License', emergency.vehicleLicense!),
                                ],
                                
                                const SizedBox(height: 24),
                                const Text(
                                  'Emergency Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Service Type', emergency.serviceTitle),
                                const SizedBox(height: 8),
                                _buildInfoRow('Request Date', DateFormat('yyyy-MM-dd HH:mm').format(emergency.requestTime)),
                                if (emergency.serviceCost != null) ...[
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Estimated Cost', emergency.serviceCost!),
                                ],
                                if (emergency.serviceEta != null) ...[
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Estimated Arrival Time', emergency.serviceEta!),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      if (emergency.notes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(emergency.notes),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      const Text(
                        'Updates',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (emergency.updates?.isNotEmpty == true)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: emergency.updates?.length ?? 0,
                          itemBuilder: (context, index) {
                            final update = emergency.updates![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          DateFormat('yyyy-MM-dd HH:mm').format(update.timestamp),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          update.author,
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(update.message),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No updates yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
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
                  if (emergency.status != 'Resolved' && emergency.status != 'Cancelled') ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateEmergencyStatus(emergency.id, 'Cancelled');
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateEmergencyStatus(emergency.id, 'Resolved');
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Resolved'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateEmergencyStatus(emergency.id, 'In Progress');
                      },
                      icon: const Icon(Icons.engineering),
                      label: const Text('In Progress'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildEmergencyCard(Emergency emergency, int index) {
    final isHovered = _hoveredIndices[index] ?? false;
    final isPending = emergency.status == 'Pending';
    final priorityText = emergency.getPriorityText();
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndices[index] = true),
      onExit: (_) => setState(() => _hoveredIndices[index] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? emergency.isUrgent
                      ? Colors.red.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isHovered ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: emergency.isUrgent
                ? Colors.red.withOpacity(isHovered ? 0.5 : 0.2)
                : Colors.grey.shade200,
            width: emergency.isUrgent ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEmergencyDetails(emergency),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(emergency.status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        emergency.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priorityText),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        priorityText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(emergency.requestTime),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  emergency.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.build_circle, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        emergency.serviceTitle,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        emergency.getVehicleInfo(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        emergency.location,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (emergency.customerPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        emergency.customerPhone,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (isPending)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _updateEmergencyStatus(emergency.id, 'Cancelled');
                        },
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          _updateEmergencyStatus(emergency.id, 'Resolved');
                        },
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Resolved'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _updateEmergencyStatus(emergency.id, 'In Progress');
                        },
                        icon: const Icon(Icons.engineering, size: 16),
                        label: const Text('Process'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEmergencies,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _emergencies.isEmpty
                  ? const Center(child: Text('No emergency cases'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search emergency cases...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildFilterMenu(),
                              const SizedBox(width: 8),
                              _buildSortMenu(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredEmergencies.length,
                              itemBuilder: (context, index) => _buildEmergencyCard(_filteredEmergencies[index], index),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          color: _selectedFilter.isNotEmpty ? Colors.blue.withOpacity(0.1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              color: _selectedFilter.isNotEmpty ? Colors.blue : null,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _getFilterText(),
              style: TextStyle(
                color: _selectedFilter.isNotEmpty ? Colors.blue : null,
              ),
            ),
          ],
        ),
      ),
      onSelected: (filter) {
        setState(() {
          _selectedFilter = filter == 'all' ? '' : filter;
        });
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'all',
          child: Text('All'),
        ),
        const PopupMenuItem<String>(
          value: 'pending',
          child: Text('Pending'),
        ),
        const PopupMenuItem<String>(
          value: 'inProgress',
          child: Text('In Progress'),
        ),
        const PopupMenuItem<String>(
          value: 'resolved',
          child: Text('Resolved'),
        ),
        const PopupMenuItem<String>(
          value: 'cancelled',
          child: Text('Cancelled'),
        ),
        const PopupMenuItem<String>(
          value: 'high',
          child: Text('High Priority'),
        ),
        const PopupMenuItem<String>(
          value: 'low',
          child: Text('Low Priority'),
        ),
      ],
    );
  }

  String _getFilterText() {
    switch (_selectedFilter) {
      case 'pending':
        return 'Pending';
      case 'inProgress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'cancelled':
        return 'Cancelled';
      case 'high':
        return 'High Priority';
      case 'low':
        return 'Low Priority';
      default:
        return 'Filter';
    }
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          color: _sortBy != 'date' ? Colors.blue.withOpacity(0.1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              color: _sortBy != 'date' ? Colors.blue : null,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _sortBy == 'date' ? 'Date' : 'Priority',
              style: TextStyle(
                color: _sortBy != 'date' ? Colors.blue : null,
              ),
            ),
          ],
        ),
      ),
      onSelected: (sort) {
        setState(() {
          _sortBy = sort;
        });
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'date',
          child: Text('Date'),
        ),
        const PopupMenuItem<String>(
          value: 'priority',
          child: Text('Priority'),
        ),
      ],
    );
  }
} 