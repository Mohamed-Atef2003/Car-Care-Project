import 'package:flutter/material.dart';
import 'package:car_care/dialogs/product_details_dialog.dart';
import 'package:car_care/models/product.dart' as models;

class ProductCard extends StatefulWidget {
  final models.StoreProduct product;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onDelete,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovering = false;

  void _showProductDetails() {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsDialog(
        product: widget.product,
        onProductUpdated: (updatedProduct) {
          // This callback will be handled by the parent widget
        },
      ),
    );
  }

  // Get image widget with proper error handling
  Widget _getImageWidget() {
    if (widget.product.imageUrl.isEmpty) {
      return Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: Colors.grey[400],
        ),
      );
    }
    
    return Image.network(
      widget.product.imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: Colors.grey[400],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _showProductDetails,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Image
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        // Image Container
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            color: Colors.grey[100],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: _getImageWidget(),
                          ),
                        ),
                        // Category badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 128),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.product.category,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // Stock indicator
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.product.stockCount > 0
                                  ? Colors.green.withValues(red: 0, green: 255, blue: 0, alpha: 179)
                                  : Colors.red.withValues(red: 255, green: 0, blue: 0, alpha: 179),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.product.stockCount > 0
                                  ? 'In Stock: ${widget.product.stockCount}'
                                  : 'Out of Stock',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Product Info
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D2D2D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'EGP ${widget.product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Delete Button (only visible on hover)
              if (_isHovering)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 26),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: widget.onDelete,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: const EdgeInsets.all(6),
                      splashRadius: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
