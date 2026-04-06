class MountPreset {
  const MountPreset({
    required this.id,
    required this.name,
    required this.registerDistanceMm,
    required this.group,
    this.isVintage = false,
  });

  final String id;
  final String name;
  final double registerDistanceMm;
  final String group;
  final bool isVintage;

  String get label => '$name (${registerDistanceMm.toStringAsFixed(1)} mm)';
}

const mountPresets = [
  MountPreset(
    id: 'canon_ef',
    name: 'Canon EF',
    registerDistanceMm: 44.0,
    group: 'Modern',
  ),
  MountPreset(
    id: 'canon_rf',
    name: 'Canon RF',
    registerDistanceMm: 20.0,
    group: 'Modern',
  ),
  MountPreset(
    id: 'nikon_f',
    name: 'Nikon F',
    registerDistanceMm: 46.5,
    group: 'Modern',
  ),
  MountPreset(
    id: 'nikon_z',
    name: 'Nikon Z',
    registerDistanceMm: 16.0,
    group: 'Modern',
  ),
  MountPreset(
    id: 'sony_e',
    name: 'Sony E',
    registerDistanceMm: 18.0,
    group: 'Modern',
  ),
  MountPreset(
    id: 'fuji_x',
    name: 'Fujifilm X',
    registerDistanceMm: 17.7,
    group: 'Modern',
  ),
  MountPreset(
    id: 'mft',
    name: 'Micro Four Thirds',
    registerDistanceMm: 19.25,
    group: 'Modern',
  ),
  MountPreset(
    id: 'leica_l',
    name: 'Leica L',
    registerDistanceMm: 20.0,
    group: 'Modern',
  ),
  MountPreset(
    id: 'pentax_k',
    name: 'Pentax K',
    registerDistanceMm: 45.46,
    group: 'Modern',
  ),
  MountPreset(
    id: 'leica_m',
    name: 'Leica M',
    registerDistanceMm: 27.8,
    group: 'Vintage',
    isVintage: true,
  ),
  MountPreset(
    id: 'm42',
    name: 'M42 Screw Mount',
    registerDistanceMm: 45.46,
    group: 'Vintage',
    isVintage: true,
  ),
  MountPreset(
    id: 'olympus_om',
    name: 'Olympus OM',
    registerDistanceMm: 46.0,
    group: 'Vintage',
    isVintage: true,
  ),
  MountPreset(
    id: 'canon_fd',
    name: 'Canon FD',
    registerDistanceMm: 42.0,
    group: 'Vintage',
    isVintage: true,
  ),
  MountPreset(
    id: 'minolta_sr',
    name: 'Minolta SR/MD',
    registerDistanceMm: 43.5,
    group: 'Vintage',
    isVintage: true,
  ),
  MountPreset(
    id: 'contax_yashica',
    name: 'Contax/Yashica C/Y',
    registerDistanceMm: 45.5,
    group: 'Vintage',
    isVintage: true,
  ),
  MountPreset(
    id: 'konica_ar',
    name: 'Konica AR',
    registerDistanceMm: 40.5,
    group: 'Vintage',
    isVintage: true,
  ),
  MountPreset(
    id: 'exakta',
    name: 'Exakta',
    registerDistanceMm: 44.7,
    group: 'Vintage',
    isVintage: true,
  ),
  MountPreset(
    id: 'pentax_645',
    name: 'Pentax 645',
    registerDistanceMm: 70.87,
    group: 'Medium Format',
    isVintage: true,
  ),
  MountPreset(
    id: 'hasselblad_v',
    name: 'Hasselblad V',
    registerDistanceMm: 74.9,
    group: 'Medium Format',
    isVintage: true,
  ),
];
