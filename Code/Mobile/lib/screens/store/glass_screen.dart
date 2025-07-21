import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../models/store/glass_product.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'product_details_screen.dart';

class GlassScreen extends StatefulWidget {
  const GlassScreen({super.key});

  @override
  State<GlassScreen> createState() => _GlassScreenState();
}

class _GlassScreenState extends State<GlassScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _searchQuery = '';
  String? _error;
  
  // Variables for the Glass product list
  List<GlassProduct> _allGlasses = [];
  
  @override
  void initState() {
    super.initState();
    _loadGlassData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadGlassData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      await storeProvider.loadGlass();
      
      setState(() {
        _allGlasses = storeProvider.glass;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading glass products: $e';
        _isLoading = false;
      });
    }
  }
  
  List<GlassProduct> _getFilteredGlasses() {
    if (_searchQuery.isEmpty) {
      return List.from(_allGlasses);
    }
    
    return _allGlasses.where((glass) =>
      glass.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      glass.brand.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _filterGlasses();
    });
  }

  void _filterGlasses() {
    setState(() {
      // Just trigger a rebuild with the current state
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search for glass...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _filterGlasses();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No glass products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try changing your search terms',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _filterGlasses();
              });
            },
            icon: Icon(Icons.refresh),
            label: Text('Clear Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Glass',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.favorite_border),
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            ),
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart_outlined),
                Consumer<StoreProvider>(
                  builder: (context, provider, _) {
                    return provider.cartItems.isNotEmpty
                      ? Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '${provider.cartItems.length}',
                            style: TextStyle(
                              color: Colors.white,
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadGlassData,
                              icon: Icon(Icons.refresh),
                              label: Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildGlassList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassList() {
    final filteredGlasses = _getFilteredGlasses();

    if (filteredGlasses.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadGlassData,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        padding: EdgeInsets.all(16),
        itemCount: filteredGlasses.length,
        physics: AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final glass = filteredGlasses[index];
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
                    builder: (context) => 
                      ProductDetailsScreen(productId: glass.id, productType: 'glass'),
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
                            image: NetworkImage(glass.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Out of stock indicator
                      if (!glass.inStock || glass.stockCount <= 0)
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
                            final isFavorite = provider.isFavorite(glass.id);
                            return InkWell(
                              onTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  Provider.of<StoreProvider>(context, listen: false).toggleFavoriteById(glass.id, context);
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
                            glass.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            glass.brand,
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
                                    '${glass.price.toStringAsFixed(2)} EGP',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (glass.hasDiscount && glass.discountPercentage > 0)
                                    Row(
                                      children: [
                                        Text(
                                          '${glass.oldPrice?.toStringAsFixed(2) ?? glass.price.toStringAsFixed(2)} EGP',
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
                                            '${glass.discountPercentage.toStringAsFixed(0)}% OFF',
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
                                    if (glass.inStock && glass.stockCount > 0) {
                                      Provider.of<StoreProvider>(context, listen: false).addToCart(glass);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${glass.name} added to cart'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${glass.name} is out of stock'),
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
                                    color: glass.inStock && glass.stockCount > 0
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