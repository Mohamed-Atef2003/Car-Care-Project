import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../models/store/tool.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'product_details_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  bool _isLoading = true;
  String? _error;
  List<Tool> _allTools = [];

  @override
  void initState() {
    super.initState();
    _loadToolsData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadToolsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storeProvider = context.read<StoreProvider>();
      await storeProvider.loadTools();
      
      setState(() {
        _allTools = storeProvider.tools;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading tools: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Tool> _getFilteredTools() {
    List<Tool> filteredProducts = List.from(_allTools);

    // Apply search filter only
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by newest
    filteredProducts.sort((a, b) => b.id.compareTo(a.id));

    return filteredProducts;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _filterTools();
    });
  }

  void _filterTools() {
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
          hintText: 'Search for tools...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _filterTools();
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
            'No tools found',
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
                _filterTools();
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
          'Tools',
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
                              onPressed: _loadToolsData,
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
                    : _buildToolsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsList() {
    final filteredTools = _getFilteredTools();

    if (filteredTools.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadToolsData,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        padding: EdgeInsets.all(16),
        itemCount: filteredTools.length,
        physics: AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final tool = filteredTools[index];
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
                      ProductDetailsScreen(productId: tool.id, productType: 'tool'),
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
                            image: NetworkImage(tool.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Out of stock indicator
                      if (!tool.inStock || tool.stockCount <= 0)
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
                            final isFavorite = provider.isFavorite(tool.id);
                            return InkWell(
                              onTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  Provider.of<StoreProvider>(context, listen: false).toggleFavoriteById(tool.id, context);
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
                            tool.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tool.brand,
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
                                    '${tool.price.toStringAsFixed(2)} EGP',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (tool.hasDiscount && tool.discountPercentage > 0)
                                    Row(
                                      children: [
                                        Text(
                                          '${tool.oldPrice?.toStringAsFixed(2) ?? tool.price.toStringAsFixed(2)} EGP',
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
                                            '${tool.discountPercentage.toStringAsFixed(0)}% OFF',
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
                                    if (tool.inStock && tool.stockCount > 0) {
                                      Provider.of<StoreProvider>(context, listen: false).addToCart(tool);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${tool.name} added to cart'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${tool.name} is out of stock'),
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
                                    color: tool.inStock && tool.stockCount > 0
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
