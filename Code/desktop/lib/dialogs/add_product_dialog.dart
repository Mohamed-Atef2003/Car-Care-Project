import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:car_care/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductDialog extends StatefulWidget {
  final Function(StoreProduct) onProductAdded;

  const AddProductDialog({
    super.key,
    required this.onProductAdded,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _brandController = TextEditingController();
  final _warrantyController = TextEditingController();
  String? _selectedCategory;
  String? _imageUrl;
  String? _customImageUrl;
  bool _isHoveringUpload = false;
  bool _isHoveringCancel = false;
  bool _isLoading = false;

  // Product type specific controllers
  final _partNumberController = TextEditingController();
  final _originController = TextEditingController();
  final _sizeController = TextEditingController();
  final _speedRatingController = TextEditingController();
  final _loadIndexController = TextEditingController();
  final _seasonController = TextEditingController();
  final _treadPatternController = TextEditingController();
  final _warrantyMilesController = TextEditingController();
  final _treadDepthController = TextEditingController();
  final _wetGripController = TextEditingController();
  final _fuelEfficiencyController = TextEditingController();
  final _noiseLevelController = TextEditingController();
  final _manufacturingCountryController = TextEditingController();
  final _glassTypeController = TextEditingController();
  final _toolTypeController = TextEditingController();
  final _powerSourceController = TextEditingController();
  final _materialController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _pieceCountController = TextEditingController();
  
  // Additional controllers for optional features
  final _oldPriceController = TextEditingController();
  final _hasDiscountController = ValueNotifier<bool>(false);
  final _discountPercentageController = TextEditingController(text: '0.0');
  final _uvProtectionController = TextEditingController(text: '0.0');
  final _hasTintingController = ValueNotifier<bool>(false);
  final _hasHeatingElementsController = ValueNotifier<bool>(false);
  final _isOriginalController = ValueNotifier<bool>(true);
  final _runFlatController = ValueNotifier<bool>(false);
  final _includesCaseController = ValueNotifier<bool>(false);

  final List<String> _productCategories = [
    'spare_parts',
    'tires',
    'glass',
    'tools',
  ];

  @override
  void dispose() {
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
      setState(() {
        _isLoading = true;
      });

      try {
        final double price = double.tryParse(_priceController.text) ?? 0.0;
        final double? oldPrice = double.tryParse(_oldPriceController.text);
        final int stock = int.tryParse(_stockController.text) ?? 0;
        final bool hasDiscount = _hasDiscountController.value;
        final double discountPercentage = double.tryParse(_discountPercentageController.text) ?? 0.0;
        final String productId = DateTime.now().millisecondsSinceEpoch.toString();
        
        // Create specific product type based on category
        StoreProduct product;
        switch (_selectedCategory) {
          case 'spare_parts':
            product = SparePart(
              id: productId,
              name: _nameController.text.trim(),
              category: 'spare_parts',
              brand: _brandController.text.trim(),
              price: price,
              oldPrice: oldPrice,
              imageUrl: _imageUrl ?? 'https://via.placeholder.com/300',
              images: [_imageUrl ?? 'https://via.placeholder.com/300'],
              description: _descriptionController.text.trim(),
              specifications: {},
              features: [],
              warranty: _warrantyController.text.trim(),
              compatibility: [],
              partNumber: _partNumberController.text.trim(),
              origin: _originController.text.trim(),
              stockCount: stock,
              inStock: stock > 0,
              hasDiscount: hasDiscount,
              discountPercentage: discountPercentage,
            );
            break;

          case 'tires':
            product = Tire(
              id: productId,
              name: _nameController.text.trim(),
              category: 'tires',
              brand: _brandController.text.trim(),
              price: price,
              oldPrice: oldPrice,
              imageUrl: _imageUrl ?? 'https://via.placeholder.com/300',
              images: [_imageUrl ?? 'https://via.placeholder.com/300'],
              description: _descriptionController.text.trim(),
              specifications: {},
              features: [],
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
              manufactureDate: DateTime.now(),
              stockCount: stock,
              inStock: stock > 0,
              hasDiscount: hasDiscount,
              discountPercentage: discountPercentage,
            );
            break;

          case 'glass':
            product = GlassProduct(
              id: productId,
              name: _nameController.text.trim(),
              category: 'glass',
              brand: _brandController.text.trim(),
              price: price,
              oldPrice: oldPrice,
              imageUrl: _imageUrl ?? 'https://via.placeholder.com/300',
              images: [_imageUrl ?? 'https://via.placeholder.com/300'],
              description: _descriptionController.text.trim(),
              specifications: {},
              features: [],
              warranty: _warrantyController.text.trim(),
              compatibility: [],
              glassType: _glassTypeController.text.trim(),
              hasTinting: _hasTintingController.value,
              uvProtectionLevel: double.tryParse(_uvProtectionController.text) ?? 0.0,
              hasHeatingElements: _hasHeatingElementsController.value,
              isOriginal: _isOriginalController.value,
              stockCount: stock,
              inStock: stock > 0,
              hasDiscount: hasDiscount,
              discountPercentage: discountPercentage,
            );
            break;

          case 'tools':
            product = Tool(
              id: productId,
              name: _nameController.text.trim(),
              category: 'tools',
              brand: _brandController.text.trim(),
              price: price,
              oldPrice: oldPrice,
              imageUrl: _imageUrl ?? 'https://via.placeholder.com/300',
              images: [_imageUrl ?? 'https://via.placeholder.com/300'],
              description: _descriptionController.text.trim(),
              specifications: {},
              features: [],
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
            );
            break;

          default:
            product = SparePart(
              id: productId,
              name: _nameController.text.trim(),
              category: 'spare_parts',
              brand: _brandController.text.trim(),
              price: price,
              oldPrice: oldPrice,
              imageUrl: _imageUrl ?? 'https://via.placeholder.com/300',
              images: [_imageUrl ?? 'https://via.placeholder.com/300'],
              description: _descriptionController.text.trim(),
              specifications: {},
              features: [],
              warranty: _warrantyController.text.trim(),
              compatibility: [],
              partNumber: '',
              origin: '',
              stockCount: stock,
              inStock: stock > 0,
              hasDiscount: hasDiscount,
              discountPercentage: discountPercentage,
            );
        }

        // Add product to Firestore
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .set(product.toMap());

        widget.onProductAdded(product);
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('Error adding product: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding product: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
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
        title: const Text('Select Image'),
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
                        'Enter image URL:',
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
                                helperText: 'URLs must start with http:// or https://',
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
                                      title: const Text('Preview Image'),
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
                                                  'Cannot load image from specified URL',
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
                                          child: const Text('Close'),
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
                                          child: const Text('Use This Image'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('URL Error'),
                                      content: const Text('Image URL must start with http:// or https://'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.preview),
                            tooltip: 'Preview Image',
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
                                      title: const Text('URL Error'),
                                      content: const Text('Image URL must start with http:// or https://'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('OK'),
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
                            child: const Text('Use'),
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
            child: const Text('Cancel'),
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
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    'Add Product',
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

                      _buildLabel('Stock Quantity'),
                      TextFormField(
                        controller: _stockController,
                        decoration: _buildInputDecoration('Enter stock quantity'),
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
                                    labelText: 'Enter Image URL',
                                    hintText: 'https://example.com/image.jpg',
                                    helperText: 'URL must start with http:// or https://',
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category-specific fields
                      if (_selectedCategory != null) _buildCategorySpecificFields(),
                      const SizedBox(height: 32),

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
                                  backgroundColor: _isHoveringCancel ? Colors.grey[100] : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: _isHoveringCancel ? Colors.grey[400]! : const Color(0xFFE0E0E0),
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
                              onEnter: (_) => setState(() => _isHoveringUpload = true),
                              onExit: (_) => setState(() => _isHoveringUpload = false),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isHoveringUpload ? const Color(0xFF404040) : Colors.black,
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
                                        'Upload',
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
    );
  }
}
