import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:car_care/dialogs/logout_dialog.dart';
import 'package:intl/intl.dart';
import 'package:car_care/services/firebase_service.dart';

import 'package:car_care/pages/my_products_page.dart';
import 'package:car_care/pages/employee_page.dart';

import 'package:car_care/pages/orders_page.dart';

import 'package:car_care/pages/chat_page.dart';


import 'appointments_page.dart';
import 'emergency_page.dart';
import 'customers_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 0;
  Map<String, bool> cardHoverStates = {};
  
  // Use the improved Firebase service instead of direct Firestore access
  final FirebaseService _firebaseService = FirebaseService();

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.home_outlined, 'title': 'Home', 'badge': false},
    {'icon': Icons.group, 'title': 'My Products', 'badge': false},
    {'icon': Icons.person_outline, 'title': 'Employee', 'badge': false},
    {'icon': Icons.shopping_cart_outlined, 'title': 'Orders', 'badge': false},
    {'icon': Icons.calendar_month_outlined, 'title': 'Appointments', 'badge': false},
    {'icon': Icons.emergency_outlined, 'title': 'Emergency', 'badge': false},
    {'icon': Icons.people_alt_outlined, 'title': 'Customers', 'badge': false},
    {'icon': Icons.chat_outlined, 'title': 'Chat', 'badge': false},
  ];

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
    
    // Schedule dashboard data initialization for after the first frame is rendered
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Dashboard is streaming in real-time now
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Modify all Firestore stream methods to handle threading properly
  Stream<int> _getCustomersCount() {
    return _firebaseService.collectionStream('customer_account')
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          print('Error getting customers count: $error');
          return 0;
        });
  }

  // For all Firebase Firestore queries, let's add a common method to run them on the platform thread
  // Add this helper method to ensure Firestore operations run on the platform thread
  Stream<T> _ensurePlatformThread<T>(Stream<T> stream) {
    // We're now using the FirebaseService's built-in platform thread handling
    return stream;
  }

  // Stream for products count
  Stream<int> _getProductsCount() {
    return _ensurePlatformThread(
      _firebaseService.collectionStream('products')
          .map((snapshot) => snapshot.docs.length)
    );
  }

  // Stream for products with low stock (less than 10)
  Stream<int> _getLowStockProductsCount() {
    return _firebaseService.collectionStream('products')
        .map((snapshot) {
          int lowStockCount = 0;
          for (var doc in snapshot.docs) {
            // First check stockCount field (preferred) then fallback to stock field
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            
            var stockData = data['stockCount'];
            stockData ??= data['stock'];
            
            int stock = 0;
            if (stockData is int) {
              stock = stockData;
            } else if (stockData is double) {
              stock = stockData.toInt();
            } else if (stockData is String) {
              stock = int.tryParse(stockData) ?? 0;
            }
            
            // Check if it's low stock (less than 10) - exact match with my_products_page.dart
            if (stock < 10) {
              lowStockCount++;
            }
          }
          print('Low stock products count: $lowStockCount');
          return lowStockCount;
        });
  }

  // Stream for products out of stock (0 stock)
  Stream<int> _getOutOfStockProductsCount() {
    return _firebaseService.collectionStream('products')
        .map((snapshot) {
          int outOfStockCount = 0;
          for (var doc in snapshot.docs) {
            // First check stockCount field (preferred) then fallback to stock field
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            
            var stockData = data['stockCount'];
            stockData ??= data['stock'];
            
            int stock = 0;
            if (stockData is int) {
              stock = stockData;
            } else if (stockData is double) {
              stock = stockData.toInt();
            } else if (stockData is String) {
              stock = int.tryParse(stockData) ?? 0;
            }
            
            // Check if it's out of stock (exactly 0)
            if (stock == 0) {
              outOfStockCount++;
            }
          }
          print('Out of stock products count: $outOfStockCount');
          return outOfStockCount;
        });
  }

  // Stream for employees count
  Stream<int> _getEmployeesCount() {
    return _firebaseService.collectionStream('Employee')
        .map((snapshot) {
          print('Employee snapshot: ${snapshot.docs.length} documents found');
          return snapshot.docs.length;
        });
  }

  // Stream for emergency cases count - only count active cases (excluding Cancelled and Resolved)
  Stream<int> _getEmergenciesCount() {
    return _firebaseService.collectionStream('emergency')
        .map((snapshot) {
          int activeCount = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            
            String status = data['status']?.toString() ?? '';
            status = status.toLowerCase().trim();
            
            // Only count emergencies with In Progress or Pending status
            if (status == 'pending' || 
                status == 'in_progress' || 
                status == 'inprogress' || 
                status == 'in progress') {
              activeCount++;
            }
          }
          debugPrint('Active emergency cases count (Pending/In Progress): $activeCount');
          return activeCount;
        });
  }

  // Stream for active orders count (not completed or rejected)
  Stream<int> _getActiveOrdersCount() {
    return _firebaseService.collectionStream(
      'orders',
      queryBuilder: (query) => query.where('status', whereNotIn: ['Completed', 'Rejected', 'completed', 'rejected'])
    ).map((snapshot) => snapshot.docs.length);
  }

  // Stream for total income from all orders
  Stream<double> _getTotalIncome() {
    return _firebaseService.collectionStream('orders')
        .map((snapshot) {
          double totalIncome = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            
            var amountData = data['amount'];
            double amount = 0;
            
            if (amountData is int) {
              amount = amountData.toDouble();
            } else if (amountData is double) {
              amount = amountData;
            } else if (amountData is String) {
              amount = double.tryParse(amountData) ?? 0;
            }
            
            totalIncome += amount;
          }
          return totalIncome;
        });
  }

  // Stream for order counts by status
  Stream<Map<String, int>> _getOrderCountsByStatus() {
    return _firebaseService.collectionStream('orders')
        .map((snapshot) {
          // Initialize counters for each status
          Map<String, int> counts = {
            'All': snapshot.docs.length,
            'Pending': 0,
            'Accepted': 0,
            'Rejected': 0,
            'Processing': 0,
            'Completed': 0
          };
          
          // Count orders by status
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            
            String status = data['status']?.toString() ?? '';
            status = status.toLowerCase().trim();
            
            // Map lowercase status to our standard format
            if (status == 'pending') {
              counts['Pending'] = (counts['Pending'] ?? 0) + 1;
            } else if (status == 'accepted') counts['Accepted'] = (counts['Accepted'] ?? 0) + 1;
            else if (status == 'rejected') counts['Rejected'] = (counts['Rejected'] ?? 0) + 1;
            else if (status == 'processing') counts['Processing'] = (counts['Processing'] ?? 0) + 1;
            else if (status == 'completed') counts['Completed'] = (counts['Completed'] ?? 0) + 1;
          }
          
          return counts;
        }).handleError((error) {
          debugPrint('Error getting order counts: $error');
          return {'All': 0, 'Pending': 0, 'Accepted': 0, 'Rejected': 0, 'Processing': 0, 'Completed': 0};
        });
  }

  // Stream for appointment counts by status
  Stream<Map<String, int>> _getAppointmentCountsByStatus() {
    return _firebaseService.collectionStream('appointment')
        .map((snapshot) {
          // Initialize counters for each status
          Map<String, int> counts = {
            'All': snapshot.docs.length,
            'Upcoming': 0,
            'Completed': 0,
            'Cancelled': 0
          };
          
          // Count appointments by status
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            
            String status = data['status']?.toString() ?? '';
            status = status.toLowerCase().trim();
            
            // Status can be upcoming, completed, cancelled
            if (status == 'upcoming' || status == 'scheduled' || status == 'pending') {
              counts['Upcoming'] = (counts['Upcoming'] ?? 0) + 1;
            } else if (status == 'completed' || status == 'done') {
              counts['Completed'] = (counts['Completed'] ?? 0) + 1;
            } else if (status == 'cancelled' || status == 'canceled') {
              counts['Cancelled'] = (counts['Cancelled'] ?? 0) + 1;
            }
          }
          
          debugPrint('Appointment counts: $counts');
          return counts;
        }).handleError((error) {
          debugPrint('Error getting appointment counts: $error');
          return {'All': 0, 'Upcoming': 0, 'Completed': 0, 'Cancelled': 0};
        });
  }

  // Stream for emergency counts by status
  Stream<Map<String, int>> _getEmergencyCountsByStatus() {
    return _firebaseService.collectionStream('emergency')
        .map((snapshot) {
          // Initialize counters for each status
          Map<String, int> counts = {
            'All': snapshot.docs.length,
            'Pending': 0,
            'In Progress': 0,
            'Resolved': 0,
            'Cancelled': 0
          };
          
          // Count emergencies by status
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            
            String status = data['status']?.toString() ?? '';
            status = status.toLowerCase().trim();
            
            // Map lowercase status to our standard format
            if (status == 'pending' || status == 'قيد الانتظار') {
              counts['Pending'] = (counts['Pending'] ?? 0) + 1;
            } else if (status == 'in progress' || status == 'inprogress' || status == 'قيد المعالجة') {
              counts['In Progress'] = (counts['In Progress'] ?? 0) + 1;
            } else if (status == 'resolved' || status == 'completed' || status == 'تم الحل') {
              counts['Resolved'] = (counts['Resolved'] ?? 0) + 1;
            } else if (status == 'cancelled' || status == 'canceled') {
              counts['Cancelled'] = (counts['Cancelled'] ?? 0) + 1;
            }
          }
          
          debugPrint('Emergency counts: $counts');
          return counts;
        }).handleError((error) {
          debugPrint('Error getting emergency counts: $error');
          return {'All': 0, 'Pending': 0, 'In Progress': 0, 'Resolved': 0, 'Cancelled': 0};
        });
  }

  Widget _buildWelcomeContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Updated header with welcome message and date
              _buildHeaderContainer(),
              
              const SizedBox(height: 32),
              
              // Section title with improved styling
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade100, Colors.blue.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Business Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Dashboard Grid with improved layout
              _buildDashboardGrid(),
              
              const SizedBox(height: 32),
              
              // Update system info card with modern design
              Container(
                margin: const EdgeInsets.only(top: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, Colors.indigo.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.indigo.shade300, Colors.indigo.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'System Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[700],
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildInfoItem(
                          icon: Icons.update,
                          title: 'Real-Time Updates',
                          description: 'All statistics are updated in real-time',
                        ),
                        _buildInfoItem(
                          icon: Icons.touch_app,
                          title: 'Interactive',
                          description: 'Click any card to navigate to its page',
                        ),
                        _buildInfoItem(
                          icon: Icons.security,
                          title: 'Secure Access',
                          description: 'All data is protected and secure',
                        ),
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

  // Update the header container with more modern design
  Widget _buildHeaderContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Welcome to Car Care Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today: ${DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                ),
                const Spacer(),
              
                    
           
            ],
          ),
          const SizedBox(height: 24),
          // Summary counts row
          _buildSummaryRow(),
        ],
      ),
    );
  }

  // Build summary row with total counts
  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: _getCustomersCount(),
            builder: (context, snapshot) {
              return _buildSummaryItem(
                title: 'Total Customers',
                count: snapshot.data ?? 0,
                icon: Icons.people,
                color: Colors.blue,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<int>(
            stream: _getProductsCount(),
            builder: (context, snapshot) {
              return _buildSummaryItem(
                title: 'Total Products',
                count: snapshot.data ?? 0,
                icon: Icons.inventory,
                color: Colors.green,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<int>(
            stream: _getActiveOrdersCount(),
            builder: (context, snapshot) {
              return _buildSummaryItem(
                title: 'Active Orders',
                count: snapshot.data ?? 0,
                icon: Icons.shopping_cart,
                color: Colors.orange,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<double>(
            stream: _getTotalIncome(),
            builder: (context, snapshot) {
              return _buildSummaryItemMoney(
                title: 'Total Income',
                amount: snapshot.data ?? 0,
                icon: Icons.attach_money,
                color: Colors.green.shade700,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<int>(
            stream: _getEmergenciesCount(),
            builder: (context, snapshot) {
              return _buildSummaryItem(
                title: 'Active Emergencies',
                count: snapshot.data ?? 0,
                icon: Icons.emergency,
                color: Colors.red,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
        ),
      ],
    );
  }

  // Summary item for the summary row - Money version
  Widget _buildSummaryItemMoney({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    // Format the amount with comma separators and 2 decimal places
    final formattedAmount = amount.toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 0.9,
                    ),
                    children: [
                      TextSpan(
                        text: 'EGP ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: formattedAmount,
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // Summary item for the summary row
  Widget _buildSummaryItem({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 0.9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Trend indicator can be added here
                  ],
                ),
        ],
      ),
    );
  }

  // Information item for the system info section
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.indigo[400],
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      height: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update _buildDashboardCard with modern design and better hover effects
  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Stream<int> countStream,
    required VoidCallback onTap,
  }) {
    color.withOpacity(0.1);
    final String hoverKey = title;
    
    return MouseRegion(
      onEnter: (_) => setState(() => cardHoverStates[hoverKey] = true),
      onExit: (_) => setState(() => cardHoverStates[hoverKey] = false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          decoration: BoxDecoration(
            color: Colors.white,
            gradient: cardHoverStates[hoverKey] == true
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, color.withOpacity(0.1)],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cardHoverStates[hoverKey] == true
                    ? color.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: cardHoverStates[hoverKey] == true ? 12 : 5,
                offset: cardHoverStates[hoverKey] == true 
                    ? const Offset(0, 4)
                    : const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: cardHoverStates[hoverKey] == true
                  ? color
                  : Colors.grey.shade200,
              width: cardHoverStates[hoverKey] == true ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Decorative corner element with animation
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                top: 0,
                right: 0,
                child: Container(
                  width: cardHoverStates[hoverKey] == true ? 50 : 40,
                  height: cardHoverStates[hoverKey] == true ? 50 : 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: cardHoverStates[hoverKey] == true
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: cardHoverStates[hoverKey] == true ? 0.125 : 0,
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: cardHoverStates[hoverKey] == true ? 20 : 16,
                      ),
                    ),
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutQuint,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: cardHoverStates[hoverKey] == true
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title with improved typography
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<int>(
                      stream: countStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          );
                        } else if (snapshot.hasError) {
                          return Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Error loading data',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red[400],
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          final count = snapshot.data ?? 0;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  count.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    height: 0.9,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Add a small trend indicator if needed later
                            ],
                          );
                        }
                      },
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

  // Update Money Dashboard Card with matching hover effects
  Widget _buildMoneyDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Stream<double> amountStream,
    required VoidCallback onTap,
  }) {
    final String hoverKey = title;
    
    return MouseRegion(
      onEnter: (_) => setState(() => cardHoverStates[hoverKey] = true),
      onExit: (_) => setState(() => cardHoverStates[hoverKey] = false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          decoration: BoxDecoration(
            color: Colors.white,
            gradient: cardHoverStates[hoverKey] == true
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, color.withOpacity(0.1)],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cardHoverStates[hoverKey] == true
                    ? color.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: cardHoverStates[hoverKey] == true ? 12 : 5,
                offset: cardHoverStates[hoverKey] == true 
                    ? const Offset(0, 4)
                    : const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: cardHoverStates[hoverKey] == true
                  ? color
                  : Colors.grey.shade200,
              width: cardHoverStates[hoverKey] == true ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Decorative corner element with animation
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                top: 0,
                right: 0,
                child: Container(
                  width: cardHoverStates[hoverKey] == true ? 50 : 40,
                  height: cardHoverStates[hoverKey] == true ? 50 : 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: cardHoverStates[hoverKey] == true
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: cardHoverStates[hoverKey] == true ? 0.125 : 0,
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: cardHoverStates[hoverKey] == true ? 20 : 16,
                      ),
                    ),
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutQuint,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: cardHoverStates[hoverKey] == true
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<double>(
                      stream: amountStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          );
                        } else if (snapshot.hasError) {
                          return Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Error loading data',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red[400],
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          final amount = snapshot.data ?? 0;
                          final formattedAmount = amount.toStringAsFixed(2)
                            .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                      height: 0.9,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'EGP ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      TextSpan(
                                        text: formattedAmount,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
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

  // Modify the Products card with IntrinsicHeight to match content exactly
  Widget _buildProductsCard() {
    final Color color = Colors.green;
    final String hoverKey = 'Products';
    
    return MouseRegion(
      onEnter: (_) => setState(() => cardHoverStates[hoverKey] = true),
      onExit: (_) => setState(() => cardHoverStates[hoverKey] = false),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = 1; // Navigate to Products page
          });
        },
        child: IntrinsicHeight( // Use IntrinsicHeight to calculate natural height based on content
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: cardHoverStates[hoverKey] == true
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, color.withOpacity(0.1)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cardHoverStates[hoverKey] == true
                      ? color.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: cardHoverStates[hoverKey] == true ? 12 : 5,
                  offset: cardHoverStates[hoverKey] == true 
                      ? const Offset(0, 4)
                      : const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: cardHoverStates[hoverKey] == true
                    ? color
                    : Colors.grey.shade200,
                width: cardHoverStates[hoverKey] == true ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Decorative corner element with animation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  top: 0,
                  right: 0,
                  child: Container(
                    width: cardHoverStates[hoverKey] == true ? 50 : 40,
                    height: cardHoverStates[hoverKey] == true ? 50 : 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          color,
                          color.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      boxShadow: cardHoverStates[hoverKey] == true
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: cardHoverStates[hoverKey] == true ? 0.125 : 0,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: cardHoverStates[hoverKey] == true ? 20 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Use minimum size needed for content
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutQuint,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: cardHoverStates[hoverKey] == true
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.green,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inventory status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Product statistics with direct placement instead of Flexible/Expanded
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Total Products Count
                          StreamBuilder<int>(
                            stream: _getProductsCount(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildLoadingIndicator(Colors.green);
                              } else if (snapshot.hasError) {
                                return _buildErrorText(snapshot.error);
                              } else {
                                final count = snapshot.data ?? 0;
                                return _buildStatRow(
                                  label: 'Total Products',
                                  value: count.toString(),
                                  color: Colors.green,
                                );
                              }
                            },
                          ),
                          
                          // Low Stock Products Count
                          StreamBuilder<int>(
                            stream: _getLowStockProductsCount(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildLoadingIndicator(Colors.orange);
                              } else if (snapshot.hasError) {
                                return _buildErrorText(snapshot.error);
                              } else {
                                final count = snapshot.data ?? 0;
                                return _buildStatRow(
                                  label: 'Low Stock',
                                  value: count.toString(),
                                  color: Colors.orange,
                                );
                              }
                            },
                          ),
                          
                          // Out of Stock Products Count
                          StreamBuilder<int>(
                            stream: _getOutOfStockProductsCount(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildLoadingIndicator(Colors.red);
                              } else if (snapshot.hasError) {
                                return _buildErrorText(snapshot.error);
                              } else {
                                final count = snapshot.data ?? 0;
                                return _buildStatRow(
                                  label: 'Out of Stock',
                                  value: count.toString(),
                                  color: Colors.red,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build Orders card with IntrinsicHeight
  Widget _buildOrdersCard() {
    final Color color = Colors.orange;
    final String hoverKey = 'Orders';
    
    return MouseRegion(
      onEnter: (_) => setState(() => cardHoverStates[hoverKey] = true),
      onExit: (_) => setState(() => cardHoverStates[hoverKey] = false),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = 3; // Navigate to Orders page
          });
        },
        child: IntrinsicHeight( // Use IntrinsicHeight to calculate natural height based on content
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: cardHoverStates[hoverKey] == true
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, color.withOpacity(0.1)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cardHoverStates[hoverKey] == true
                      ? color.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: cardHoverStates[hoverKey] == true ? 12 : 5,
                  offset: cardHoverStates[hoverKey] == true 
                      ? const Offset(0, 4)
                      : const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: cardHoverStates[hoverKey] == true
                    ? color
                    : Colors.grey.shade200,
                width: cardHoverStates[hoverKey] == true ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Decorative corner element with animation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  top: 0,
                  right: 0,
                  child: Container(
                    width: cardHoverStates[hoverKey] == true ? 50 : 40,
                    height: cardHoverStates[hoverKey] == true ? 50 : 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          color,
                          color.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      boxShadow: cardHoverStates[hoverKey] == true
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: cardHoverStates[hoverKey] == true ? 0.125 : 0,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: cardHoverStates[hoverKey] == true ? 20 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
                // Card content with proper layout
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Use minimum size needed for content
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon section
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutQuint,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: cardHoverStates[hoverKey] == true
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.orange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title section
                      Text(
                        'Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order status breakdown',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Order statistics directly in column instead of Flexible
                      StreamBuilder<Map<String, int>>(
                        stream: _getOrderCountsByStatus(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLoadingIndicator(Colors.orange),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return _buildErrorText(snapshot.error);
                          } else {
                            final counts = snapshot.data ?? {};
                            
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatRow(
                                  label: 'All Orders',
                                  value: counts['All']?.toString() ?? '0',
                                  color: Colors.blue,
                                ),
                                _buildStatRow(
                                  label: 'Pending',
                                  value: counts['Pending']?.toString() ?? '0',
                                  color: Colors.orange,
                                ),
                                _buildStatRow(
                                  label: 'Accepted',
                                  value: counts['Accepted']?.toString() ?? '0',
                                  color: Colors.green,
                                ),
                                _buildStatRow(
                                  label: 'Processing',
                                  value: counts['Processing']?.toString() ?? '0',
                                  color: Colors.purple,
                                ),
                                _buildStatRow(
                                  label: 'Completed',
                                  value: counts['Completed']?.toString() ?? '0',
                                  color: Colors.blue,
                                ),
                                _buildStatRow(
                                  label: 'Rejected',
                                  value: counts['Rejected']?.toString() ?? '0',
                                  color: Colors.red,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build Appointments card with IntrinsicHeight
  Widget _buildAppointmentsCard() {
    final Color color = Colors.teal;
    final String hoverKey = 'Appointments';
    
    return MouseRegion(
      onEnter: (_) => setState(() => cardHoverStates[hoverKey] = true),
      onExit: (_) => setState(() => cardHoverStates[hoverKey] = false),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = 4; // Navigate to Appointments page
          });
        },
        child: IntrinsicHeight( // Use IntrinsicHeight to calculate natural height based on content
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: cardHoverStates[hoverKey] == true
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, color.withOpacity(0.1)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cardHoverStates[hoverKey] == true
                      ? color.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: cardHoverStates[hoverKey] == true ? 12 : 5,
                  offset: cardHoverStates[hoverKey] == true 
                      ? const Offset(0, 4)
                      : const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: cardHoverStates[hoverKey] == true
                    ? color
                    : Colors.grey.shade200,
                width: cardHoverStates[hoverKey] == true ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  top: 0,
                  right: 0,
                  child: Container(
                    width: cardHoverStates[hoverKey] == true ? 50 : 40,
                    height: cardHoverStates[hoverKey] == true ? 50 : 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          color,
                          color.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      boxShadow: cardHoverStates[hoverKey] == true
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: cardHoverStates[hoverKey] == true ? 0.125 : 0,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: cardHoverStates[hoverKey] == true ? 20 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Use minimum size needed for content
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutQuint,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: cardHoverStates[hoverKey] == true
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.teal,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Appointments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Appointment status breakdown',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Appointment statistics directly in column instead of Flexible
                      StreamBuilder<Map<String, int>>(
                        stream: _getAppointmentCountsByStatus(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLoadingIndicator(Colors.teal),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading ...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return _buildErrorText(snapshot.error);
                          } else {
                            final counts = snapshot.data ?? {};
                            
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatRow(
                                  label: 'All Appointments',
                                  value: counts['All']?.toString() ?? '0',
                                  color: Colors.blue,
                                ),
                                _buildStatRow(
                                  label: 'Upcoming',
                                  value: counts['Upcoming']?.toString() ?? '0',
                                  color: Colors.teal,
                                ),
                                _buildStatRow(
                                  label: 'Completed',
                                  value: counts['Completed']?.toString() ?? '0',
                                  color: Colors.green,
                                ),
                                _buildStatRow(
                                  label: 'Cancelled',
                                  value: counts['Cancelled']?.toString() ?? '0',
                                  color: Colors.red,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build Emergency card with IntrinsicHeight
  Widget _buildEmergencyCard() {
    final Color color = Colors.red;
    final String hoverKey = 'Emergency';
    
    return MouseRegion(
      onEnter: (_) => setState(() => cardHoverStates[hoverKey] = true),
      onExit: (_) => setState(() => cardHoverStates[hoverKey] = false),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = 5; // Navigate to Emergency page
          });
        },
        child: IntrinsicHeight( // Use IntrinsicHeight to calculate natural height based on content
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: cardHoverStates[hoverKey] == true
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, color.withOpacity(0.1)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cardHoverStates[hoverKey] == true
                      ? color.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: cardHoverStates[hoverKey] == true ? 12 : 5,
                  offset: cardHoverStates[hoverKey] == true 
                      ? const Offset(0, 4)
                      : const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: cardHoverStates[hoverKey] == true
                    ? color
                    : Colors.grey.shade200,
                width: cardHoverStates[hoverKey] == true ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  top: 0,
                  right: 0,
                  child: Container(
                    width: cardHoverStates[hoverKey] == true ? 50 : 40,
                    height: cardHoverStates[hoverKey] == true ? 50 : 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          color,
                          color.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      boxShadow: cardHoverStates[hoverKey] == true
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: cardHoverStates[hoverKey] == true ? 0.125 : 0,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: cardHoverStates[hoverKey] == true ? 20 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Use minimum size needed for content
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutQuint,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: cardHoverStates[hoverKey] == true
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: const Icon(
                          Icons.emergency_outlined,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Emergency Cases',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Emergency status breakdown',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Emergency statistics directly in column instead of Flexible
                      StreamBuilder<Map<String, int>>(
                        stream: _getEmergencyCountsByStatus(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLoadingIndicator(Colors.red),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading ...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return _buildErrorText(snapshot.error);
                          } else {
                            final counts = snapshot.data ?? {};
                            
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatRow(
                                  label: 'All Emergencies',
                                  value: counts['All']?.toString() ?? '0',
                                  color: Colors.blue,
                                ),
                                _buildStatRow(
                                  label: 'Pending',
                                  value: counts['Pending']?.toString() ?? '0',
                                  color: Colors.orange,
                                ),
                                _buildStatRow(
                                  label: 'In Progress',
                                  value: counts['In Progress']?.toString() ?? '0',
                                  color: Colors.purple,
                                ),
                                _buildStatRow(
                                  label: 'Resolved',
                                  value: counts['Resolved']?.toString() ?? '0',
                                  color: Colors.green,
                                ),
                                _buildStatRow(
                                  label: 'Cancelled',
                                  value: counts['Cancelled']?.toString() ?? '0',
                                  color: Colors.red,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Replace GridView with a more flexible layout that adapts to content height
  Widget _buildDashboardGrid() {
    return Wrap(
      spacing: 20, // horizontal spacing
      runSpacing: 20, // vertical spacing
      children: [
        // Each card is wrapped in a SizedBox with percentage-based width
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25, // Approximately 3 cards per row
          child: _buildDashboardCard(
            title: 'Customers',
            subtitle: 'Registered accounts',
            icon: Icons.people_alt_outlined,
            color: Colors.blue,
            countStream: _getCustomersCount(),
            onTap: () {
              setState(() {
                _selectedIndex = 6; // Navigate to Customers page
              });
            },
          ),
        ),
        
        // Products card (with more content)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: _buildProductsCard(),
        ),
        
        // Employees Card
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: _buildDashboardCard(
            title: 'Employees',
            subtitle: 'Active staff',
            icon: Icons.person_outline,
            color: Colors.purple,
            countStream: _getEmployeesCount(),
            onTap: () {
              setState(() {
                _selectedIndex = 2; // Navigate to Employees page
              });
            },
          ),
        ),
        
        // Orders card (with more content)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: _buildOrdersCard(),
        ),
        
        // Appointments Card (with more content)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: _buildAppointmentsCard(),
        ),
        
        // Emergency Cases Card (with more content)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: _buildEmergencyCard(),
        ),

        // Total Income Card
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: _buildMoneyDashboardCard(
            title: 'Total Income',
            subtitle: 'Revenue from orders',
            icon: Icons.attach_money,
            color: Colors.amber,
            amountStream: _getTotalIncome(),
            onTap: () {
              setState(() {
                _selectedIndex = 3; // Navigate to Orders page
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildWelcomeContent();
      case 1:
        return const MyProductsPage();
      case 2:
        return const EmployeePage();
      case 3:
        return const OrdersPage();
      case 4:
        return const AppointmentsPage();
      case 5:
        return const EmergencyPage();
      case 6:
        return const CustomersPage();
      case 7:
        return const ChatPage();
      default:
        return _buildWelcomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Navigation
          Container(
            width: 280,
            color: Colors.white,
            child: Column(
              children: [
                // App Logo
                Padding(
                  padding: const EdgeInsets.fromLTRB(19, 20, 0, 30),
                  child: Row(
                    children: const [
                      Text(
                        'Car Care',
                        style: TextStyle(
                          fontSize: 50,
                          fontFamily: 'MacondoSwashCaps',
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        color: Color(0xFF6C6C6C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isSelected = _selectedIndex == index;
                      return ListTile(
                        leading: Icon(
                          item['icon'],
                          color: isSelected ? Colors.red : const Color(0xFF6C6C6C),
                        ),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            color: isSelected ? Colors.red : const Color(0xFF6C6C6C),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: item['badge']
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF000000),
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        selected: isSelected,
                        selectedTileColor: const Color(0xFFF5F5F5),
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Color(0xFF6C6C6C),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFF6C6C6C),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const LogoutDialog(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area with Scrolling
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a loading indicator
  Widget _buildLoadingIndicator(Color color) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  // Helper method to build an error text
  Widget _buildErrorText(Object? error) {
    return Text(
      'Error: ${error.toString()}',
      style: const TextStyle(
        fontSize: 14,
        color: Colors.red,
      ),
    );
  }
  
  // Helper method to build a stat row
  Widget _buildStatRow({
    required String label,
    required String value,
    required Color color,
  }) {
    final double percentage = double.tryParse(value) != null 
        ? (double.parse(value) / 100.0).clamp(0.0, 1.0) 
        : 0.3; // Default for non-numeric values
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // Reduced from 12 to 8
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Reduced from 6 to 4
          // Progress bar for the stat
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: value == '0' ? 0.01 : percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.7), color],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
