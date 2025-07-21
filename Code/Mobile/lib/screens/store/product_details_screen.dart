import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../models/store/store_product.dart';
import '../../models/store/tire.dart';
import '../../models/store/tool.dart';
import '../../models/store/spare_part.dart';
import '../../models/store/glass_product.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final String productType;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.productType,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final product = storeProvider.findProductById(widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
        ),
        body: const Center(
          child: Text('Product not found'),
        ),
      );
    }

    final bool isFavorite = storeProvider.isFavorite(product.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<StoreProvider>(context, listen: false).toggleFavoriteById(product.id, context);
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: product.images.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    product.images[index],
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            
            // Image indicators
            if (product.images.length > 1)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    product.images.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedImageIndex == index ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Product info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and price
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${product.price.toStringAsFixed(2)} EGP',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.oldPrice != null)
                            Text(
                              '${product.oldPrice!.toStringAsFixed(2)} EGP',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      if (product.hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${product.discountPercentage.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Brand and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Brand: ${product.brand}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          Text(
                            ' ${product.rating.toStringAsFixed(1)} (${product.ratingCount})',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stock status
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: product.inStock && product.stockCount > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.inStock && product.stockCount > 0
                            ? 'In stock (${product.stockCount})'
                            : 'Out of stock',
                        style: TextStyle(
                          color: product.inStock && product.stockCount > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  // Product quantity selector
                  if (product.inStock)
                    Row(
                      children: [
                        const Text(
                          'Quantity:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _decrementQuantity,
                              ),
                              Text(
                                _quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _incrementQuantity,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                  const SizedBox(height: 24),
                  // Add to cart button
                  if (product.inStock)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: product.stockCount > 0 ? () {
                          storeProvider.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product added to cart'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: Text(
                          product.stockCount > 0 ? 'Add to cart' : 'Out of stock',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  // Specifications
                  const Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...product.specifications.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              '${entry.key}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(entry.value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  // Features
                  if (product.features.isNotEmpty) ...[
                    const Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...product.features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Type-specific additional information
                  const SizedBox(height: 24),
                  _buildTypeSpecificInfo(product, widget.productType),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificInfo(StoreProduct product, String type) {
    switch (type) {
      case 'spare_part':
        final sparePart = product as SparePart;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Part Number', sparePart.partNumber),
            _buildInfoRow('Manufacturing Country', sparePart.manufacturingCountry),
            _buildInfoRow('Warranty', sparePart.warranty),
          ],
        );
        
      case 'tire':
        final tire = product as Tire;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Size', tire.size),
            _buildInfoRow('Season', tire.season),
            _buildInfoRow('Speed Rating', tire.speedRating),
            _buildInfoRow('Load Index', tire.loadIndex),
            _buildInfoRow('Tread Pattern', tire.treadPattern),
            _buildInfoRow('Wet Grip', '${(tire.wetGrip * 100).toInt()}%'),
            _buildInfoRow('Fuel Efficiency', '${(tire.fuelEfficiency * 100).toInt()}%'),
            _buildInfoRow('Noise Level', '${tire.noiseLevel} dB'),
            _buildInfoRow('Run Flat', tire.runFlat ? 'Yes' : 'No'),
          ],
        );
        
      case 'glass':
        final glass = product as GlassProduct;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Glass Type', glass.glassType),
            _buildInfoRow('Tinted', glass.tinted ? 'Yes' : 'No'),
            _buildInfoRow('UV Protection', glass.hasUVProtection ? 'Yes' : 'No'),
            _buildInfoRow('Heated', glass.isHeated ? 'Yes' : 'No'),
            _buildInfoRow('Manufacturing Country', glass.manufacturingCountry),
          ],
        );
        
      case 'tool':
        final tool = product as Tool;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Tool Type', tool.toolType),
            _buildInfoRow('Power Source', tool.powerSource),
            _buildInfoRow('Material', tool.material),
            _buildInfoRow('Weight', '${tool.weight} kg'),
            _buildInfoRow('Dimensions', tool.dimensions),
            _buildInfoRow('Piece Count', '${tool.pieceCount}'),
            _buildInfoRow('Includes Case', tool.includesCase ? 'Yes' : 'No'),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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
      ),
    );
  }
} 