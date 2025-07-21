import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class ServiceCentersScreen extends StatefulWidget {
  const ServiceCentersScreen({super.key});

  // Add static getter to access service centers from other files
  static List<Map<String, dynamic>> get serviceCenters => _ServiceCentersScreenState._serviceCenters;
  
  @override
  State<ServiceCentersScreen> createState() => _ServiceCentersScreenState();
}

class _ServiceCentersScreenState extends State<ServiceCentersScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  
  // Map Controllers
  late AnimationController _animationController;
  late GoogleMapController _mapController;
  
  // Timer for updating open status
  Timer? _openStatusTimer;
  
  // Default camera position (will be updated when user location is fetched)
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(30.0444, 31.2357), // Cairo, Egypt as default
    zoom: 12,
  );

  // Set of markers on the map
  final Set<Marker> _markers = {};
  
  // Polylines for directions
  final Map<PolylineId, Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];
  
  // Map type
  MapType _currentMapType = MapType.normal;
  
  // View states
  bool _isListView = false;
  bool _isDetailsView = false;
  bool _isNavigationMode = false;
  bool _isLoading = true;
  bool _locationPermissionDenied = false;
  
  // Animation controller for smooth transitions
  
  // Selected service center for details
  Map<String, dynamic>? _selectedCenter;
  
  // Filter options
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All', 
    'Open Now', 
    'High Rating',
    'Maintenance', 
    'Oil Change',
    'Diagnostics',
    'Tire Service',
    'Electrical',
    'Electrical Systems',
    'Battery Service',
    'Engine Repair',
    'Body Repair',
    'Brakes',
    'Suspension',
    'Car Wash',
    'Detailing'
  ];
  
  // Distance filter
  double _maxDistance = 100.0; // in kilometers
  
  // Rating filter
  double _minRating = 0.0;
  
  // Search query
  final TextEditingController _searchController = TextEditingController();
  
  // Current user position
  Position? _currentPosition;
  
  // Location tracking
  final loc.Location _location = loc.Location();
  
  // Service center data - make it static so it can be accessed by the getter
static final List<Map<String, dynamic>> _serviceCenters = [
  {
    'id': 'center-1',
    'name': 'Downtown Auto Service',
    'address': 'Tahrir Square, Downtown Cairo',
    'latitude': 30.044420,
    'longitude': 31.235712,
    'phone': '+20 100 200 3000',
    'rating': 4.6,
    'isOpen': true,
    'openHours': '8:00 AM - 10:00 PM',
    'services': ['Maintenance', 'Oil Change', 'Electrical'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 142,
    'description': 'Modern service center offering comprehensive auto repairs with experienced technicians.',
    'amenities': ['Waiting Lounge', 'WiFi', 'Refreshments'],
    'prices': {
      'Oil Change': '350-550 EGP',
      'Engine Tune-Up': '600-900 EGP',
      'Basic Service': '800-1200 EGP'
    },
  },
  {
    'id': 'center-2',
    'name': 'Alexandria Car Clinic',
    'address': 'Stanley Bridge Road, Alexandria',
    'latitude': 31.200092,
    'longitude': 29.918886,
    'phone': '+20 101 201 3001',
    'rating': 4.3,
    'isOpen': true,
    'openHours': '9:00 AM - 8:00 PM',
    'services': ['Maintenance', 'Tire Service', 'Body Repair'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 87,
    'description': 'Reliable car clinic specializing in tire services and body repairs with quality parts.',
    'amenities': ['Comfortable Seating', 'Free Parking', 'WiFi'],
    'prices': {
      'Tire Replacement': '400-700 EGP per tire',
      'Body Repair': '1200-2500 EGP',
      'Full Service': '1000-1600 EGP'
    },
  },
  {
    'id': 'center-3',
    'name': 'Giza Auto Repair Hub',
    'address': '6th of October Road, Giza',
    'latitude': 30.013056,
    'longitude': 31.208889,
    'phone': '+20 102 202 3002',
    'rating': 4.7,
    'isOpen': true,
    'openHours': '7:30 AM - 9:30 PM',
    'services': ['Maintenance', 'Diagnostics', 'Tire Service', 'Engine Repair'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 176,
    'description': 'Well-equipped facility using the latest diagnostic tools and expert mechanics.',
    'amenities': ['Waiting Area', 'Complimentary Coffee', 'TV'],
    'prices': {
      'Diagnostics': '250-350 EGP',
      'Tire Change': '150-250 EGP',
      'Engine Repair': '2000-3500 EGP'
    },
  },
  {
    'id': 'center-4',
    'name': 'Nasr City Motor Works',
    'address': 'Road 9, Nasr City, Cairo',
    'latitude': 30.0850,
    'longitude': 31.3300,
    'phone': '+20 103 203 3003',
    'rating': 4.0,
    'isOpen': true,
    'openHours': '9:00 AM - 6:00 PM',
    'services': ['Maintenance', 'Tire Service'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 64,
    'description': 'A straightforward service center offering reliable basic maintenance and tire repair services.',
    'amenities': ['Basic Waiting Area'],
    'prices': {
      'Basic Maintenance': '300-500 EGP',
      'Tire Repair': '120-200 EGP'
    },
  },
  {
    'id': 'center-5',
    'name': 'El Obour Auto Fix',
    'address': 'Obour City, Industrial Zone',
    'latitude': 30.1288,
    'longitude': 31.4800,
    'phone': '+20 106 206 3006',
    'rating': 4.2,
    'isOpen': true,
    'openHours': '8:00 AM - 8:00 PM',
    'services': ['Maintenance', 'Brakes', 'Suspension'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 89,
    'description': 'Affordable and reliable service center for brakes, suspension, and general repairs.',
    'amenities': ['Free Parking', 'WiFi'],
    'prices': {
      'Brake Pads Change': '400-700 EGP',
      'Suspension Check': '300-500 EGP'
    },
  },
  {
    'id': 'center-6',
    'name': 'Heliopolis Auto Tech',
    'address': 'El Merghany Street, Heliopolis',
    'latitude': 30.0975,
    'longitude': 31.3220,
    'phone': '+20 105 205 3005',
    'rating': 4.5,
    'isOpen': true,
    'openHours': '8:00 AM - 9:00 PM',
    'services': ['Maintenance', 'Electrical Systems', 'Battery Service'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 132,
    'description': 'Expert service center in Heliopolis specializing in electrical diagnostics and battery maintenance.',
    'amenities': ['Modern Waiting Area', 'WiFi', 'Refreshments'],
    'prices': {
      'Battery Service': '200-300 EGP',
      'Electrical Diagnostics': '300-400 EGP',
      'Basic Service': '700-1100 EGP'
    },
  },
  {
    'id': 'center-7',
    'name': 'Smart Auto Center',
    'address': 'Smart Village, 6th of October City',
    'latitude': 29.9910,
    'longitude': 30.9730,
    'phone': '+20 107 207 3007',
    'rating': 4.4,
    'isOpen': true,
    'openHours': '7:00 AM - 8:00 PM',
    'services': ['Maintenance', 'Oil Change', 'Tire Service', 'Diagnostics'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 110,
    'description': 'Efficient service center in Smart Village offering a wide range of car maintenance and diagnostic services.',
    'amenities': ['Comfortable Seating', 'WiFi', 'Free Refreshments'],
    'prices': {
      'Oil Change': '350-550 EGP',
      'Tire Alignment': '250-400 EGP',
      'Full Service': '900-1300 EGP'
    },
  },
  {
    'id': 'center-8',
    'name': 'Mansoura Auto Experts',
    'address': 'Gomhoria Street, Mansoura',
    'latitude': 31.0450,
    'longitude': 31.3800,
    'phone': '+20 108 208 3008',
    'rating': 4.3,
    'isOpen': true,
    'openHours': '8:30 AM - 9:00 PM',
    'services': ['Maintenance', 'Car Wash', 'Diagnostics'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 92,
    'description': 'Professional auto experts providing complete car services in Mansoura.',
    'amenities': ['WiFi', 'Coffee', 'TV'],
    'prices': {
      'Full Service': '900-1400 EGP',
      'Car Wash': '100-200 EGP'
    },
  },
  {
    'id': 'center-9',
    'name': 'Sharqia Auto Care Center',
    'address': 'Al-Mohandiseen Street, Zagazig, Sharqia',
    'latitude': 30.5872,
    'longitude': 31.5024,
    'phone': '+20 109 209 3009',
    'rating': 4.4,
    'isOpen': true,
    'openHours': '8:00 AM - 9:00 PM',
    'services': ['Maintenance', 'Oil Change', 'Tire Service', 'Diagnostics'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 75,
    'description': 'Reliable auto care center in Sharqia offering a range of maintenance and repair services by certified technicians.',
    'amenities': ['Waiting Area', 'WiFi', 'Refreshments'],
    'prices': {
      'Oil Change': '350-500 EGP',
      'Tire Replacement': '300-450 EGP',
      'Full Service': '900-1200 EGP'
    },
  },
  {
    'id': 'center-10',
    'name': 'Sinai Auto Service',
    'address': 'El Arish, North Sinai',
    'latitude': 31.1313,
    'longitude': 33.7986,
    'phone': '+20 110 210 3010',
    'rating': 4.2,
    'isOpen': true,
    'openHours': '8:00 AM - 8:30 PM',
    'services': ['Maintenance', 'Oil Change', 'Diagnostics'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 68,
    'description': 'Trusted service center in North Sinai providing essential auto repair and maintenance services.',
    'amenities': ['Basic Waiting Area', 'WiFi'],
    'prices': {
      'Oil Change': '350-500 EGP',
      'Diagnostics': '250-350 EGP'
    },
  },
  {
    'id': 'center-11',
    'name': 'Port Said Car Clinic',
    'address': 'El Mahatta Street, Port Said',
    'latitude': 31.2653,
    'longitude': 32.3019,
    'phone': '+20 111 211 3011',
    'rating': 4.3,
    'isOpen': true,
    'openHours': '9:00 AM - 8:00 PM',
    'services': ['Maintenance', 'Tire Service', 'Body Repair'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 80,
    'description': 'Efficient car clinic in Port Said with quality repair services and genuine spare parts.',
    'amenities': ['Comfortable Seating', 'Free Parking'],
    'prices': {
      'Tire Replacement': '400-700 EGP per tire',
      'Body Repair': '1300-2600 EGP'
    },
  },
  {
    'id': 'center-12',
    'name': 'Aswan Service Hub',
    'address': 'Nubian Street, Aswan',
    'latitude': 24.0889,
    'longitude': 32.8998,
    'phone': '+20 112 212 3012',
    'rating': 4.5,
    'isOpen': true,
    'openHours': '7:00 AM - 9:00 PM',
    'services': ['Maintenance', 'Engine Repair', 'Diagnostics'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 95,
    'description': 'Leading auto hub in Aswan offering advanced diagnostics and expert engine repair services.',
    'amenities': ['Waiting Lounge', 'WiFi', 'Refreshments'],
    'prices': {
      'Engine Repair': '2200-3700 EGP',
      'Diagnostics': '250-350 EGP'
    },
  },
  {
    'id': 'center-13',
    'name': 'Damietta Auto Solutions',
    'address': 'Al Salam Street, Damietta',
    'latitude': 31.4167,
    'longitude': 31.8139,
    'phone': '+20 113 213 3013',
    'rating': 4.1,
    'isOpen': true,
    'openHours': '8:00 AM - 8:30 PM',
    'services': ['Maintenance', 'Oil Change', 'Tire Service'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 70,
    'description': 'Cost-effective auto solutions center in Damietta with experienced technicians and quality service.',
    'amenities': ['Basic Waiting Area', 'WiFi'],
    'prices': {
      'Oil Change': '350-500 EGP',
      'Tire Service': '150-250 EGP'
    },
  },
  {
    'id': 'center-14',
    'name': 'Luxor Car Care',
    'address': 'Al Khalifa Street, Luxor',
    'latitude': 25.6872,
    'longitude': 32.6396,
    'phone': '+20 114 214 3014',
    'rating': 4.4,
    'isOpen': true,
    'openHours': '8:00 AM - 9:30 PM',
    'services': ['Maintenance', 'Diagnostics', 'Body Repair'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 85,
    'description': 'Premium car care center in Luxor offering quality maintenance and repair services with expert staff.',
    'amenities': ['Comfortable Seating', 'WiFi', 'Refreshments'],
    'prices': {
      'Diagnostics': '250-350 EGP',
      'Body Repair': '1400-2800 EGP'
    },
  },
  {
    'id': 'center-15',
    'name': 'New Cairo Advanced Auto',
    'address': 'Tech Road, New Cairo',
    'latitude': 30.0444,
    'longitude': 31.5600,
    'phone': '+20 115 215 3015',
    'rating': 4.7,
    'isOpen': true,
    'openHours': '8:00 AM - 10:00 PM',
    'services': ['Maintenance', 'Oil Change', 'Detailing', 'Electrical'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 150,
    'description': 'Advanced auto center in New Cairo equipped with the latest technology and professional technicians.',
    'amenities': ['Premium Lounge', 'WiFi', 'Complimentary Snacks', 'Car Pickup Service'],
    'prices': {
      'Oil Change': '400-600 EGP',
      'Full Detailing': '900-1400 EGP'
    },
  },
  // المراكز الجديدة من 16 إلى 30
  // New centers from 16 to 30
  {
    'id': 'center-16',
    'name': 'Suez Auto Repair',
    'address': 'Port Said Road, Suez',
    'latitude': 30.5833,
    'longitude': 32.2667,
    'phone': '+20 116 216 3016',
    'rating': 4.3,
    'isOpen': true,
    'openHours': '8:00 AM - 9:00 PM',
    'services': ['Maintenance', 'Oil Change', 'Diagnostics'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 78,
    'description': 'Efficient repair services in Suez offering oil changes and basic diagnostics.',
    'amenities': ['Waiting Area', 'WiFi'],
    'prices': {
      'Oil Change': '350-500 EGP',
      'Diagnostics': '250-350 EGP'
    },
  },
  {
    'id': 'center-17',
    'name': 'Fayoum Car Service',
    'address': 'El Mahala Street, Fayoum',
    'latitude': 29.3100,
    'longitude': 30.8410,
    'phone': '+20 117 217 3017',
    'rating': 4.2,
    'isOpen': true,
    'openHours': '8:30 AM - 8:30 PM',
    'services': ['Maintenance', 'Engine Repair', 'Tire Service'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 65,
    'description': 'Reliable car service center in Fayoum with a focus on engine repairs and tire services.',
    'amenities': ['Basic Lounge', 'WiFi'],
    'prices': {
      'Engine Repair': '1800-3200 EGP',
      'Tire Service': '200-350 EGP'
    },
  },
  {
    'id': 'center-18',
    'name': 'Beni Suef Auto Clinic',
    'address': 'Saad Zaghloul Street, Beni Suef',
    'latitude': 29.0730,
    'longitude': 31.0930,
    'phone': '+20 118 218 3018',
    'rating': 4.1,
    'isOpen': true,
    'openHours': '9:00 AM - 7:00 PM',
    'services': ['Maintenance', 'Brakes', 'Suspension'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 54,
    'description': 'Affordable clinic in Beni Suef specializing in brake services and suspension checks.',
    'amenities': ['Waiting Area', 'Free Parking'],
    'prices': {
      'Brake Pads Change': '350-600 EGP',
      'Suspension Check': '300-500 EGP'
    },
  },
  {
    'id': 'center-19',
    'name': 'Minya Auto Solutions',
    'address': 'Al Nahda Street, Minya',
    'latitude': 28.1100,
    'longitude': 30.7500,
    'phone': '+20 119 219 3019',
    'rating': 4.0,
    'isOpen': true,
    'openHours': '8:00 AM - 6:00 PM',
    'services': ['Maintenance', 'Oil Change', 'Detailing'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 60,
    'description': 'Cost-effective solutions in Minya with quality oil changes and detailing services.',
    'amenities': ['Basic Lounge', 'WiFi'],
    'prices': {
      'Oil Change': '300-450 EGP',
      'Full Detailing': '800-1200 EGP'
    },
  },
  {
    'id': 'center-20',
    'name': 'Sohag Car Care',
    'address': 'El Amreya Street, Sohag',
    'latitude': 26.5600,
    'longitude': 31.7000,
    'phone': '+20 120 220 3020',
    'rating': 4.3,
    'isOpen': true,
    'openHours': '7:30 AM - 8:30 PM',
    'services': ['Maintenance', 'Diagnostics', 'Tire Service'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 72,
    'description': 'Service center in Sohag offering reliable diagnostics and tire services.',
    'amenities': ['Waiting Area', 'WiFi'],
    'prices': {
      'Diagnostics': '200-300 EGP',
      'Tire Service': '150-250 EGP'
    },
  },
  {
    'id': 'center-21',
    'name': 'Red Sea Auto Repair',
    'address': 'El-Qusair, Hurghada, Red Sea',
    'latitude': 27.2579,
    'longitude': 33.8121,
    'phone': '+20 121 221 3021',
    'rating': 4.5,
    'isOpen': true,
    'openHours': '8:00 AM - 9:30 PM',
    'services': ['Maintenance', 'Oil Change', 'Car Wash'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 88,
    'description': 'Quality auto repair in the Red Sea area with specialized oil changes and car wash services.',
    'amenities': ['Comfortable Seating', 'WiFi'],
    'prices': {
      'Oil Change': '400-600 EGP',
      'Car Wash': '150-250 EGP'
    },
  },
  {
    'id': 'center-22',
    'name': 'Sharm El Sheikh Car Clinic',
    'address': 'Nafoura Road, Sharm El Sheikh',
    'latitude': 27.9158,
    'longitude': 34.3299,
    'phone': '+20 122 222 3022',
    'rating': 4.6,
    'isOpen': true,
    'openHours': '9:00 AM - 8:00 PM',
    'services': ['Maintenance', 'Detailing', 'Body Repair'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 83,
    'description': 'Premium clinic in Sharm El Sheikh offering detailing and body repair with a modern touch.',
    'amenities': ['Comfortable Seating', 'WiFi', 'Refreshments'],
    'prices': {
      'Full Detailing': '950-1400 EGP',
      'Body Repair': '1500-2800 EGP'
    },
  },
  {
    'id': 'center-23',
    'name': 'Hurghada Auto Hub',
    'address': 'El Salam Road, Hurghada',
    'latitude': 27.2579,
    'longitude': 33.8116,
    'phone': '+20 123 223 3023',
    'rating': 4.4,
    'isOpen': true,
    'openHours': '8:00 AM - 10:00 PM',
    'services': ['Maintenance', 'Battery Service', 'Electrical Systems'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 90,
    'description': 'Modern auto hub in Hurghada with expertise in battery and electrical system services.',
    'amenities': ['Waiting Lounge', 'WiFi'],
    'prices': {
      'Battery Service': '250-350 EGP',
      'Electrical Diagnostics': '350-450 EGP'
    },
  },
  {
    'id': 'center-24',
    'name': 'El-Mahalla Auto Experts',
    'address': 'El-Mahalla, Gharbia',
    'latitude': 30.9750,
    'longitude': 31.1640,
    'phone': '+20 124 224 3024',
    'rating': 4.2,
    'isOpen': true,
    'openHours': '8:00 AM - 9:00 PM',
    'services': ['Maintenance', 'Oil Change', 'Engine Repair'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 77,
    'description': 'Trusted auto experts in El-Mahalla providing quality oil changes and engine repairs.',
    'amenities': ['Modern Waiting Area', 'WiFi'],
    'prices': {
      'Oil Change': '350-500 EGP',
      'Engine Repair': '2100-3600 EGP'
    },
  },
  {
    'id': 'center-25',
    'name': 'Zagazig Advanced Service',
    'address': 'Downtown Zagazig, Sharqia',
    'latitude': 30.5892,
    'longitude': 31.5024,
    'phone': '+20 125 225 3025',
    'rating': 4.5,
    'isOpen': true,
    'openHours': '8:00 AM - 9:00 PM',
    'services': ['Maintenance', 'Diagnostics', 'Tire Service', 'Electrical'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 82,
    'description': 'Advanced service center in Zagazig with comprehensive diagnostics and tire services.',
    'amenities': ['Waiting Area', 'WiFi'],
    'prices': {
      'Diagnostics': '250-350 EGP',
      'Tire Service': '200-350 EGP'
    },
  },
  {
    'id': 'center-26',
    'name': 'Cairo Elite Auto',
    'address': 'Maadi, Cairo',
    'latitude': 30.0050,
    'longitude': 31.2310,
    'phone': '+20 126 226 3026',
    'rating': 4.8,
    'isOpen': true,
    'openHours': '7:00 AM - 11:00 PM',
    'services': ['Maintenance', 'Oil Change', 'Electrical', 'Detailing'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 160,
    'description': 'Elite auto center in Maadi offering top-notch services with modern facilities.',
    'amenities': ['Premium Lounge', 'WiFi', 'Complimentary Snacks'],
    'prices': {
      'Oil Change': '400-600 EGP',
      'Full Detailing': '1000-1500 EGP'
    },
  },
  {
    'id': 'center-27',
    'name': 'Alexandria Premier Auto',
    'address': 'Raml Station, Alexandria',
    'latitude': 31.2000,
    'longitude': 29.9167,
    'phone': '+20 127 227 3027',
    'rating': 4.7,
    'isOpen': true,
    'openHours': '8:00 AM - 10:00 PM',
    'services': ['Maintenance', 'Tire Service', 'Engine Repair'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 140,
    'description': 'Premier auto center in Alexandria providing high-quality tire and engine repair services.',
    'amenities': ['Comfortable Seating', 'WiFi'],
    'prices': {
      'Tire Replacement': '450-750 EGP',
      'Engine Repair': '2200-3700 EGP'
    },
  },
  {
    'id': 'center-28',
    'name': 'Giza Pro Auto Care',
    'address': 'Dokki, Giza',
    'latitude': 30.0300,
    'longitude': 31.2100,
    'phone': '+20 128 228 3028',
    'rating': 4.6,
    'isOpen': true,
    'openHours': '8:00 AM - 9:00 PM',
    'services': ['Maintenance', 'Oil Change', 'Brakes', 'Suspension'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 115,
    'description': 'Professional auto care center in Dokki, Giza offering efficient oil changes and brake services.',
    'amenities': ['Waiting Area', 'WiFi'],
    'prices': {
      'Brake Pads Change': '400-700 EGP',
      'Suspension Check': '300-500 EGP'
    },
  },
  {
    'id': 'center-29',
    'name': 'Port Said Motor Clinic',
    'address': 'El-Galaa Street, Port Said',
    'latitude': 31.2650,
    'longitude': 32.2999,
    'phone': '+20 129 229 3029',
    'rating': 4.3,
    'isOpen': true,
    'openHours': '9:00 AM - 8:00 PM',
    'services': ['Maintenance', 'Electrical Systems', 'Battery Service'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 69,
    'description': 'Motor clinic in Port Said specializing in electrical diagnostics and battery services.',
    'amenities': ['Comfortable Seating', 'Free Parking'],
    'prices': {
      'Electrical Diagnostics': '300-400 EGP',
      'Battery Service': '200-300 EGP'
    },
  },
  {
    'id': 'center-30',
    'name': 'Damietta Car Solutions',
    'address': 'Al-Huda Street, Damietta',
    'latitude': 31.4167,
    'longitude': 31.8139,
    'phone': '+20 130 230 3030',
    'rating': 4.4,
    'isOpen': true,
    'openHours': '8:00 AM - 9:00 PM',
    'services': ['Maintenance', 'Oil Change', 'Car Wash', 'Detailing'],
    'images': ['assets/image/car-maintenance.png'],
    'reviews': 80,
    'description': 'Comprehensive car solutions in Damietta offering quality oil changes, car washes, and detailing services.',
    'amenities': ['Waiting Area', 'WiFi'],
    'prices': {
      'Oil Change': '350-500 EGP',
      'Car Wash': '100-200 EGP',
      'Full Detailing': '900-1400 EGP'
    },
  },
  {
  'id': 'center-31',
  'name': 'Obour Auto Center',
  'address': 'El Obour City, Al Obour, Qaliubia',
  'latitude': 30.279523,
  'longitude': 31.475272,
  'phone': '+20 6362342',
  'rating': 4.4,
  'isOpen': true,
  'openHours': '8:00 AM - 9:00 PM',
  'services': ['Maintenance', 'Oil Change', 'Diagnostics'],
  'images': ['assets/image/car-maintenance.png'],
  'reviews': 100,
  'description': 'A maintenance center in Obour City provides high-quality car maintenance services with a specialized team.',
  'amenities': ['Waiting Area', 'WiFi'],
  'prices': {
    'Oil Change': '350-500 EGP',
    'Diagnostics': '250-350 EGP'
  },
},
{
  'id': 'center-31',
  'name': 'Car Care Main Center',
  'address': 'Main Road, Cairo, Egypt',
  'latitude': 30.0500,
  'longitude': 31.2333,
  'phone': '+20 200000000',
  'rating': 4.5,
  'isOpen': true,
  'openHours': 'Open 24/7',
  'services': ['Maintenance', 'Oil Change', 'Diagnostics', 'Engine Repair', 'Car Wash','Tire Service','Body Repair','Electrical','Battery Service','Brakes','Suspension',],
  'images': ['assets/image/car-maintenance.png'],
  'reviews': 120,
  'description': 'A leading car maintenance center offering comprehensive auto care services using the latest technologies with a specialized team.',
  'amenities': ['Waiting Lounge', 'WiFi', 'Refreshments'],
  'prices': {
    'Oil Change': '350-600 EGP',
    'Engine Repair': '2000-4000 EGP',
    'Car Wash': '100-200 EGP',
    'Tire Service': '200-300 EGP',
    'Body Repair': '1000-2000 EGP',
    'Electrical': '200-300 EGP',
    'Battery Service': '200-300 EGP',
    'Brakes': '200-300 EGP',
    'Suspension': '200-300 EGP',
  },
},


];

  // Function to check if a service center is open based on current time
  bool _isServiceCenterOpen(String openHours) {
    // If the center is open 24/7
    if (openHours == 'Open 24/7') {
      return true;
    }
    
    // Parse the opening hours (expected format: "9:00 AM - 8:00 PM")
    final parts = openHours.split(' - ');
    if (parts.length != 2) return false;
    
    final openTimeStr = parts[0];
    final closeTimeStr = parts[1];
    
    // Parse opening time
    final openTimeParts = openTimeStr.split(' ');
    final openHourMinute = openTimeParts[0].split(':');
    int openHour = int.parse(openHourMinute[0]);
    int openMinute = int.parse(openHourMinute[1]);
    final openAmPm = openTimeParts[1];
    
    // Convert to 24-hour format
    if (openAmPm == 'PM' && openHour < 12) {
      openHour += 12;
    } else if (openAmPm == 'AM' && openHour == 12) {
      openHour = 0;
    }
    
    // Parse closing time
    final closeTimeParts = closeTimeStr.split(' ');
    final closeHourMinute = closeTimeParts[0].split(':');
    int closeHour = int.parse(closeHourMinute[0]);
    int closeMinute = int.parse(closeHourMinute[1]);
    final closeAmPm = closeTimeParts[1];
    
    // Convert to 24-hour format
    if (closeAmPm == 'PM' && closeHour < 12) {
      closeHour += 12;
    } else if (closeAmPm == 'AM' && closeHour == 12) {
      closeHour = 0;
    }
    
    // Get current time
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // Convert all times to minutes for easier comparison
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    final openTimeInMinutes = openHour * 60 + openMinute;
    final closeTimeInMinutes = closeHour * 60 + closeMinute;
    
    // Check if current time is within opening hours
    if (closeTimeInMinutes > openTimeInMinutes) {
      // Normal case: opening hours within the same day
      return currentTimeInMinutes >= openTimeInMinutes && currentTimeInMinutes <= closeTimeInMinutes;
    } else {
      // Special case: closing time is after midnight
      return currentTimeInMinutes >= openTimeInMinutes || currentTimeInMinutes <= closeTimeInMinutes;
    }
  }
  
  // Filtered list of service centers
  List<Map<String, dynamic>> _filteredCenters = [];
  
  @override
  void initState() {
    super.initState();
    
    // Update isOpen status based on current time
    _updateServiceCentersOpenStatus();
    
    // Set up timer to update isOpen status every minute
    _openStatusTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateServiceCentersOpenStatus();
    });
    
    _filteredCenters = List.from(_serviceCenters);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Update filters based on available services
    _updateFiltersFromServiceCenters();
    
    // Initialize location services
    _initLocationService();
  }
  
  // Update open status of all service centers
  void _updateServiceCentersOpenStatus() {
    bool statusChanged = false;
    
    for (var center in _serviceCenters) {
      bool newStatus = _isServiceCenterOpen(center['openHours']);
      if (center['isOpen'] != newStatus) {
        center['isOpen'] = newStatus;
        statusChanged = true;
      }
    }
    
    // If the status changed for any center, update the markers on the map
    if (statusChanged) {
      // If the widget is mounted, update the UI and refresh markers
      if (mounted) {
        setState(() {
          _addMarkers(); // Refresh all markers to update their colors
        });
      }
    } else {
      // If no status changed, still update the UI if needed
      if (mounted) {
        setState(() {});
      }
    }
  }
  
  // Update filters list based on unique services in service centers
  void _updateFiltersFromServiceCenters() {
    // Start with the special filters
    final Set<String> uniqueServices = {'All', 'Open Now', 'High Rating'};
    
    // Collect all unique services from service centers
    for (var center in _serviceCenters) {
      if (center['services'] != null) {
        for (var service in center['services']) {
          uniqueServices.add(service.toString());
        }
      }
    }
    
    // Update the filters list while keeping special filters at the beginning
    _filters.clear();
    _filters.addAll([
      'All', 
      'Open Now', 
      'High Rating',
    ]);
    
    // Add all other unique services
    _filters.addAll(uniqueServices.where((service) => 
      service != 'All' && service != 'Open Now' && service != 'High Rating')
    );
    
    print('Updated filters: $_filters');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    if (_controller.isCompleted) {
      _mapController.dispose();
    }
    
    // Cancel the timer to prevent memory leaks
    _openStatusTimer?.cancel();
    
    super.dispose();
  }

  // Initialize location services and request permissions
  void _initLocationService() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;
    
    try {
      serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _locationPermissionDenied = true;
            _isLoading = false;
          });
          return;
        }
      }
      
      permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          setState(() {
            _locationPermissionDenied = true;
            _isLoading = false;
          });
          return;
        }
      }
      
      // Get the current user location
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        
        // Calculate real distances to service centers
        _updateServiceCenterDistances();
        
        // Add marker for current location
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'Your Current Location',
            ),
          ),
        );
        
        // Add markers for service centers
        _addMarkers();
        
        _isLoading = false;
      });
      
      // Start location tracking
      _startLocationTracking();
      
    } catch (e) {
      print("Error initializing location service: $e");
      setState(() {
        _isLoading = false;
        _locationPermissionDenied = true;
      });
    }
  }

  // Calculate real distances between user location and service centers
  void _updateServiceCenterDistances() {
    if (_currentPosition == null) return;
    
    for (var center in _serviceCenters) {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        center['latitude'],
        center['longitude']
      );
      
      // Convert to kilometers and round to 1 decimal place
      double distanceInKm = (distanceInMeters / 1000);
      center['distance'] = double.parse(distanceInKm.toStringAsFixed(1));
    }
    
    // Update filtered centers too
    for (var center in _filteredCenters) {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        center['latitude'],
        center['longitude']
      );
      
      // Convert to kilometers and round to 1 decimal place
      double distanceInKm = (distanceInMeters / 1000);
      center['distance'] = double.parse(distanceInKm.toStringAsFixed(1));
    }
  }

  // Start location tracking for navigation
  Future<void> _startLocationTracking() async {
    try {
      _location.onLocationChanged.listen((loc.LocationData currentLocation) {
        if (currentLocation.latitude != null && 
            currentLocation.longitude != null) {
          // Update the current position
          setState(() {
            _currentPosition = Position(
              latitude: currentLocation.latitude!,
              longitude: currentLocation.longitude!,
              timestamp: DateTime.now(),
              accuracy: currentLocation.accuracy ?? 0.0,
              altitude: currentLocation.altitude ?? 0.0,
              heading: currentLocation.heading ?? 0.0,
              speed: currentLocation.speed ?? 0.0,
              speedAccuracy: currentLocation.speedAccuracy ?? 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            );
          });
          
          // Update distances when location changes
          _updateServiceCenterDistances();
          
          // Update user location
          _updateUserLocationMarker(
            LatLng(currentLocation.latitude!, currentLocation.longitude!),
          );
          
          // Update route if navigation mode is active
          if (_polylineCoordinates.isNotEmpty) {
            _updateRouteProgress(
              LatLng(currentLocation.latitude!, currentLocation.longitude!),
            );
          }
        }
      });
      
      setState(() {
      });
      
    } catch (e) {
      print("Error starting location tracking: $e");
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while getting directions. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Update the user location marker during live tracking
  void _updateUserLocationMarker(LatLng newPosition) {
    setState(() {
      // Remove old user marker
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'currentLocation',
      );
      
      // Add new user marker
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: newPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Current Location',
          ),
        ),
      );
    });
  }
  
  // Update route progress during navigation
  void _updateRouteProgress(LatLng currentPosition) {
    // This is a simplified implementation
    // In a real app, you would recalculate distance to destination
    // and potentially re-request directions if the user is off route
    
    if (_selectedCenter != null) {
      // Calculate remaining distance
      double distanceRemaining = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        _selectedCenter!['latitude'],
        _selectedCenter!['longitude'],
      ) / 1000; // Convert to km
      
      // If user is very close to destination, show arrival notification
      if (distanceRemaining < 0.05) { // 50 meters
        // Show arrival dialog/notification
        if (_isNavigationMode) {
          _showArrivalNotification();
        }
      }
    }
  }
  
  // Show arrival notification
  void _showArrivalNotification() {
    setState(() {
      _isNavigationMode = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You have arrived at ${_selectedCenter!['name']}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Apply filters to service centers
  void _applyFilters() {
    print('Selected filter: $_selectedFilter');
    print('Total service centers: ${_serviceCenters.length}');
    
    // Helper function to normalize strings for comparison
    String normalize(String text) {
      return text.toLowerCase().trim();
    }
    
    _filteredCenters = _serviceCenters.where((center) {
      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final searchText = normalize(_searchController.text);
        final centerName = normalize(center['name']);
        final centerAddress = normalize(center['address']);
        
        if (!centerName.contains(searchText) && !centerAddress.contains(searchText)) {
          return false;
        }
      }
      
      // Apply service type filter
      if (_selectedFilter != 'All') {
        if (_selectedFilter == 'Open Now') {
          return center['isOpen'] == true;
        } else if (_selectedFilter == 'High Rating') {
          return center['rating'] >= 4.0;
        } else {
          // Check if center provides the selected service
          List<dynamic> services = center['services'] ?? [];
          
          // Convert the services to lowercase strings for case-insensitive comparison
          bool hasService = false;
          for (var service in services) {
            String normalizedService = normalize(service.toString());
            String normalizedFilter = normalize(_selectedFilter);
            
            // Look for both exact and partial matches
            if (normalizedService == normalizedFilter || 
                normalizedService.contains(normalizedFilter) || 
                normalizedFilter.contains(normalizedService)) {
              hasService = true;
              break;
            }
          }
          
          // Debug output to help troubleshoot
          print('${center['name']} services: $services, selected filter: $_selectedFilter, match: $hasService');
          
          if (!hasService) {
            return false;
          }
        }
      }
      
      // Apply distance filter
      if (_maxDistance < 100 && _currentPosition != null) {
        // Skip centers without coordinates
        if (center['latitude'] == null || center['longitude'] == null) {
          return false;
        }
        
        final centerLat = center['latitude'];
        final centerLng = center['longitude'];
        
        final distance = _calculateDistance(
          _currentPosition!.latitude, 
          _currentPosition!.longitude, 
          centerLat, 
          centerLng
        );
        
        if (distance > _maxDistance) {
          return false;
        }
      }
      
      // Apply rating filter
      if (center['rating'] < _minRating) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort by distance if we have current position
    if (_currentPosition != null) {
      _filteredCenters.sort((a, b) {
        // Skip centers without coordinates
        if (a['latitude'] == null || a['longitude'] == null) return 1;
        if (b['latitude'] == null || b['longitude'] == null) return -1;
        
        final distanceA = _calculateDistance(
          _currentPosition!.latitude, 
          _currentPosition!.longitude, 
          a['latitude'], 
          a['longitude']
        );
        
        final distanceB = _calculateDistance(
          _currentPosition!.latitude, 
          _currentPosition!.longitude, 
          b['latitude'], 
          b['longitude']
        );
        
        return distanceA.compareTo(distanceB);
      });
    }
    
  }

  // Launch phone call
  Future<void> _launchPhoneCall(String phoneNumber) async {
    // Clean phone number
    phoneNumber = phoneNumber.replaceAll(' ', '').replaceAll('-', '');
    
    // Create URI for calling
    final Uri uri = Uri.parse('tel:$phoneNumber');
    
    try {
      // Open phone app directly
      await launchUrl(uri);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot call number: $phoneNumber')),
      );
      print('Error launching phone call: $e');
    }
  }
  
  // Launch map app with directions
  Future<void> _launchMapDirections(double lat, double lng, String name) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name&travelmode=driving';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Cannot open maps app $uri';
    }
  }

  // Show bottom sheet with service center details
  void _showServiceCenterDetails(Map<String, dynamic> center) {
    setState(() {
      _selectedCenter = center;
      _isDetailsView = true;
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.1,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: const [0.1, 0.3, 0.7, 0.9],
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Improved drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 10),
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          
                          // Image
                          Container(
                            height: 180,
                            width: double.infinity,
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: AssetImage(center['images'][0]),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: center['isOpen']
                                          ? Colors.green.withOpacity(0.8)
                                          : Colors.grey.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      center['isOpen'] ? 'Open Now' : 'Closed',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name and rating
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        center['name'],
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${center['rating']} (${center['reviews']})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Description
                                Text(
                                  center['description'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Address
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Address',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            center['address'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Opening hours
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.access_time,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Working Hours',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            center['openHours'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Distance
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.directions_car,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Distance',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '${center['distance']} km',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '(${_calculateETA(center['distance'])})',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                                
                                // Services offered
                                const Text(
                                  'Services',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (center['services'] as List).map((service) {
                                    IconData serviceIcon;
                                    String translatedService = service;
                                    
                                    // Translate service names
                                    switch (service) {
                                      case 'Maintenance':
                                        serviceIcon = FontAwesomeIcons.wrench;
                                        translatedService = 'Maintenance';
                                        break;
                                      case 'Tires':
                                        serviceIcon = FontAwesomeIcons.road;
                                        translatedService = 'Tires';
                                        break;
                                      case 'Electric':
                                        serviceIcon = FontAwesomeIcons.carBattery;
                                        translatedService = 'Electric';
                                        break;
                                      case 'Oil Change':
                                        serviceIcon = FontAwesomeIcons.oilCan;
                                        translatedService = 'Oil Change';
                                        break;
                                      case 'Body Shops':
                                        serviceIcon = FontAwesomeIcons.sprayCan;
                                        translatedService = 'Body Shops';
                                        break;
                                      case 'Car Wash':
                                        serviceIcon = FontAwesomeIcons.soap;
                                        translatedService = 'Car Wash';
                                        break;
                                      case 'Wheel Alignment':
                                        serviceIcon = FontAwesomeIcons.dharmachakra;
                                        translatedService = 'Wheel Alignment';
                                        break;
                                      case 'Detailing':
                                        serviceIcon = FontAwesomeIcons.brush;
                                        translatedService = 'Detailing';
                                        break;
                                      default:
                                        serviceIcon = FontAwesomeIcons.car;
                                    }
                                    
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            serviceIcon,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            translatedService,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Amenities
                                if ((center['amenities'] as List).isNotEmpty) ...[
                                  const Text(
                                    'Amenities',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: (center['amenities'] as List).map((amenity) {
                                      IconData amenityIcon;
                                      String translatedAmenity = amenity;
                                      
                                      switch (amenity) {
                                        case 'WiFi':
                                          amenityIcon = Icons.wifi;
                                          translatedAmenity = 'WiFi';
                                          break;
                                        case 'Coffee':
                                          amenityIcon = Icons.coffee;
                                          translatedAmenity = 'Coffee';
                                          break;
                                        case 'Waiting Area':
                                          amenityIcon = Icons.chair;
                                          translatedAmenity = 'Waiting Area';
                                          break;
                                        case 'Luxury Waiting Area':
                                          amenityIcon = Icons.chair_alt;
                                          translatedAmenity = 'Luxury Waiting Area';
                                          break;
                                        case 'Premium Lounge':
                                          amenityIcon = Icons.weekend;
                                          translatedAmenity = 'Premium Lounge';
                                          break;
                                        case 'Kid\'s Area':
                                          amenityIcon = Icons.child_care;
                                          translatedAmenity = 'Kid\'s Area';
                                          break;
                                        case 'Pickup Service':
                                          amenityIcon = Icons.airport_shuttle;
                                          translatedAmenity = 'Pickup Service';
                                          break;
                                        case 'Pickup & Delivery':
                                          amenityIcon = Icons.delivery_dining;
                                          translatedAmenity = 'Pickup & Delivery';
                                          break;
                                        case 'Car Pickup & Delivery':
                                          amenityIcon = Icons.local_shipping;
                                          translatedAmenity = 'Car Pickup & Delivery';
                                          break;
                                        case 'Loaner Cars':
                                          amenityIcon = Icons.car_rental;
                                          translatedAmenity = 'Loaner Cars';
                                          break;
                                        case 'TV':
                                          amenityIcon = Icons.tv;
                                          translatedAmenity = 'TV';
                                          break;
                                        case 'Refreshments':
                                          amenityIcon = Icons.restaurant;
                                          translatedAmenity = 'Refreshments';
                                          break;
                                        case 'Snacks':
                                          amenityIcon = Icons.fastfood;
                                          translatedAmenity = 'Snacks';
                                          break;
                                        default:
                                          amenityIcon = Icons.star;
                                      }
                                      
                                      return Chip(
                                        avatar: Icon(
                                          amenityIcon,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
                                        label: Text(
                                          translatedAmenity,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        backgroundColor: Colors.grey[100],
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                
                                // Price list
                                if ((center['prices'] as Map).isNotEmpty) ...[
                                  const Text(
                                    'Price List',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...List.generate(
                                    (center['prices'] as Map).length, 
                                    (index) {
                                      final entry = (center['prices'] as Map).entries.elementAt(index);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              entry.key,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              entry.value,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                
                                const Divider(),
                                const SizedBox(height: 12),
                                
                                // Contact info
                                const Text(
                                  'Contact Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        center['phone'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      ElevatedButton(
                                        onPressed: () => _launchPhoneCall(center['phone']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text(
                                          'Call',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // Close the bottom sheet
                                          Navigator.pop(context);
                                          
                                          // Start navigation
                                          if (_currentPosition != null) {
                                            _getDirections(
                                              LatLng(
                                                _currentPosition!.latitude,
                                                _currentPosition!.longitude,
                                              ),
                                              LatLng(
                                                center['latitude'],
                                                center['longitude'],
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Unable to get your current location.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.directions),
                                        label: const Text('Directions'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _isDetailsView = false;
      });
    });
  }
  
  // Get current location and center map on it
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        
        // Update real distances when user location changes
        _updateServiceCenterDistances();
        
        // Re-apply filters with new distances
        _applyFilters();
        
        // Update the user's location marker
        _updateUserLocationMarker(
          LatLng(position.latitude, position.longitude),
        );
      });
      
      // Animate camera to user's location
      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
      }
      
    } catch (e) {
      print("Error getting current location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get your current location.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Service Centers'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: 'Change Map Type',
              onPressed: () {
                setState(() {
                  _currentMapType = _currentMapType == MapType.normal
                      ? MapType.satellite
                      : MapType.normal;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Filter',
              onPressed: () {
                _showFilterBottomSheet();
              },
            ),
          ],
        ),
        body: _locationPermissionDenied
            ? _buildLocationPermissionDeniedView()
            : _isLoading
                ? _buildLoadingView()
                : Column(
                    children: [
                      // Search bar
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for service centers...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _applyFilters();
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            _applyFilters();
                          },
                          onSubmitted: (value) {
                            _searchAndMoveTo(value);
                          },
                        ),
                      ),
                      
                      // Filter chips
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          itemBuilder: (context, index) {
                            final filter = _filters[index];
                            final isSelected = filter == _selectedFilter;
                            
                            // Set filter color based on category
                            Color chipColor;
                            IconData? chipIcon;
                            
                            if (filter == 'All') {
                              chipColor = Colors.blue;
                              chipIcon = Icons.filter_list;
                            } else if (filter == 'Open Now') {
                              chipColor = Colors.green;
                              chipIcon = Icons.access_time;
                            } else if (filter == 'High Rating') {
                              chipColor = Colors.amber;
                              chipIcon = Icons.star;
                            } else if (filter.contains('Oil')) {
                              chipColor = Colors.orange;
                              chipIcon = Icons.oil_barrel;
                            } else if (filter.contains('Tire') || filter.contains('Wheel')) {
                              chipColor = Colors.brown;
                              chipIcon = Icons.tire_repair;
                            } else if (filter.contains('Electrical')) {
                              chipColor = Colors.indigo;
                              chipIcon = Icons.electrical_services;
                            } else if (filter.contains('Battery')) {
                              chipColor = Colors.purple;
                              chipIcon = Icons.battery_charging_full;
                            } else if (filter.contains('Engine')) {
                              chipColor = Colors.red;
                              chipIcon = Icons.engineering;
                            } else if (filter.contains('Wash') || filter.contains('Detailing')) {
                              chipColor = Colors.lightBlue;
                              chipIcon = Icons.water_drop;
                            } else if (filter.contains('Brake')) {
                              chipColor = Colors.red.shade800;
                              chipIcon = Icons.speed;
                            } else {
                              chipColor = AppColors.primary;
                              chipIcon = null;
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (chipIcon != null) ...[
                                      Icon(
                                        chipIcon,
                                        size: 16,
                                        color: isSelected ? Colors.white : chipColor,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(filter),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                    _applyFilters();
                                  });
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor: chipColor.withOpacity(0.7),
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Selected filters info
                      if (_selectedFilter != 'All' || _minRating > 0 || _maxDistance < 100)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Text(
                                'Applied Filters: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedFilter != 'All')
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Chip(
                                    label: Text(_selectedFilter),
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              if (_minRating > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Chip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 12,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 2),
                                        Text('$_minRating+'),
                                      ],
                                    ),
                                    backgroundColor: Colors.amber.withOpacity(0.1),
                                    labelStyle: const TextStyle(
                                      fontSize: 12,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              if (_maxDistance < 100)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Chip(
                                    label: Text('≤ ${_maxDistance.round()} km'),
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    labelStyle: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = 'All';
                                    _minRating = 0;
                                    _maxDistance = 100;
                                    _applyFilters();
                                  });
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Text(
                                    'Reset',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Map and list view toggle
                      Expanded(
                        child: Stack(
                          children: [
                            // Google Map
                            GoogleMap(
                              initialCameraPosition: _defaultLocation,
                              markers: _markers,
                              polylines: Set<Polyline>.of(_polylines.values),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              mapType: _currentMapType,
                              onMapCreated: (GoogleMapController controller) {
                                if (!_controller.isCompleted) {
                                  _controller.complete(controller);
                                  _mapController = controller;
                                  
                                  // Once the map is created and controller is available, move to user location
                                  if (_currentPosition != null) {
                                    controller.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                          zoom: 14,
                                        ),
                                      ),
                                    );
                                    
                                    // Add markers for service centers
                                    _addMarkers();
                                  }
                                }
                              },
                              onTap: (_) {
                                // Close bottom sheet on map tap for better UX
                                if (_isDetailsView) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                            
                            // Navigation mode overlay
                            if (_isNavigationMode)
                              _buildNavigationOverlay(),
                            
                            // Bottom sheet with service centers list
                            if (!_isNavigationMode)
                              DraggableScrollableSheet(
                                initialChildSize: 0.3,
                                minChildSize: 0.1,
                                maxChildSize: 0.9,
                                snap: true,
                                snapSizes: const [0.1, 0.3, 0.7, 0.9],
                                builder: (context, scrollController) {
                                  return Container(
                                    constraints: BoxConstraints(
                                      minHeight: MediaQuery.of(context).size.height * 0.1,
                                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Handle for dragging
                                        Center(
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 10),
                                            width: 40,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        
                                        // Result count and view options row
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.location_on,
                                                      size: 16,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Found ${_filteredCenters.length} service centers',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  // Sort dropdown
                                                  PopupMenuButton<String>(
                                                    tooltip: 'Sort by',
                                                    padding: EdgeInsets.zero,
                                                    icon: Icon(
                                                      Icons.sort,
                                                      color: AppColors.primary,
                                                      size: 20,
                                                    ),
                                                    onSelected: (value) {
                                                      setState(() {
                                                        _sortCenters(value);
                                                      });
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'distance',
                                                        child: Text('Distance'),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'rating',
                                                        child: Text('Rating'),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'name',
                                                        child: Text('Name'),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // List/Map view toggle
                                                  TextButton.icon(
                                                    onPressed: () {
                                                      setState(() {
                                                        _isListView = !_isListView;
                                                      });
                                                    },
                                                    icon: Icon(
                                                      _isListView ? Icons.map : Icons.list,
                                                      size: 18,
                                                    ),
                                                    label: Text(
                                                      _isListView ? 'Show Map' : 'Show List',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      visualDensity: VisualDensity.compact,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Service Centers List with RefreshIndicator
                                        Expanded(
                                          child: _filteredCenters.isEmpty
                                              ? Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.location_off,
                                                        size: 50,
                                                        color: Colors.grey[400],
                                                      ),
                                                      const SizedBox(height: 16),
                                                      const Text(
                                                        'No service centers match your criteria',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 16),
                                                      TextButton.icon(
                                                        onPressed: () {
                                                          setState(() {
                                                            _selectedFilter = 'All';
                                                            _minRating = 0;
                                                            _maxDistance = 100;
                                                            _searchController.clear();
                                                            _applyFilters();
                                                          });
                                                        },
                                                        icon: const Icon(Icons.refresh),
                                                        label: const Text('Reset Filters'),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : RefreshIndicator(
                                                  onRefresh: () async {
                                                    await _fetchServiceCenters();
                                                    return Future.value();
                                                  },
                                                  color: AppColors.primary,
                                                  child: ListView.builder(
                                                    controller: scrollController,
                                                    physics: const AlwaysScrollableScrollPhysics(),
                                                    itemCount: _filteredCenters.length,
                                                    itemBuilder: (context, index) {
                                                      final center = _filteredCenters[index];
                                                      return Column(
                                                        children: [
                                                          _buildListDivider(index),
                                                          // Clickable list item
                                                          InkWell(
                                                            onTap: () => _onCenterSelected(center),
                                                            child: _buildServiceCenterItem(center),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
        floatingActionButton: _isLoading || _locationPermissionDenied
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // My location button
                  FloatingActionButton(
                    heroTag: 'locationBtn',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _getCurrentLocation,
                    child: Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Navigation mode toggle button
                  if (_isNavigationMode)
                    FloatingActionButton(
                      heroTag: 'exitNavBtn',
                      backgroundColor: Colors.red,
                      onPressed: () {
                        setState(() {
                          _isNavigationMode = false;
                          _polylines.clear();
                          _polylineCoordinates.clear();
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 80), // Space for the draggable sheet
                ],
              ),
      ),
    );
  }

  // Build loading view
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Determining your location...',
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build location permission denied view
  Widget _buildLocationPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Location Access Denied',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We need access to your location to show service centers near you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _initLocationService();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build navigation overlay
  Widget _buildNavigationOverlay() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Directions to ${_selectedCenter?['name'] ?? 'Destination'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedCenter != null)
              Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedCenter!['distance']} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _calculateETA(_selectedCenter!['distance']),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedCenter != null) {
                      _launchMapDirections(
                        _selectedCenter!['latitude'],
                        _selectedCenter!['longitude'],
                        _selectedCenter!['name'],
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open in Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isNavigationMode = false;
                      _polylines.clear();
                      _polylineCoordinates.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Get directions between two points
  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    setState(() {
      _isNavigationMode = true;
      _polylineCoordinates.clear();
      _polylines.clear();
    });
    
    try {
      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=YOUR_API_KEY'
      ));
      
      // Process the result
      if (response.statusCode == 200) {
        // ...
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while getting directions. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Zoom the map to fit the entire route
  
  // Calculate estimated arrival time
  String _calculateETA(double distanceInKm) {
    // Assuming average speed of 40 km/h in city
    double timeInHours = distanceInKm / 40;
    int minutes = (timeInHours * 60).round();
    
    if (minutes < 1) {
      return 'Less than a minute';
    } else if (minutes < 60) {
      return '$minutes minutes';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '$hours hour${hours > 1 ? 's' : ''} $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
    }
  }
  
  // Geocode address to get coordinates
  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }
    return null;
  }
  
  // Search for address and move camera to it
  Future<void> _searchAndMoveTo(String query) async {
    if (query.isEmpty) return;
    
    try {
      LatLng? location = await _geocodeAddress(query);
      if (location != null && _controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: location,
              zoom: 15,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location not found. Please try a different search.'),
          ),
        );
      }
    } catch (e) {
      print('Error searching for location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get your current location.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Service center list item
  Widget _buildServiceCenterItem(Map<String, dynamic> center) {
    return InkWell(
      onTap: () {
        // Navigate to the center's location on the map when clicking the list item
        _navigateToServiceCenterOnMap(center);
        
        // Show center details
        _showServiceCenterDetails(center);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Service center icon/avatar
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                // Add small icon indicating that pressing will navigate to the map
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.map,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Service center info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          center['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${center['rating']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    center['address'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Distance
                      Text(
                        '${center['distance']} km',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Open/Closed status
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: center['isOpen'] ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        center['isOpen'] ? 'Open' : 'Closed',
                        style: TextStyle(
                          color: center['isOpen'] ? Colors.green : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Directions button
            IconButton(
              icon: Icon(
                Icons.directions,
                color: AppColors.primary,
              ),
              onPressed: () {
                // Start navigation if location is available
                if (_currentPosition != null) {
                  _getDirections(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    LatLng(
                      center['latitude'],
                      center['longitude'],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to get your current location.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Navigate to service center on map
  Future<void> _navigateToServiceCenterOnMap(Map<String, dynamic> center) async {
    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      
      // Navigate to the center's location with smooth camera animation
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(center['latitude'], center['longitude']),
            zoom: 16, // Appropriate zoom level to clearly show the center
          ),
        ),
      );
      
      // Show the selected location marker for a few seconds
      setState(() {
        _selectedCenter = center;
      });
      
      // Show a message indicating navigation to the center's location
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigated to ${center['name']} location'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // Show filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Service Centers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  // Filter options
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Distance filter
                          const Text(
                            'Maximum Distance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _maxDistance,
                                  min: 1,
                                  max: 100,
                                  divisions: 99,
                                  label: '${_maxDistance.round()} km',
                                  activeColor: AppColors.primary,
                                  onChanged: (value) {
                                    setState(() {
                                      _maxDistance = value;
                                    });
                                  },
                                ),
                              ),
                              Text(
                                '${_maxDistance.round()} km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Rating filter
                          const Text(
                            'Minimum Rating',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _minRating,
                                  min: 0,
                                  max: 5,
                                  divisions: 10,
                                  label: _minRating.toString(),
                                  activeColor: Colors.amber,
                                  onChanged: (value) {
                                    setState(() {
                                      _minRating = value;
                                    });
                                  },
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _minRating.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Services filter
                          const Text(
                            'Services',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _filters.map((service) {
                              if (service == 'All' || service == 'High Rating') return Container();
                              
                              final isSelected = _selectedFilter == service;
                              return ChoiceChip(
                                label: Text(service),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedFilter = service;
                                    } else {
                                      _selectedFilter = 'All';
                                    }
                                  });
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor: AppColors.primary.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : Colors.black,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          
                          // Open now filter
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Open Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Switch(
                                value: _selectedFilter == 'Open Now',
                                activeColor: AppColors.primary,
                                onChanged: (value) {
                                  setState(() {
                                    if (value) {
                                      _selectedFilter = 'Open Now';
                                    } else if (_selectedFilter == 'Open Now') {
                                      _selectedFilter = 'All';
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Highly rated filter
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'High Rating (4.5+)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Switch(
                                value: _selectedFilter == 'High Rating',
                                activeColor: Colors.amber,
                                onChanged: (value) {
                                  setState(() {
                                    if (value) {
                                      _selectedFilter = 'High Rating';
                                    } else if (_selectedFilter == 'High Rating') {
                                      _selectedFilter = 'All';
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Action buttons
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedFilter = 'All';
                                _maxDistance = 100;
                                _minRating = 0;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              
                              // Apply filters
                              this.setState(() {
                                _applyFilters();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Add markers for each service center
  void _addMarkers() {
    // Only rebuild markers when necessary to improve performance
    if (_markers.length - 1 == _serviceCenters.length && _currentPosition != null) {
      // Markers are already up to date (subtract 1 for current location marker)
      return;
    }
    
    setState(() {
      _markers.clear();
      
      // Add current location marker if available
      if (_currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'Your Current Location',
            ),
          ),
        );
      }
      
      // Add markers for ALL service centers, no limit
      for (final center in _serviceCenters) {
        _markers.add(
          Marker(
            markerId: MarkerId(center['id']),
            position: LatLng(center['latitude'], center['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              center['isOpen'] ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: center['name'],
              snippet: center['address'],
              onTap: () {
                _showServiceCenterDetails(center);
              },
            ),
            onTap: () {
              _showServiceCenterDetails(center);
            },
          ),
        );
      }
    });
  }

  // Calculate the distance between two coordinates in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371.0; // Earth's radius in kilometers
    var dLat = _toRadians(lat2 - lat1);
    var dLon = _toRadians(lon2 - lon1);
    var a = 
      math.sin(dLat/2) * math.sin(dLat/2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * 
      math.sin(dLon/2) * math.sin(dLon/2);
    var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    var d = radius * c; // Distance in kilometers
    return d;
  }
  
  // Convert degrees to radians
  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  // Method to handle sorting centers
  void _sortCenters(String sortBy) {
    switch (sortBy) {
      case 'distance':
        _filteredCenters.sort((a, b) {
          double distanceA = a['distance'] ?? double.maxFinite;
          double distanceB = b['distance'] ?? double.maxFinite;
          return distanceA.compareTo(distanceB);
        });
        break;
      case 'rating':
        _filteredCenters.sort((a, b) {
          double ratingA = a['rating'] ?? 0.0;
          double ratingB = b['rating'] ?? 0.0;
          return ratingB.compareTo(ratingA); // Higher ratings first
        });
        break;
      case 'name':
        _filteredCenters.sort((a, b) {
          String nameA = a['name'] ?? '';
          String nameB = b['name'] ?? '';
          return nameA.compareTo(nameB);
        });
        break;
    }
  }

  // Method to refresh service centers data
  Future<void> _fetchServiceCenters() async {
    // In a real app, this would fetch from an API or database
    // For this demo, we'll just recalculate distances based on current location
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current location to update distances
      await _getCurrentLocation();
      
      // Update open status based on current time
      _updateServiceCentersOpenStatus();
      
      // Reapply filters
      _applyFilters();
    } catch (e) {
      print('Error refreshing service centers: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to build list divider
  Widget _buildListDivider(int index) {
    // No divider for the first item
    if (index == 0) return const SizedBox.shrink();
    
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey[300],
      indent: 16,
      endIndent: 16,
    );
  }


  // Method to handle when a center is selected
  void _onCenterSelected(Map<String, dynamic> center) {
    // Highlight the selected center
    setState(() {
      _selectedCenter = center;
    });
    
    // Navigate to the center's location on the map
    _navigateToServiceCenterOnMap(center);
    
    // Show center details
    _showServiceCenterDetails(center);
  }
} 