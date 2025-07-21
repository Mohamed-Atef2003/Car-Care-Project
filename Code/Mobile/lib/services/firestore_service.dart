import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store/store_product.dart';
import '../models/store/tire.dart';
import '../models/store/tool.dart';
import '../models/store/spare_part.dart';
import '../models/store/glass_product.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Single products collection
  final String _productsCollection = 'products';
  final String _favoritesCollection = 'favorites';

  // ====== Get products by type ======
  
  // Get all products
  Future<List<StoreProduct>> getAllProducts() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_productsCollection).get();
      
      final List<StoreProduct> products = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String category = data['category'] ?? '';
        
        switch (category) {
          case 'tires':
            products.add(Tire.fromMap({...data, 'id': doc.id}));
            break;
          case 'tools':
            products.add(Tool.fromMap({...data, 'id': doc.id}));
            break;
          case 'spare_parts':
            products.add(SparePart.fromMap({...data, 'id': doc.id}));
            break;
          case 'glass':
            products.add(GlassProduct.fromMap({...data, 'id': doc.id}));
            break;
        }
      }
      
      return products;
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }

  // Obtener todos los neumáticos
  Future<List<Tire>> getAllTires() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_productsCollection)
          .where('category', isEqualTo: 'tires')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Tire.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting tires: $e');
      return [];
    }
  }

  // Obtener todas las herramientas
  Future<List<Tool>> getAllTools() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_productsCollection)
          .where('category', isEqualTo: 'tools')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Tool.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting tools: $e');
      return [];
    }
  }

  // Obtener todas las piezas de repuesto
  Future<List<SparePart>> getAllSpareParts() async {
    print("📁 getAllSpareParts() called in FirestoreService");
    try {
      print("📁 Before querying collection: $_productsCollection with category=spare_parts");
      final QuerySnapshot snapshot = await _firestore
          .collection(_productsCollection)
          .where('category', isEqualTo: 'spare_parts')
          .get();
      print("📁 After querying collection, docs count: ${snapshot.docs.length}");
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SparePart.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('📁 Error getting spare parts: $e');
      return [];
    }
  }

  // Obtener todos los cristales
  Future<List<GlassProduct>> getAllGlass() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_productsCollection)
          .where('category', isEqualTo: 'glass')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GlassProduct.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting glass products: $e');
      return [];
    }
  }

  // ====== Get product by ID ======
  
  // Get any product by ID
  Future<StoreProduct?> getProductById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(_productsCollection).doc(id).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final String category = data['category'] ?? '';
        
        switch (category) {
          case 'tires':
            return Tire.fromMap({...data, 'id': doc.id});
          case 'tools':
            return Tool.fromMap({...data, 'id': doc.id});
          case 'spare_parts':
            return SparePart.fromMap({...data, 'id': doc.id});
          case 'glass':
            return GlassProduct.fromMap({...data, 'id': doc.id});
          default:
            return null;
        }
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Get a tire by ID
  Future<Tire?> getTireById(String id) async {
    try {
      final StoreProduct? product = await getProductById(id);
      if (product is Tire) {
        return product;
      }
      return null;
    } catch (e) {
      print('Error getting tire: $e');
      return null;
    }
  }

  // Get a tool by ID
  Future<Tool?> getToolById(String id) async {
    try {
      final StoreProduct? product = await getProductById(id);
      if (product is Tool) {
        return product;
      }
      return null;
    } catch (e) {
      print('Error getting tool: $e');
      return null;
    }
  }

  // Get a spare part by ID
  Future<SparePart?> getSparePartById(String id) async {
    try {
      final StoreProduct? product = await getProductById(id);
      if (product is SparePart) {
        return product;
      }
      return null;
    } catch (e) {
      print('Error getting spare part: $e');
      return null;
    }
  }

  // Get a glass product by ID
  Future<GlassProduct?> getGlassById(String id) async {
    try {
      final StoreProduct? product = await getProductById(id);
      if (product is GlassProduct) {
        return product;
      }
      return null;
    } catch (e) {
      print('Error getting glass product: $e');
      return null;
    }
  }

  // ====== CRUD operations for adding products ======

  // Add a product
  Future<String> addProduct(StoreProduct product, String type) async {
    try {
      // Crear un mapa con todos los datos del producto
      final Map<String, dynamic> productData = product.toMap();
      
      // Ya no es necesario agregar el campo type, ya que usamos category
      
      // Agregar a Firestore
      final docRef = await _firestore.collection(_productsCollection).add(productData);
      return docRef.id;
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  // ====== CRUD operations for updating products ======

  // Update a product
  Future<void> updateProduct(String id, StoreProduct product, String type) async {
    try {
      // Crear un mapa con todos los datos del producto
      final Map<String, dynamic> productData = product.toMap();
      
      // Ya no es necesario agregar el campo type, ya que usamos category
      
      // Actualizar en Firestore
      await _firestore.collection(_productsCollection).doc(id).update(productData);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // ====== CRUD operations for deleting products ======

  // Delete a product
  Future<void> deleteProduct(String id, String type) async {
    try {
      await _firestore.collection(_productsCollection).doc(id).delete();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // ====== Favorites Management ======
  
  // Add product to favorites
  Future<void> addToFavorites(String userId, String productId) async {
    try {
      // Get the product details
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Product not found');
      }

      await _firestore
          .collection(_favoritesCollection)
          .doc(userId)
          .collection('products')
          .doc(productId)
          .set({
            'productId': productId,
            'productName': product.name,
            'userId': userId,
            'addedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove product from favorites
  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      await _firestore
          .collection(_favoritesCollection)
          .doc(userId)
          .collection('products')
          .doc(productId)
          .delete();
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Get user's favorite products
  Future<List<String>> getUserFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_favoritesCollection)
          .doc(userId)
          .collection('products')
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  // Check if product is in favorites
  Future<bool> isProductInFavorites(String userId, String productId) async {
    try {
      final doc = await _firestore
          .collection(_favoritesCollection)
          .doc(userId)
          .collection('products')
          .doc(productId)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('Error checking favorites: $e');
      return false;
    }
  }
} 