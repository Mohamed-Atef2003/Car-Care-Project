import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/user_provider.dart';
import 'product_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      await Provider.of<StoreProvider>(context, listen: false).loadFavorites(context);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading favorites: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final favoriteProducts = storeProvider.favoriteProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : favoriteProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No products in favorites',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Add products to your favorites',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: favoriteProducts.length,
                      itemBuilder: (ctx, i) {
                        final product = favoriteProducts[i];
                        String productType = 'unknown';
                        
                        // Determine product type for navigation
                        if (product.runtimeType.toString().contains('SparePart')) {
                          productType = 'spare_part';
                        } else if (product.runtimeType.toString().contains('Tire')) {
                          productType = 'tire';
                        } else if (product.runtimeType.toString().contains('GlassProduct')) {
                          productType = 'glass';
                        } else if (product.runtimeType.toString().contains('Tool')) {
                          productType = 'tool';
                        }

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(
                                  productId: product.id, 
                                  productType: productType
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image with favorite button
                                Stack(
                                  children: [
                                    Container(
                                      height: 120,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(10),
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(product.imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    // Out of stock indicator
                                    if (!product.inStock || product.stockCount <= 0)
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
                                          final isFavorite = provider.isFavorite(product.id);
                                          return InkWell(
                                            onTap: () {
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                Provider.of<StoreProvider>(context, listen: false).toggleFavoriteById(product.id, context);
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
                                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          product.brand,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${product.price.toStringAsFixed(2)} EGP',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).primaryColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (product.hasDiscount && product.discountPercentage > 0)
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${product.oldPrice?.toStringAsFixed(2) ?? product.price.toStringAsFixed(2)} EGP',
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
                                                          '${product.discountPercentage.toStringAsFixed(0)}% OFF',
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
                                                  if (product.inStock && product.stockCount > 0) {
                                                    Provider.of<StoreProvider>(context, listen: false).addToCart(product);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('${product.name} added to cart'),
                                                        duration: const Duration(seconds: 1),
                                                      ),
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('${product.name} is out of stock'),
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
                                                  color: product.inStock && product.stockCount > 0
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