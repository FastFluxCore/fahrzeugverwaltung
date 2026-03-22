const vehicleModels = <String, List<String>>{
  'Alfa Romeo': [
    'Giulia', 'Giulietta', 'Stelvio', 'Tonale', 'MiTo', '4C', '159', '147',
  ],
  'Audi': [
    'A1', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8',
    'Q2', 'Q3', 'Q4 e-tron', 'Q5', 'Q7', 'Q8',
    'TT', 'R8', 'e-tron', 'e-tron GT',
    'RS3', 'RS4', 'RS5', 'RS6', 'RS7', 'RS Q8',
    'S3', 'S4', 'S5', 'S6', 'S7', 'S8',
  ],
  'BMW': [
    '1er', '2er', '3er', '4er', '5er', '6er', '7er', '8er',
    'X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7',
    'Z4', 'i3', 'i4', 'i5', 'i7', 'iX', 'iX1', 'iX3',
    'M2', 'M3', 'M4', 'M5', 'M8',
  ],
  'Citro\u00ebn': [
    'C1', 'C3', 'C3 Aircross', 'C4', 'C4 X', 'C5 Aircross', 'C5 X',
    'Berlingo', '\u00eb-C4', 'SpaceTourer',
  ],
  'Cupra': [
    'Born', 'Formentor', 'Leon', 'Ateca', 'Tavascan',
  ],
  'Dacia': [
    'Duster', 'Sandero', 'Jogger', 'Spring', 'Logan',
  ],
  'DS': [
    'DS 3', 'DS 4', 'DS 7', 'DS 9',
  ],
  'Fiat': [
    '500', '500X', '500L', '500e', 'Panda', 'Tipo', 'Punto', 'Ducato',
    'Doblo', '600',
  ],
  'Ford': [
    'Fiesta', 'Focus', 'Mondeo', 'Puma', 'Kuga', 'EcoSport',
    'Explorer', 'Mustang', 'Mustang Mach-E', 'Ranger', 'Galaxy',
    'S-MAX', 'Transit', 'Tourneo',
  ],
  'Honda': [
    'Civic', 'Jazz', 'HR-V', 'CR-V', 'ZR-V', 'e:Ny1', 'e', 'Accord',
  ],
  'Hyundai': [
    'i10', 'i20', 'i30', 'i40',
    'Kona', 'Tucson', 'Santa Fe', 'Bayon',
    'Ioniq', 'Ioniq 5', 'Ioniq 6',
  ],
  'Jaguar': [
    'XE', 'XF', 'F-Type', 'E-Pace', 'F-Pace', 'I-Pace',
  ],
  'Jeep': [
    'Renegade', 'Compass', 'Cherokee', 'Grand Cherokee', 'Wrangler',
    'Avenger', 'Gladiator',
  ],
  'Kia': [
    'Picanto', 'Rio', 'Ceed', 'ProCeed', 'XCeed',
    'Stonic', 'Niro', 'Sportage', 'Sorento', 'EV6', 'EV9',
  ],
  'Land Rover': [
    'Defender', 'Discovery', 'Discovery Sport',
    'Range Rover', 'Range Rover Sport', 'Range Rover Velar', 'Range Rover Evoque',
  ],
  'Mazda': [
    'Mazda2', 'Mazda3', 'Mazda6',
    'CX-3', 'CX-30', 'CX-5', 'CX-60', 'MX-5', 'MX-30',
  ],
  'Mercedes-Benz': [
    'A-Klasse', 'B-Klasse', 'C-Klasse', 'E-Klasse', 'S-Klasse',
    'CLA', 'CLS', 'GLA', 'GLB', 'GLC', 'GLE', 'GLS', 'G-Klasse',
    'EQA', 'EQB', 'EQC', 'EQE', 'EQS',
    'AMG GT', 'SL', 'V-Klasse', 'Vito', 'Sprinter',
  ],
  'Mini': [
    'Cooper', 'Clubman', 'Countryman', 'Cabrio', 'John Cooper Works',
  ],
  'Mitsubishi': [
    'Space Star', 'ASX', 'Eclipse Cross', 'Outlander', 'L200',
  ],
  'Nissan': [
    'Micra', 'Juke', 'Qashqai', 'X-Trail', 'Leaf', 'Ariya',
    'Navara', 'Townstar',
  ],
  'Opel': [
    'Corsa', 'Astra', 'Insignia', 'Mokka', 'Crossland', 'Grandland',
    'Combo', 'Zafira', 'Vivaro', 'Movano', 'Rocks-e',
  ],
  'Peugeot': [
    '108', '208', '308', '408', '508',
    '2008', '3008', '5008',
    'Rifter', 'Partner', 'Expert', 'e-208', 'e-2008',
  ],
  'Porsche': [
    '911', '718 Cayman', '718 Boxster',
    'Cayenne', 'Macan', 'Panamera', 'Taycan',
  ],
  'Renault': [
    'Clio', 'Captur', 'Megane', 'Scenic', 'Austral', 'Espace',
    'Kadjar', 'Koleos', 'Twingo', 'Zoe', 'Arkana', 'Kangoo',
  ],
  'Seat': [
    'Ibiza', 'Leon', 'Arona', 'Ateca', 'Tarraco',
  ],
  'Skoda': [
    'Fabia', 'Scala', 'Octavia', 'Superb',
    'Kamiq', 'Karoq', 'Kodiaq', 'Enyaq', 'Citigo',
  ],
  'Smart': [
    'fortwo', 'forfour', '#1', '#3',
  ],
  'Suzuki': [
    'Swift', 'Ignis', 'Vitara', 'S-Cross', 'Across', 'Jimny', 'Swace',
  ],
  'Tesla': [
    'Model 3', 'Model Y', 'Model S', 'Model X',
  ],
  'Toyota': [
    'Aygo', 'Aygo X', 'Yaris', 'Yaris Cross', 'Corolla',
    'Camry', 'C-HR', 'RAV4', 'Highlander',
    'bZ4X', 'Prius', 'Supra', 'GR86', 'Land Cruiser', 'Hilux', 'Proace',
  ],
  'Volkswagen': [
    'up!', 'Polo', 'Golf', 'Golf GTI', 'Golf R', 'T-Roc', 'T-Cross',
    'Tiguan', 'Touareg', 'Passat', 'Arteon',
    'ID.3', 'ID.4', 'ID.5', 'ID.7', 'ID. Buzz',
    'Caddy', 'Multivan', 'Transporter', 'Amarok',
  ],
  'Volvo': [
    'XC40', 'XC60', 'XC90', 'C40', 'S60', 'S90', 'V60', 'V90',
    'EX30', 'EX90',
  ],
};

const vehicleBrands = [
  'Alfa Romeo', 'Audi', 'BMW', 'Citro\u00ebn', 'Cupra', 'Dacia', 'DS',
  'Fiat', 'Ford', 'Honda', 'Hyundai', 'Jaguar', 'Jeep', 'Kia',
  'Land Rover', 'Mazda', 'Mercedes-Benz', 'Mini', 'Mitsubishi', 'Nissan',
  'Opel', 'Peugeot', 'Porsche', 'Renault', 'Seat', 'Skoda', 'Smart',
  'Suzuki', 'Tesla', 'Toyota', 'Volkswagen', 'Volvo',
];
