class Car {
  final String id;
  final String brand;
  final String? model;
  final String? trim; // Model trim (e.g., SE, LE, Sport, etc)
  final String? engine; // Engine information (e.g., V6 3.5L, 4cyl 2.0L, etc)
  final String? version; // Model version/generation
  final int modelYear;
  final String carNumber;
  final String carLicense;
  final String? imageUrl;
  final String? customerId;
  final String? color;

  Car({
    required this.id,
    required this.brand,
    this.model,
    this.trim,
    this.engine,
    this.version,
    required this.modelYear,
    required this.carNumber,
    required this.carLicense,
    this.imageUrl,
    this.customerId,
    this.color,
  });

  // Convert from Map to Car object
  factory Car.fromMap(Map<String, dynamic> map, String documentId) {
    return Car(
      id: documentId,
      brand: map['brand'] ?? '',
      model: map['model'],
      trim: map['trim'],
      engine: map['engine'],
      version: map['version'],
      modelYear: map['modelYear'] ?? 0,
      carNumber: map['carNumber'] ?? '',
      carLicense: map['carLicense'] ?? '',
      imageUrl: map['imageUrl'],
      customerId: map['customerId'],
      color: map['color'],
    );
  }

  // Convert from Car object to Map (useful for storage)
  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'trim': trim,
      'engine': engine,
      'version': version,
      'modelYear': modelYear,
      'carNumber': carNumber,
      'carLicense': carLicense,
      'imageUrl': imageUrl,
      'customerId': customerId,
      'color': color,
    };
  }

  // Return full model name with trim if available
  String get fullModelName {
    if (trim != null && trim!.isNotEmpty) {
      return '$model $trim';
    }
    return model ?? '';
  }

  // Return full car name with brand, model, year
  String get fullName {
    final List<String> parts = [];
    parts.add(brand);
    
    if (model != null && model!.isNotEmpty) {
      parts.add(model!);
    }
    
    if (trim != null && trim!.isNotEmpty) {
      parts.add(trim!);
    }
    
    parts.add(modelYear.toString());
    
    return parts.join(' ');
  }
}

// Car model information by brand
class CarModels {
  static const List<String> toyota = [
    'Corolla', 'Camry', 'Yaris', 'RAV4', 'Land Cruiser', 'Prado', 
    'Hilux', 'Fortuner', 'Avalon', 'C-HR', 'Highlander', '4Runner',
    'Tacoma', 'Tundra', 'Sequoia', 'Venza', 'Sienna', 'Crown',
    'Supra', 'GR86', 'GR Corolla', 'bZ4X', 'Vellfire', 'Alphard',
    'Corolla Cross', 'Corolla Hatchback', 'Corolla Sedan', 'Corolla Hybrid',
    'Camry Hybrid', 'RAV4 Hybrid', 'RAV4 Prime', 'Highlander Hybrid',
    'Venza Hybrid', 'Sienna Hybrid', 'bZ3', 'bZ5', 'GR Yaris', 'GR Supra',
    'GR86 GT', 'GR Corolla Circuit', 'GR Corolla Morizo', 'Crown Signia',
    'Crown Sport', 'Crown Estate', 'Grand Highlander', 'Tundra Hybrid',
    'Tacoma TRD Pro', '4Runner TRD Pro', 'Sequoia TRD Pro'
  ];

  // Honda models
  static const List<String> honda = [
    'Civic', 'Accord', 'CR-V', 'HR-V', 'Pilot', 'City',
    'Odyssey', 'Ridgeline', 'Passport', 'Fit', 'Insight',
    'Ridgeline', 'Element', 'S2000', 'NSX', 'e:Ny1',
    'Civic Type R', 'Civic Si', 'Civic Hatchback', 'Civic Sedan',
    'Accord Hybrid', 'CR-V Hybrid', 'HR-V Sport', 'Pilot TrailSport',
    'Ridgeline TrailSport', 'Passport TrailSport', 'Odyssey Elite',
    'Fit Sport', 'Insight Touring', 'NSX Type S', 'e:Ny1 Sport',
    'Civic e:HEV', 'ZR-V', 'e:Ny1 GT', 'e:Ny1 Touring'
  ];

  // Nissan models
  static const List<String> nissan = [
    'Altima', 'Maxima', 'Sunny', 'Patrol', 'X-Trail', 'Pathfinder', 'Navara',
    'Kicks', 'Murano', 'Rogue', 'Frontier', 'Titan', 'GT-R', 'Z', 'Leaf',
    'Juke', '370Z', 'NV200', 'NV350', 'NV1500', 'Ariya',
    'Altima SR', 'Maxima SR', 'Patrol NISMO', 'X-Trail e-POWER',
    'Pathfinder Rock Creek', 'Navara PRO-4X', 'Kicks SR',
    'Murano Platinum', 'Rogue Platinum', 'Frontier PRO-4X',
    'Titan PRO-4X', 'GT-R NISMO', 'Z NISMO', 'Leaf SL Plus',
    'Juke NISMO', 'Ariya Venture+', 'Ariya Evolve+', 'Ariya Empower+',
    'Ariya Platinum+', 'NV200 Compact Cargo', 'NV350 HD'
  ];

  // Ford models
  static const List<String> ford = [
    'F-150', 'Mustang', 'Explorer', 'Escape', 'Edge', 'Expedition',
    'Ranger', 'Bronco', 'F-250', 'F-350', 'F-450', 'F-550',
    'Transit', 'E-Transit', 'Mach-E', 'Focus', 'Fusion',
    'EcoSport', 'Flex', 'Super Duty', 'Transit Connect',
    'F-150 Lightning', 'F-150 Raptor', 'F-150 Tremor',
    'Mustang Mach 1', 'Mustang GT', 'Mustang Shelby GT500',
    'Explorer ST', 'Explorer Timberline', 'Escape PHEV',
    'Edge ST', 'Edge ST-Line', 'Expedition MAX',
    'Ranger Raptor', 'Bronco Wildtrak', 'Bronco Badlands',
    'F-250 Tremor', 'F-350 Tremor', 'F-450 Limited',
    'Transit Custom', 'E-Transit Custom', 'Mach-E GT',
    'Focus ST', 'Focus Active', 'Fusion Hybrid',
    'EcoSport ST-Line', 'Flex Limited', 'Super Duty Limited'
  ];

  // BMW models
  static const List<String> bmw = [
    '3 Series', '5 Series', '7 Series', 'X3', 'X5', 'X7', 'M3', 'M5',
    '2 Series', '4 Series', '6 Series', '8 Series', 'X1', 'X2', 'X4', 'X6',
    'M2', 'M4', 'M6', 'M8', 'i3', 'i4', 'i7', 'iX', 'iX3', 'M340i',
    'M550i', 'M760i', 'X3M', 'X4M', 'X5M', 'X6M',
    'M3 Competition', 'M4 Competition', 'M5 CS', 'M8 Competition',
    'i4 M50', 'i7 M70', 'iX M60', 'X3 M40i', 'X4 M40i',
    'X5 M50i', 'X6 M50i', 'M2 Competition', 'M3 Touring',
    'M4 Convertible', 'M6 Gran Coupe', 'M8 Gran Coupe',
    'i3s', 'i4 eDrive35', 'i4 eDrive40', 'i7 eDrive50',
    'iX xDrive50', 'iX3 M Sport', 'X1 M35i', 'X2 M35i'
  ];

  // Mercedes-Benz models
  static const List<String> mercedesBenz = [
    'C-Class', 'E-Class', 'S-Class', 'GLC', 'GLE', 'GLS', 'G-Class',
    'A-Class', 'B-Class', 'CLA', 'CLS', 'EQA', 'EQB', 'EQC', 'EQS',
    'GLA', 'GLB', 'GLE Coupe', 'GLS Maybach', 'AMG GT', 'V-Class',
    'Sprinter', 'Vito', 'Citan', 'EQS SUV', 'EQE', 'EQE SUV',
    'C-Class AMG', 'E-Class AMG', 'S-Class Maybach', 'GLC AMG',
    'GLE AMG', 'GLS AMG', 'G-Class AMG', 'A-Class AMG',
    'CLA AMG', 'CLS AMG', 'EQA 250', 'EQB 300', 'EQC 400',
    'EQS 450+', 'GLA AMG', 'GLB AMG', 'GLE Coupe AMG',
    'AMG GT Black Series', 'V-Class AMG', 'Sprinter Crew',
    'Vito Tourer', 'Citan Tourer', 'EQS SUV 450+',
    'EQE 350', 'EQE SUV 350', 'EQS 580', 'EQS SUV 580'
  ];

  // Hyundai models
  static const List<String> hyundai = [
    'Elantra', 'Sonata', 'Tucson', 'Santa Fe', 'Palisade', 'Accent',
    'Venue', 'Kona', 'Porter', 'Staria', 'Starex', 'H1', 'IONIQ',
    'IONIQ 5', 'IONIQ 6', 'NEXO', 'Genesis', 'Genesis G70',
    'Genesis G80', 'Genesis G90', 'Genesis GV70', 'Genesis GV80',
    'Elantra N', 'Sonata N Line', 'Tucson N Line', 'Santa Fe Calligraphy',
    'Palisade Calligraphy', 'Accent N Line', 'Venue N Line',
    'Kona N', 'Porter II', 'Staria Premium', 'Starex Premium',
    'H1 Premium', 'IONIQ N', 'IONIQ 5 N', 'IONIQ 6 N',
    'NEXO Blue', 'Genesis G70 Shooting Brake', 'Genesis G80 Sport',
    'Genesis G90 Limousine', 'Genesis GV70 Coupe', 'Genesis GV80 Coupe'
  ];

  // Kia models
  static const List<String> kia = [
    'Cerato', 'Optima', 'K5', 'Sportage', 'Sorento', 'Telluride', 'Rio',
    'Forte', 'K3', 'K8', 'K9', 'Soul', 'Seltos', 'EV6', 'EV9',
    'Carnival', 'Mohave', 'Bongo', 'KX3', 'KX5', 'KX7', 'Niro',
    'Stinger', 'XCeed', 'ProCeed', 'Ceed', 'Picanto',
    'Cerato GT', 'K5 GT', 'Sportage GT-Line', 'Sorento SX',
    'Telluride SX', 'Rio GT-Line', 'Forte GT', 'K3 GT',
    'K8 GT', 'K9 Premium', 'Soul GT-Line', 'Seltos GT-Line',
    'EV6 GT', 'EV9 GT-Line', 'Carnival SX', 'Mohave Master',
    'Bongo III', 'KX3 GT-Line', 'KX5 GT-Line', 'KX7 Premium',
    'Niro EV', 'Stinger GT', 'XCeed GT', 'ProCeed GT',
    'Ceed GT', 'Picanto GT-Line'
  ];

  // Audi models
  static const List<String> audi = [
    'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'Q2', 'Q3', 'Q5', 'Q7', 'Q8',
    'RS3', 'RS4', 'RS5', 'RS6', 'RS7', 'RS Q8', 'S3', 'S4', 'S5',
    'S6', 'S7', 'S8', 'SQ5', 'SQ7', 'SQ8', 'e-tron', 'e-tron GT',
    'Q4 e-tron', 'Q8 e-tron', 'RS e-tron GT',
    'A3 Sportback', 'A4 Avant', 'A5 Sportback', 'A6 Avant',
    'A7 Sportback', 'A8 L', 'Q2 Sportback', 'Q3 Sportback',
    'Q5 Sportback', 'Q7 e-tron', 'Q8 e-tron Sportback',
    'RS3 Sportback', 'RS4 Avant', 'RS5 Sportback', 'RS6 Avant',
    'RS7 Sportback', 'RS Q8', 'S3 Sportback', 'S4 Avant',
    'S5 Sportback', 'S6 Avant', 'S7 Sportback', 'S8 L',
    'SQ5 Sportback', 'SQ7', 'SQ8', 'e-tron S', 'e-tron GT RS',
    'Q4 e-tron Sportback', 'Q8 e-tron GT'
  ];

  // موديلات فولكس واجن
  static const List<String> volkswagen = [
    'Golf', 'Passat', 'Tiguan', 'Jetta', 'Arteon', 'Atlas', 'Taos',
    'ID.3', 'ID.4', 'ID.5', 'ID.Buzz', 'Polo', 'T-Roc', 'T-Cross',
    'Touareg', 'Amarok', 'Caddy', 'Transporter', 'Crafter', 'ID.7',
    'Golf GTI', 'Golf R', 'Passat GT', 'Tiguan R', 'Jetta GLI',
    'Arteon R', 'Atlas Cross Sport', 'Taos SEL', 'ID.3 Pro S',
    'ID.4 Pro', 'ID.5 GTX', 'ID.Buzz Cargo', 'Polo GTI',
    'T-Roc R', 'T-Cross R-Line', 'Touareg R', 'Amarok V6',
    'Caddy Cargo', 'Transporter Caravelle', 'Crafter Panel Van',
    'ID.7 Pro', 'Golf GTD', 'Passat Alltrack', 'Tiguan Allspace',
    'Jetta Sport', 'Arteon Shooting Brake', 'Atlas Basecamp',
    'Taos 4Motion', 'ID.3 Tour', 'ID.4 AWD', 'ID.5 Pro S',
    'ID.Buzz Pro', 'Polo R-Line', 'T-Roc Cabriolet', 'T-Cross 4Motion'
  ];

  // موديلات بورش
  static const List<String> porsche = [
    '911', 'Cayenne', 'Macan', 'Panamera', 'Taycan', '718 Cayman',
    '718 Boxster', 'Cayenne Coupe', 'Macan GTS', 'Panamera GTS',
    'Taycan Cross Turismo', 'Taycan Sport Turismo', '911 GT3',
    '911 GT3 RS', '911 Turbo', '911 Turbo S', 'Cayenne Turbo',
    'Panamera Turbo', 'Taycan Turbo', 'Taycan Turbo S',
    '911 Carrera', '911 Carrera S', '911 Carrera GTS',
    '911 Targa', '911 Targa 4', '911 Targa 4S', '911 Dakar',
    'Cayenne S', 'Cayenne GTS', 'Cayenne Turbo GT', 'Cayenne E-Hybrid',
    'Macan S', 'Macan T', 'Macan GTS', 'Macan Turbo',
    'Panamera 4', 'Panamera 4S', 'Panamera 4 E-Hybrid',
    'Taycan 4S', 'Taycan GTS', 'Taycan Turbo Cross Turismo',
    '718 Cayman S', '718 Cayman GTS', '718 Boxster S',
    '718 Boxster GTS', '911 GT3 Touring', '911 GT3 RS Weissach'
  ];

  // موديلات لكزس
  static const List<String> lexus = [
    'ES', 'IS', 'LS', 'NX', 'RX', 'GX', 'LX', 'UX', 'RC', 'LC',
    'NX Hybrid', 'RX Hybrid', 'ES Hybrid', 'LS Hybrid', 'UX Hybrid',
    'RC F', 'LC 500', 'GX 460', 'LX 600', 'NX 350', 'RX 350',
    'RX 450h', 'ES 300h', 'IS 300', 'IS 350',
    'ES F Sport', 'IS F Sport', 'LS F Sport', 'NX F Sport',
    'RX F Sport', 'UX F Sport', 'RC F Sport', 'LC 500h',
    'GX 550', 'LX 570', 'NX 450h+', 'RX 500h', 'ES 250',
    'IS 500', 'LS 500', 'NX 250', 'RX 350L', 'UX 250h',
    'RC 300', 'LC Convertible', 'GX Black Line', 'LX Inspiration',
    'NX Black Line', 'RX Black Line', 'ES Ultra Luxury',
    'LS Executive', 'NX Executive', 'RX Executive'
  ];

  // موديلات إنفينيتي
  static const List<String> infiniti = [
    'Q50', 'Q60', 'Q70', 'QX50', 'QX55', 'QX60', 'QX80',
    'Q30', 'Q40', 'Q70L', 'QX30', 'QX70', 'QX80', 'Q Inspiration',
    'QX Inspiration', 'Project Black S', 'Q60 Project Black S',
    'Q50 Red Sport', 'Q60 Red Sport', 'Q70 5.6', 'QX50 Sensory',
    'QX55 Sensory', 'QX60 Sensory', 'QX80 Sensory', 'Q30 Sport',
    'Q40 Sport', 'Q70L Sport', 'QX30 Sport', 'QX70 Sport',
    'QX80 Sport', 'Q Inspiration Concept', 'QX Inspiration Concept',
    'Q60 Project Black S', 'Q50 Project Black S', 'Q70 Project Black S'
  ];

  // موديلات جينيسيس
  static const List<String> genesis = [
    'G70', 'G80', 'G90', 'GV70', 'GV80', 'GV60', 'G70 Shooting Brake',
    'G80 Sport', 'G90 L', 'GV70 Sport', 'GV80 Sport', 'GV60 Performance',
    'G70 3.3T', 'G80 3.5T', 'G90 3.3T', 'GV70 3.5T', 'GV80 3.5T',
    'GV60 Standard', 'G70 2.0T', 'G80 2.5T', 'G90 5.0L', 'GV70 2.5T',
    'GV80 2.5T', 'GV60 Advanced', 'G70 Sport', 'G80 Electrified',
    'G90 Sport', 'GV70 Electrified', 'GV80 Electrified', 'GV60 Sport',
    'G70 Dynamic', 'G80 Dynamic', 'G90 Dynamic', 'GV70 Dynamic',
    'GV80 Dynamic', 'GV60 Dynamic', 'G70 Prestige', 'G80 Prestige',
    'G90 Prestige', 'GV70 Prestige', 'GV80 Prestige', 'GV60 Prestige'
  ];

  // موديلات تسلا
  static const List<String> tesla = [
    'Model S', 'Model 3', 'Model X', 'Model Y', 'Cybertruck',
    'Model S Plaid', 'Model 3 Performance', 'Model X Plaid',
    'Model Y Performance', 'Model S Long Range', 'Model 3 Long Range',
    'Model X Long Range', 'Model Y Long Range', 'Model S Standard Range',
    'Model 3 Standard Range', 'Model X Standard Range', 'Model Y Standard Range',
    'Model S Dual Motor', 'Model 3 Dual Motor', 'Model X Dual Motor',
    'Model Y Dual Motor', 'Model S Tri Motor', 'Model 3 Single Motor',
    'Model X Tri Motor', 'Model Y Single Motor', 'Model S Performance',
    'Model 3 Standard Range Plus', 'Model X Performance', 'Model Y Standard Range Plus',
    'Model S Raven', 'Model 3 Mid Range', 'Model X Raven', 'Model Y Mid Range',
    'Model S Refresh', 'Model 3 Highland', 'Model X Refresh', 'Model Y Highland',
    'Model S Plaid Plus', 'Model 3 Plaid', 'Model X Plaid Plus', 'Model Y Plaid'
  ];

  // موديلات رولز رويس
  static const List<String> rollsRoyce = [
    'Phantom', 'Ghost', 'Cullinan', 'Wraith', 'Dawn', 'Phantom Extended',
    'Ghost Extended', 'Cullinan Extended', 'Wraith Extended', 'Dawn Extended',
    'Phantom Black Badge', 'Ghost Black Badge', 'Cullinan Black Badge',
    'Wraith Black Badge', 'Dawn Black Badge', 'Phantom Series II',
    'Ghost Series II', 'Cullinan Series II', 'Wraith Series II', 'Dawn Series II',
    'Phantom Coupe', 'Ghost Coupe', 'Cullinan Coupe', 'Wraith Coupe', 'Dawn Coupe',
    'Phantom Convertible', 'Ghost Convertible', 'Cullinan Convertible',
    'Wraith Convertible', 'Dawn Convertible', 'Phantom Limousine',
    'Ghost Limousine', 'Cullinan Limousine', 'Wraith Limousine', 'Dawn Limousine',
    'Phantom Bespoke', 'Ghost Bespoke', 'Cullinan Bespoke', 'Wraith Bespoke',
    'Dawn Bespoke', 'Phantom Coachbuild', 'Ghost Coachbuild', 'Cullinan Coachbuild',
    'Wraith Coachbuild', 'Dawn Coachbuild'
  ];

  // موديلات بنتلي
  static const List<String> bentley = [
    'Continental GT', 'Flying Spur', 'Bentayga', 'Mulsanne', 'Continental GTC',
    'Continental GT Speed', 'Flying Spur Speed', 'Bentayga Speed', 'Mulsanne Speed',
    'Continental GTC Speed', 'Continental GT V8', 'Flying Spur V8', 'Bentayga V8',
    'Mulsanne V8', 'Continental GTC V8', 'Continental GT W12', 'Flying Spur W12',
    'Bentayga W12', 'Mulsanne W12', 'Continental GTC W12', 'Continental GT Mulliner',
    'Flying Spur Mulliner', 'Bentayga Mulliner', 'Mulsanne Mulliner', 'Continental GTC Mulliner',
    'Continental GT Azure', 'Flying Spur Azure', 'Bentayga Azure', 'Mulsanne Azure',
    'Continental GTC Azure', 'Continental GT Supersports', 'Flying Spur Supersports',
    'Bentayga Supersports', 'Mulsanne Supersports', 'Continental GTC Supersports',
    'Continental GT Convertible', 'Flying Spur Convertible', 'Bentayga Convertible',
    'Mulsanne Convertible', 'Continental GTC Convertible', 'Continental GT Hybrid',
    'Flying Spur Hybrid', 'Bentayga Hybrid', 'Mulsanne Hybrid', 'Continental GTC Hybrid'
  ];

  // موديلات فيراري
  static const List<String> ferrari = [
    'F8', 'SF90', '296', '812', 'Roma', 'Portofino', 'SF90 Stradale',
    'F8 Tributo', '296 GTB', '812 GTS', 'Roma Spider', 'Portofino M',
    'SF90 Spider', 'F8 Spider', '296 GTS', '812 Competizione',
    'Roma GT', 'Portofino M Spider', 'SF90 XX', 'F8 GT', '296 GT3',
    '812 Competizione A', 'Roma GT Spider', 'Portofino M GT',
    'SF90 XX Spider', 'F8 GT Spider', '296 GT3 RS', '812 Competizione T',
    'Roma GT Coupe', 'Portofino M GT Spider', 'SF90 XX Stradale',
    'F8 GT Coupe', '296 GT3 RS Spider', '812 Competizione S',
    'Roma GT Spider', 'Portofino M GT Coupe', 'SF90 XX Spider',
    'F8 GT Spider', '296 GT3 RS Coupe', '812 Competizione T Spider',
    'Roma GT Coupe', 'Portofino M GT Spider'
  ];

  // موديلات لامبورجيني
  static const List<String> lamborghini = [
    'Huracán', 'Aventador', 'Urus', 'Revuelto', 'Huracán STO',
    'Aventador SVJ', 'Urus S', 'Revuelto Performante', 'Huracán Tecnica',
    'Aventador Ultimae', 'Urus Performante', 'Revuelto S', 'Huracán EVO',
    'Aventador S', 'Urus SVR', 'Revuelto Performante S', 'Huracán RWD',
    'Aventador SV', 'Urus SVR', 'Revuelto SVR', 'Huracán Spyder',
    'Aventador Roadster', 'Urus SVR Spyder', 'Revuelto SVR Spyder',
    'Huracán Performante', 'Aventador SVJ Roadster', 'Urus SVR Coupe',
    'Revuelto SVR Coupe', 'Huracán EVO Spyder', 'Aventador S Roadster',
    'Urus SVR Convertible', 'Revuelto SVR Convertible', 'Huracán RWD Spyder',
    'Aventador SV Roadster', 'Urus SVR SUV', 'Revuelto SVR SUV',
    'Huracán STO Spyder', 'Aventador Ultimae Roadster', 'Urus SVR GT',
    'Revuelto SVR GT', 'Huracán Tecnica Spyder', 'Aventador SVR',
    'Urus SVR GT Spyder', 'Revuelto SVR GT Spyder'
  ];

  // موديلات مازيراتي
  static const List<String> maserati = [
    'Ghibli', 'Levante', 'Quattroporte', 'MC20', 'Grecale',
    'Ghibli Trofeo', 'Levante Trofeo', 'Quattroporte Trofeo',
    'MC20 Cielo', 'Grecale Trofeo', 'Ghibli Hybrid', 'Levante Hybrid',
    'Quattroporte Hybrid', 'MC20 GT', 'Grecale Hybrid', 'Ghibli Modena',
    'Levante Modena', 'Quattroporte Modena', 'MC20 GT2', 'Grecale Modena',
    'Ghibli GT', 'Levante GT', 'Quattroporte GT', 'MC20 GT3',
    'Grecale GT', 'Ghibli S', 'Levante S', 'Quattroporte S',
    'MC20 GT4', 'Grecale S', 'Ghibli S Q4', 'Levante S Q4',
    'Quattroporte S Q4', 'MC20 GT5', 'Grecale S Q4', 'Ghibli S Q4 GranLusso',
    'Levante S Q4 GranLusso', 'Quattroporte S Q4 GranLusso', 'MC20 GT6',
    'Grecale S Q4 GranLusso', 'Ghibli S Q4 GranSport', 'Levante S Q4 GranSport',
    'Quattroporte S Q4 GranSport', 'MC20 GT7', 'Grecale S Q4 GranSport'
  ];

  // موديلات أستون مارتن
  static const List<String> astonMartin = [
    'DB11', 'DBX', 'Vantage', 'DBS', 'DBX707', 'Vantage F1 Edition',
    'DBX Straight-Six', 'DB11 V8', 'DB11 V12', 'Vantage V8',
    'Vantage V12', 'DBS Superleggera', 'DBS Volante', 'DBX V8',
    'Vantage Roadster', 'DB11 Volante',
    'DB11 AMR', 'DBX707', 'Vantage F1 Edition', 'DBS Superleggera',
    'DBX Straight-Six', 'DB11 V8', 'DB11 V12', 'Vantage V8',
    'Vantage V12', 'DBS Superleggera', 'DBS Volante', 'DBX V8',
    'Vantage Roadster', 'DB11 Volante', 'DB11 AMR', 'DBX707',
    'Vantage F1 Edition', 'DBS Superleggera', 'DBX Straight-Six',
    'DB11 V8', 'DB11 V12', 'Vantage V8', 'Vantage V12',
    'DBS Superleggera', 'DBS Volante', 'DBX V8', 'Vantage Roadster',
    'DB11 Volante', 'DB11 AMR', 'DBX707', 'Vantage F1 Edition',
    'DBS Superleggera', 'DBX Straight-Six', 'DB11 V8', 'DB11 V12',
    'Vantage V8', 'Vantage V12', 'DBS Superleggera', 'DBS Volante',
    'DBX V8', 'Vantage Roadster', 'DB11 Volante', 'DB11 AMR'
  ];

  // موديلات ماكلارين
  static const List<String> mclaren = [
    '720S', '765LT', 'Artura', 'GT', '570S', '600LT',
    'Senna', 'Speedtail', 'Elva', 'F1', 'P1', '650S',
    '675LT', '570GT', '540C', '600LT Spider', '720S Spider',
    '765LT Spider', 'Artura Spider',
    '720S GT3', '765LT Spider', 'Artura GT4', 'GT3',
    '570S GT4', '600LT Spider', 'Senna GTR', 'Speedtail',
    'Elva M1A', 'F1 GTR', 'P1 GTR', '650S GT3',
    '675LT Spider', '570GT Spider', '540C Spider',
    '600LT Spider', '720S Spider', '765LT Spider',
    'Artura Spider', '720S GT3', '765LT Spider',
    'Artura GT4', 'GT3', '570S GT4', '600LT Spider',
    'Senna GTR', 'Speedtail', 'Elva M1A', 'F1 GTR',
    'P1 GTR', '650S GT3', '675LT Spider', '570GT Spider',
    '540C Spider', '600LT Spider', '720S Spider', '765LT Spider',
    'Artura Spider', '720S GT3', '765LT Spider', 'Artura GT4'
  ];

  // موديلات بوغاتي
  static const List<String> bugatti = [
    'Chiron', 'Divo', 'Centodieci', 'La Voiture Noire',
    'Chiron Super Sport', 'Chiron Sport', 'Chiron Profilée',
    'Mistral', 'Bolide', 'Chiron Pur Sport', 'Chiron Noire',
    'Chiron Super Sport 300+', 'Divo Lady Bug', 'Centodieci',
    'Chiron Profilée', 'Mistral', 'Bolide', 'Chiron Pur Sport',
    'Chiron Noire', 'Chiron Super Sport 300+', 'Divo Lady Bug',
    'Centodieci', 'Chiron Profilée', 'Mistral', 'Bolide',
    'Chiron Pur Sport', 'Chiron Noire', 'Chiron Super Sport 300+',
    'Divo Lady Bug', 'Centodieci', 'Chiron Profilée', 'Mistral',
    'Bolide', 'Chiron Pur Sport', 'Chiron Noire', 'Chiron Super Sport 300+',
    'Divo Lady Bug', 'Centodieci', 'Chiron Profilée', 'Mistral',
    'Bolide', 'Chiron Pur Sport', 'Chiron Noire', 'Chiron Super Sport 300+',
    'Divo Lady Bug', 'Centodieci', 'Chiron Profilée', 'Mistral'
  ];

  // موديلات كاديلاك
  static const List<String> cadillac = [
    'CT4', 'CT5', 'CT6', 'XT4', 'XT5', 'XT6', 'Escalade',
    'Lyriq', 'Celestiq', 'CT4-V', 'CT5-V', 'CT4-V Blackwing',
    'CT5-V Blackwing', 'Escalade-V', 'XT6-V', 'XT5-V',
    'CT4 Premium Luxury', 'CT5 Premium Luxury', 'CT6 Premium Luxury',
    'XT4 Sport', 'XT5 Sport', 'XT6 Sport', 'Escalade ESV',
    'Lyriq AWD', 'Celestiq AWD', 'CT4-V Sport', 'CT5-V Sport',
    'CT4-V Blackwing', 'CT5-V Blackwing', 'Escalade-V Sport',
    'XT6-V Sport', 'XT5-V Sport', 'CT4 Luxury', 'CT5 Luxury',
    'CT6 Luxury', 'XT4 Luxury', 'XT5 Luxury', 'XT6 Luxury',
    'Escalade Luxury', 'Lyriq Luxury', 'Celestiq Luxury',
    'CT4-V Luxury', 'CT5-V Luxury', 'CT4-V Blackwing Luxury',
    'CT5-V Blackwing Luxury', 'Escalade-V Luxury', 'XT6-V Luxury',
    'XT5-V Luxury'
  ];

  // موديلات جيب
  static const List<String> jeep = [
    'Wrangler', 'Grand Cherokee', 'Cherokee', 'Compass',
    'Renegade', 'Gladiator', 'Grand Wagoneer', 'Wagoneer',
    'Grand Cherokee L', 'Grand Cherokee 4xe', 'Wrangler 4xe',
    'Compass 4xe', 'Renegade 4xe', 'Grand Cherokee SRT',
    'Grand Cherokee Trackhawk',
    'Wrangler Rubicon', 'Grand Cherokee Summit', 'Cherokee Trailhawk',
    'Compass Trailhawk', 'Renegade Trailhawk', 'Gladiator Rubicon',
    'Grand Wagoneer Series III', 'Wagoneer Series III',
    'Grand Cherokee L Summit', 'Grand Cherokee 4xe Trailhawk',
    'Wrangler 4xe Rubicon', 'Compass 4xe Trailhawk',
    'Renegade 4xe Trailhawk', 'Grand Cherokee SRT Trackhawk',
    'Grand Cherokee Trackhawk', 'Wrangler Rubicon 392',
    'Grand Cherokee Summit Reserve', 'Cherokee Trailhawk Elite',
    'Compass Trailhawk Elite', 'Renegade Trailhawk Elite',
    'Gladiator Rubicon 392', 'Grand Wagoneer Series III',
    'Wagoneer Series III', 'Grand Cherokee L Summit Reserve',
    'Grand Cherokee 4xe Trailhawk Elite', 'Wrangler 4xe Rubicon 392',
    'Compass 4xe Trailhawk Elite', 'Renegade 4xe Trailhawk Elite',
    'Grand Cherokee SRT Trackhawk Elite', 'Grand Cherokee Trackhawk Elite'
  ];

  // موديلات دودج
  static const List<String> dodge = [
    'Challenger', 'Charger', 'Durango', 'Challenger SRT',
    'Charger SRT', 'Durango SRT', 'Challenger Hellcat',
    'Charger Hellcat', 'Durango Hellcat', 'Challenger Demon',
    'Challenger Redeye', 'Charger Redeye', 'Charger Scat Pack',
    'Charger Scat Pack', 'Durango SRT Hellcat',
    'Challenger R/T', 'Charger R/T', 'Durango R/T',
    'Challenger SRT Hellcat', 'Charger SRT Hellcat',
    'Durango SRT Hellcat', 'Challenger Hellcat Redeye',
    'Charger Hellcat Redeye', 'Durango Hellcat Redeye',
    'Challenger Demon 170', 'Challenger Redeye 170',
    'Charger Redeye 170', 'Challenger Scat Pack Widebody',
    'Charger Scat Pack Widebody', 'Durango SRT Hellcat Widebody',
    'Challenger R/T Scat Pack', 'Charger R/T Scat Pack',
    'Durango R/T Scat Pack', 'Challenger SRT Hellcat Widebody',
    'Charger SRT Hellcat Widebody', 'Durango SRT Hellcat Widebody',
    'Challenger Hellcat Redeye Widebody', 'Charger Hellcat Redeye Widebody',
    'Durango Hellcat Redeye Widebody', 'Challenger Demon 170 Widebody',
    'Challenger Redeye 170 Widebody', 'Charger Redeye 170 Widebody',
    'Challenger Scat Pack Widebody', 'Charger Scat Pack Widebody',
    'Durango SRT Hellcat Widebody', 'Challenger R/T Scat Pack Widebody',
    'Charger R/T Scat Pack Widebody', 'Durango R/T Scat Pack Widebody'
  ];

  // موديلات شيفروليه
  static const List<String> chevrolet = [
    'Camaro', 'Corvette', 'Silverado', 'Tahoe', 'Suburban',
    'Equinox', 'Traverse', 'Blazer', 'Malibu', 'Spark',
    'Trax', 'Colorado', 'Express', 'Sonic', 'Bolt',
    'Corvette Z06', 'Corvette Stingray', 'Silverado EV',
    'Blazer EV', 'Equinox EV',
    'Camaro ZL1', 'Corvette ZR1', 'Silverado HD', 'Tahoe RST',
    'Suburban RST', 'Equinox RS', 'Traverse RS', 'Blazer RS',
    'Malibu RS', 'Spark RS', 'Trax RS', 'Colorado ZR2',
    'Express 3500', 'Sonic RS', 'Bolt EUV', 'Corvette Z06 Convertible',
    'Corvette Stingray Convertible', 'Silverado EV RST',
    'Blazer EV RS', 'Equinox EV RS', 'Camaro ZL1 1LE',
    'Corvette ZR1 Convertible', 'Silverado HD High Country',
    'Tahoe RST Performance', 'Suburban RST Performance',
    'Equinox RS AWD', 'Traverse RS AWD', 'Blazer RS AWD',
    'Malibu RS AWD', 'Spark RS AWD', 'Trax RS AWD',
    'Colorado ZR2 Bison', 'Express 4500', 'Sonic RS AWD',
    'Bolt EUV Premier', 'Corvette Z06 Convertible 3LT',
    'Corvette Stingray Convertible 3LT', 'Silverado EV RST First Edition',
    'Blazer EV RS First Edition', 'Equinox EV RS First Edition'
  ];

  // موديلات جي إم سي
  static const List<String> gmc = [
    'Sierra', 'Sierra HD', 'Sierra 1500', 'Sierra 2500HD',
    'Sierra 3500HD', 'Sierra AT4', 'Sierra Denali', 'Sierra Elevation',
    'Sierra Pro', 'Sierra SLT', 'Sierra SLE', 'Sierra SL', 'Sierra Base',
    'Sierra CarbonPro', 'Sierra Denali Ultimate', 'Sierra AT4X',
    'Sierra 1500 Limited', 'Sierra 2500HD Denali', 'Sierra 3500HD Denali',
    'Sierra 1500 Elevation', 'Sierra 2500HD AT4', 'Sierra 3500HD AT4',
    'Sierra 1500 Pro', 'Sierra 2500HD SLT', 'Sierra 3500HD SLT',
    'Sierra 1500 SL', 'Sierra 2500HD SLE', 'Sierra 3500HD SLE',
    'Sierra 1500 Base', 'Sierra 2500HD SL', 'Sierra 3500HD SL',
    'Sierra 1500 CarbonPro', 'Sierra 2500HD Base', 'Sierra 3500HD Base',
    'Sierra 1500 Denali Ultimate', 'Sierra 2500HD CarbonPro',
    'Sierra 3500HD CarbonPro', 'Sierra 1500 AT4X', 'Sierra 2500HD Denali Ultimate',
    'Sierra 3500HD Denali Ultimate', 'Sierra 1500 Limited', 'Sierra 2500HD AT4X',
    'Sierra 3500HD AT4X'
  ];

  // موديلات لاند روفر
  static const List<String> landRover = [
    'Defender', 'Discovery', 'Discovery Sport', 'Range Rover',
    'Range Rover Sport', 'Range Rover Velar', 'Range Rover Evoque',
    'Defender 90', 'Defender 110', 'Defender 130', 'Range Rover L',
    'Range Rover Sport SVR', 'Range Rover PHEV', 'Defender PHEV',
    'Discovery Sport PHEV',
    'Defender V8', 'Discovery HSE', 'Discovery Sport HSE',
    'Range Rover Autobiography', 'Range Rover Sport HSE',
    'Range Rover Velar R-Dynamic', 'Range Rover Evoque R-Dynamic',
    'Defender 90 P300', 'Defender 110 P400', 'Defender 130 P400',
    'Range Rover L Autobiography', 'Range Rover Sport SVR',
    'Range Rover PHEV', 'Defender PHEV', 'Discovery Sport PHEV',
    'Defender V8', 'Discovery HSE', 'Discovery Sport HSE',
    'Range Rover Autobiography', 'Range Rover Sport HSE',
    'Range Rover Velar R-Dynamic', 'Range Rover Evoque R-Dynamic',
    'Defender 90 P300', 'Defender 110 P400', 'Defender 130 P400',
    'Range Rover L Autobiography', 'Range Rover Sport SVR',
    'Range Rover PHEV', 'Defender PHEV', 'Discovery Sport PHEV',
    'Defender V8', 'Discovery HSE', 'Discovery Sport HSE',
    'Range Rover Autobiography', 'Range Rover Sport HSE',
    'Range Rover Velar R-Dynamic', 'Range Rover Evoque R-Dynamic',
    'Defender 90 P300', 'Defender 110 P400', 'Defender 130 P400',
    'Range Rover L Autobiography', 'Range Rover Sport SVR'
  ];

  // موديلات جاكوار
  static const List<String> jaguar = [
    'F-Type', 'XE', 'XF', 'XJ', 'E-Pace', 'F-Pace', 'I-Pace',
    'F-Type R', 'F-Type SVR', 'F-Pace SVR', 'I-Pace HSE',
    'XE Project 8', 'XF Sportbrake', 'XJ L', 'F-Type Convertible',
    'F-Type P300', 'XE P300', 'XF P300', 'XJ P300',
    'E-Pace P300', 'F-Pace P300', 'I-Pace HSE', 'F-Type R-Dynamic',
    'F-Type SVR', 'F-Pace SVR', 'I-Pace HSE', 'XE Project 8',
    'XF Sportbrake', 'XJ L', 'F-Type Convertible', 'F-Type P300',
    'XE P300', 'XF P300', 'XJ P300', 'E-Pace P300', 'F-Pace P300',
    'I-Pace HSE', 'F-Type R-Dynamic', 'F-Type SVR', 'F-Pace SVR',
    'I-Pace HSE', 'XE Project 8', 'XF Sportbrake', 'XJ L',
    'F-Type Convertible', 'F-Type P300', 'XE P300', 'XF P300',
    'XJ P300', 'E-Pace P300', 'F-Pace P300', 'I-Pace HSE',
    'F-Type R-Dynamic', 'F-Type SVR', 'F-Pace SVR', 'I-Pace HSE'
  ];

  // موديلات فولفو
  static const List<String> volvo = [
    'S60', 'S90', 'V60', 'V90', 'XC40', 'XC60', 'XC90',
    'S60 Recharge', 'S90 Recharge', 'V60 Recharge', 'V90 Recharge',
    'XC40 Recharge', 'XC60 Recharge', 'XC90 Recharge',
    'C40 Recharge', 'V60 Cross Country', 'V90 Cross Country',
    'S60 Polestar', 'S90 Polestar', 'V60 Polestar',
    'V90 Polestar', 'XC40 Polestar', 'XC60 Polestar',
    'XC90 Polestar', 'S60 Recharge Polestar', 'S90 Recharge Polestar',
    'V60 Recharge Polestar', 'V90 Recharge Polestar',
    'XC40 Recharge Polestar', 'XC60 Recharge Polestar',
    'XC90 Recharge Polestar', 'C40 Recharge Polestar',
    'V60 Cross Country Polestar', 'V90 Cross Country Polestar',
    'S60 R-Design', 'S90 R-Design', 'V60 R-Design',
    'V90 R-Design', 'XC40 R-Design', 'XC60 R-Design',
    'XC90 R-Design', 'S60 Recharge R-Design', 'S90 Recharge R-Design',
    'V60 Recharge R-Design', 'V90 Recharge R-Design',
    'XC40 Recharge R-Design', 'XC60 Recharge R-Design',
    'XC90 Recharge R-Design', 'C40 Recharge R-Design',
    'V60 Cross Country R-Design', 'V90 Cross Country R-Design'
  ];

  // موديلات ألفا روميو
  static const List<String> alfaRomeo = [
    'Giulia', 'Stelvio', 'Giulietta', 'Tonale', '4C',
    'Giulia Quadrifoglio', 'Stelvio Quadrifoglio',
    'Giulia GTA', 'Giulia GTAm', 'Tonale PHEV',
    'Giulia Ti', 'Stelvio Ti', 'Giulia Ti Sport',
    'Stelvio Ti Sport', 'Giulia Sprint',
    'Giulia Ti Lusso', 'Stelvio Ti Lusso', 'Giulietta Veloce',
    'Tonale Veloce', '4C Spider', 'Giulia Quadrifoglio Verde',
    'Stelvio Quadrifoglio Verde', 'Giulia GTA', 'Giulia GTAm',
    'Tonale PHEV Veloce', 'Giulia Ti Sport', 'Stelvio Ti Sport',
    'Giulia Ti Sport', 'Stelvio Ti Sport', 'Giulia Sprint',
    'Giulia Ti Lusso', 'Stelvio Ti Lusso', 'Giulietta Veloce',
    'Tonale Veloce', '4C Spider', 'Giulia Quadrifoglio Verde',
    'Stelvio Quadrifoglio Verde', 'Giulia GTA', 'Giulia GTAm',
    'Tonale PHEV Veloce', 'Giulia Ti Sport', 'Stelvio Ti Sport',
    'Giulia Ti Sport', 'Stelvio Ti Sport', 'Giulia Sprint',
    'Giulia Ti Lusso', 'Stelvio Ti Lusso', 'Giulietta Veloce',
    'Tonale Veloce', '4C Spider', 'Giulia Quadrifoglio Verde',
    'Stelvio Quadrifoglio Verde', 'Giulia GTA', 'Giulia GTAm',
    'Tonale PHEV Veloce', 'Giulia Ti Sport', 'Stelvio Ti Sport'
  ];

  // موديلات فيات
  static const List<String> fiat = [
    '500', '500X', '500e', 'Panda', 'Tipo', '500 Hybrid', '500X Hybrid',
    '500e Electric', 'Panda Hybrid', 'Tipo Hybrid', '500 Sport', '500X Sport',
    '500e Sport', 'Panda Sport', 'Tipo Sport', '500 Lounge', '500X Lounge',
    '500e Lounge', 'Panda Lounge', 'Tipo Lounge', '500 Pop', '500X Pop',
    '500e Pop', 'Panda Pop', 'Tipo Pop', '500 Dolcevita', '500X Dolcevita',
    '500e Dolcevita', 'Panda Dolcevita', 'Tipo Dolcevita', '500 Red',
    '500X Red', '500e Red', 'Panda Red', 'Tipo Red', '500 Star',
    '500X Star', '500e Star', 'Panda Star', 'Tipo Star', '500 Rock',
    '500X Rock', '500e Rock', 'Panda Rock', 'Tipo Rock', '500 City',
    '500X City', '500e City', 'Panda City', 'Tipo City'
  ];

  // موديلات رينو
  static const List<String> renault = [
    'Clio', 'Captur', 'Megane', 'Kadjar', 'Talisman', 'Clio E-Tech',
    'Captur E-Tech', 'Megane E-Tech', 'Kadjar E-Tech', 'Talisman E-Tech',
    'Clio RS', 'Captur RS', 'Megane RS', 'Kadjar RS', 'Talisman RS',
    'Clio GT', 'Captur GT', 'Megane GT', 'Kadjar GT', 'Talisman GT',
    'Clio Iconic', 'Captur Iconic', 'Megane Iconic', 'Kadjar Iconic',
    'Talisman Iconic', 'Clio S Edition', 'Captur S Edition', 'Megane S Edition',
    'Kadjar S Edition', 'Talisman S Edition', 'Clio R.S. Line', 'Captur R.S. Line',
    'Megane R.S. Line', 'Kadjar R.S. Line', 'Talisman R.S. Line', 'Clio Initiale',
    'Captur Initiale', 'Megane Initiale', 'Kadjar Initiale', 'Talisman Initiale',
    'Clio Zen', 'Captur Zen', 'Megane Zen', 'Kadjar Zen', 'Talisman Zen',
    'Clio Play', 'Captur Play', 'Megane Play', 'Kadjar Play', 'Talisman Play'
  ];

  // موديلات بيجو
  static const List<String> peugeot = [
    '208', '2008', '308', '3008', '508', '208 GTi', '2008 GT',
    '308 GTi', '3008 GT', '508 GT', '208 Allure', '2008 Allure',
    '308 Allure', '3008 Allure', '508 Allure', '208 Active',
    '2008 Active', '308 Active', '3008 Active', '508 Active',
    '208 GT Line', '2008 GT Line', '308 GT Line', '3008 GT Line',
    '508 GT Line', '208 PureTech', '2008 PureTech', '308 PureTech',
    '3008 PureTech', '508 PureTech', '208 e-208', '2008 e-2008',
    '308 e-308', '3008 e-3008', '508 e-508', '208 First Edition',
    '2008 First Edition', '308 First Edition', '3008 First Edition',
    '508 First Edition', '208 Business', '2008 Business', '308 Business',
    '3008 Business', '508 Business', '208 Sport', '2008 Sport',
    '308 Sport', '3008 Sport', '508 Sport', '208 Premium',
    '2008 Premium', '308 Premium', '3008 Premium', '508 Premium'
  ];

  // موديلات ستروين
  static const List<String> citroen = [
    'C1', 'C3', 'C4', 'C5', 'C5 X', 'C1 Feel', 'C3 Feel', 'C4 Feel',
    'C5 Feel', 'C5 X Feel', 'C1 Flair', 'C3 Flair', 'C4 Flair', 'C5 Flair',
    'C5 X Flair', 'C1 Live', 'C3 Live', 'C4 Live', 'C5 Live', 'C5 X Live',
    'C1 Shine', 'C3 Shine', 'C4 Shine', 'C5 Shine', 'C5 X Shine', 'C1 PureTech',
    'C3 PureTech', 'C4 PureTech', 'C5 PureTech', 'C5 X PureTech', 'C1 e-C1',
    'C3 e-C3', 'C4 e-C4', 'C5 e-C5', 'C5 X e-C5 X', 'C1 Edition',
    'C3 Edition', 'C4 Edition', 'C5 Edition', 'C5 X Edition', 'C1 Business',
    'C3 Business', 'C4 Business', 'C5 Business', 'C5 X Business', 'C1 Sport',
    'C3 Sport', 'C4 Sport', 'C5 Sport', 'C5 X Sport', 'C1 Premium',
    'C3 Premium', 'C4 Premium', 'C5 Premium', 'C5 X Premium', 'C1 Collection',
    'C3 Collection', 'C4 Collection', 'C5 Collection', 'C5 X Collection'
  ];

  // موديلات سكودا
  static const List<String> skoda = [
    'Fabia', 'Octavia', 'Superb', 'Kamiq', 'Karoq', 'Kodiaq', 'Fabia Monte Carlo',
    'Octavia RS', 'Superb SportLine', 'Kamiq Monte Carlo', 'Karoq SportLine',
    'Kodiaq RS', 'Fabia Scout', 'Octavia Scout', 'Superb Scout', 'Kamiq Scout',
    'Karoq Scout', 'Kodiaq Scout', 'Fabia Style', 'Octavia Style', 'Superb Style',
    'Kamiq Style', 'Karoq Style', 'Kodiaq Style', 'Fabia Ambition', 'Octavia Ambition',
    'Superb Ambition', 'Kamiq Ambition', 'Karoq Ambition', 'Kodiaq Ambition',
    'Fabia Active', 'Octavia Active', 'Superb Active', 'Kamiq Active', 'Karoq Active',
    'Kodiaq Active', 'Fabia Business', 'Octavia Business', 'Superb Business',
    'Kamiq Business', 'Karoq Business', 'Kodiaq Business', 'Fabia Laurin & Klement',
    'Octavia Laurin & Klement', 'Superb Laurin & Klement', 'Kamiq Laurin & Klement',
    'Karoq Laurin & Klement', 'Kodiaq Laurin & Klement', 'Fabia iV', 'Octavia iV',
    'Superb iV', 'Kamiq iV', 'Karoq iV', 'Kodiaq iV'
  ];

  // موديلات سيات
  static const List<String> seat = [
    'Ibiza', 'Leon', 'Arona', 'Ateca', 'Tarraco', 'Ibiza FR', 'Leon FR',
    'Arona FR', 'Ateca FR', 'Tarraco FR', 'Ibiza Xcellence', 'Leon Xcellence',
    'Arona Xcellence', 'Ateca Xcellence', 'Tarraco Xcellence', 'Ibiza FR Sport',
    'Leon FR Sport', 'Arona FR Sport', 'Ateca FR Sport', 'Tarraco FR Sport',
    'Ibiza SE', 'Leon SE', 'Arona SE', 'Ateca SE', 'Tarraco SE', 'Ibiza SE Technology',
    'Leon SE Technology', 'Arona SE Technology', 'Ateca SE Technology', 'Tarraco SE Technology',
    'Ibiza FR Technology', 'Leon FR Technology', 'Arona FR Technology', 'Ateca FR Technology',
    'Tarraco FR Technology', 'Ibiza Xcellence Lux', 'Leon Xcellence Lux', 'Arona Xcellence Lux',
    'Ateca Xcellence Lux', 'Tarraco Xcellence Lux', 'Ibiza Cupra', 'Leon Cupra', 'Arona Cupra',
    'Ateca Cupra', 'Tarraco Cupra', 'Ibiza e-Ibiza', 'Leon e-Leon', 'Arona e-Arona',
    'Ateca e-Ateca', 'Tarraco e-Tarraco', 'Ibiza FR First Edition', 'Leon FR First Edition',
    'Arona FR First Edition', 'Ateca FR First Edition', 'Tarraco FR First Edition'
  ];

  // موديلات ميني
  static const List<String> mini = [
    'Cooper', 'Countryman', 'Clubman', 'Convertible', 'Electric',
    'Cooper S', 'Countryman S', 'Clubman S', 'Convertible S', 'Electric S',
    'Cooper JCW', 'Countryman JCW', 'Clubman JCW', 'Convertible JCW', 'Electric JCW',
    'Cooper Classic', 'Countryman Classic', 'Clubman Classic', 'Convertible Classic',
    'Electric Classic', 'Cooper Sport', 'Countryman Sport', 'Clubman Sport',
    'Convertible Sport', 'Electric Sport', 'Cooper Exclusive', 'Countryman Exclusive',
    'Clubman Exclusive', 'Convertible Exclusive', 'Electric Exclusive', 'Cooper Resolute',
    'Countryman Resolute', 'Clubman Resolute', 'Convertible Resolute', 'Electric Resolute',
    'Cooper Iconic', 'Countryman Iconic', 'Clubman Iconic', 'Convertible Iconic',
    'Electric Iconic', 'Cooper Untold', 'Countryman Untold', 'Clubman Untold',
    'Convertible Untold', 'Electric Untold', 'Cooper First Edition', 'Countryman First Edition',
    'Clubman First Edition', 'Convertible First Edition', 'Electric First Edition'
  ];

  // موديلات ألباين
  static const List<String> alpine = [
    'A110', 'A110S', 'A110 GT4', 'A110 R', 'A110 Pure',
    'A110 Legende', 'A110S Legende', 'A110 R Le Mans',
    'A110 Tour de Corse 75', 'A110S Tour de Corse 75',
    'A110 GT', 'A110S GT', 'A110 R Rally', 'A110S Rally',
    'A110 Pure Rally',
    'A110 GT4', 'A110S GT4', 'A110 R GT4', 'A110 Pure GT4',
    'A110 Legende GT4', 'A110S Legende GT4', 'A110 R Le Mans GT4',
    'A110 Tour de Corse 75 GT4', 'A110S Tour de Corse 75 GT4',
    'A110 GT GT4', 'A110S GT GT4', 'A110 R Rally GT4',
    'A110S Rally GT4', 'A110 Pure Rally GT4', 'A110 GT4',
    'A110S GT4', 'A110 R GT4', 'A110 Pure GT4', 'A110 Legende GT4',
    'A110S Legende GT4', 'A110 R Le Mans GT4', 'A110 Tour de Corse 75 GT4',
    'A110S Tour de Corse 75 GT4', 'A110 GT GT4', 'A110S GT GT4',
    'A110 R Rally GT4', 'A110S Rally GT4', 'A110 Pure Rally GT4',
    'A110 GT4', 'A110S GT4', 'A110 R GT4', 'A110 Pure GT4',
    'A110 Legende GT4', 'A110S Legende GT4', 'A110 R Le Mans GT4',
    'A110 Tour de Corse 75 GT4', 'A110S Tour de Corse 75 GT4',
    'A110 GT GT4', 'A110S GT GT4', 'A110 R Rally GT4',
    'A110S Rally GT4', 'A110 Pure Rally GT4', 'A110 GT4',
    'A110S GT4', 'A110 R GT4', 'A110 Pure GT4', 'A110 Legende GT4',
    'A110S Legende GT4', 'A110 R Le Mans GT4', 'A110 Tour de Corse 75 GT4',
    'A110S Tour de Corse 75 GT4', 'A110 GT GT4', 'A110S GT GT4',
    'A110 R Rally GT4', 'A110S Rally GT4', 'A110 Pure Rally GT4'
  ];

  // موديلات لوتس
  static const List<String> lotus = [
    'Emira', 'Evija', 'Elise', 'Exige', 'Evora',
    'Emira GT4', 'Evija Fittipaldi', 'Emira V6',
    'Emira i4', 'Evija Fittipaldi', 'Emira First Edition',
    'Emira Base Edition', 'Evija Type 130', 'Emira GT',
    'Emira Sport', 'Emira Touring',
    'Emira GT4', 'Evija Fittipaldi', 'Emira V6',
    'Emira i4', 'Evija Fittipaldi', 'Emira First Edition',
    'Emira Base Edition', 'Evija Type 130', 'Emira GT',
    'Emira Sport', 'Emira Touring', 'Emira GT4',
    'Evija Fittipaldi', 'Emira V6', 'Emira i4',
    'Evija Fittipaldi', 'Emira First Edition', 'Emira Base Edition',
    'Evija Type 130', 'Emira GT', 'Emira Sport', 'Emira Touring',
    'Emira GT4', 'Evija Fittipaldi', 'Emira V6', 'Emira i4',
    'Evija Fittipaldi', 'Emira First Edition', 'Emira Base Edition',
    'Evija Type 130', 'Emira GT', 'Emira Sport', 'Emira Touring',
    'Emira GT4', 'Evija Fittipaldi', 'Emira V6', 'Emira i4',
    'Evija Fittipaldi', 'Emira First Edition', 'Emira Base Edition',
    'Evija Type 130', 'Emira GT', 'Emira Sport', 'Emira Touring',
    'Emira GT4', 'Evija Fittipaldi', 'Emira V6', 'Emira i4',
    'Evija Fittipaldi', 'Emira First Edition', 'Emira Base Edition',
    'Evija Type 130', 'Emira GT', 'Emira Sport', 'Emira Touring'
  ];

  // موديلات مازدا
  static const List<String> mazda = [
    'Mazda3', 'Mazda6', 'CX-3', 'CX-30', 'CX-5', 'CX-9', 'MX-30',
    'MX-5', 'BT-50', 'Mazda2', 'Mazda3 Hatchback', 'Mazda6 Wagon',
    'CX-4', 'CX-8', 'MX-30 e-Skyactiv', 'MX-5 RF', 'BT-50 Pro',
    'Mazda2 Hybrid', 'Mazda3 Hybrid', 'Mazda6 Hybrid', 'CX-5 Hybrid',
    'CX-9 Hybrid', 'MX-30 Hybrid', 'MX-5 Sport', 'BT-50 GT',
    'Mazda2 Sport', 'Mazda3 Sport', 'Mazda6 Sport', 'CX-5 Sport',
    'CX-9 Sport', 'MX-30 Sport', 'MX-5 Club', 'BT-50 XTR',
    'Mazda2 X', 'Mazda3 X', 'Mazda6 X', 'CX-5 X', 'CX-9 X',
    'MX-30 X', 'MX-5 Grand Touring', 'BT-50 XTR Hi-Rider'
  ];

  // موديلات ميتسوبيشي
  static const List<String> mitsubishi = [
    'Lancer', 'Outlander', 'Eclipse Cross', 'ASX', 'Pajero',
    'Triton', 'Mirage', 'Delica', 'Pajero Sport', 'Eclipse',
    'Outlander PHEV', 'ASX PHEV', 'Pajero Hybrid', 'Triton Hybrid',
    'Mirage G4', 'Delica D:5', 'Pajero Sport Hybrid', 'Eclipse Cross PHEV',
    'Lancer Evolution', 'Outlander GT', 'ASX GT', 'Pajero GLS',
    'Triton GLS', 'Mirage GT', 'Delica GT', 'Pajero Sport GT',
    'Eclipse Cross GT', 'Lancer Ralliart', 'Outlander Ralliart',
    'ASX Ralliart', 'Pajero Ralliart', 'Triton Ralliart',
    'Mirage Ralliart', 'Delica Ralliart', 'Pajero Sport Ralliart',
    'Eclipse Cross Ralliart', 'Lancer GT', 'Outlander GT',
    'ASX GT', 'Pajero GT', 'Triton GT', 'Mirage GT',
    'Delica GT', 'Pajero Sport GT', 'Eclipse Cross GT'
  ];

  // موديلات سوبارو
  static const List<String> subaru = [
    'Impreza', 'Legacy', 'Outback', 'Forester', 'Crosstrek',
    'Ascent', 'WRX', 'BRZ', 'Solterra', 'Tribeca',
    'Impreza WRX', 'Legacy GT', 'Outback Wilderness',
    'Forester Wilderness', 'Crosstrek Wilderness',
    'Ascent Touring', 'WRX STI', 'BRZ tS', 'Solterra Touring',
    'Impreza Sport', 'Legacy Sport', 'Outback Sport',
    'Forester Sport', 'Crosstrek Sport', 'Ascent Sport',
    'WRX Limited', 'BRZ Limited', 'Solterra Limited',
    'Impreza Limited', 'Legacy Limited', 'Outback Limited',
    'Forester Limited', 'Crosstrek Limited', 'Ascent Limited',
    'WRX Premium', 'BRZ Premium', 'Solterra Premium',
    'Impreza Premium', 'Legacy Premium', 'Outback Premium',
    'Forester Premium', 'Crosstrek Premium', 'Ascent Premium'
  ];

  // موديلات سوزوكي
  static const List<String> suzuki = [
    'Swift', 'Vitara', 'S-Cross', 'Jimny', 'Ignis',
    'Baleno', 'SX4 S-Cross', 'Grand Vitara', 'XL7',
    'Swift Sport', 'Vitara Sport', 'S-Cross Sport',
    'Jimny Sierra', 'Ignis Sport', 'Baleno Sport',
    'SX4 S-Cross Sport', 'Grand Vitara Sport', 'XL7 Sport',
    'Swift Hybrid', 'Vitara Hybrid', 'S-Cross Hybrid',
    'Jimny Hybrid', 'Ignis Hybrid', 'Baleno Hybrid',
    'SX4 S-Cross Hybrid', 'Grand Vitara Hybrid', 'XL7 Hybrid',
    'Swift GLX', 'Vitara GLX', 'S-Cross GLX', 'Jimny GLX',
    'Ignis GLX', 'Baleno GLX', 'SX4 S-Cross GLX',
    'Grand Vitara GLX', 'XL7 GLX', 'Swift GL', 'Vitara GL',
    'S-Cross GL', 'Jimny GL', 'Ignis GL', 'Baleno GL',
    'SX4 S-Cross GL', 'Grand Vitara GL', 'XL7 GL'
  ];

  // موديلات أكرا
  static const List<String> acura = [
    'ILX', 'TLX', 'RLX', 'RDX', 'MDX', 'NSX',
    'ILX A-Spec', 'TLX Type S', 'RLX Sport Hybrid',
    'RDX A-Spec', 'MDX Type S', 'NSX Type S',
    'ILX Premium', 'TLX Premium', 'RLX Premium',
    'RDX Premium', 'MDX Premium', 'NSX Premium',
    'ILX Technology', 'TLX Technology', 'RLX Technology',
    'RDX Technology', 'MDX Technology', 'NSX Technology',
    'ILX Advance', 'TLX Advance', 'RLX Advance',
    'RDX Advance', 'MDX Advance', 'NSX Advance',
    'ILX Elite', 'TLX Elite', 'RLX Elite', 'RDX Elite',
    'MDX Elite', 'NSX Elite', 'ILX Sport', 'TLX Sport',
    'RLX Sport', 'RDX Sport', 'MDX Sport', 'NSX Sport'
  ];

  // موديلات شيفروليه
  static const List<String> chrysler = [
    '300', 'Pacifica', 'Voyager', '300S', 'Pacifica Hybrid',
    'Voyager L', '300C', 'Pacifica Pinnacle', 'Voyager LX',
    '300 Touring', 'Pacifica Touring', 'Voyager Touring',
    '300S Alloy', 'Pacifica Touring L', 'Voyager Touring L',
    '300C Platinum', 'Pacifica Pinnacle Hybrid', 'Voyager LX',
    '300 Limited', 'Pacifica Limited', 'Voyager Limited',
    '300S Heritage', 'Pacifica Touring L Hybrid', 'Voyager Touring',
    '300C SRT', 'Pacifica Pinnacle', 'Voyager LX',
    '300 Touring L', 'Pacifica Touring', 'Voyager Touring L',
    '300S Platinum', 'Pacifica Limited Hybrid', 'Voyager Limited',
    '300C Heritage', 'Pacifica Touring L', 'Voyager Touring',
    '300 Limited Platinum', 'Pacifica Limited', 'Voyager Limited L',
    '300S Heritage Edition', 'Pacifica Touring L Hybrid', 'Voyager LX',
    '300C SRT Heritage', 'Pacifica Pinnacle', 'Voyager Touring L',
    '300 Touring L Platinum', 'Pacifica Touring', 'Voyager Touring',
    '300S Platinum Heritage', 'Pacifica Limited Hybrid', 'Voyager Limited',
    '300C Heritage Edition', 'Pacifica Touring L', 'Voyager Touring L'
  ];

  // موديلات بيك
  static const List<String> buick = [
    'Encore', 'Encore GX', 'Envision', 'Enclave', 'Regal',
    'Encore Sport Touring', 'Encore GX Sport Touring',
    'Envision Sport Touring', 'Enclave Sport Touring',
    'Regal Sport Touring', 'Encore Preferred', 'Encore GX Preferred',
    'Envision Preferred', 'Enclave Preferred', 'Regal Preferred',
    'Encore Essence', 'Encore GX Essence', 'Envision Essence',
    'Enclave Essence', 'Regal Essence', 'Encore Avenir',
    'Encore GX Avenir', 'Envision Avenir', 'Enclave Avenir',
    'Regal Avenir', 'Encore Sport', 'Encore GX Sport',
    'Envision Sport', 'Enclave Sport', 'Regal Sport',
    'Encore TourX', 'Encore GX TourX', 'Envision TourX',
    'Enclave TourX', 'Regal TourX', 'Encore GS', 'Encore GX GS',
    'Envision GS', 'Enclave GS', 'Regal GS', 'Encore GSX',
    'Encore GX GSX', 'Envision GSX', 'Enclave GSX', 'Regal GSX'
  ];

  // موديلات لنكولن
  static const List<String> lincoln = [
    'Corsair', 'Nautilus', 'Aviator', 'Navigator', 'Continental',
    'Corsair Grand Touring', 'Nautilus Grand Touring',
    'Aviator Grand Touring', 'Navigator Grand Touring',
    'Continental Grand Touring', 'Corsair Reserve', 'Nautilus Reserve',
    'Aviator Reserve', 'Navigator Reserve', 'Continental Reserve',
    'Corsair Black Label', 'Nautilus Black Label', 'Aviator Black Label',
    'Navigator Black Label', 'Continental Black Label', 'Corsair Standard',
    'Nautilus Standard', 'Aviator Standard', 'Navigator Standard',
    'Continental Standard', 'Corsair Select', 'Nautilus Select',
    'Aviator Select', 'Navigator Select', 'Continental Select',
    'Corsair Premiere', 'Nautilus Premiere', 'Aviator Premiere',
    'Navigator Premiere', 'Continental Premiere', 'Corsair Signature',
    'Nautilus Signature', 'Aviator Signature', 'Navigator Signature',
    'Continental Signature', 'Corsair Presidential', 'Nautilus Presidential',
    'Aviator Presidential', 'Navigator Presidential', 'Continental Presidential'
  ];

  // موديلات سانج يونج
  static const List<String> ssangyong = [
    'Actyon', 'Actyon Sports', 'Actyon Grand', 'Korando',
    'Korando C', 'Korando Sports', 'Kyron', 'Musso',
    'Musso Grand', 'Rexton', 'Rexton Sports', 'Stavic',
    'Tivoli', 'Tivoli Air', 'XLV', 'XLV Air',
    'Actyon Electric', 'Korando Electric', 'Musso Electric',
    'Rexton Electric', 'Tivoli Electric', 'Actyon Hybrid',
    'Korando Hybrid', 'Musso Hybrid', 'Rexton Hybrid',
    'Tivoli Hybrid', 'Actyon Sport', 'Korando Sport',
    'Musso Sport', 'Rexton Sport', 'Tivoli Sport',
    'Actyon Grand Sport', 'Korando C Sport', 'Korando Sports Sport',
    'Kyron Sport', 'Musso Grand Sport', 'Rexton Sports Sport',
    'Stavic Sport', 'Tivoli Air Sport', 'XLV Sport', 'XLV Air Sport',
    'Actyon Electric Sport', 'Korando Electric Sport', 'Musso Electric Sport',
    'Rexton Electric Sport', 'Tivoli Electric Sport', 'Actyon Hybrid Sport',
    'Korando Hybrid Sport', 'Musso Hybrid Sport', 'Rexton Hybrid Sport',
    'Tivoli Hybrid Sport'
  ];

  // موديلات BYD
  static const List<String> byd = [
    'Atto 3', 'Dolphin', 'Seal', 'Tang', 'Han',
    'Atto 3 Premium', 'Dolphin Premium', 'Seal Premium',
    'Tang Premium', 'Han Premium', 'Atto 3 Sport',
    'Dolphin Sport', 'Seal Sport', 'Tang Sport', 'Han Sport',
    'Atto 3 Luxury', 'Dolphin Luxury', 'Seal Luxury',
    'Tang Luxury', 'Han Luxury', 'Atto 3 Elite',
    'Dolphin Elite', 'Seal Elite', 'Tang Elite', 'Han Elite',
    'Atto 3 Pro', 'Dolphin Pro', 'Seal Pro', 'Tang Pro',
    'Han Pro', 'Atto 3 Max', 'Dolphin Max', 'Seal Max',
    'Tang Max', 'Han Max', 'Atto 3 Plus', 'Dolphin Plus',
    'Seal Plus', 'Tang Plus', 'Han Plus', 'Atto 3 Ultra',
    'Dolphin Ultra', 'Seal Ultra', 'Tang Ultra', 'Han Ultra'
  ];

  // موديلات جيلي
  static const List<String> geely = [
    'Emgrand', 'Coolray', 'Okavango', 'Azkarra', 'Tugella',
    'Emgrand GT', 'Coolray GT', 'Okavango GT', 'Azkarra GT',
    'Tugella GT', 'Emgrand Sport', 'Coolray Sport',
    'Okavango Sport', 'Azkarra Sport', 'Tugella Sport',
    'Emgrand Luxury', 'Coolray Luxury', 'Okavango Luxury',
    'Azkarra Luxury', 'Tugella Luxury', 'Emgrand Elite',
    'Coolray Elite', 'Okavango Elite', 'Azkarra Elite',
    'Tugella Elite', 'Emgrand Pro', 'Coolray Pro',
    'Okavango Pro', 'Azkarra Pro', 'Tugella Pro',
    'Emgrand Max', 'Coolray Max', 'Okavango Max',
    'Azkarra Max', 'Tugella Max', 'Emgrand Plus',
    'Coolray Plus', 'Okavango Plus', 'Azkarra Plus',
    'Tugella Plus', 'Emgrand Ultra', 'Coolray Ultra',
    'Okavango Ultra', 'Azkarra Ultra', 'Tugella Ultra'
  ];

  // موديلات شيري
  static const List<String> chery = [
    'Tiggo', 'Arrizo', 'QQ', 'Fulwin', 'Kimo',
    'Tiggo Pro', 'Arrizo Pro', 'QQ Pro', 'Fulwin Pro',
    'Kimo Pro', 'Tiggo Sport', 'Arrizo Sport', 'QQ Sport',
    'Fulwin Sport', 'Kimo Sport', 'Tiggo Luxury',
    'Arrizo Luxury', 'QQ Luxury', 'Fulwin Luxury',
    'Kimo Luxury', 'Tiggo Elite', 'Arrizo Elite',
    'QQ Elite', 'Fulwin Elite', 'Kimo Elite', 'Tiggo Pro Sport',
    'Arrizo Pro Sport', 'QQ Pro Sport', 'Fulwin Pro Sport',
    'Kimo Pro Sport', 'Tiggo Sport Luxury', 'Arrizo Sport Luxury',
    'QQ Sport Luxury', 'Fulwin Sport Luxury', 'Kimo Sport Luxury',
    'Tiggo Luxury Elite', 'Arrizo Luxury Elite', 'QQ Luxury Elite',
    'Fulwin Luxury Elite', 'Kimo Luxury Elite', 'Tiggo Pro Elite',
    'Arrizo Pro Elite', 'QQ Pro Elite', 'Fulwin Pro Elite',
    'Kimo Pro Elite', 'Tiggo Sport Elite', 'Arrizo Sport Elite',
    'QQ Sport Elite', 'Fulwin Sport Elite', 'Kimo Sport Elite'
  ];

  // موديلات جريت وول
  static const List<String> greatWall = [
    'Haval', 'Wey', 'Ora', 'Tank', 'Poer',
    'Haval H6', 'Wey VV7', 'Ora Good Cat', 'Tank 300',
    'Poer P12', 'Haval H9', 'Wey VV5', 'Ora Black Cat',
    'Tank 500', 'Poer P15', 'Haval Jolion', 'Wey VV6',
    'Ora White Cat', 'Tank 700', 'Poer P18', 'Haval F7',
    'Wey VV7 GT', 'Ora Punk Cat', 'Tank 800', 'Poer P20',
    'Haval F5', 'Wey VV7 PHEV', 'Ora Lightning Cat',
    'Tank 300 PHEV', 'Poer P12 PHEV', 'Haval H6 PHEV',
    'Wey VV5 PHEV', 'Ora Good Cat PHEV', 'Tank 500 PHEV',
    'Poer P15 PHEV', 'Haval H9 PHEV', 'Wey VV6 PHEV',
    'Ora Black Cat PHEV', 'Tank 700 PHEV', 'Poer P18 PHEV',
    'Haval Jolion PHEV', 'Wey VV7 GT PHEV', 'Ora White Cat PHEV',
    'Tank 800 PHEV', 'Poer P20 PHEV', 'Haval F7 PHEV',
    'Wey VV7 PHEV', 'Ora Punk Cat PHEV', 'Tank 300 PHEV',
    'Poer P12 PHEV', 'Haval F5 PHEV', 'Wey VV5 PHEV',
    'Ora Lightning Cat PHEV', 'Tank 500 PHEV', 'Poer P15 PHEV'
  ];

  // موديلات MG
  static const List<String> mg = [
    'MG3', 'MG4', 'MG5', 'MG6', 'MG HS',
    'MG ZS', 'MG ZS EV', 'MG Marvel R', 'MG One',
    'MG3 Sport', 'MG4 Sport', 'MG5 Sport', 'MG6 Sport',
    'MG HS Sport', 'MG ZS Sport', 'MG ZS EV Sport',
    'MG Marvel R Sport', 'MG One Sport', 'MG3 Luxury',
    'MG4 Luxury', 'MG5 Luxury', 'MG6 Luxury', 'MG HS Luxury',
    'MG ZS Luxury', 'MG ZS EV Luxury', 'MG Marvel R Luxury',
    'MG One Luxury', 'MG3 Elite', 'MG4 Elite', 'MG5 Elite',
    'MG6 Elite', 'MG HS Elite', 'MG ZS Elite', 'MG ZS EV Elite',
    'MG Marvel R Elite', 'MG One Elite', 'MG3 Pro', 'MG4 Pro',
    'MG5 Pro', 'MG6 Pro', 'MG HS Pro', 'MG ZS Pro',
    'MG ZS EV Pro', 'MG Marvel R Pro', 'MG One Pro',
    'MG3 Max', 'MG4 Max', 'MG5 Max', 'MG6 Max', 'MG HS Max',
    'MG ZS Max', 'MG ZS EV Max', 'MG Marvel R Max', 'MG One Max'
  ];

  // موديلات هافال
  static const List<String> haval = [
    'H6', 'H9', 'Jolion', 'F7', 'F5', 'H6 GT',
    'H9 GT', 'Jolion GT', 'F7 GT', 'F5 GT', 'H6 Luxury',
    'H9 Luxury', 'Jolion Luxury', 'F7 Luxury', 'F5 Luxury',
    'H6 Elite', 'H9 Elite', 'Jolion Elite', 'F7 Elite',
    'F5 Elite', 'H6 Pro', 'H9 Pro', 'Jolion Pro',
    'F7 Pro', 'F5 Pro', 'H6 Max', 'H9 Max', 'Jolion Max',
    'F7 Max', 'F5 Max', 'H6 Plus', 'H9 Plus', 'Jolion Plus',
    'F7 Plus', 'F5 Plus', 'H6 Ultra', 'H9 Ultra',
    'Jolion Ultra', 'F7 Ultra', 'F5 Ultra', 'H6 Hybrid',
    'H9 Hybrid', 'Jolion Hybrid', 'F7 Hybrid', 'F5 Hybrid',
    'H6 PHEV', 'H9 PHEV', 'Jolion PHEV', 'F7 PHEV',
    'F5 PHEV', 'H6 EV', 'H9 EV', 'Jolion EV', 'F7 EV',
    'F5 EV', 'H6 GT Hybrid', 'H9 GT Hybrid', 'Jolion GT Hybrid',
    'F7 GT Hybrid', 'F5 GT Hybrid', 'H6 GT PHEV', 'H9 GT PHEV',
    'Jolion GT PHEV', 'F7 GT PHEV', 'F5 GT PHEV'
  ];

  // موديلات هونجكي
  static const List<String> hongqi = [
    'H5', 'H7', 'H9', 'HS5', 'HS7', 'E-HS9',
    'H5 Sport', 'H7 Sport', 'H9 Sport', 'HS5 Sport',
    'HS7 Sport', 'E-HS9 Sport', 'H5 Luxury', 'H7 Luxury',
    'H9 Luxury', 'HS5 Luxury', 'HS7 Luxury', 'E-HS9 Luxury',
    'H5 Elite', 'H7 Elite', 'H9 Elite', 'HS5 Elite',
    'HS7 Elite', 'E-HS9 Elite', 'H5 Pro', 'H7 Pro',
    'H9 Pro', 'HS5 Pro', 'HS7 Pro', 'E-HS9 Pro',
    'H5 Max', 'H7 Max', 'H9 Max', 'HS5 Max', 'HS7 Max',
    'E-HS9 Max', 'H5 Plus', 'H7 Plus', 'H9 Plus',
    'HS5 Plus', 'HS7 Plus', 'E-HS9 Plus', 'H5 Ultra',
    'H7 Ultra', 'H9 Ultra', 'HS5 Ultra', 'HS7 Ultra',
    'E-HS9 Ultra', 'H5 Hybrid', 'H7 Hybrid', 'H9 Hybrid',
    'HS5 Hybrid', 'HS7 Hybrid', 'E-HS9 Hybrid', 'H5 PHEV',
    'H7 PHEV', 'H9 PHEV', 'HS5 PHEV', 'HS7 PHEV',
    'E-HS9 PHEV', 'H5 EV', 'H7 EV', 'H9 EV', 'HS5 EV',
    'HS7 EV', 'E-HS9 EV', 'H5 GT Hybrid', 'H7 GT Hybrid',
    'H9 GT Hybrid', 'HS5 GT Hybrid', 'HS7 GT Hybrid',
    'E-HS9 GT Hybrid', 'H5 GT PHEV', 'H7 GT PHEV',
    'H9 GT PHEV', 'HS5 GT PHEV', 'HS7 GT PHEV', 'E-HS9 GT PHEV'
  ];

  // موديلات GAC
  static const List<String> gac = [
    'GS3', 'GS4', 'GS5', 'GS8', 'GA4', 'GA6', 'GA8',
    'GS3 Sport', 'GS4 Sport', 'GS5 Sport', 'GS8 Sport',
    'GA4 Sport', 'GA6 Sport', 'GA8 Sport', 'GS3 Luxury',
    'GS4 Luxury', 'GS5 Luxury', 'GS8 Luxury', 'GA4 Luxury',
    'GA6 Luxury', 'GA8 Luxury', 'GS3 Elite', 'GS4 Elite',
    'GS5 Elite', 'GS8 Elite', 'GA4 Elite', 'GA6 Elite',
    'GA8 Elite', 'GS3 Pro', 'GS4 Pro', 'GS5 Pro', 'GS8 Pro',
    'GA4 Pro', 'GA6 Pro', 'GA8 Pro', 'GS3 Max', 'GS4 Max',
    'GS5 Max', 'GS8 Max', 'GA4 Max', 'GA6 Max', 'GA8 Max',
    'GS3 Plus', 'GS4 Plus', 'GS5 Plus', 'GS8 Plus',
    'GA4 Plus', 'GA6 Plus', 'GA8 Plus', 'GS3 Ultra',
    'GS4 Ultra', 'GS5 Ultra', 'GS8 Ultra', 'GA4 Ultra',
    'GA6 Ultra', 'GA8 Ultra', 'GS3 Hybrid', 'GS4 Hybrid',
    'GS5 Hybrid', 'GS8 Hybrid', 'GA4 Hybrid', 'GA6 Hybrid',
    'GA8 Hybrid', 'GS3 PHEV', 'GS4 PHEV', 'GS5 PHEV',
    'GS8 PHEV', 'GA4 PHEV', 'GA6 PHEV', 'GA8 PHEV',
    'GS3 EV', 'GS4 EV', 'GS5 EV', 'GS8 EV', 'GA4 EV',
    'GA6 EV', 'GA8 EV', 'GS3 GT Hybrid', 'GS4 GT Hybrid',
    'GS5 GT Hybrid', 'GS8 GT Hybrid', 'GA4 GT Hybrid',
    'GA6 GT Hybrid', 'GA8 GT Hybrid', 'GS3 GT PHEV',
    'GS4 GT PHEV', 'GS5 GT PHEV', 'GS8 GT PHEV',
    'GA4 GT PHEV', 'GA6 GT PHEV', 'GA8 GT PHEV'
  ];

  // موديلات وولينج
  static const List<String> wuling = [
    'Hongguang', 'Rongguang', 'Xingwang', 'Xingchi',
    'Xingchen', 'Xingyao', 'Xingtu', 'Xingzhi',
    'Hongguang Plus', 'Rongguang Plus', 'Xingwang Plus',
    'Xingchi Plus', 'Xingchen Plus', 'Xingyao Plus',
    'Xingtu Plus', 'Xingzhi Plus', 'Hongguang Sport',
    'Rongguang Sport', 'Xingwang Sport', 'Xingchi Sport',
    'Xingchen Sport', 'Xingyao Sport', 'Xingtu Sport',
    'Xingzhi Sport', 'Hongguang Luxury', 'Rongguang Luxury',
    'Xingwang Luxury', 'Xingchi Luxury', 'Xingchen Luxury',
    'Xingyao Luxury', 'Xingtu Luxury', 'Xingzhi Luxury',
    'Hongguang Elite', 'Rongguang Elite', 'Xingwang Elite',
    'Xingchi Elite', 'Xingchen Elite', 'Xingyao Elite',
    'Xingtu Elite', 'Xingzhi Elite', 'Hongguang Pro',
    'Rongguang Pro', 'Xingwang Pro', 'Xingchi Pro',
    'Xingchen Pro', 'Xingyao Pro', 'Xingtu Pro',
    'Xingzhi Pro', 'Hongguang Max', 'Rongguang Max',
    'Xingwang Max', 'Xingchi Max', 'Xingchen Max',
    'Xingyao Max', 'Xingtu Max', 'Xingzhi Max',
    'Hongguang Plus Sport', 'Rongguang Plus Sport',
    'Xingwang Plus Sport', 'Xingchi Plus Sport',
    'Xingchen Plus Sport', 'Xingyao Plus Sport',
    'Xingtu Plus Sport', 'Xingzhi Plus Sport',
    'Hongguang Sport Luxury', 'Rongguang Sport Luxury',
    'Xingwang Sport Luxury', 'Xingchi Sport Luxury',
    'Xingchen Sport Luxury', 'Xingyao Sport Luxury',
    'Xingtu Sport Luxury', 'Xingzhi Sport Luxury',
    'Hongguang Luxury Elite', 'Rongguang Luxury Elite',
    'Xingwang Luxury Elite', 'Xingchi Luxury Elite',
    'Xingchen Luxury Elite', 'Xingyao Luxury Elite',
    'Xingtu Luxury Elite', 'Xingzhi Luxury Elite'
  ];


  // الحصول على موديلات ماركة معينة
  static List<String> getModelsForBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'toyota':
        return toyota;
      case 'honda':
        return honda;
      case 'nissan':
        return nissan;
      case 'ford':
        return ford;
      case 'bmw':
        return bmw;
      case 'mercedes-benz':
        return mercedesBenz;
      case 'hyundai':
        return hyundai;
      case 'kia':
        return kia;
      case 'audi':
        return audi;
      case 'volkswagen':
        return volkswagen;
      case 'porsche':
        return porsche;
      case 'lexus':
        return lexus;
      case 'infiniti':
        return infiniti;
      case 'genesis':
        return genesis;
      case 'tesla':
        return tesla;
      case 'rolls-royce':
        return rollsRoyce;
      case 'bentley':
        return bentley;
      case 'ferrari':
        return ferrari;
      case 'lamborghini':
        return lamborghini;
      case 'maserati':
        return maserati;
      case 'aston-martin':
        return astonMartin;
      case 'mclaren':
        return mclaren;
      case 'bugatti':
        return bugatti;
      case 'cadillac':
        return cadillac;
      case 'jeep':
        return jeep;
      case 'dodge':
        return dodge;
      case 'chevrolet':
        return chevrolet;
      case 'gmc':
        return gmc;
      case 'land-rover':
        return landRover;
      case 'jaguar':
        return jaguar;
      case 'volvo':
        return volvo;
      case 'alfa-romeo':
        return alfaRomeo;
      case 'fiat':
        return fiat;
      case 'renault':
        return renault;
      case 'peugeot':
        return peugeot;
      case 'citroen':
        return citroen;
      case 'skoda':
        return skoda;
      case 'seat':
        return seat;
      case 'mini':
        return mini;
      case 'alpine':
        return alpine;
      case 'lotus':
        return lotus;
      case 'mazda':
        return mazda;
      case 'mitsubishi':
        return mitsubishi;
      case 'subaru':
        return subaru;
      case 'suzuki':
        return suzuki;
      case 'acura':
        return acura;
      case 'chrysler':
        return chrysler;
      case 'buick':
        return buick;
      case 'lincoln':
        return lincoln;
      case 'ssangyong':
        return ssangyong;
      case 'byd':
        return byd;
      case 'geely':
        return geely;
      case 'chery':
        return chery;
      case 'great wall':
        return greatWall;
      case 'mg':
        return mg;
      case 'haval':
        return haval;
      case 'hongqi':
        return hongqi;
      case 'gac':
        return gac;
      case 'wuling':
        return wuling;
      default:
        return [];
    }
  }

  // Get only model names for a specific brand
  static List<String> getModelNamesForBrand(String brand) {
    return getModelsForBrand(brand);
  }

  // Get available trims (categories) for a specific model
  static List<String> getTrimsForModel(String brand, String model) {
    // We'll define some common trim levels for popular models
    if (brand.toLowerCase() == 'toyota') {
      if (model == 'Corolla') {
        return ['L', 'LE', 'SE', 'XLE', 'XSE', 'Hybrid'];
      } else if (model == 'Camry') {
        return ['LE', 'SE', 'XLE', 'XSE', 'TRD', 'Hybrid'];
      } else if (model == 'RAV4') {
        return ['LE', 'XLE', 'Adventure', 'Limited', 'TRD Off-Road', 'Hybrid'];
      }
    } else if (brand.toLowerCase() == 'honda') {
      if (model == 'Civic') {
        return ['LX', 'Sport', 'EX', 'Touring', 'Si', 'Type R'];
      } else if (model == 'Accord') {
        return ['LX', 'Sport', 'EX', 'EX-L', 'Touring', 'Hybrid'];
      } else if (model == 'CR-V') {
        return ['LX', 'EX', 'EX-L', 'Touring', 'Hybrid'];
      }
    } else if (brand.toLowerCase() == 'ford') {
      if (model == 'F-150') {
        return ['XL', 'XLT', 'Lariat', 'King Ranch', 'Platinum', 'Limited', 'Raptor'];
      } else if (model == 'Mustang') {
        return ['EcoBoost', 'GT', 'Mach 1', 'Shelby GT500'];
      }
    } else if (brand.toLowerCase() == 'bmw') {
      if (model.contains('Series')) {
        return ['Base', 'Sport', 'M Sport', 'Luxury', 'xDrive'];
      } else if (model.startsWith('X')) {
        return ['sDrive', 'xDrive', 'M', 'M Competition'];
      }
    }
    
    // Default generic trims if specific ones are not defined
    return ['Base', 'Sport', 'Luxury', 'Premium'];
  }

  // Get available engine options for a specific model
  static List<String> getEngineOptionsForModel(String brand, String model) {
    // Define some common engine options for popular models
    if (brand.toLowerCase() == 'toyota') {
      if (model == 'Corolla') {
        return ['1.8L 4-cylinder', '2.0L 4-cylinder', 'Hybrid'];
      } else if (model == 'Camry') {
        return ['2.5L 4-cylinder', '3.5L V6', 'Hybrid'];
      } else if (model == 'Land Cruiser') {
        return ['4.0L V6', '4.5L V8 Diesel', '5.7L V8'];
      }
    } else if (brand.toLowerCase() == 'ford') {
      if (model == 'F-150') {
        return ['3.3L V6', '2.7L EcoBoost V6', '3.5L EcoBoost V6', '5.0L V8', 'PowerBoost Hybrid'];
      } else if (model == 'Mustang') {
        return ['2.3L EcoBoost', '5.0L V8', '5.2L Supercharged V8'];
      }
    } else if (brand.toLowerCase() == 'bmw') {
      if (model == '3 Series') {
        return ['2.0L Turbo 4-cylinder', '3.0L Turbo 6-cylinder'];
      } else if (model == '5 Series') {
        return ['2.0L Turbo 4-cylinder', '3.0L Turbo 6-cylinder', '4.4L Turbo V8'];
      }
    }
    
    // Default generic engine options
    return ['4-cylinder', '6-cylinder', '8-cylinder', 'Hybrid', 'Electric'];
  }
}

// List of common car brands
class CarBrands {
  // Japanese car brands
  static const List<String> japanese = [
    'Toyota', 'Honda', 'Nissan', 'Mazda', 'Mitsubishi', 'Subaru', 'Suzuki', 'Lexus', 'Infiniti', 'Acura'
  ];

  // American car brands
  static const List<String> american = [
    'Ford', 'Chevrolet', 'Jeep', 'Dodge', 'Chrysler', 'Cadillac', 'GMC', 'Buick', 'Lincoln', 'Tesla'
  ];

  // European car brands
  static const List<String> european = [
    'Mercedes-Benz', 'BMW', 'Audi', 'Volkswagen', 'Porsche', 'Volvo', 'Land Rover', 'Jaguar',
    'Ferrari', 'Lamborghini', 'Maserati', 'Bentley', 'Rolls Royce', 'Fiat', 'Renault', 'Peugeot',
    'Citroën', 'Škoda', 'SEAT', 'Mini', 'Alpine', 'Lotus'
  ];

  // Korean car brands
  static const List<String> korean = [
    'Hyundai', 'Kia', 'Genesis', 'SsangYong'
  ];

  // Chinese car brands
  static const List<String> chinese = [
    'BYD', 'Geely', 'Chery', 'Great Wall', 'MG', 'Haval', 'Hongqi', 'GAC', 'Wuling'
  ];

  // All brands sorted alphabetically
  static List<String> get all {
    final allBrands = [...japanese, ...american, ...european, ...korean, ...chinese];
    allBrands.sort((a, b) => a.compareTo(b));
    return allBrands;
  }

  // Get brands categorized by country
  static Map<String, List<String>> get categorized {
    return {
      'Japanese': japanese,
      'American': american,
      'European': european,
      'Korean': korean,
      'Chinese': chinese,
    };
  }
} 