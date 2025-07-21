import 'package:flutter/material.dart';
import 'package:car_care/models/product.dart' as models;
import 'package:car_care/dialogs/edit_product_dialog.dart';

class ProductDetailsDialog extends StatelessWidget {
  final models.StoreProduct product;
  final Function(models.StoreProduct) onProductUpdated;

  const ProductDetailsDialog({
    super.key,
    required this.product,
    required this.onProductUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl,
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 300,
                              height: 300,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Basic Information
                    _buildSection(
                      title: 'Basic Information',
                      children: [
                        _buildDetailRow('Name', product.name),
                        _buildDetailRow('Price', 'EGP ${product.price.toStringAsFixed(2)}'),
                        if (product.oldPrice != null && product.oldPrice! > 0) 
                          _buildDetailRow('Old Price', 'EGP ${product.oldPrice!.toStringAsFixed(2)}'),
                        if (product.hasDiscount)
                          _buildDetailRow('Discount', '${product.discountPercentage.toStringAsFixed(1)}%'),
                        _buildDetailRow('Category', product.category.replaceAll('_', ' ').toUpperCase()),
                        _buildDetailRow('Brand', product.brand),
                        _buildDetailRow('Stock', product.stockCount.toString()),
                        _buildDetailRow('In Stock', product.inStock ? 'Yes' : 'No'),
                        _buildDetailRow('Warranty', product.warranty),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Category Specific Information
                    if (product is models.SparePart) ...[
                      _buildSection(
                        title: 'Spare Part Details',
                        children: [
                          _buildDetailRow('Part Number', (product as models.SparePart).partNumber),
                          _buildDetailRow('Origin', (product as models.SparePart).origin),
                          if ((product as models.SparePart).compatibility.isNotEmpty)
                            _buildDetailRow('Compatibility', (product as models.SparePart).compatibility.join(', ')),
                        ],
                      ),
                    ] else if (product is models.Tire) ...[
                      _buildSection(
                        title: 'Tire Details',
                        children: [
                          _buildDetailRow('Size', (product as models.Tire).size),
                          _buildDetailRow('Speed Rating', (product as models.Tire).speedRating),
                          _buildDetailRow('Load Index', (product as models.Tire).loadIndex),
                          _buildDetailRow('Season', (product as models.Tire).season),
                          _buildDetailRow('Tread Pattern', (product as models.Tire).treadPattern),
                          _buildDetailRow('Warranty Miles', (product as models.Tire).warrantyMiles.toString()),
                          _buildDetailRow('Tread Depth', '${(product as models.Tire).treadDepth.toString()} mm'),
                          _buildDetailRow('Wet Grip', (product as models.Tire).wetGrip.toString()),
                          _buildDetailRow('Fuel Efficiency', (product as models.Tire).fuelEfficiency.toString()),
                          _buildDetailRow('Noise Level', '${(product as models.Tire).noiseLevel.toString()} dB'),
                          _buildDetailRow('Run Flat', (product as models.Tire).runFlat ? 'Yes' : 'No'),
                          _buildDetailRow('Manufacturing Country', (product as models.Tire).manufacturingCountry),
                          _buildDetailRow('Manufacture Date', (product as models.Tire).manufactureDate.toString().split(' ')[0]),
                        ],
                      ),
                    ] else if (product is models.GlassProduct) ...[
                      _buildSection(
                        title: 'Glass Details',
                        children: [
                          _buildDetailRow('Glass Type', (product as models.GlassProduct).glassType),
                          if ((product as models.GlassProduct).compatibility.isNotEmpty)
                            _buildDetailRow('Compatibility', (product as models.GlassProduct).compatibility.join(', ')),
                          _buildDetailRow('Has Tinting', (product as models.GlassProduct).hasTinting ? 'Yes' : 'No'),
                          _buildDetailRow('UV Protection Level', (product as models.GlassProduct).uvProtectionLevel.toString()),
                          _buildDetailRow('Has Heating Elements', (product as models.GlassProduct).hasHeatingElements ? 'Yes' : 'No'),
                          _buildDetailRow('Is Original Part', (product as models.GlassProduct).isOriginal ? 'Yes' : 'No'),
                        ],
                      ),
                    ] else if (product is models.Tool) ...[
                      _buildSection(
                        title: 'Tool Details',
                        children: [
                          _buildDetailRow('Tool Type', (product as models.Tool).toolType),
                          _buildDetailRow('Material', (product as models.Tool).material),
                          _buildDetailRow('Power Source', (product as models.Tool).powerSource),
                          _buildDetailRow('Weight', '${(product as models.Tool).weight.toString()} kg'),
                          _buildDetailRow('Dimensions', (product as models.Tool).dimensions),
                          _buildDetailRow('Piece Count', (product as models.Tool).pieceCount.toString()),
                          _buildDetailRow('Includes Case', (product as models.Tool).includesCase ? 'Yes' : 'No'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Description
                    _buildSection(
                      title: 'Description',
                      children: [
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Features
                    if (product.features.isNotEmpty) ...[
                      _buildSection(
                        title: 'Features',
                        children: [
                          ...product.features.map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (context) => EditProductDialog(
                                product: product,
                                onProductUpdated: onProductUpdated,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Edit'),
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
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
