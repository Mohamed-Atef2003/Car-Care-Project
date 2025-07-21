import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../payment/payment_details_screen.dart';
import '../../providers/store_provider.dart';
import '../../models/store/tire.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'product_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/payment_model.dart';
import '../../utils/network_image_helper.dart';
import '../../utils/placeholder_image_provider.dart';

class TiresScreen extends StatefulWidget {
  const TiresScreen({super.key});

  @override
  State<TiresScreen> createState() => _TiresScreenState();
}

class _TiresScreenState extends State<TiresScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;
  List<Tire> _allTires = [];

  @override
  void initState() {
    super.initState();
    _loadTiresData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTiresData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isOffline = false;
    });

    try {
      // Check for internet connection first
      final hasConnection = await NetworkImageHelper.hasInternetConnection();
      if (!hasConnection) {
        setState(() {
          _isOffline = true;
        });
      }

      final storeProvider = context.read<StoreProvider>();
      await storeProvider.loadTires();

      setState(() {
        _allTires = storeProvider.tires;
        _isLoading = false;

        // If we have tires but are offline, show a message that images might not load
        if (_isOffline && _allTires.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                      child:
                          Text('You are in offline mode. Some images may not appear')),
                ],
              ),
              duration: Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.orange[700],
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        if (e is SocketException) {
          _error = 'Cannot connect to server. Check your internet connection.';
          _isOffline = true;
        } else {
          _error = 'An error occurred while loading tires: ${e.toString()}';
        }
        _isLoading = false;
      });
    }
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
            color: Colors.grey.shade200.withOpacity(0.7),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search for tires...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _filterTires();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            VerticalDivider(
              color: Colors.grey[300],
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Text(
                '${_getFilteredTires().length}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: EdgeInsets.only(top: 8, left: 8, right: 8),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6, // Show 6 skeleton items
        padding: EdgeInsets.only(bottom: 16),
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 140,
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 16,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 20,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 12,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 24,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 24,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 14,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 30,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
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
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    } 
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    final filteredTires = _getFilteredTires();
    
    if (filteredTires.isEmpty) {
      return _buildEmptyState();
    }
    
    return Padding(
      padding: EdgeInsets.only(top: 8, left: 8, right: 8),
      child: RefreshIndicator(
        onRefresh: _loadTiresData,
        color: Theme.of(context).primaryColor,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: filteredTires.length,
          padding: EdgeInsets.only(bottom: 16),
          physics: BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final tire = filteredTires[index];
            // Create staggered animation effect
            return AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()
                  ..translate(0.0, index % 2 == 0 ? 0.0 : 10.0),
                child: _buildProductCard(tire),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tires found',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your search terms',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterTires();
                });
              },
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: TextStyle(fontSize: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isOffline ? Icons.wifi_off : Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An error occurred',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadTiresData,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: TextStyle(fontSize: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Tires',
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
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Tire tire) {
    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(
                    productId: tire.id, productType: 'tire'),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with favorite button overlay
              AspectRatio(
                aspectRatio: 1.2,
                child: Stack(
                  children: [
                    Hero(
                      tag: 'tire_${tire.id}',
                      child: SizedBox(
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: tire.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor.withOpacity(0.5),
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              error is SocketException
                                  ? NetworkImageHelper.buildErrorWidget(
                                      context, error)
                                  : PlaceholderImageProvider.getPlaceholderWidget(
                                      'tire'),
                          cacheKey: 'tire_${tire.id}_image',
                          memCacheWidth:
                              (MediaQuery.of(context).size.width * 0.5).toInt(),
                        ),
                      ),
                    ),
                    // Quick add to cart button
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (tire.inStock && tire.stockCount > 0) {
                              Provider.of<StoreProvider>(context, listen: false)
                                  .addToCart(tire);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${tire.name} added to cart'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${tire.name} is out of stock'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tire.inStock && tire.stockCount > 0
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.3),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_shopping_cart,
                              color: tire.inStock && tire.stockCount > 0
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.4),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Discount badge if applicable
                    if (tire.discountPercentage > 0)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${tire.discountPercentage.toInt()}% discount',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    // Stock status badge
                    if (!tire.inStock || tire.stockCount <= 0)
                      Positioned(
                        top: tire.discountPercentage > 0 ? 40 : 10,
                        left: 10,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
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
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final provider = Provider.of<StoreProvider>(context,
                                listen: false);
                            provider.toggleFavoriteById(tire.id, context);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.isFavorite(tire.id)
                                      ? '${tire.name} removed from favorites'
                                      : '${tire.name} added to favorites',
                                ),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Consumer<StoreProvider>(
                                builder: (context, provider, _) {
                              final isFavorite = provider.isFavorite(tire.id);
                              return AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                transitionBuilder:
                                    (Widget child, Animation<double> animation) {
                                  return ScaleTransition(
                                      scale: animation, child: child);
                                },
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  key: ValueKey<bool>(isFavorite),
                                  color: isFavorite ? Colors.red : Colors.grey,
                                  size: 18,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Product details section
              Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title and rating
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tire.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 10,
                                ),
                                Text(
                                  '${tire.rating}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        tire.brand,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Specifications chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(child: _buildSpecChip(tire.size, Icons.straighten)),
                          SizedBox(width: 4),
                          Flexible(child: _buildSpecChip(tire.season, Icons.circle_outlined)),
                        ],
                      ),
                      // Expanded space to push price row to bottom
                      Spacer(),
                      // Price row
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (tire.discountPercentage > 0)
                                Text(
                                  '${tire.price.toStringAsFixed(2)} EGP',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 8,
                                  ),
                                ),
                              Text(
                                '${(tire.price * (1 - tire.discountPercentage / 100)).toStringAsFixed(2)} EGP',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  fontSize: tire.discountPercentage > 0 ? 12 : 10,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          // Buy now button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: tire.inStock && tire.stockCount > 0 ? () {
                                final price = tire.price *
                                    (1 - tire.discountPercentage / 100);
                                final subtotal = price;
                                final tax = subtotal * 0.15;
                                final deliveryFee = 30.0;

                                final items = [
                                  {
                                    'productId': tire.id,
                                    'name': tire.name,
                                    'price': price,
                                    'quantity': 1,
                                    'category': tire.brand,
                                    'imageUrl': tire.imageUrl,
                                  }
                                ];

                                final paymentSummary = PaymentSummary(
                                  subtotal: subtotal,
                                  tax: tax,
                                  deliveryFee: deliveryFee,
                                  discount: 0,
                                  total: subtotal + tax + deliveryFee,
                                  currency: 'EGP',
                                  items: items,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentDetailsScreen(
                                      paymentSummary: paymentSummary,
                                      orderId:
                                          'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}',
                                    ),
                                  ),
                                );
                              } : () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${tire.name} is out of stock'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: tire.inStock && tire.stockCount > 0 
                                      ? Colors.green[700]
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tire.inStock && tire.stockCount > 0 
                                          ? Icons.flash_on
                                          : Icons.not_interested,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    Text(
                                      tire.inStock && tire.stockCount > 0
                                          ? 'Buy'
                                          : 'Out',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
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
      ),
    );
  }

  Widget _buildSpecChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[700]),
          SizedBox(width: 2),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<Tire> _getFilteredTires() {
    List<Tire> filteredProducts = List.from(_allTires);

    // Apply search filter only
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            product.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.size.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by newest by default
    filteredProducts.sort((a, b) => b.id.compareTo(a.id));

    return filteredProducts;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _filterTires();
    });
  }

  void _filterTires() {
    setState(() {
      // Just trigger a rebuild with the current state
    });
  }
}
