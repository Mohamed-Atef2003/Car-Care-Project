import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'product_details_screen.dart';

/// Base class for all store screens to ensure consistent implementation and avoid setState during build issues
abstract class BaseStoreScreen<T> extends StatefulWidget {
  const BaseStoreScreen({super.key});
}

abstract class BaseStoreScreenState<T, S extends BaseStoreScreen<T>> extends State<S> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isLoading = true;
  String? error;
  List<T> items = [];

  /// The product type string (e.g., 'glass', 'tire', 'tool', 'spare_part')
  String get productType;
  
  /// Title to display in the app bar
  String get screenTitle;
  
  /// Load product data from the store provider
  Future<void> loadData();
  
  /// Filter the products based on search query
  List<T> getFilteredItems();
  
  /// Get product ID for a given item
  String getItemId(T item);
  
  /// Get product name for a given item
  String getItemName(T item);
  
  /// Get product price for a given item
  double getItemPrice(T item);
  
  /// Get product brand for a given item
  String getItemBrand(T item);
  
  /// Get product image URL for a given item
  String getItemImageUrl(T item);

  /// Get product old price for a given item
  double? getItemOldPrice(T item);

  /// Get product discount for a given item
  double? getItemDiscount(T item);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      searchQuery = '';
    });
  }

  void addToCart(BuildContext context, T item) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final itemId = getItemId(item);
      final product = storeProvider.findProductById(itemId);
      
      if (product != null) {
        if (product.inStock && product.stockCount > 0) {
          storeProvider.addToCart(product);
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${getItemName(item)} added to cart'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${getItemName(item)} is out of stock'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  void toggleFavorite(BuildContext context, T item) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoreProvider>(context, listen: false).toggleFavoriteById(getItemId(item), context);
    });
  }

  Widget buildEmptyState() {
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
            'No products found',
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
            onPressed: clearSearch,
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

  Widget buildSearchBar() {
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
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search for products...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget buildErrorWidget() {
    return Center(
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
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loadData,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFavoriteButton(BuildContext context, T item) {
    return Consumer<StoreProvider>(
      builder: (ctx, provider, _) {
        final isFavorite = provider.isFavorite(getItemId(item));
        return InkWell(
          onTap: () => toggleFavorite(context, item),
          child: Container(
            padding: EdgeInsets.all(5),
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
    );
  }

  Widget buildItemCard(BuildContext context, T item) {
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
                productId: getItemId(item), 
                productType: productType
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(getItemImageUrl(item)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 5,
                  right: 5,
                  child: buildFavoriteButton(context, item),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getItemName(item),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    getItemBrand(item),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${getItemPrice(item).toStringAsFixed(2)} EGP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                            ),
                          ),
                          if (getItemOldPrice(item) != null || getItemDiscount(item) != null)
                            Row(
                              children: [
                                Text(
                                  '${getItemOldPrice(item)?.toStringAsFixed(2) ?? getItemPrice(item).toStringAsFixed(2)} EGP',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 4),
                                if (getItemDiscount(item) != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${getItemDiscount(item)}% OFF',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      InkWell(
                        onTap: () => addToCart(context, item),
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
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
          ],
        ),
      ),
    );
  }

  Widget buildGrid(List<T> items) {
    return RefreshIndicator(
      onRefresh: loadData,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        padding: EdgeInsets.all(16),
        itemCount: items.length,
        physics: AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) => buildItemCard(context, items[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = getFilteredItems();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          screenTitle,
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
            icon: Icon(Icons.favorite_border),
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
          buildSearchBar(),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : error != null
                    ? buildErrorWidget()
                    : filteredItems.isEmpty
                        ? buildEmptyState()
                        : buildGrid(filteredItems),
          ),
        ],
      ),
    );
  }
} 