import 'package:flutter/material.dart';
import 'package:car_care/models/product.dart' as models;
import 'package:car_care/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Add this import for Timer


// Import dialogs with prefixes to avoid name conflicts
import 'package:car_care/dialogs/add_product_dialog.dart' ;
import 'package:car_care/dialogs/product_details_dialog.dart' ;

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  final List<models.StoreProduct> _products = [];
  List<models.StoreProduct> _filteredProducts = [];
  final searchController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer; // Timer for auto-refresh
  bool _isRefreshing = false; // Flag to track refresh status
  DateTime? _lastRefreshTime; // Track the last refresh time

  final List<String> _categoryFilters = [
    'All Categories',
    'spare_parts',
    'tires',
    'glass',
    'tools',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch products from Firestore instead of adding sample products
    _fetchProductsFromFirestore();
    
    // Start timer for auto-refresh every minute (60 seconds)
    _startAutoRefreshTimer();
  }

  // Start auto-refresh timer
  void _startAutoRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        debugPrint('Auto refresh triggered at ${DateTime.now()}');
        _refreshProducts(); // This already calls _fetchProductsFromFirestore which updates the dashboard
      }
    });
  }

  // Fetch products from Firestore
  Future<void> _fetchProductsFromFirestore() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isRefreshing = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('products').get();
      
      debugPrint('Fetched ${querySnapshot.docs.length} products from Firestore');
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('No products in the "products" collection');
        setState(() {
          _products.clear();
          _filteredProducts.clear();
          _isLoading = false;
          _isRefreshing = false;
          _lastRefreshTime = DateTime.now();
        });
        
        return;
      }
      
      final productsList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final category = data['category'] ?? 'spare_parts';
        
        debugPrint('Converting product: ${doc.id} - Category: $category');
        
        try {
          switch (category) {
            case 'spare_parts':
              return models.SparePart.fromMap(doc.id, data);
            case 'tires':
              return models.Tire.fromMap(doc.id, data);
            case 'glass':
              return models.GlassProduct.fromMap(doc.id, data);
            case 'tools':
              return models.Tool.fromMap(doc.id, data);
            default:
              return models.SparePart.fromMap(doc.id, data);
          }
        } catch (e) {
          debugPrint('Error converting product ${doc.id}: ${e.toString()}');
          // Create a simple product instead
          return models.Product(
            id: doc.id,
            name: data['name'] ?? 'Unknown product',
            price: (data['price'] ?? 0.0).toDouble(),
            description: data['description'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            stock: data['stockCount'] ?? 0,
            category: category,
          );
        }
      }).toList();
      
      setState(() {
        _products.clear();
        _products.addAll(productsList);
        _filteredProducts = List.from(_products);
        _isLoading = false;
        _isRefreshing = false;
        _lastRefreshTime = DateTime.now();
      });
      
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = 'Failed to fetch products: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error while fetching products: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add a new product - called after adding the product to Firestore in the add dialog
  void _addProduct(models.StoreProduct product) {
    setState(() {
      _products.add(product);
      _applyFilters();
    });
    
    
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Update an existing product
  Future<void> _updateProduct(models.StoreProduct updatedProduct) async {
    try {
      debugPrint('Updating product in my_products_page: Product ID: ${updatedProduct.id}');
      
      await FirebaseFirestore.instance.collection('products').doc(updatedProduct.id).update(updatedProduct.toMap());

      debugPrint('Product updated successfully in Firestore from my_products_page');

      setState(() {
        final index = _products.indexWhere((product) => product.id == updatedProduct.id);
        if (index != -1) {
          _products[index] = updatedProduct;
          _applyFilters();
        }
      });
      
      

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in my_products_page: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Remove a product
  Future<void> _removeProduct(String id) async {
    try {
      // Verify ID
      if (id.isEmpty) {
        throw Exception('Invalid product ID');
      }
      
      debugPrint('Deleting product from Firestore: $id');
      
      // Delete product from Firestore
      await FirebaseFirestore.instance.collection('products').doc(id).delete();

      debugPrint('Product deleted successfully from Firestore');

      // Remove product from local list
      setState(() {
        _products.removeWhere((product) => product.id == id);
        _applyFilters();
      });
      
      

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting product: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error while deleting product: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Helper method to update the DashboardProvider
  
  

  // Apply filters to product list
  void _applyFilters() {
    setState(() {
      final searchQuery = searchController.text.toLowerCase();
      
      _filteredProducts = _products.where((product) {
        // Apply category filter
        if (_selectedCategory != null && _selectedCategory != 'All Categories') {
          if (product.category != _selectedCategory) {
            return false;
          }
        }
        
        // Apply search filter
        if (searchQuery.isNotEmpty) {
          return product.name.toLowerCase().contains(searchQuery) ||
              product.description.toLowerCase().contains(searchQuery) ||
              product.category.toLowerCase().contains(searchQuery);
        }
        
        return true;
      }).toList();
    });
  }

  // Separate function to create add product dialog
  Widget _createAddProductDialog() {
    return AddProductDialog(
      onProductAdded: _addProduct,
    );
  }
  
  // Separate function to create product details dialog
  Widget _createProductDetailsDialog(models.StoreProduct product) {
    return ProductDetailsDialog(
      product: product,
      onProductUpdated: _updateProduct,
    );
  }

  // Show product details
  void _showProductDetails(models.StoreProduct product) {
    showDialog(
      context: context,
      builder: (_) => _createProductDetailsDialog(product),
    );
  }

  // Refresh data by reloading from Firestore
  Future<void> _refreshProducts() async {
    // Don't refresh if already refreshing
    if (_isRefreshing) return;
    
    await _fetchProductsFromFirestore();
    
    // Show a short message that data was refreshed
    if (mounted && _error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data updated'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _refreshTimer?.cancel(); // Cancel timer when disposing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title bar with search and add product
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      const Text(
                        'My Products',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: _lastRefreshTime != null 
                                ? 'Last update: ${_lastRefreshTime!.hour}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}'
                                : 'Refresh Products',
                            onPressed: _isRefreshing ? null : _refreshProducts,
                          ),
                          if (_isRefreshing)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_lastRefreshTime != null)
                        Flexible(
                          child: Text(
                            'Last update: ${_lastRefreshTime!.hour}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                          width: 180,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory ?? 'All Categories',
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _categoryFilters.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue == 'All Categories' ? null : newValue;
                                _applyFilters();
                              });
                            },
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C6C6C)),
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 200,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: (query) {
                              _applyFilters();
                            },
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: const TextStyle(color: Color(0xFF6C6C6C)),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF6C6C6C)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => _createAddProductDialog(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 0,
                              ),
                            ),
                            child: const Text(
                              'Add Product',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Product statistics
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildStatCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Total Products',
                    value: _products.length.toString(),
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    icon: Icons.category_outlined,
                    title: 'Categories',
                    value: _products.map((p) => p.category).toSet().length.toString(),
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    icon: Icons.warning_amber_outlined,
                    title: 'Low Stock',
                    value: _products.where((p) => p.stockCount < 10).length.toString(),
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    icon: Icons.inventory_outlined,
                    title: 'Out of Stock',
                    value: _products.where((p) => p.stockCount == 0).length.toString(),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Product list
            Expanded(
              child: _isLoading 
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error occurred',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshProducts,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : _filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search or filters',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshProducts,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return GestureDetector(
                                    onTap: () => _showProductDetails(product),
                                    child: ProductCard(
                                      product: product,
                                      onDelete: () => _removeProduct(product.id),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
