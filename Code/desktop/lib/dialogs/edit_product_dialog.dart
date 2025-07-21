import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:car_care/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductDialog extends StatefulWidget {
  final StoreProduct product;
  final Function(StoreProduct) onProductUpdated;

  const EditProductDialog({
    super.key,
    required this.product,
    required this.onProductUpdated,
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;
  late final TextEditingController _brandController;
  late final TextEditingController _warrantyController;
  late String? _selectedCategory;
  String? _imageUrl;
  String? _customImageUrl;
  bool _isHoveringUpdate = false;
  bool _isHoveringCancel = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Animation controller
  late AnimationController _controller;

  // Product type specific controllers
  late TextEditingController _partNumberController;
  late TextEditingController _originController;
  late TextEditingController _sizeController;
  late TextEditingController _speedRatingController;
  late TextEditingController _loadIndexController;
  late TextEditingController _seasonController;
  late TextEditingController _treadPatternController;
  late TextEditingController _warrantyMilesController;
  late TextEditingController _treadDepthController;
  late TextEditingController _wetGripController;
  late TextEditingController _fuelEfficiencyController;
  late TextEditingController _noiseLevelController;
  late TextEditingController _manufacturingCountryController;
  late TextEditingController _glassTypeController;
  late TextEditingController _toolTypeController;
  late TextEditingController _powerSourceController;
  late TextEditingController _materialController;
  late TextEditingController _weightController;
  late TextEditingController _dimensionsController;
  late TextEditingController _pieceCountController;

  // Optional feature controllers
  late TextEditingController _oldPriceController;
  late ValueNotifier<bool> _hasDiscountController;
  late TextEditingController _discountPercentageController;
  late TextEditingController _uvProtectionController;
  late ValueNotifier<bool> _hasTintingController;
  late ValueNotifier<bool> _hasHeatingElementsController;
  late ValueNotifier<bool> _isOriginalController;
  late ValueNotifier<bool> _runFlatController;
  late ValueNotifier<bool> _includesCaseController;

  final List<String> _productCategories = [
    'spare_parts',
    'tires',
    'glass',
    'tools',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Initialize controllers with existing product data
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _descriptionController = TextEditingController(text: widget.product.description);
    _stockController = TextEditingController(text: widget.product.stockCount.toString());
    _brandController = TextEditingController(text: widget.product.brand);
    _warrantyController = TextEditingController(text: widget.product.warranty);
    _selectedCategory = widget.product.category;
    
    // Initialize optional feature controllers
    _oldPriceController = TextEditingController(text: widget.product.oldPrice?.toString() ?? '');
    _hasDiscountController = ValueNotifier<bool>(widget.product.hasDiscount);
    _discountPercentageController = TextEditingController(
      text: widget.product.hasDiscount ? widget.product.discountPercentage.toString() : '0.0'
    );
    
    // Initialize common product type specific controllers with default values
    _partNumberController = TextEditingController(text: '');
    _originController = TextEditingController(text: '');
    _sizeController = TextEditingController(text: '');
    _speedRatingController = TextEditingController(text: '');
    _loadIndexController = TextEditingController(text: '');
    _seasonController = TextEditingController(text: '');
    _treadPatternController = TextEditingController(text: '');
    _warrantyMilesController = TextEditingController(text: '0');
    _treadDepthController = TextEditingController(text: '0.0');
    _wetGripController = TextEditingController(text: '0.0');
    _fuelEfficiencyController = TextEditingController(text: '0.0');
    _noiseLevelController = TextEditingController(text: '0.0');
    _manufacturingCountryController = TextEditingController(text: '');
    _glassTypeController = TextEditingController(text: '');
    _toolTypeController = TextEditingController(text: '');
    _powerSourceController = TextEditingController(text: '');
    _materialController = TextEditingController(text: '');
    _weightController = TextEditingController(text: '0.0');
    _dimensionsController = TextEditingController(text: '');
    _pieceCountController = TextEditingController(text: '1');
    
    // Initialize feature-specific controllers based on product type
    _uvProtectionController = TextEditingController(text: '0.0');
    _hasTintingController = ValueNotifier<bool>(false);
    _hasHeatingElementsController = ValueNotifier<bool>(false);
    _isOriginalController = ValueNotifier<bool>(true);
    _runFlatController = ValueNotifier<bool>(false);
    _includesCaseController = ValueNotifier<bool>(false);

    // Set product type specific values based on actual product type
    if (widget.product is SparePart) {
      final sparePart = widget.product as SparePart;
      _partNumberController.text = sparePart.partNumber;
      _originController.text = sparePart.origin;
    } else if (widget.product is Tire) {
      final tire = widget.product as Tire;
      _sizeController.text = tire.size;
      _speedRatingController.text = tire.speedRating;
      _loadIndexController.text = tire.loadIndex;
      _seasonController.text = tire.season;
      _treadPatternController.text = tire.treadPattern;
      _warrantyMilesController.text = tire.warrantyMiles.toString();
      _treadDepthController.text = tire.treadDepth.toString();
      _wetGripController.text = tire.wetGrip.toString();
      _fuelEfficiencyController.text = tire.fuelEfficiency.toString();
      _noiseLevelController.text = tire.noiseLevel.toString();
      _manufacturingCountryController.text = tire.manufacturingCountry;
      _runFlatController.value = tire.runFlat;
    } else if (widget.product is GlassProduct) {
      final glass = widget.product as GlassProduct;
      _glassTypeController.text = glass.glassType;
      _hasTintingController.value = glass.hasTinting;
      _uvProtectionController.text = glass.uvProtectionLevel.toString();
      _hasHeatingElementsController.value = glass.hasHeatingElements;
      _isOriginalController.value = glass.isOriginal;
    } else if (widget.product is Tool) {
      final tool = widget.product as Tool;
      _toolTypeController.text = tool.toolType;
      _powerSourceController.text = tool.powerSource;
      _materialController.text = tool.material;
      _weightController.text = tool.weight.toString();
      _dimensionsController.text = tool.dimensions;
      _pieceCountController.text = tool.pieceCount.toString();
      _includesCaseController.value = tool.includesCase;
    }

    _imageUrl = widget.product.imageUrl;
    
    debugPrint('Product data loaded: ${widget.product.name}');
    debugPrint('Product type: ${widget.product.category}');
    debugPrint('Price: ${widget.product.price}');
    debugPrint('Stock: ${widget.product.stockCount}');
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _warrantyController.dispose();
    _partNumberController.dispose();
    _originController.dispose();
    _sizeController.dispose();
    _speedRatingController.dispose();
    _loadIndexController.dispose();
    _seasonController.dispose();
    _treadPatternController.dispose();
    _warrantyMilesController.dispose();
    _treadDepthController.dispose();
    _wetGripController.dispose();
    _fuelEfficiencyController.dispose();
    _noiseLevelController.dispose();
    _manufacturingCountryController.dispose();
    _glassTypeController.dispose();
    _toolTypeController.dispose();
    _powerSourceController.dispose();
    _materialController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _pieceCountController.dispose();
    _oldPriceController.dispose();
    _discountPercentageController.dispose();
    _uvProtectionController.dispose();
    _hasDiscountController.dispose();
    _hasTintingController.dispose();
    _hasHeatingElementsController.dispose();
    _isOriginalController.dispose();
    _runFlatController.dispose();
    _includesCaseController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Prevent multiple clicks
      if (_isSubmitting) return;
      
      setState(() {
        _isLoading = true;
        _isSubmitting = true;
      });

      try {
        // Validate data
        final double price = double.tryParse(_priceController.text) ?? 0.0;
        final double? oldPrice = _oldPriceController.text.isNotEmpty 
            ? double.tryParse(_oldPriceController.text) 
            : null;
        final int stock = int.tryParse(_stockController.text) ?? 0;
        final bool hasDiscount = _hasDiscountController.value;
        final double discountPercentage = hasDiscount 
            ? (double.tryParse(_discountPercentageController.text) ?? 0.0)
            : 0.0;
        
        debugPrint('Submitting form to update product');
        debugPrint('Selected category: $_selectedCategory');
        
        // Create updated product based on type
        StoreProduct updatedProduct;
        switch (_selectedCategory) {
          case 'spare_parts':
            updatedProduct = SparePart(
              id: widget.product.id,
              name: _nameController.text.trim(),
              category: 'spare_parts',
              brand: _brandController.text.trim(),
              price: price,
              oldPrice: oldPrice,
              imageUrl: _imageUrl ?? widget.product.imageUrl,
              images: widget.product.images,
              description: _descriptionController.text.trim(),
              specifications: widget.product.specifications,
              features: widget.product.features,
              warranty: _warrantyController.text.trim(),
              compatibility: (widget.product is SparePart) ? (widget.product as SparePart).compatibility : [],
              partNumber: _partNumberController.text.trim(),
              origin: _originController.text.trim(),
              stockCount: stock,
              inStock: stock > 0,
              hasDiscount: hasDiscount,
              discountPercentage: discountPercentage,
              rating: widget.product.rating,
              ratingCount: widget.product.ratingCount,
              reviews: widget.product.reviews,
            );
            break;

          case 'tires':
            updatedProduct = Tire(
              id: widget.product.id,
              name: _nameController.text.trim(),
              category: 'tires',
              brand: _brandController.text.trim(),
              price: price,
              oldPrice: oldPrice,
              imageUrl: _imageUrl ?? widget.product.imageUrl,
              images: widget.product.images,
              description: _descriptionController.text.trim(),
              specifications: widget.product.specifications,
              features: widget.product.features,
              warranty: _warrantyController.text.trim(),
              size: _sizeController.text.trim(),
              speedRating: _speedRatingController.text.trim(),
              loadIndex: _loadIndexController.text.trim(),
              season: _seasonController.text.trim(),
              treadPattern: _treadPatternController.text.trim(),
              warrantyMiles: int.tryParse(_warrantyMilesController.text) ?? 0,
              treadDepth: double.tryParse(_treadDepthController.text) ?? 0.0,
              wetGrip: double.tryParse(_wetGripController.text) ?? 0.0,
              fuelEfficiency: double.tryParse(_fuelEfficiencyController.text) ?? 0.0,
              noiseLevel: double.tryParse(_noiseLevelController.text) ?? 0.0,
              runFlat: _runFlatController.value,
              manufacturingCountry: _manufacturingCountryController.text.trim(),
              manufactureDate: (widget.product is Tire) ? (widget.product as Tire).manufactureDate : DateTime.now(),
              stockCount: stock,
              inStock: stock > 0,
              hasDiscount: hasDiscount,
              discountPercentage: discountPercentage,
              rating: widget.product.rating,
              ratingCount: widget.product.ratingCount,
              reviews: widget.product.reviews,
            );
            break;

          case 'glass':
            updatedProduct = GlassProduct(
              id: widget.product.id,
              name: _nameController.text.trim(),
              category: 'glass',
              brand: _brandController.text.trim(),
              price: price,
              oldPrice: oldPrice,
              imageUrl: _imageUrl ?? widget.product.imageUrl,
              images: widget.product.images,
              description: _descriptionController.text.trim(),
              specifications: widget.product.specifications,
              features: widget.product.features,
              warranty: _warrantyController.text.trim(),
              compatibility: (widget.product is GlassProduct) ? (widget.product as GlassProduct).compatibility : [],
              glassType: _glassTypeController.text.trim(),
              hasTinting: _hasTintingController.value,
              uvProtectionLevel: double.tryParse(_uvProtectionController.text) ?? 0.0,
              hasHeatingElements: _hasHeatingElementsController.value,
              isOriginal: _isOriginalController.value,
              stockCount: stock,
              inStock: stock > 0,
              hasDiscount: hasDiscount,
              discountPercentage: discountPercentage,
              rating: widget.product.rating,
              ratingCount: widget.product.ratingCount,
              reviews: widget.product.reviews,
            );
            break;

          case 'tools':
            updatedProduct = Tool(
              id: widget.product.id,
              name: _nameController.text.trim(),
              category: 'tools',
              brand: _brandController.text.trim(),
              price: price,
              oldPrice: oldPrice,
              imageUrl: _imageUrl ?? widget.product.imageUrl,
              images: widget.product.images,
              description: _descriptionController.text.trim(),
              specifications: widget.product.specifications,
              features: widget.product.features,
              warranty: _warrantyController.text.trim(),
              toolType: _toolTypeController.text.trim(),
              powerSource: _powerSourceController.text.trim(),
              material: _materialController.text.trim(),
              weight: double.tryParse(_weightController.text) ?? 0.0,
              dimensions: _dimensionsController.text.trim(),
              pieceCount: int.tryParse(_pieceCountController.text) ?? 1,
              includesCase: _includesCaseController.value,
              stockCount: stock,
              inStock: stock > 0,
              hasDiscount: hasDiscount,
              discountPercentage: discountPercentage,
              rating: widget.product.rating,
              ratingCount: widget.product.ratingCount,
              reviews: widget.product.reviews,
            );
            break;

          default:
            updatedProduct = widget.product;
        }

        // Debug information
        debugPrint('Updating product in Firestore with ID: ${updatedProduct.id}');
        try {
          // Update product in Firestore
          await FirebaseFirestore.instance.collection('products').doc(updatedProduct.id).update(updatedProduct.toMap());
          
          debugPrint('Product updated successfully in Firestore');
          
          // Call update function to update UI
          widget.onProductUpdated(updatedProduct);
          
          // Close the dialog safely
          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (firestoreError) {
          debugPrint('Firestore update error: $firestoreError');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating product: ${firestoreError.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error during product update: $e');
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating product: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _isLoading = false;
          });
        }
      }
    }
  }

  void _selectImage() {
    // Show a simplified dialog with predefined image options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختيار صورة'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom URL input field
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'أدخل رابط الصورة:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'https://example.com/image.jpg',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                helperText: 'يجب أن تبدأ الروابط بـ http:// أو https://',
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _customImageUrl = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              if (_customImageUrl != null && _customImageUrl!.isNotEmpty) {
                                if (_customImageUrl!.startsWith('http://') || _customImageUrl!.startsWith('https://')) {
                                  // Preview image
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('معاينة الصورة'),
                                      content: SizedBox(
                                        width: 300,
                                        height: 300,
                                        child: Image.network(
                                          _customImageUrl!,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded / 
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'لا يمكن تحميل الصورة من الرابط المحدد',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('إغلاق'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _imageUrl = _customImageUrl;
                                            });
                                            Navigator.of(context).pop(); // Close preview dialog
                                            Navigator.of(context).pop(); // Close image selection dialog
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                          ),
                                          child: const Text('استخدام هذه الصورة'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('خطأ في الرابط'),
                                      content: const Text('يجب أن يبدأ رابط الصورة بـ http:// أو https://'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('حسنًا'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.preview),
                            tooltip: 'معاينة الصورة',
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_customImageUrl != null && _customImageUrl!.isNotEmpty) {
                                if (_customImageUrl!.startsWith('http://') || _customImageUrl!.startsWith('https://')) {
                                  setState(() {
                                    _imageUrl = _customImageUrl;
                                  });
                                  Navigator.of(context).pop();
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('خطأ في الرابط'),
                                      content: const Text('يجب أن يبدأ رابط الصورة بـ http:// أو https://'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('حسنًا'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('استخدام'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }



  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildCategorySpecificFields() {
    switch (_selectedCategory) {
      case 'spare_parts':
        return Column(
          children: [
            _buildLabel('Part Number'),
            TextFormField(
              controller: _partNumberController,
              decoration: _buildInputDecoration('Enter Part Number'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter part number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Origin'),
            TextFormField(
              controller: _originController,
              decoration: _buildInputDecoration('Enter Country of Origin'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter country of origin';
                }
                return null;
              },
            ),
          ],
        );

      case 'tires':
        return Column(
          children: [
            _buildLabel('Size'),
            TextFormField(
              controller: _sizeController,
              decoration: _buildInputDecoration('Enter Tire Size'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter tire size';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Speed Rating'),
            TextFormField(
              controller: _speedRatingController,
              decoration: _buildInputDecoration('Enter Speed Rating'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter speed rating';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Load Index'),
            TextFormField(
              controller: _loadIndexController,
              decoration: _buildInputDecoration('Enter Load Index'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter load index';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Season'),
            DropdownButtonFormField<String>(
              value: _seasonController.text.isEmpty ? null : _seasonController.text,
              decoration: _buildInputDecoration('Select Season'),
              items: [
                DropdownMenuItem(value: Tire.SEASON_SUMMER, child: Text(Tire.SEASON_SUMMER)),
                DropdownMenuItem(value: Tire.SEASON_WINTER, child: Text(Tire.SEASON_WINTER)),
                DropdownMenuItem(value: Tire.SEASON_ALL_SEASON, child: Text(Tire.SEASON_ALL_SEASON)),
              ],
              onChanged: (value) {
                setState(() {
                  _seasonController.text = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select season';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Tread Pattern'),
            DropdownButtonFormField<String>(
              value: _treadPatternController.text.isEmpty ? null : _treadPatternController.text,
              decoration: _buildInputDecoration('Select Tread Pattern'),
              items: [
                DropdownMenuItem(value: Tire.PATTERN_ASYMMETRIC, child: Text(Tire.PATTERN_ASYMMETRIC)),
                DropdownMenuItem(value: Tire.PATTERN_DIRECTIONAL, child: Text(Tire.PATTERN_DIRECTIONAL)),
                DropdownMenuItem(value: Tire.PATTERN_SYMMETRIC, child: Text(Tire.PATTERN_SYMMETRIC)),
              ],
              onChanged: (value) {
                setState(() {
                  _treadPatternController.text = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select tread pattern';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Warranty Miles'),
            TextFormField(
              controller: _warrantyMilesController,
              decoration: _buildInputDecoration('Enter Warranty Miles'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel('Tread Depth (mm)'),
            TextFormField(
              controller: _treadDepthController,
              decoration: _buildInputDecoration('Enter Tread Depth'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            _buildLabel('Wet Grip (0-1)'),
            TextFormField(
              controller: _wetGripController,
              decoration: _buildInputDecoration('Enter Wet Grip Rating'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            _buildLabel('Fuel Efficiency (0-1)'),
            TextFormField(
              controller: _fuelEfficiencyController,
              decoration: _buildInputDecoration('Enter Fuel Efficiency Rating'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            _buildLabel('Noise Level (dB)'),
            TextFormField(
              controller: _noiseLevelController,
              decoration: _buildInputDecoration('Enter Noise Level'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            _buildLabel('Run Flat'),
            SwitchListTile(
              title: const Text('Run Flat Tire'),
              value: _runFlatController.value,
              onChanged: (value) {
                setState(() {
                  _runFlatController.value = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            _buildLabel('Manufacturing Country'),
            TextFormField(
              controller: _manufacturingCountryController,
              decoration: _buildInputDecoration('Enter Manufacturing Country'),
            ),
            const SizedBox(height: 30),
          ],
        );

      case 'glass':
        return Column(
          children: [
            _buildLabel('Glass Type'),
            TextFormField(
              controller: _glassTypeController,
              decoration: _buildInputDecoration('Enter Glass Type'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter glass type';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Has Tinting'),
            SwitchListTile(
              title: const Text('Glass Has Tinting'),
              value: _hasTintingController.value,
              onChanged: (value) {
                setState(() {
                  _hasTintingController.value = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            _buildLabel('UV Protection Level (0-1)'),
            TextFormField(
              controller: _uvProtectionController,
              decoration: _buildInputDecoration('Enter UV Protection Level'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            _buildLabel('Has Heating Elements'),
            SwitchListTile(
              title: const Text('Glass Has Heating Elements'),
              value: _hasHeatingElementsController.value,
              onChanged: (value) {
                setState(() {
                  _hasHeatingElementsController.value = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            _buildLabel('Is Original Part'),
            SwitchListTile(
              title: const Text('Original Manufacturer Part'),
              value: _isOriginalController.value,
              onChanged: (value) {
                setState(() {
                  _isOriginalController.value = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
          ],
        );

      case 'tools':
        return Column(
          children: [
            _buildLabel('Tool Type'),
            TextFormField(
              controller: _toolTypeController,
              decoration: _buildInputDecoration('Enter Tool Type'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter tool type';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Power Source'),
            TextFormField(
              controller: _powerSourceController,
              decoration: _buildInputDecoration('Enter Power Source'),
            ),
            const SizedBox(height: 20),
            _buildLabel('Material'),
            TextFormField(
              controller: _materialController,
              decoration: _buildInputDecoration('Enter Material'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter material';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Weight (kg)'),
            TextFormField(
              controller: _weightController,
              decoration: _buildInputDecoration('Enter Weight'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            _buildLabel('Dimensions'),
            TextFormField(
              controller: _dimensionsController,
              decoration: _buildInputDecoration('Enter Dimensions'),
            ),
            const SizedBox(height: 20),
            _buildLabel('Piece Count'),
            TextFormField(
              controller: _pieceCountController,
              decoration: _buildInputDecoration('Enter Piece Count'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel('Includes Case'),
            SwitchListTile(
              title: const Text('Includes Storage Case'),
              value: _includesCaseController.value,
              onChanged: (value) {
                setState(() {
                  _includesCaseController.value = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 30),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // منع الخروج المفاجئ أثناء التحميل
      canPop: !_isLoading,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 450,
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
                      'Edit Product',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Product Name'),
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration('Enter Product Name'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Product Category'),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: _buildInputDecoration('Select category'),
                          items: _productCategories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category.replaceAll('_', ' ').toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select product category';
                            }
                            return null;
                          },
                          icon: const Icon(Icons.keyboard_arrow_down),
                          isExpanded: true,
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Brand'),
                        TextFormField(
                          controller: _brandController,
                          decoration: _buildInputDecoration('Enter Brand Name'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter brand name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Description'),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _buildInputDecoration('Enter a Short Description'),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter product description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Price'),
                        TextFormField(
                          controller: _priceController,
                          decoration: _buildInputDecoration('Enter Price')
                              .copyWith(prefixText: 'EGP '),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel('Old Price (optional)'),
                        TextFormField(
                          controller: _oldPriceController,
                          decoration: _buildInputDecoration('Enter Old Price for Discount')
                              .copyWith(prefixText: 'EGP '),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel('Apply Discount'),
                        SwitchListTile(
                          title: const Text('This Product Has a Discount'),
                          value: _hasDiscountController.value,
                          onChanged: (value) {
                            setState(() {
                              _hasDiscountController.value = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        if (_hasDiscountController.value) ...[
                          const SizedBox(height: 20),
                          _buildLabel('Discount Percentage'),
                          TextFormField(
                            controller: _discountPercentageController,
                            decoration: _buildInputDecoration('Enter Discount Percentage')
                                .copyWith(suffixText: '%'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (_hasDiscountController.value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter discount percentage';
                                }
                                final percentage = double.tryParse(value);
                                if (percentage == null || percentage < 0 || percentage > 100) {
                                  return 'Please enter a valid percentage (0-100)';
                                }
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 20),

                        _buildLabel('Stock'),
                        TextFormField(
                          controller: _stockController,
                          decoration: _buildInputDecoration('Enter Stock Quantity'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter stock quantity';
                            }
                            final stock = int.tryParse(value);
                            if (stock == null || stock < 0) {
                              return 'Please enter a valid stock quantity';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel('Warranty'),
                        TextFormField(
                          controller: _warrantyController,
                          decoration: _buildInputDecoration('Enter Warranty Information'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter warranty information';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Product Image'),
                        GestureDetector(
                          onTap: _selectImage,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'أدخل رابط الصورة',
                                      hintText: 'https://example.com/image.jpg',
                                      helperText: 'يجب أن يبدأ الرابط بـ http:// أو https://',
                                      prefixIcon: const Icon(Icons.link),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _imageUrl = value.isNotEmpty ? value : null;
                                      });
                                    },
                                    initialValue: _imageUrl,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_imageUrl != null && _imageUrl!.isNotEmpty)
                                      TextButton.icon(
                                        onPressed: () {
                                          if (_imageUrl != null && _imageUrl!.isNotEmpty) {
                                            if (_imageUrl!.startsWith('http://') || _imageUrl!.startsWith('https://')) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('معاينة الصورة'),
                                                  content: SizedBox(
                                                    width: 300,
                                                    height: 300,
                                                    child: Image.network(
                                                      _imageUrl!,
                                                      fit: BoxFit.contain,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return Center(
                                                          child: CircularProgressIndicator(
                                                            value: loadingProgress.expectedTotalBytes != null
                                                                ? loadingProgress.cumulativeBytesLoaded / 
                                                                    loadingProgress.expectedTotalBytes!
                                                                : null,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return const Center(
                                                          child: Icon(
                                                            Icons.error_outline,
                                                            color: Colors.red,
                                                            size: 48,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(),
                                                      child: const Text('إغلاق'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('خطأ في الرابط'),
                                                  content: const Text('يجب أن يبدأ رابط الصورة بـ http:// أو https://'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(),
                                                      child: const Text('حسنًا'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.preview),
                                        label: const Text('معاينة'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        _buildCategorySpecificFields(),

                        Row(
                          children: [
                            Expanded(
                              child: MouseRegion(
                                onEnter: (_) => setState(() => _isHoveringCancel = true),
                                onExit: (_) => setState(() => _isHoveringCancel = false),
                                child: TextButton(
                                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor:
                                        _isHoveringCancel ? Colors.grey[100] : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: _isHoveringCancel
                                            ? Colors.grey[400]!
                                            : const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: MouseRegion(
                                onEnter: (_) => setState(() => _isHoveringUpdate = true),
                                onExit: (_) => setState(() => _isHoveringUpdate = false),
                                child: ElevatedButton(
                                  onPressed: (_isLoading || _isSubmitting) ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isHoveringUpdate
                                        ? const Color(0xFF404040)
                                        : Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Update',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
} 