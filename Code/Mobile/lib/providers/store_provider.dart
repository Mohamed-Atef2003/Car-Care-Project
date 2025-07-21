import '../models/store/store_product.dart';
import '../models/store/tire.dart';
import '../models/store/tool.dart';
import '../models/store/spare_part.dart';
import '../models/store/glass_product.dart';
import '../models/payment_model.dart';
import '../services/firestore_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:flutter/material.dart';

class StoreProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Product lists
  List<Tire> _tires = [];
  List<Tool> _tools = [];
  List<SparePart> _spareParts = [];
  List<GlassProduct> _glass = [];
  final List<StoreProduct> _favoriteProducts = [];
  final Map<String, StoreProduct> _cart = {};
  final Map<String, int> _quantities = {};

  // Loading state
  bool _loading = false;
  String _error = '';

  // State getters
  bool get isLoading => _loading;
  String get error => _error;
  bool get hasError => _error.isNotEmpty;

  // Product list getters
  List<Tire> get tires => _tires;
  List<Tool> get tools => _tools;
  List<SparePart> get spareParts => _spareParts;
  List<GlassProduct> get glass => _glass;
  List<StoreProduct> get favoriteProducts => _favoriteProducts;
  
  // Getter for cart items
  List<MapEntry<String, StoreProduct>> get cartItems => _cart.entries.toList();
  
  // Getter for cart total
  double get cartTotal {
    double total = 0;
    _cart.forEach((id, product) {
      total += (product.price * (_quantities[id] ?? 1));
    });
    return total;
  }

  // Initialize and load data
  Future<void> initialize() async {
    await loadTires();
    await loadTools();
    await loadSpareParts();
    await loadGlass();
    notifyListeners();
  }

  // Methods to load products from Firebase
  
  Future<void> loadTires() async {
    try {
      _tires = await _firestoreService.getAllTires();
      notifyListeners();
    } catch (e) {
      print('Error loading tires: $e');
    }
  }

  Future<void> loadTools() async {
    try {
      _tools = await _firestoreService.getAllTools();
      notifyListeners();
    } catch (e) {
      print('Error loading tools: $e');
    }
  }

  Future<void> loadSpareParts() async {
    try {
      print("📁 loadSpareParts() in StoreProvider");
      _spareParts = await _firestoreService.getAllSpareParts();
      print("📁 Loaded ${_spareParts.length} spare parts");
      notifyListeners();
    } catch (e) {
      print('📁 Error loading spare parts in provider: $e');
    }
  }

  Future<void> loadGlass() async {
    try {
      _glass = await _firestoreService.getAllGlass();
      notifyListeners();
    } catch (e) {
      print('Error loading glass products: $e');
    }
  }

  // Methods for favorites
  
  bool isFavorite(String id) {
    return _favoriteProducts.any((product) => product.id == id);
  }

  Future<void> toggleFavoriteById(String id, BuildContext context) async {
    // Search for product in each list
    StoreProduct? product = findProductById(id);
    
    if (product != null) {
      await toggleFavorite(product, context);
    }
  }

  Future<void> toggleFavorite(StoreProduct product, BuildContext context) async {
    final isAlreadyFavorite = _favoriteProducts.any((p) => p.id == product.id);
    
    try {
      // Get current user ID
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      if (isAlreadyFavorite) {
        // Remove from favorites
        await _firestoreService.removeFromFavorites(userId, product.id);
        _favoriteProducts.removeWhere((p) => p.id == product.id);
      } else {
        // Add to favorites
        await _firestoreService.addToFavorites(userId, product.id);
        _favoriteProducts.add(product);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Load user's favorites from Firestore
  Future<void> loadFavorites(BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final favoriteIds = await _firestoreService.getUserFavorites(userId);
      final List<StoreProduct> favorites = [];
      
      for (final id in favoriteIds) {
        final product = await _firestoreService.getProductById(id);
        if (product != null) {
          favorites.add(product);
        }
      }
      
      _favoriteProducts.clear();
      _favoriteProducts.addAll(favorites);
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
      rethrow;
    }
  }

  // Methods for cart
  
  bool isInCart(String id) {
    return _cart.containsKey(id);
  }

  int getQuantity(String id) {
    return _quantities[id] ?? 0;
  }

  void addToCart(StoreProduct product) {
    if (_cart.containsKey(product.id)) {
      _quantities[product.id] = (_quantities[product.id] ?? 0) + 1;
    } else {
      _cart[product.id] = product;
      _quantities[product.id] = 1;
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cart.remove(id);
    _quantities.remove(id);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeFromCart(id);
    } else {
      _quantities[id] = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _quantities.clear();
    notifyListeners();
  }

  // Method to find product by ID
  StoreProduct? findProductById(String id) {
    // Search in tires
    for (var tire in _tires) {
      if (tire.id == id) return tire;
    }
    
    // Search in tools
    for (var tool in _tools) {
      if (tool.id == id) return tool;
    }
    
    // Search in spare parts
    for (var part in _spareParts) {
      if (part.id == id) return part;
    }
    
    // Search in glass products
    for (var glassItem in _glass) {
      if (glassItem.id == id) return glassItem;
    }
    
    return null;
  }

  // Method to create payment summary from a product
  PaymentSummary createPaymentSummaryFromProduct(StoreProduct product, {int quantity = 1}) {
    double subtotal = product.price * quantity;
    double tax = subtotal * 0.16; // 16% tax
    
    return PaymentSummary(
      subtotal: subtotal,
      tax: tax,
      discount: 0.0,
      total: subtotal + tax,
      currency: 'EGP',
      items: [
        {
          'product': product.toMap(),
          'quantity': quantity,
        }
      ],
    );
  }

  // Method to create payment summary from cart
  PaymentSummary createPaymentSummaryFromCart() {
    double subtotal = 0;
    List<Map<String, dynamic>> items = [];
    
    for (var entry in cartItems) {
      String id = entry.key;
      StoreProduct product = entry.value;
      int quantity = _quantities[id] ?? 1;
      subtotal += product.price * quantity;
      
      items.add({
        'product': product.toMap(),
        'quantity': quantity,
      });
    }
    
    double tax = subtotal * 0.16; // 16% tax
    
    return PaymentSummary(
      subtotal: subtotal,
      tax: tax,
      discount: 0.0,
      total: subtotal + tax,
      currency: 'EGP',
      items: items,
    );
  }

  // CRUD operations with Firestore
  
  // Add product to Firestore
  Future<String> addProduct(StoreProduct product, String type) async {
    try {
      _setLoading(true);
      final id = await _firestoreService.addProduct(product, type);
      
      // Update appropriate list
      switch (type) {
        case 'spare_part':
          await loadSpareParts();
          break;
        case 'tire':
          await loadTires();
          break;
        case 'glass':
          await loadGlass();
          break;
        case 'tool':
          await loadTools();
          break;
      }
      
      _setLoading(false);
      return id;
    } catch (e) {
      _setError('Error adding product: $e');
      rethrow;
    }
  }
  
  // Update product in Firestore
  Future<void> updateProduct(String id, StoreProduct product, String type) async {
    try {
      _setLoading(true);
      await _firestoreService.updateProduct(id, product, type);
      
      // Update appropriate list
      switch (type) {
        case 'spare_part':
          await loadSpareParts();
          break;
        case 'tire':
          await loadTires();
          break;
        case 'glass':
          await loadGlass();
          break;
        case 'tool':
          await loadTools();
          break;
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Error updating product: $e');
      rethrow;
    }
  }
  
  // Delete product from Firestore
  Future<void> deleteProduct(String id, String type) async {
    try {
      _setLoading(true);
      await _firestoreService.deleteProduct(id, type);
      
      // Update appropriate list
      switch (type) {
        case 'spare_part':
          await loadSpareParts();
          break;
        case 'tire':
          await loadTires();
          break;
        case 'glass':
          await loadGlass();
          break;
        case 'tool':
          await loadTools();
          break;
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Error deleting product: $e');
      rethrow;
    }
  }
  
  // Helper functions for state management
  void _setLoading(bool isLoading) {
    _loading = isLoading;
    if (isLoading) {
      _clearError();
    }
    notifyListeners();
  }
  
  void _setError(String errorMessage) {
    _error = errorMessage;
    _loading = false;
    notifyListeners();
  }
  
  void _clearError() {
    _error = '';
    notifyListeners();
  }
} 