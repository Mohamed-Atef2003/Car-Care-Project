import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/constants/colors.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';


class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelYearController = TextEditingController();
  final _carNumberController = TextEditingController();
  final _carLicenseController = TextEditingController();
  final _colorController = TextEditingController();
  // Replace model text controller with dropdown selections
  String? _selectedModel;
  String? _selectedTrim;
  String? _selectedEngine;
  final _versionController = TextEditingController();
  String? _selectedBrand;

  // Available models, trims, and engines based on selection
  List<String> _availableModels = [];
  List<String> _availableTrims = [];
  List<String> _availableEngines = [];


  final _selectedColor = AppColors.primary;
  
  final CarService _carService = CarService();
  
  @override
  void dispose() {
    _modelYearController.dispose();
    _carNumberController.dispose();
    _carLicenseController.dispose();
    _colorController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  // Get customer ID from UserProvider
  String getCustomerId() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.user?.id ?? '';
  }

  // Update available models when selecting a brand
  void _updateAvailableModels() {
    if (_selectedBrand != null) {
      setState(() {
        _availableModels = CarModels.getModelNamesForBrand(_selectedBrand!);
        _selectedModel = null; // Reset model selection
        _selectedTrim = null; // Reset trim selection
        _selectedEngine = null; // Reset engine selection
        _availableTrims = []; 
        _availableEngines = [];
      });
    }
  }

  // Update available trims when selecting a model
  void _updateAvailableTrims() {
    if (_selectedBrand != null && _selectedModel != null) {
      setState(() {
        _availableTrims = CarModels.getTrimsForModel(_selectedBrand!, _selectedModel!);
        _availableEngines = CarModels.getEngineOptionsForModel(_selectedBrand!, _selectedModel!);
      });
    }
  }

  Future<void> _addCarToFirestore() async {
    final customerId = getCustomerId();
    if (customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add a car'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    await FirebaseFirestore.instance
        .collection("cars")
        .add({
          'customerId': customerId,
          'brand': _selectedBrand,
          'model': _selectedModel,
          'trim': _selectedTrim,
          'engine': _selectedEngine,
          'version': _versionController.text.trim(),
          'modelYear': _modelYearController.text.trim(),
          'carNumber': _carNumberController.text.trim(),
          'carLicense': _carLicenseController.text.trim(),
          'color': _colorController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
    
    // The success message is now shown in the _saveCar method
  }
  
  Future<void> _saveCar() async {
    if (_selectedBrand == null) {
      // Show error message if no brand is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a car brand'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedModel == null) {
      // Show error message if no model is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a car model'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      // Check if user is logged in
      final customerId = getCustomerId();
      if (customerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to add a car'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      try {
        // Save car to Firestore only
        await _addCarToFirestore();
        
        // Notify user of success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Car added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Close the page and return true to indicate a new car was saved
        Navigator.pop(context, true);
      } catch (e) {
        // Show error message if saving fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving car: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Add New Car'),
        centerTitle: true,
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.indigo,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Add Your Car Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This information will be used to facilitate maintenance and provide customized services for your car',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car Brand (Dropdown)
          _buildInputLabel('Car Brand'),
          _buildBrandDropdown(),
          const SizedBox(height: 16),
          
          // Car Model (Dropdown)
          _buildInputLabel('Car Model'),
          _buildModelDropdown(),
          const SizedBox(height: 16),
          
          // Car Trim (Dropdown) - visible only if a model is selected
          if (_selectedModel != null && _availableTrims.isNotEmpty) ...[
            _buildInputLabel('Car Trim'),
            _buildTrimDropdown(),
            const SizedBox(height: 16),
          ],
          
          // Car Engine (Dropdown) - visible only if a model is selected
          if (_selectedModel != null && _availableEngines.isNotEmpty) ...[
            _buildInputLabel('Engine'),
            _buildEngineDropdown(),
            const SizedBox(height: 16),
          ],
          
          // Car Version/Generation (Optional)
          _buildInputLabel('Version (Optional)'),
          TextFormField(
            controller: _versionController,
            decoration: _inputDecoration('Enter version/generation', Icons.merge_type),
          ),
          const SizedBox(height: 16),
          
          // Model Year
          _buildInputLabel('Model Year'),
          TextFormField(
            controller: _modelYearController,
            decoration: _inputDecoration('Enter model year', Icons.calendar_today),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the model year';
              }
              final year = int.tryParse(value);
              if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                return 'Please enter a valid year';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Car Number
          _buildInputLabel('Car Number'),
          TextFormField(
            controller: _carNumberController,
            decoration: _inputDecoration('Enter car number', Icons.numbers),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the car number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Car License
          _buildInputLabel('Car License'),
          TextFormField(
            controller: _carLicenseController,
            decoration: _inputDecoration('Enter license number', Icons.badge),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the car license number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Car Color
          _buildInputLabel('Car Color'),
          TextFormField(
            controller: _colorController,
            decoration: _inputDecoration('Enter car color', Icons.color_lens),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the car color';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveCar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Car',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
    );
  }
  
  Widget _buildBrandDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          _selectedBrand ?? 'Select Car Brand',
          style: TextStyle(
            color: _selectedBrand == null ? Colors.grey : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(Icons.arrow_drop_down, color: Colors.indigo),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        onExpansionChanged: (expanded) {
          // When the dropdown is closed, update available models
          if (!expanded && _selectedBrand != null) {
            _updateAvailableModels();
          }
        },
        children: [
          SizedBox(
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildBrandCategories(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildBrandCategories() {
    final Map<String, List<String>> categorizedBrands = _carService.getCategorizedBrands();
    final Map<String, String> categoryTranslations = {
      'يابانية': 'Japanese',
      'أمريكية': 'American',
      'أوروبية': 'European',
      'كورية': 'Korean',
      'صينية': 'Chinese',
    };
    
    List<Widget> categories = [];
    
    categorizedBrands.forEach((category, brands) {
      categories.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  categoryTranslations[category] ?? category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.indigo,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: brands.map((brand) {
                  final isSelected = _selectedBrand == brand;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBrand = brand;
                      });
                      // Close dropdown after selection
                      Future.delayed(Duration(milliseconds: 300), () {
                        setState(() {});
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        brand,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    });
    
    return categories;
  }

  Widget _buildModelDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          _selectedModel ?? 'Select Car Model',
          style: TextStyle(
            color: _selectedModel == null ? Colors.grey : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(Icons.arrow_drop_down, color: Colors.indigo),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        onExpansionChanged: (expanded) {
          // When the dropdown is closed, update available trims
          if (!expanded && _selectedModel != null) {
            _updateAvailableTrims();
          }
        },
        children: [
          _availableModels.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Please select a brand first',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : SizedBox(
                  height: 300,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildModelList(),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
  
  List<Widget> _buildModelList() {
    return _availableModels.map((model) {
      final isSelected = _selectedModel == model;
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedModel = model;
          });
          // Close dropdown after selection
          Future.delayed(Duration(milliseconds: 300), () {
            setState(() {});
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Text(
                model,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.indigo : Colors.black87,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.indigo,
                  size: 24,
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTrimDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _selectedTrim,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        hint: Text('Select Trim',
          style: TextStyle(color: Colors.grey),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.indigo),
        isExpanded: true,
        onChanged: (value) {
          setState(() {
            _selectedTrim = value;
          });
        },
        items: _availableTrims.map((trim) {
          return DropdownMenuItem<String>(
            value: trim,
            child: Text(trim),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEngineDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _selectedEngine,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        hint: Text('Select Engine',
          style: TextStyle(color: Colors.grey),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.indigo),
        isExpanded: true,
        onChanged: (value) {
          setState(() {
            _selectedEngine = value;
          });
        },
        items: _availableEngines.map((engine) {
          return DropdownMenuItem<String>(
            value: engine,
            child: Text(engine),
          );
        }).toList(),
      ),
    );
  }
} 