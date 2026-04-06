class AppSettings {
  static const defaultMountIds = ['canon_ef', 'sony_e', 'm42'];
  static const defaultHomeToolOrder = [
    'exposure',
    'dof',
    'extension_tubes',
    'reverse_lens',
    'dual_lens_macro',
    'sun_planner',
    'long_exposure',
  ];

  final String distanceUnit;
  final String timeUnit;
  final bool darkMode;
  final List<String> enabledMountIds;
  final List<String> homeToolOrder;
  final List<HomeFolder> homeFolders;

  const AppSettings({
    this.distanceUnit = 'm',
    this.timeUnit = '24h',
    this.darkMode = false,
    this.enabledMountIds = defaultMountIds,
    this.homeToolOrder = defaultHomeToolOrder,
    this.homeFolders = const [],
  });

  AppSettings copyWith({
    String? distanceUnit,
    String? timeUnit,
    bool? darkMode,
    List<String>? enabledMountIds,
    List<String>? homeToolOrder,
    List<HomeFolder>? homeFolders,
  }) {
    return AppSettings(
      distanceUnit: distanceUnit ?? this.distanceUnit,
      timeUnit: timeUnit ?? this.timeUnit,
      darkMode: darkMode ?? this.darkMode,
      enabledMountIds: enabledMountIds ?? this.enabledMountIds,
      homeToolOrder: homeToolOrder ?? this.homeToolOrder,
      homeFolders: homeFolders ?? this.homeFolders,
    );
  }
}

class HomeFolder {
  const HomeFolder({
    required this.id,
    required this.name,
    required this.toolIds,
  });

  final String id;
  final String name;
  final List<String> toolIds;

  String get orderKey => 'folder:$id';

  HomeFolder copyWith({
    String? id,
    String? name,
    List<String>? toolIds,
  }) {
    return HomeFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      toolIds: toolIds ?? this.toolIds,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'toolIds': toolIds,
    };
  }

  static HomeFolder? fromMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final id = raw['id'];
    final name = raw['name'];
    final toolIds = raw['toolIds'];
    if (id is! String || name is! String || toolIds is! List) {
      return null;
    }

    return HomeFolder(
      id: id,
      name: name,
      toolIds: toolIds.whereType<String>().toList(),
    );
  }
}
