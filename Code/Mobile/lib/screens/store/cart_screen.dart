import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../payment/payment_details_screen.dart';
import '../../providers/store_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/payment_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/placeholder_image_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final cartEntries = storeProvider.cartItems;
    final total = storeProvider.cartTotal;

    // Convert cart items to a more usable format
    final List<Map<String, dynamic>> cartProducts = cartEntries.map((entry) {
      final product = entry.value;
      final quantity = storeProvider.getQuantity(entry.key);
      String type = 'unknown';
      
      if (product.runtimeType.toString().contains('SparePart')) {
        type = 'spare_part';
      } else if (product.runtimeType.toString().contains('Tire')) {
        type = 'tire';
      } else if (product.runtimeType.toString().contains('GlassProduct')) {
        type = 'glass';
      } else if (product.runtimeType.toString().contains('Tool')) {
        type = 'tool';
      }
      
      return {
        'product': product,
        'quantity': quantity,
        'type': type
      };
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart),
            SizedBox(width: 8),
            Text('Shopping Cart'),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          if (cartProducts.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Cart'),
                      ],
                    ),
                    content: Text('Are you sure you want to remove all items from the cart?'),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.delete_outline, size: 18),
                        label: Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          storeProvider.clearCart();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cart is empty',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Add products to your cart to purchase',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: Icon(Icons.shopping_bag_outlined),
                    label: Text('Shop Now'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: cartProducts.length,
                    itemBuilder: (ctx, i) {
                      final item = cartProducts[i];
                      final product = item['product'];
                      final quantity = item['quantity'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: product.imageUrl,
                                  width: 100,
                                  height: 100,
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
                                        ? Container(
                                            color: Colors.grey[200],
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.wifi_off,
                                                  size: 30,
                                                  color: Colors.orange[400],
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: Text(
                                                    'Check Connection',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey[600],
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : PlaceholderImageProvider.getPlaceholderWidget(
                                            product.category == 'إطارات سيارات' ? 'tire' : 
                                            product.category == 'زجاج' ? 'glass' : 
                                            product.category == 'أدوات' ? 'tool' : 'part',
                                            width: 100,
                                            height: 100,
                                          ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Product info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      product.brand,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${product.price.toStringAsFixed(2)} EGP',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                                fontSize: 16,
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
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.shade100,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '${product.discountPercentage.toStringAsFixed(0)}% OFF',
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
                                        const SizedBox(width: 5),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  if (quantity > 1) {
                                                    storeProvider.updateQuantity(
                                                        product.id, quantity - 1);
                                                  } else {
                                                    storeProvider.removeFromCart(product.id);
                                                  }
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.1),
                                                        blurRadius: 2,
                                                        spreadRadius: 0.5,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    Icons.remove,
                                                    size: 16,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                quantity.toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              InkWell(
                                                onTap: () {
                                                  storeProvider.updateQuantity(
                                                      product.id, quantity + 1 <= product.stockCount ? quantity + 1 : quantity);
                                                  
                                                  if (quantity >= product.stockCount) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Sorry, only ${product.stockCount} items available in stock'),
                                                        duration: const Duration(seconds: 2),
                                                        backgroundColor: Colors.orange,
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: quantity < product.stockCount 
                                                      ? Theme.of(context).primaryColor
                                                      : Colors.grey,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Spacer(),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red[400],
                                          ),
                                          onPressed: () {
                                            storeProvider.removeFromCart(product.id);
                                          },
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
                ),
                // Cart total and checkout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        // Summary rows
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Items Count:',
                                style: TextStyle(color: Colors.grey[700])),
                            Text('${cartProducts.length}',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal:',
                                style: TextStyle(color: Colors.grey[700])),
                            Text('${total.toStringAsFixed(2)} EGP',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tax:',
                                style: TextStyle(color: Colors.grey[700])),
                            Text('${(total * 0.15).toStringAsFixed(2)} EGP',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(total * 1.15).toStringAsFixed(2)} EGP',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Create payment summary from cart
                              final subtotal = total;
                              final tax = subtotal * 0.15;
                              final deliveryFee = 30.0; // Default delivery fee
                              
                              // Map cart items to payment items format
                              final items = cartProducts.map((item) {
                                final product = item['product'];
                                final quantity = item['quantity'];
                                return {
                                  'productId': product.id,
                                  'name': product.name,
                                  'price': product.price,
                                  'quantity': quantity,
                                  'category': product.brand,
                                  'imageUrl': product.imageUrl,
                                };
                              }).toList();
                              
                              // Get current user ID if available
                              final userProvider = Provider.of<UserProvider>(context, listen: false);
                              final Map<String, dynamic> additionalData = {};
                              if (userProvider.user != null) {
                                additionalData['customerId'] = userProvider.user!.id;
                                additionalData['customerName'] = '${userProvider.user!.firstName} ${userProvider.user!.lastName}';
                                additionalData['customerEmail'] = userProvider.user!.email;
                                additionalData['customerMobile'] = userProvider.user!.mobile;
                              }
                              
                              // Add items to additional data
                              additionalData['items'] = items;
                              
                              // Create payment summary object
                              final paymentSummary = PaymentSummary(
                                subtotal: subtotal,
                                tax: tax,
                                deliveryFee: deliveryFee,
                                discount: 0, // No discount applied yet
                                total: subtotal + tax + deliveryFee,
                                currency: 'EGP',
                                items: items,
                                additionalData: additionalData,
                              );
                              
                              // Navigate to payment details screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentDetailsScreen(
                                    paymentSummary: paymentSummary,
                                    orderId: 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Checkout',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
    );
  }
} 