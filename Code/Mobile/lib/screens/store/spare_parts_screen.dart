import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../models/store/spare_part.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'product_details_screen.dart';

class SparePartsScreen extends StatefulWidget {
  const SparePartsScreen({super.key});

  @override
  State<SparePartsScreen> createState() => _SparePartsScreenState();
}

class _SparePartsScreenState extends State<SparePartsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  bool _isLoading = true;
  String? _error;
  
  // List of all spare parts
  List<SparePart> _allSpareParts = [];
  // Filtered list of spare parts
  List<SparePart> _filteredSpareParts = [];
  
  @override
  void initState() {
    super.initState();
    _loadSpareParts();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load spare parts from the provider
  Future<void> _loadSpareParts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await Provider.of<StoreProvider>(context, listen: false).loadSpareParts();
      setState(() {
        _allSpareParts = Provider.of<StoreProvider>(context, listen: false).spareParts;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading spare parts: $e';
        _isLoading = false;
      });
    }
  }
  
  // Apply filters to the spare parts
  void _applyFilters() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredSpareParts = List.from(_allSpareParts);
      } else {
        _filteredSpareParts = _allSpareParts.where((part) {
          final nameMatch = part.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final brandMatch = part.brand.toLowerCase().contains(_searchQuery.toLowerCase());
          final categoryMatch = part.category.toLowerCase().contains(_searchQuery.toLowerCase());
          final partNumberMatch = part.partNumber.toLowerCase().contains(_searchQuery.toLowerCase());
          return nameMatch || brandMatch || categoryMatch || partNumberMatch;
        }).toList();
      }
    });
  }
  
  // Update search query
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }
  
  // Clear filters
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
    });
  }
  
  // // Start buying a spare part
  // void _buyNow(SparePart sparePart) {
  //   // Schedule after the build is complete
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     // Logic for buying now
  //     final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      
  //     // Add to cart
  //     storeProvider.addToCart(sparePart);
      
  //     // Navigate to payment screen
  //     Navigator.push(
  //       context, 
  //       MaterialPageRoute(builder: (context) => const CartScreen()),
  //     );
  //   });
  // }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spare Parts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.favorite),
                Consumer<StoreProvider>(
                  builder: (context, provider, _) {
                    return provider.favoriteProducts.isNotEmpty
                        ? Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '${provider.favoriteProducts.length}',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : SizedBox.shrink();
                  },
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                Consumer<StoreProvider>(
                  builder: (context, provider, _) {
                    return provider.cartItems.isNotEmpty
                      ? Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '${provider.cartItems.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : const SizedBox.shrink();
                  },
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search for spare parts',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearFilters,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200.withOpacity(0.7),
              ),
            ),
          ),
          
          // Main content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSpareParts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_filteredSpareParts.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildSparePartsList();
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No spare parts found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing your search terms',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _clearFilters,
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 16,
                          width: 60,
                          color: Colors.grey.shade300,
                        ),
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSparePartsList() {
    return RefreshIndicator(
      onRefresh: _loadSpareParts,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _filteredSpareParts.length,
        itemBuilder: (context, index) {
          final part = _filteredSpareParts[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(
                      productId: part.id, 
                      productType: 'spare_part',
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with favorite button
                  Stack(
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                          image: DecorationImage(
                            image: NetworkImage(part.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Out of stock indicator
                      if (!part.inStock || part.stockCount <= 0)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Out of stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      // Favorite button
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Consumer<StoreProvider>(
                          builder: (ctx, provider, _) {
                            final isFavorite = provider.isFavorite(part.id);
                            return InkWell(
                              onTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  Provider.of<StoreProvider>(context, listen: false).toggleFavoriteById(part.id, context);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            part.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            part.brand,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${part.price.toStringAsFixed(2)} EGP',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (part.hasDiscount && part.discountPercentage > 0)
                                    Row(
                                      children: [
                                        Text(
                                          '${part.oldPrice?.toStringAsFixed(2) ?? part.price.toStringAsFixed(2)} EGP',
                                          style: TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${part.discountPercentage.toStringAsFixed(0)}% OFF',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (part.inStock && part.stockCount > 0) {
                                      Provider.of<StoreProvider>(context, listen: false).addToCart(part);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${part.name} added to cart'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${part.name} is out of stock'),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: part.inStock && part.stockCount > 0
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
