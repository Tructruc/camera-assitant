// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CameraBodiesTable extends CameraBodies
    with TableInfo<$CameraBodiesTable, CameraBody> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CameraBodiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    check: () => sourceType.isIn(_sourceTypes),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNoteMeta = const VerificationMeta(
    'sourceNote',
  );
  @override
  late final GeneratedColumn<String> sourceNote = GeneratedColumn<String>(
    'source_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensorWidthMmMeta = const VerificationMeta(
    'sensorWidthMm',
  );
  @override
  late final GeneratedColumn<double> sensorWidthMm = GeneratedColumn<double>(
    'sensor_width_mm',
    aliasedName,
    false,
    check: () => ComparableExpr(sensorWidthMm).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sensorHeightMmMeta = const VerificationMeta(
    'sensorHeightMm',
  );
  @override
  late final GeneratedColumn<double> sensorHeightMm = GeneratedColumn<double>(
    'sensor_height_mm',
    aliasedName,
    false,
    check: () => ComparableExpr(sensorHeightMm).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultCircleOfConfusionMmMeta =
      const VerificationMeta('defaultCircleOfConfusionMm');
  @override
  late final GeneratedColumn<double> defaultCircleOfConfusionMm =
      GeneratedColumn<double>(
        'default_circle_of_confusion_mm',
        aliasedName,
        true,
        check: () =>
            defaultCircleOfConfusionMm.isNull() |
            ComparableExpr(defaultCircleOfConfusionMm).isBiggerThanValue(0),
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    normalizedName,
    sourceType,
    sourceNote,
    createdAt,
    updatedAt,
    archivedAt,
    sensorWidthMm,
    sensorHeightMm,
    defaultCircleOfConfusionMm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'camera_bodies';
  @override
  VerificationContext validateIntegrity(
    Insertable<CameraBody> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_note')) {
      context.handle(
        _sourceNoteMeta,
        sourceNote.isAcceptableOrUnknown(data['source_note']!, _sourceNoteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('sensor_width_mm')) {
      context.handle(
        _sensorWidthMmMeta,
        sensorWidthMm.isAcceptableOrUnknown(
          data['sensor_width_mm']!,
          _sensorWidthMmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sensorWidthMmMeta);
    }
    if (data.containsKey('sensor_height_mm')) {
      context.handle(
        _sensorHeightMmMeta,
        sensorHeightMm.isAcceptableOrUnknown(
          data['sensor_height_mm']!,
          _sensorHeightMmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sensorHeightMmMeta);
    }
    if (data.containsKey('default_circle_of_confusion_mm')) {
      context.handle(
        _defaultCircleOfConfusionMmMeta,
        defaultCircleOfConfusionMm.isAcceptableOrUnknown(
          data['default_circle_of_confusion_mm']!,
          _defaultCircleOfConfusionMmMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CameraBody map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CameraBody(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      sensorWidthMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sensor_width_mm'],
      )!,
      sensorHeightMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sensor_height_mm'],
      )!,
      defaultCircleOfConfusionMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_circle_of_confusion_mm'],
      ),
    );
  }

  @override
  $CameraBodiesTable createAlias(String alias) {
    return $CameraBodiesTable(attachedDatabase, alias);
  }
}

class CameraBody extends DataClass implements Insertable<CameraBody> {
  final String id;
  final String name;
  final String normalizedName;
  final String sourceType;
  final String? sourceNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final double sensorWidthMm;
  final double sensorHeightMm;
  final double? defaultCircleOfConfusionMm;
  const CameraBody({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.sourceType,
    this.sourceNote,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    required this.sensorWidthMm,
    required this.sensorHeightMm,
    this.defaultCircleOfConfusionMm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourceNote != null) {
      map['source_note'] = Variable<String>(sourceNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['sensor_width_mm'] = Variable<double>(sensorWidthMm);
    map['sensor_height_mm'] = Variable<double>(sensorHeightMm);
    if (!nullToAbsent || defaultCircleOfConfusionMm != null) {
      map['default_circle_of_confusion_mm'] = Variable<double>(
        defaultCircleOfConfusionMm,
      );
    }
    return map;
  }

  CameraBodiesCompanion toCompanion(bool nullToAbsent) {
    return CameraBodiesCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      sourceType: Value(sourceType),
      sourceNote: sourceNote == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceNote),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      sensorWidthMm: Value(sensorWidthMm),
      sensorHeightMm: Value(sensorHeightMm),
      defaultCircleOfConfusionMm:
          defaultCircleOfConfusionMm == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultCircleOfConfusionMm),
    );
  }

  factory CameraBody.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CameraBody(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceNote: serializer.fromJson<String?>(json['sourceNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      sensorWidthMm: serializer.fromJson<double>(json['sensorWidthMm']),
      sensorHeightMm: serializer.fromJson<double>(json['sensorHeightMm']),
      defaultCircleOfConfusionMm: serializer.fromJson<double?>(
        json['defaultCircleOfConfusionMm'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceNote': serializer.toJson<String?>(sourceNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'sensorWidthMm': serializer.toJson<double>(sensorWidthMm),
      'sensorHeightMm': serializer.toJson<double>(sensorHeightMm),
      'defaultCircleOfConfusionMm': serializer.toJson<double?>(
        defaultCircleOfConfusionMm,
      ),
    };
  }

  CameraBody copyWith({
    String? id,
    String? name,
    String? normalizedName,
    String? sourceType,
    Value<String?> sourceNote = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    double? sensorWidthMm,
    double? sensorHeightMm,
    Value<double?> defaultCircleOfConfusionMm = const Value.absent(),
  }) => CameraBody(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    sourceType: sourceType ?? this.sourceType,
    sourceNote: sourceNote.present ? sourceNote.value : this.sourceNote,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    sensorWidthMm: sensorWidthMm ?? this.sensorWidthMm,
    sensorHeightMm: sensorHeightMm ?? this.sensorHeightMm,
    defaultCircleOfConfusionMm: defaultCircleOfConfusionMm.present
        ? defaultCircleOfConfusionMm.value
        : this.defaultCircleOfConfusionMm,
  );
  CameraBody copyWithCompanion(CameraBodiesCompanion data) {
    return CameraBody(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceNote: data.sourceNote.present
          ? data.sourceNote.value
          : this.sourceNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      sensorWidthMm: data.sensorWidthMm.present
          ? data.sensorWidthMm.value
          : this.sensorWidthMm,
      sensorHeightMm: data.sensorHeightMm.present
          ? data.sensorHeightMm.value
          : this.sensorHeightMm,
      defaultCircleOfConfusionMm: data.defaultCircleOfConfusionMm.present
          ? data.defaultCircleOfConfusionMm.value
          : this.defaultCircleOfConfusionMm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CameraBody(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('sensorWidthMm: $sensorWidthMm, ')
          ..write('sensorHeightMm: $sensorHeightMm, ')
          ..write('defaultCircleOfConfusionMm: $defaultCircleOfConfusionMm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    normalizedName,
    sourceType,
    sourceNote,
    createdAt,
    updatedAt,
    archivedAt,
    sensorWidthMm,
    sensorHeightMm,
    defaultCircleOfConfusionMm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CameraBody &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.sourceType == this.sourceType &&
          other.sourceNote == this.sourceNote &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt &&
          other.sensorWidthMm == this.sensorWidthMm &&
          other.sensorHeightMm == this.sensorHeightMm &&
          other.defaultCircleOfConfusionMm == this.defaultCircleOfConfusionMm);
}

class CameraBodiesCompanion extends UpdateCompanion<CameraBody> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String> sourceType;
  final Value<String?> sourceNote;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<double> sensorWidthMm;
  final Value<double> sensorHeightMm;
  final Value<double?> defaultCircleOfConfusionMm;
  final Value<int> rowid;
  const CameraBodiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.sensorWidthMm = const Value.absent(),
    this.sensorHeightMm = const Value.absent(),
    this.defaultCircleOfConfusionMm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CameraBodiesCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    required String sourceType,
    this.sourceNote = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    required double sensorWidthMm,
    required double sensorHeightMm,
    this.defaultCircleOfConfusionMm = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName),
       sourceType = Value(sourceType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       sensorWidthMm = Value(sensorWidthMm),
       sensorHeightMm = Value(sensorHeightMm);
  static Insertable<CameraBody> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? sourceType,
    Expression<String>? sourceNote,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<double>? sensorWidthMm,
    Expression<double>? sensorHeightMm,
    Expression<double>? defaultCircleOfConfusionMm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceNote != null) 'source_note': sourceNote,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (sensorWidthMm != null) 'sensor_width_mm': sensorWidthMm,
      if (sensorHeightMm != null) 'sensor_height_mm': sensorHeightMm,
      if (defaultCircleOfConfusionMm != null)
        'default_circle_of_confusion_mm': defaultCircleOfConfusionMm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CameraBodiesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<String>? sourceType,
    Value<String?>? sourceNote,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<double>? sensorWidthMm,
    Value<double>? sensorHeightMm,
    Value<double?>? defaultCircleOfConfusionMm,
    Value<int>? rowid,
  }) {
    return CameraBodiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      sourceType: sourceType ?? this.sourceType,
      sourceNote: sourceNote ?? this.sourceNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      sensorWidthMm: sensorWidthMm ?? this.sensorWidthMm,
      sensorHeightMm: sensorHeightMm ?? this.sensorHeightMm,
      defaultCircleOfConfusionMm:
          defaultCircleOfConfusionMm ?? this.defaultCircleOfConfusionMm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceNote.present) {
      map['source_note'] = Variable<String>(sourceNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (sensorWidthMm.present) {
      map['sensor_width_mm'] = Variable<double>(sensorWidthMm.value);
    }
    if (sensorHeightMm.present) {
      map['sensor_height_mm'] = Variable<double>(sensorHeightMm.value);
    }
    if (defaultCircleOfConfusionMm.present) {
      map['default_circle_of_confusion_mm'] = Variable<double>(
        defaultCircleOfConfusionMm.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CameraBodiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('sensorWidthMm: $sensorWidthMm, ')
          ..write('sensorHeightMm: $sensorHeightMm, ')
          ..write('defaultCircleOfConfusionMm: $defaultCircleOfConfusionMm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LensesTable extends Lenses with TableInfo<$LensesTable, Lense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    check: () => sourceType.isIn(_sourceTypes),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNoteMeta = const VerificationMeta(
    'sourceNote',
  );
  @override
  late final GeneratedColumn<String> sourceNote = GeneratedColumn<String>(
    'source_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minimumFocalLengthMmMeta =
      const VerificationMeta('minimumFocalLengthMm');
  @override
  late final GeneratedColumn<double> minimumFocalLengthMm =
      GeneratedColumn<double>(
        'minimum_focal_length_mm',
        aliasedName,
        false,
        check: () => ComparableExpr(minimumFocalLengthMm).isBiggerThanValue(0),
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _maximumFocalLengthMmMeta =
      const VerificationMeta('maximumFocalLengthMm');
  @override
  late final GeneratedColumn<double> maximumFocalLengthMm =
      GeneratedColumn<double>(
        'maximum_focal_length_mm',
        aliasedName,
        false,
        check: () => ComparableExpr(
          maximumFocalLengthMm,
        ).isBiggerOrEqual(minimumFocalLengthMm),
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _minimumApertureMeta = const VerificationMeta(
    'minimumAperture',
  );
  @override
  late final GeneratedColumn<double> minimumAperture = GeneratedColumn<double>(
    'minimum_aperture',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maximumFocalLengthMinimumApertureMeta =
      const VerificationMeta('maximumFocalLengthMinimumAperture');
  @override
  late final GeneratedColumn<double> maximumFocalLengthMinimumAperture =
      GeneratedColumn<double>(
        'maximum_focal_length_minimum_aperture',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _minimumFocusDistanceMmMeta =
      const VerificationMeta('minimumFocusDistanceMm');
  @override
  late final GeneratedColumn<double> minimumFocusDistanceMm =
      GeneratedColumn<double>(
        'minimum_focus_distance_mm',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    normalizedName,
    sourceType,
    sourceNote,
    createdAt,
    updatedAt,
    archivedAt,
    minimumFocalLengthMm,
    maximumFocalLengthMm,
    minimumAperture,
    maximumFocalLengthMinimumAperture,
    minimumFocusDistanceMm,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_note')) {
      context.handle(
        _sourceNoteMeta,
        sourceNote.isAcceptableOrUnknown(data['source_note']!, _sourceNoteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('minimum_focal_length_mm')) {
      context.handle(
        _minimumFocalLengthMmMeta,
        minimumFocalLengthMm.isAcceptableOrUnknown(
          data['minimum_focal_length_mm']!,
          _minimumFocalLengthMmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minimumFocalLengthMmMeta);
    }
    if (data.containsKey('maximum_focal_length_mm')) {
      context.handle(
        _maximumFocalLengthMmMeta,
        maximumFocalLengthMm.isAcceptableOrUnknown(
          data['maximum_focal_length_mm']!,
          _maximumFocalLengthMmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maximumFocalLengthMmMeta);
    }
    if (data.containsKey('minimum_aperture')) {
      context.handle(
        _minimumApertureMeta,
        minimumAperture.isAcceptableOrUnknown(
          data['minimum_aperture']!,
          _minimumApertureMeta,
        ),
      );
    }
    if (data.containsKey('maximum_focal_length_minimum_aperture')) {
      context.handle(
        _maximumFocalLengthMinimumApertureMeta,
        maximumFocalLengthMinimumAperture.isAcceptableOrUnknown(
          data['maximum_focal_length_minimum_aperture']!,
          _maximumFocalLengthMinimumApertureMeta,
        ),
      );
    }
    if (data.containsKey('minimum_focus_distance_mm')) {
      context.handle(
        _minimumFocusDistanceMmMeta,
        minimumFocusDistanceMm.isAcceptableOrUnknown(
          data['minimum_focus_distance_mm']!,
          _minimumFocusDistanceMmMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      minimumFocalLengthMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum_focal_length_mm'],
      )!,
      maximumFocalLengthMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}maximum_focal_length_mm'],
      )!,
      minimumAperture: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum_aperture'],
      ),
      maximumFocalLengthMinimumAperture: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}maximum_focal_length_minimum_aperture'],
      ),
      minimumFocusDistanceMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum_focus_distance_mm'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $LensesTable createAlias(String alias) {
    return $LensesTable(attachedDatabase, alias);
  }
}

class Lense extends DataClass implements Insertable<Lense> {
  final String id;
  final String name;
  final String normalizedName;
  final String sourceType;
  final String? sourceNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final double minimumFocalLengthMm;
  final double maximumFocalLengthMm;
  final double? minimumAperture;
  final double? maximumFocalLengthMinimumAperture;
  final double? minimumFocusDistanceMm;
  final String? notes;
  const Lense({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.sourceType,
    this.sourceNote,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    required this.minimumFocalLengthMm,
    required this.maximumFocalLengthMm,
    this.minimumAperture,
    this.maximumFocalLengthMinimumAperture,
    this.minimumFocusDistanceMm,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourceNote != null) {
      map['source_note'] = Variable<String>(sourceNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['minimum_focal_length_mm'] = Variable<double>(minimumFocalLengthMm);
    map['maximum_focal_length_mm'] = Variable<double>(maximumFocalLengthMm);
    if (!nullToAbsent || minimumAperture != null) {
      map['minimum_aperture'] = Variable<double>(minimumAperture);
    }
    if (!nullToAbsent || maximumFocalLengthMinimumAperture != null) {
      map['maximum_focal_length_minimum_aperture'] = Variable<double>(
        maximumFocalLengthMinimumAperture,
      );
    }
    if (!nullToAbsent || minimumFocusDistanceMm != null) {
      map['minimum_focus_distance_mm'] = Variable<double>(
        minimumFocusDistanceMm,
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  LensesCompanion toCompanion(bool nullToAbsent) {
    return LensesCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      sourceType: Value(sourceType),
      sourceNote: sourceNote == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceNote),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      minimumFocalLengthMm: Value(minimumFocalLengthMm),
      maximumFocalLengthMm: Value(maximumFocalLengthMm),
      minimumAperture: minimumAperture == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumAperture),
      maximumFocalLengthMinimumAperture:
          maximumFocalLengthMinimumAperture == null && nullToAbsent
          ? const Value.absent()
          : Value(maximumFocalLengthMinimumAperture),
      minimumFocusDistanceMm: minimumFocusDistanceMm == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumFocusDistanceMm),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory Lense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lense(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceNote: serializer.fromJson<String?>(json['sourceNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      minimumFocalLengthMm: serializer.fromJson<double>(
        json['minimumFocalLengthMm'],
      ),
      maximumFocalLengthMm: serializer.fromJson<double>(
        json['maximumFocalLengthMm'],
      ),
      minimumAperture: serializer.fromJson<double?>(json['minimumAperture']),
      maximumFocalLengthMinimumAperture: serializer.fromJson<double?>(
        json['maximumFocalLengthMinimumAperture'],
      ),
      minimumFocusDistanceMm: serializer.fromJson<double?>(
        json['minimumFocusDistanceMm'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceNote': serializer.toJson<String?>(sourceNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'minimumFocalLengthMm': serializer.toJson<double>(minimumFocalLengthMm),
      'maximumFocalLengthMm': serializer.toJson<double>(maximumFocalLengthMm),
      'minimumAperture': serializer.toJson<double?>(minimumAperture),
      'maximumFocalLengthMinimumAperture': serializer.toJson<double?>(
        maximumFocalLengthMinimumAperture,
      ),
      'minimumFocusDistanceMm': serializer.toJson<double?>(
        minimumFocusDistanceMm,
      ),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Lense copyWith({
    String? id,
    String? name,
    String? normalizedName,
    String? sourceType,
    Value<String?> sourceNote = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    double? minimumFocalLengthMm,
    double? maximumFocalLengthMm,
    Value<double?> minimumAperture = const Value.absent(),
    Value<double?> maximumFocalLengthMinimumAperture = const Value.absent(),
    Value<double?> minimumFocusDistanceMm = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => Lense(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    sourceType: sourceType ?? this.sourceType,
    sourceNote: sourceNote.present ? sourceNote.value : this.sourceNote,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    minimumFocalLengthMm: minimumFocalLengthMm ?? this.minimumFocalLengthMm,
    maximumFocalLengthMm: maximumFocalLengthMm ?? this.maximumFocalLengthMm,
    minimumAperture: minimumAperture.present
        ? minimumAperture.value
        : this.minimumAperture,
    maximumFocalLengthMinimumAperture: maximumFocalLengthMinimumAperture.present
        ? maximumFocalLengthMinimumAperture.value
        : this.maximumFocalLengthMinimumAperture,
    minimumFocusDistanceMm: minimumFocusDistanceMm.present
        ? minimumFocusDistanceMm.value
        : this.minimumFocusDistanceMm,
    notes: notes.present ? notes.value : this.notes,
  );
  Lense copyWithCompanion(LensesCompanion data) {
    return Lense(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceNote: data.sourceNote.present
          ? data.sourceNote.value
          : this.sourceNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      minimumFocalLengthMm: data.minimumFocalLengthMm.present
          ? data.minimumFocalLengthMm.value
          : this.minimumFocalLengthMm,
      maximumFocalLengthMm: data.maximumFocalLengthMm.present
          ? data.maximumFocalLengthMm.value
          : this.maximumFocalLengthMm,
      minimumAperture: data.minimumAperture.present
          ? data.minimumAperture.value
          : this.minimumAperture,
      maximumFocalLengthMinimumAperture:
          data.maximumFocalLengthMinimumAperture.present
          ? data.maximumFocalLengthMinimumAperture.value
          : this.maximumFocalLengthMinimumAperture,
      minimumFocusDistanceMm: data.minimumFocusDistanceMm.present
          ? data.minimumFocusDistanceMm.value
          : this.minimumFocusDistanceMm,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lense(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('minimumFocalLengthMm: $minimumFocalLengthMm, ')
          ..write('maximumFocalLengthMm: $maximumFocalLengthMm, ')
          ..write('minimumAperture: $minimumAperture, ')
          ..write(
            'maximumFocalLengthMinimumAperture: $maximumFocalLengthMinimumAperture, ',
          )
          ..write('minimumFocusDistanceMm: $minimumFocusDistanceMm, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    normalizedName,
    sourceType,
    sourceNote,
    createdAt,
    updatedAt,
    archivedAt,
    minimumFocalLengthMm,
    maximumFocalLengthMm,
    minimumAperture,
    maximumFocalLengthMinimumAperture,
    minimumFocusDistanceMm,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lense &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.sourceType == this.sourceType &&
          other.sourceNote == this.sourceNote &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt &&
          other.minimumFocalLengthMm == this.minimumFocalLengthMm &&
          other.maximumFocalLengthMm == this.maximumFocalLengthMm &&
          other.minimumAperture == this.minimumAperture &&
          other.maximumFocalLengthMinimumAperture ==
              this.maximumFocalLengthMinimumAperture &&
          other.minimumFocusDistanceMm == this.minimumFocusDistanceMm &&
          other.notes == this.notes);
}

class LensesCompanion extends UpdateCompanion<Lense> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String> sourceType;
  final Value<String?> sourceNote;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<double> minimumFocalLengthMm;
  final Value<double> maximumFocalLengthMm;
  final Value<double?> minimumAperture;
  final Value<double?> maximumFocalLengthMinimumAperture;
  final Value<double?> minimumFocusDistanceMm;
  final Value<String?> notes;
  final Value<int> rowid;
  const LensesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.minimumFocalLengthMm = const Value.absent(),
    this.maximumFocalLengthMm = const Value.absent(),
    this.minimumAperture = const Value.absent(),
    this.maximumFocalLengthMinimumAperture = const Value.absent(),
    this.minimumFocusDistanceMm = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LensesCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    required String sourceType,
    this.sourceNote = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    required double minimumFocalLengthMm,
    required double maximumFocalLengthMm,
    this.minimumAperture = const Value.absent(),
    this.maximumFocalLengthMinimumAperture = const Value.absent(),
    this.minimumFocusDistanceMm = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName),
       sourceType = Value(sourceType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       minimumFocalLengthMm = Value(minimumFocalLengthMm),
       maximumFocalLengthMm = Value(maximumFocalLengthMm);
  static Insertable<Lense> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? sourceType,
    Expression<String>? sourceNote,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<double>? minimumFocalLengthMm,
    Expression<double>? maximumFocalLengthMm,
    Expression<double>? minimumAperture,
    Expression<double>? maximumFocalLengthMinimumAperture,
    Expression<double>? minimumFocusDistanceMm,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceNote != null) 'source_note': sourceNote,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (minimumFocalLengthMm != null)
        'minimum_focal_length_mm': minimumFocalLengthMm,
      if (maximumFocalLengthMm != null)
        'maximum_focal_length_mm': maximumFocalLengthMm,
      if (minimumAperture != null) 'minimum_aperture': minimumAperture,
      if (maximumFocalLengthMinimumAperture != null)
        'maximum_focal_length_minimum_aperture':
            maximumFocalLengthMinimumAperture,
      if (minimumFocusDistanceMm != null)
        'minimum_focus_distance_mm': minimumFocusDistanceMm,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LensesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<String>? sourceType,
    Value<String?>? sourceNote,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<double>? minimumFocalLengthMm,
    Value<double>? maximumFocalLengthMm,
    Value<double?>? minimumAperture,
    Value<double?>? maximumFocalLengthMinimumAperture,
    Value<double?>? minimumFocusDistanceMm,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return LensesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      sourceType: sourceType ?? this.sourceType,
      sourceNote: sourceNote ?? this.sourceNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      minimumFocalLengthMm: minimumFocalLengthMm ?? this.minimumFocalLengthMm,
      maximumFocalLengthMm: maximumFocalLengthMm ?? this.maximumFocalLengthMm,
      minimumAperture: minimumAperture ?? this.minimumAperture,
      maximumFocalLengthMinimumAperture:
          maximumFocalLengthMinimumAperture ??
          this.maximumFocalLengthMinimumAperture,
      minimumFocusDistanceMm:
          minimumFocusDistanceMm ?? this.minimumFocusDistanceMm,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceNote.present) {
      map['source_note'] = Variable<String>(sourceNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (minimumFocalLengthMm.present) {
      map['minimum_focal_length_mm'] = Variable<double>(
        minimumFocalLengthMm.value,
      );
    }
    if (maximumFocalLengthMm.present) {
      map['maximum_focal_length_mm'] = Variable<double>(
        maximumFocalLengthMm.value,
      );
    }
    if (minimumAperture.present) {
      map['minimum_aperture'] = Variable<double>(minimumAperture.value);
    }
    if (maximumFocalLengthMinimumAperture.present) {
      map['maximum_focal_length_minimum_aperture'] = Variable<double>(
        maximumFocalLengthMinimumAperture.value,
      );
    }
    if (minimumFocusDistanceMm.present) {
      map['minimum_focus_distance_mm'] = Variable<double>(
        minimumFocusDistanceMm.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LensesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('minimumFocalLengthMm: $minimumFocalLengthMm, ')
          ..write('maximumFocalLengthMm: $maximumFocalLengthMm, ')
          ..write('minimumAperture: $minimumAperture, ')
          ..write(
            'maximumFocalLengthMinimumAperture: $maximumFocalLengthMinimumAperture, ',
          )
          ..write('minimumFocusDistanceMm: $minimumFocusDistanceMm, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NdFiltersTable extends NdFilters
    with TableInfo<$NdFiltersTable, NdFilter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NdFiltersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    check: () => sourceType.isIn(_sourceTypes),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNoteMeta = const VerificationMeta(
    'sourceNote',
  );
  @override
  late final GeneratedColumn<String> sourceNote = GeneratedColumn<String>(
    'source_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strengthStopsMeta = const VerificationMeta(
    'strengthStops',
  );
  @override
  late final GeneratedColumn<double> strengthStops = GeneratedColumn<double>(
    'strength_stops',
    aliasedName,
    false,
    check: () => ComparableExpr(strengthStops).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opticalDensityMeta = const VerificationMeta(
    'opticalDensity',
  );
  @override
  late final GeneratedColumn<double> opticalDensity = GeneratedColumn<double>(
    'optical_density',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filterFactorMeta = const VerificationMeta(
    'filterFactor',
  );
  @override
  late final GeneratedColumn<double> filterFactor = GeneratedColumn<double>(
    'filter_factor',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    normalizedName,
    sourceType,
    sourceNote,
    createdAt,
    updatedAt,
    archivedAt,
    strengthStops,
    opticalDensity,
    filterFactor,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nd_filters';
  @override
  VerificationContext validateIntegrity(
    Insertable<NdFilter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_note')) {
      context.handle(
        _sourceNoteMeta,
        sourceNote.isAcceptableOrUnknown(data['source_note']!, _sourceNoteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('strength_stops')) {
      context.handle(
        _strengthStopsMeta,
        strengthStops.isAcceptableOrUnknown(
          data['strength_stops']!,
          _strengthStopsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strengthStopsMeta);
    }
    if (data.containsKey('optical_density')) {
      context.handle(
        _opticalDensityMeta,
        opticalDensity.isAcceptableOrUnknown(
          data['optical_density']!,
          _opticalDensityMeta,
        ),
      );
    }
    if (data.containsKey('filter_factor')) {
      context.handle(
        _filterFactorMeta,
        filterFactor.isAcceptableOrUnknown(
          data['filter_factor']!,
          _filterFactorMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NdFilter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NdFilter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      strengthStops: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}strength_stops'],
      )!,
      opticalDensity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}optical_density'],
      ),
      filterFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}filter_factor'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $NdFiltersTable createAlias(String alias) {
    return $NdFiltersTable(attachedDatabase, alias);
  }
}

class NdFilter extends DataClass implements Insertable<NdFilter> {
  final String id;
  final String name;
  final String normalizedName;
  final String sourceType;
  final String? sourceNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final double strengthStops;
  final double? opticalDensity;
  final double? filterFactor;
  final String? notes;
  const NdFilter({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.sourceType,
    this.sourceNote,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    required this.strengthStops,
    this.opticalDensity,
    this.filterFactor,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourceNote != null) {
      map['source_note'] = Variable<String>(sourceNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['strength_stops'] = Variable<double>(strengthStops);
    if (!nullToAbsent || opticalDensity != null) {
      map['optical_density'] = Variable<double>(opticalDensity);
    }
    if (!nullToAbsent || filterFactor != null) {
      map['filter_factor'] = Variable<double>(filterFactor);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  NdFiltersCompanion toCompanion(bool nullToAbsent) {
    return NdFiltersCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      sourceType: Value(sourceType),
      sourceNote: sourceNote == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceNote),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      strengthStops: Value(strengthStops),
      opticalDensity: opticalDensity == null && nullToAbsent
          ? const Value.absent()
          : Value(opticalDensity),
      filterFactor: filterFactor == null && nullToAbsent
          ? const Value.absent()
          : Value(filterFactor),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory NdFilter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NdFilter(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceNote: serializer.fromJson<String?>(json['sourceNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      strengthStops: serializer.fromJson<double>(json['strengthStops']),
      opticalDensity: serializer.fromJson<double?>(json['opticalDensity']),
      filterFactor: serializer.fromJson<double?>(json['filterFactor']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceNote': serializer.toJson<String?>(sourceNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'strengthStops': serializer.toJson<double>(strengthStops),
      'opticalDensity': serializer.toJson<double?>(opticalDensity),
      'filterFactor': serializer.toJson<double?>(filterFactor),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  NdFilter copyWith({
    String? id,
    String? name,
    String? normalizedName,
    String? sourceType,
    Value<String?> sourceNote = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    double? strengthStops,
    Value<double?> opticalDensity = const Value.absent(),
    Value<double?> filterFactor = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => NdFilter(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    sourceType: sourceType ?? this.sourceType,
    sourceNote: sourceNote.present ? sourceNote.value : this.sourceNote,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    strengthStops: strengthStops ?? this.strengthStops,
    opticalDensity: opticalDensity.present
        ? opticalDensity.value
        : this.opticalDensity,
    filterFactor: filterFactor.present ? filterFactor.value : this.filterFactor,
    notes: notes.present ? notes.value : this.notes,
  );
  NdFilter copyWithCompanion(NdFiltersCompanion data) {
    return NdFilter(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceNote: data.sourceNote.present
          ? data.sourceNote.value
          : this.sourceNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      strengthStops: data.strengthStops.present
          ? data.strengthStops.value
          : this.strengthStops,
      opticalDensity: data.opticalDensity.present
          ? data.opticalDensity.value
          : this.opticalDensity,
      filterFactor: data.filterFactor.present
          ? data.filterFactor.value
          : this.filterFactor,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NdFilter(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('strengthStops: $strengthStops, ')
          ..write('opticalDensity: $opticalDensity, ')
          ..write('filterFactor: $filterFactor, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    normalizedName,
    sourceType,
    sourceNote,
    createdAt,
    updatedAt,
    archivedAt,
    strengthStops,
    opticalDensity,
    filterFactor,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NdFilter &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.sourceType == this.sourceType &&
          other.sourceNote == this.sourceNote &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt &&
          other.strengthStops == this.strengthStops &&
          other.opticalDensity == this.opticalDensity &&
          other.filterFactor == this.filterFactor &&
          other.notes == this.notes);
}

class NdFiltersCompanion extends UpdateCompanion<NdFilter> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String> sourceType;
  final Value<String?> sourceNote;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<double> strengthStops;
  final Value<double?> opticalDensity;
  final Value<double?> filterFactor;
  final Value<String?> notes;
  final Value<int> rowid;
  const NdFiltersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.strengthStops = const Value.absent(),
    this.opticalDensity = const Value.absent(),
    this.filterFactor = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NdFiltersCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    required String sourceType,
    this.sourceNote = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    required double strengthStops,
    this.opticalDensity = const Value.absent(),
    this.filterFactor = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName),
       sourceType = Value(sourceType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       strengthStops = Value(strengthStops);
  static Insertable<NdFilter> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? sourceType,
    Expression<String>? sourceNote,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<double>? strengthStops,
    Expression<double>? opticalDensity,
    Expression<double>? filterFactor,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceNote != null) 'source_note': sourceNote,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (strengthStops != null) 'strength_stops': strengthStops,
      if (opticalDensity != null) 'optical_density': opticalDensity,
      if (filterFactor != null) 'filter_factor': filterFactor,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NdFiltersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<String>? sourceType,
    Value<String?>? sourceNote,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<double>? strengthStops,
    Value<double?>? opticalDensity,
    Value<double?>? filterFactor,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return NdFiltersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      sourceType: sourceType ?? this.sourceType,
      sourceNote: sourceNote ?? this.sourceNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      strengthStops: strengthStops ?? this.strengthStops,
      opticalDensity: opticalDensity ?? this.opticalDensity,
      filterFactor: filterFactor ?? this.filterFactor,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceNote.present) {
      map['source_note'] = Variable<String>(sourceNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (strengthStops.present) {
      map['strength_stops'] = Variable<double>(strengthStops.value);
    }
    if (opticalDensity.present) {
      map['optical_density'] = Variable<double>(opticalDensity.value);
    }
    if (filterFactor.present) {
      map['filter_factor'] = Variable<double>(filterFactor.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NdFiltersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('strengthStops: $strengthStops, ')
          ..write('opticalDensity: $opticalDensity, ')
          ..write('filterFactor: $filterFactor, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OpticalAccessoriesTable extends OpticalAccessories
    with TableInfo<$OpticalAccessoriesTable, OpticalAccessory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OpticalAccessoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    check: () => sourceType.isIn(_sourceTypes),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNoteMeta = const VerificationMeta(
    'sourceNote',
  );
  @override
  late final GeneratedColumn<String> sourceNote = GeneratedColumn<String>(
    'source_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(const <String>['extension_tube', 'teleconverter']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    check: () => ComparableExpr(value).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    normalizedName,
    sourceType,
    sourceNote,
    createdAt,
    updatedAt,
    archivedAt,
    kind,
    value,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'optical_accessories';
  @override
  VerificationContext validateIntegrity(
    Insertable<OpticalAccessory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_note')) {
      context.handle(
        _sourceNoteMeta,
        sourceNote.isAcceptableOrUnknown(data['source_note']!, _sourceNoteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OpticalAccessory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OpticalAccessory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $OpticalAccessoriesTable createAlias(String alias) {
    return $OpticalAccessoriesTable(attachedDatabase, alias);
  }
}

class OpticalAccessory extends DataClass
    implements Insertable<OpticalAccessory> {
  final String id;
  final String name;
  final String normalizedName;
  final String sourceType;
  final String? sourceNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final String kind;
  final double value;
  final String? notes;
  const OpticalAccessory({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.sourceType,
    this.sourceNote,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    required this.kind,
    required this.value,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourceNote != null) {
      map['source_note'] = Variable<String>(sourceNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['kind'] = Variable<String>(kind);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  OpticalAccessoriesCompanion toCompanion(bool nullToAbsent) {
    return OpticalAccessoriesCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      sourceType: Value(sourceType),
      sourceNote: sourceNote == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceNote),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      kind: Value(kind),
      value: Value(value),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory OpticalAccessory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OpticalAccessory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceNote: serializer.fromJson<String?>(json['sourceNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      kind: serializer.fromJson<String>(json['kind']),
      value: serializer.fromJson<double>(json['value']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceNote': serializer.toJson<String?>(sourceNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'kind': serializer.toJson<String>(kind),
      'value': serializer.toJson<double>(value),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  OpticalAccessory copyWith({
    String? id,
    String? name,
    String? normalizedName,
    String? sourceType,
    Value<String?> sourceNote = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    String? kind,
    double? value,
    Value<String?> notes = const Value.absent(),
  }) => OpticalAccessory(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    sourceType: sourceType ?? this.sourceType,
    sourceNote: sourceNote.present ? sourceNote.value : this.sourceNote,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    kind: kind ?? this.kind,
    value: value ?? this.value,
    notes: notes.present ? notes.value : this.notes,
  );
  OpticalAccessory copyWithCompanion(OpticalAccessoriesCompanion data) {
    return OpticalAccessory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceNote: data.sourceNote.present
          ? data.sourceNote.value
          : this.sourceNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OpticalAccessory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    normalizedName,
    sourceType,
    sourceNote,
    createdAt,
    updatedAt,
    archivedAt,
    kind,
    value,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OpticalAccessory &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.sourceType == this.sourceType &&
          other.sourceNote == this.sourceNote &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt &&
          other.kind == this.kind &&
          other.value == this.value &&
          other.notes == this.notes);
}

class OpticalAccessoriesCompanion extends UpdateCompanion<OpticalAccessory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String> sourceType;
  final Value<String?> sourceNote;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<String> kind;
  final Value<double> value;
  final Value<String?> notes;
  final Value<int> rowid;
  const OpticalAccessoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OpticalAccessoriesCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    required String sourceType,
    this.sourceNote = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    required String kind,
    required double value,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName),
       sourceType = Value(sourceType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       kind = Value(kind),
       value = Value(value);
  static Insertable<OpticalAccessory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? sourceType,
    Expression<String>? sourceNote,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<String>? kind,
    Expression<double>? value,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceNote != null) 'source_note': sourceNote,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OpticalAccessoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<String>? sourceType,
    Value<String?>? sourceNote,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<String>? kind,
    Value<double>? value,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return OpticalAccessoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      sourceType: sourceType ?? this.sourceType,
      sourceNote: sourceNote ?? this.sourceNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceNote.present) {
      map['source_note'] = Variable<String>(sourceNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OpticalAccessoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalculationSnapshotsTable extends CalculationSnapshots
    with TableInfo<$CalculationSnapshotsTable, CalculationSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalculationSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calculatorIdMeta = const VerificationMeta(
    'calculatorId',
  );
  @override
  late final GeneratedColumn<String> calculatorId = GeneratedColumn<String>(
    'calculator_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formulaVersionMeta = const VerificationMeta(
    'formulaVersion',
  );
  @override
  late final GeneratedColumn<int> formulaVersion = GeneratedColumn<int>(
    'formula_version',
    aliasedName,
    false,
    check: () => ComparableExpr(formulaVersion).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadVersionMeta = const VerificationMeta(
    'payloadVersion',
  );
  @override
  late final GeneratedColumn<int> payloadVersion = GeneratedColumn<int>(
    'payload_version',
    aliasedName,
    false,
    check: () => ComparableExpr(payloadVersion).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputPayloadMeta = const VerificationMeta(
    'inputPayload',
  );
  @override
  late final GeneratedColumn<String> inputPayload = GeneratedColumn<String>(
    'input_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputPayloadMeta = const VerificationMeta(
    'outputPayload',
  );
  @override
  late final GeneratedColumn<String> outputPayload = GeneratedColumn<String>(
    'output_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayContextMeta = const VerificationMeta(
    'displayContext',
  );
  @override
  late final GeneratedColumn<String> displayContext = GeneratedColumn<String>(
    'display_context',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assumptionsMeta = const VerificationMeta(
    'assumptions',
  );
  @override
  late final GeneratedColumn<String> assumptions = GeneratedColumn<String>(
    'assumptions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warningsMeta = const VerificationMeta(
    'warnings',
  );
  @override
  late final GeneratedColumn<String> warnings = GeneratedColumn<String>(
    'warnings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentSnapshotMeta = const VerificationMeta(
    'equipmentSnapshot',
  );
  @override
  late final GeneratedColumn<String> equipmentSnapshot =
      GeneratedColumn<String>(
        'equipment_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    calculatorId,
    formulaVersion,
    createdAt,
    title,
    notes,
    payloadVersion,
    inputPayload,
    outputPayload,
    displayContext,
    assumptions,
    warnings,
    equipmentSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calculation_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalculationSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('calculator_id')) {
      context.handle(
        _calculatorIdMeta,
        calculatorId.isAcceptableOrUnknown(
          data['calculator_id']!,
          _calculatorIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculatorIdMeta);
    }
    if (data.containsKey('formula_version')) {
      context.handle(
        _formulaVersionMeta,
        formulaVersion.isAcceptableOrUnknown(
          data['formula_version']!,
          _formulaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formulaVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('payload_version')) {
      context.handle(
        _payloadVersionMeta,
        payloadVersion.isAcceptableOrUnknown(
          data['payload_version']!,
          _payloadVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadVersionMeta);
    }
    if (data.containsKey('input_payload')) {
      context.handle(
        _inputPayloadMeta,
        inputPayload.isAcceptableOrUnknown(
          data['input_payload']!,
          _inputPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputPayloadMeta);
    }
    if (data.containsKey('output_payload')) {
      context.handle(
        _outputPayloadMeta,
        outputPayload.isAcceptableOrUnknown(
          data['output_payload']!,
          _outputPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outputPayloadMeta);
    }
    if (data.containsKey('display_context')) {
      context.handle(
        _displayContextMeta,
        displayContext.isAcceptableOrUnknown(
          data['display_context']!,
          _displayContextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayContextMeta);
    }
    if (data.containsKey('assumptions')) {
      context.handle(
        _assumptionsMeta,
        assumptions.isAcceptableOrUnknown(
          data['assumptions']!,
          _assumptionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assumptionsMeta);
    }
    if (data.containsKey('warnings')) {
      context.handle(
        _warningsMeta,
        warnings.isAcceptableOrUnknown(data['warnings']!, _warningsMeta),
      );
    } else if (isInserting) {
      context.missing(_warningsMeta);
    }
    if (data.containsKey('equipment_snapshot')) {
      context.handle(
        _equipmentSnapshotMeta,
        equipmentSnapshot.isAcceptableOrUnknown(
          data['equipment_snapshot']!,
          _equipmentSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_equipmentSnapshotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalculationSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalculationSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      calculatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calculator_id'],
      )!,
      formulaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}formula_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      payloadVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payload_version'],
      )!,
      inputPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_payload'],
      )!,
      outputPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_payload'],
      )!,
      displayContext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_context'],
      )!,
      assumptions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assumptions'],
      )!,
      warnings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warnings'],
      )!,
      equipmentSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_snapshot'],
      )!,
    );
  }

  @override
  $CalculationSnapshotsTable createAlias(String alias) {
    return $CalculationSnapshotsTable(attachedDatabase, alias);
  }
}

class CalculationSnapshot extends DataClass
    implements Insertable<CalculationSnapshot> {
  final String id;
  final String calculatorId;
  final int formulaVersion;
  final DateTime createdAt;
  final String title;
  final String? notes;
  final int payloadVersion;
  final String inputPayload;
  final String outputPayload;
  final String displayContext;
  final String assumptions;
  final String warnings;
  final String equipmentSnapshot;
  const CalculationSnapshot({
    required this.id,
    required this.calculatorId,
    required this.formulaVersion,
    required this.createdAt,
    required this.title,
    this.notes,
    required this.payloadVersion,
    required this.inputPayload,
    required this.outputPayload,
    required this.displayContext,
    required this.assumptions,
    required this.warnings,
    required this.equipmentSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['calculator_id'] = Variable<String>(calculatorId);
    map['formula_version'] = Variable<int>(formulaVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['payload_version'] = Variable<int>(payloadVersion);
    map['input_payload'] = Variable<String>(inputPayload);
    map['output_payload'] = Variable<String>(outputPayload);
    map['display_context'] = Variable<String>(displayContext);
    map['assumptions'] = Variable<String>(assumptions);
    map['warnings'] = Variable<String>(warnings);
    map['equipment_snapshot'] = Variable<String>(equipmentSnapshot);
    return map;
  }

  CalculationSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return CalculationSnapshotsCompanion(
      id: Value(id),
      calculatorId: Value(calculatorId),
      formulaVersion: Value(formulaVersion),
      createdAt: Value(createdAt),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      payloadVersion: Value(payloadVersion),
      inputPayload: Value(inputPayload),
      outputPayload: Value(outputPayload),
      displayContext: Value(displayContext),
      assumptions: Value(assumptions),
      warnings: Value(warnings),
      equipmentSnapshot: Value(equipmentSnapshot),
    );
  }

  factory CalculationSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalculationSnapshot(
      id: serializer.fromJson<String>(json['id']),
      calculatorId: serializer.fromJson<String>(json['calculatorId']),
      formulaVersion: serializer.fromJson<int>(json['formulaVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      payloadVersion: serializer.fromJson<int>(json['payloadVersion']),
      inputPayload: serializer.fromJson<String>(json['inputPayload']),
      outputPayload: serializer.fromJson<String>(json['outputPayload']),
      displayContext: serializer.fromJson<String>(json['displayContext']),
      assumptions: serializer.fromJson<String>(json['assumptions']),
      warnings: serializer.fromJson<String>(json['warnings']),
      equipmentSnapshot: serializer.fromJson<String>(json['equipmentSnapshot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'calculatorId': serializer.toJson<String>(calculatorId),
      'formulaVersion': serializer.toJson<int>(formulaVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'payloadVersion': serializer.toJson<int>(payloadVersion),
      'inputPayload': serializer.toJson<String>(inputPayload),
      'outputPayload': serializer.toJson<String>(outputPayload),
      'displayContext': serializer.toJson<String>(displayContext),
      'assumptions': serializer.toJson<String>(assumptions),
      'warnings': serializer.toJson<String>(warnings),
      'equipmentSnapshot': serializer.toJson<String>(equipmentSnapshot),
    };
  }

  CalculationSnapshot copyWith({
    String? id,
    String? calculatorId,
    int? formulaVersion,
    DateTime? createdAt,
    String? title,
    Value<String?> notes = const Value.absent(),
    int? payloadVersion,
    String? inputPayload,
    String? outputPayload,
    String? displayContext,
    String? assumptions,
    String? warnings,
    String? equipmentSnapshot,
  }) => CalculationSnapshot(
    id: id ?? this.id,
    calculatorId: calculatorId ?? this.calculatorId,
    formulaVersion: formulaVersion ?? this.formulaVersion,
    createdAt: createdAt ?? this.createdAt,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    payloadVersion: payloadVersion ?? this.payloadVersion,
    inputPayload: inputPayload ?? this.inputPayload,
    outputPayload: outputPayload ?? this.outputPayload,
    displayContext: displayContext ?? this.displayContext,
    assumptions: assumptions ?? this.assumptions,
    warnings: warnings ?? this.warnings,
    equipmentSnapshot: equipmentSnapshot ?? this.equipmentSnapshot,
  );
  CalculationSnapshot copyWithCompanion(CalculationSnapshotsCompanion data) {
    return CalculationSnapshot(
      id: data.id.present ? data.id.value : this.id,
      calculatorId: data.calculatorId.present
          ? data.calculatorId.value
          : this.calculatorId,
      formulaVersion: data.formulaVersion.present
          ? data.formulaVersion.value
          : this.formulaVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      payloadVersion: data.payloadVersion.present
          ? data.payloadVersion.value
          : this.payloadVersion,
      inputPayload: data.inputPayload.present
          ? data.inputPayload.value
          : this.inputPayload,
      outputPayload: data.outputPayload.present
          ? data.outputPayload.value
          : this.outputPayload,
      displayContext: data.displayContext.present
          ? data.displayContext.value
          : this.displayContext,
      assumptions: data.assumptions.present
          ? data.assumptions.value
          : this.assumptions,
      warnings: data.warnings.present ? data.warnings.value : this.warnings,
      equipmentSnapshot: data.equipmentSnapshot.present
          ? data.equipmentSnapshot.value
          : this.equipmentSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalculationSnapshot(')
          ..write('id: $id, ')
          ..write('calculatorId: $calculatorId, ')
          ..write('formulaVersion: $formulaVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('inputPayload: $inputPayload, ')
          ..write('outputPayload: $outputPayload, ')
          ..write('displayContext: $displayContext, ')
          ..write('assumptions: $assumptions, ')
          ..write('warnings: $warnings, ')
          ..write('equipmentSnapshot: $equipmentSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    calculatorId,
    formulaVersion,
    createdAt,
    title,
    notes,
    payloadVersion,
    inputPayload,
    outputPayload,
    displayContext,
    assumptions,
    warnings,
    equipmentSnapshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalculationSnapshot &&
          other.id == this.id &&
          other.calculatorId == this.calculatorId &&
          other.formulaVersion == this.formulaVersion &&
          other.createdAt == this.createdAt &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.payloadVersion == this.payloadVersion &&
          other.inputPayload == this.inputPayload &&
          other.outputPayload == this.outputPayload &&
          other.displayContext == this.displayContext &&
          other.assumptions == this.assumptions &&
          other.warnings == this.warnings &&
          other.equipmentSnapshot == this.equipmentSnapshot);
}

class CalculationSnapshotsCompanion
    extends UpdateCompanion<CalculationSnapshot> {
  final Value<String> id;
  final Value<String> calculatorId;
  final Value<int> formulaVersion;
  final Value<DateTime> createdAt;
  final Value<String> title;
  final Value<String?> notes;
  final Value<int> payloadVersion;
  final Value<String> inputPayload;
  final Value<String> outputPayload;
  final Value<String> displayContext;
  final Value<String> assumptions;
  final Value<String> warnings;
  final Value<String> equipmentSnapshot;
  final Value<int> rowid;
  const CalculationSnapshotsCompanion({
    this.id = const Value.absent(),
    this.calculatorId = const Value.absent(),
    this.formulaVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.payloadVersion = const Value.absent(),
    this.inputPayload = const Value.absent(),
    this.outputPayload = const Value.absent(),
    this.displayContext = const Value.absent(),
    this.assumptions = const Value.absent(),
    this.warnings = const Value.absent(),
    this.equipmentSnapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalculationSnapshotsCompanion.insert({
    required String id,
    required String calculatorId,
    required int formulaVersion,
    required DateTime createdAt,
    required String title,
    this.notes = const Value.absent(),
    required int payloadVersion,
    required String inputPayload,
    required String outputPayload,
    required String displayContext,
    required String assumptions,
    required String warnings,
    required String equipmentSnapshot,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       calculatorId = Value(calculatorId),
       formulaVersion = Value(formulaVersion),
       createdAt = Value(createdAt),
       title = Value(title),
       payloadVersion = Value(payloadVersion),
       inputPayload = Value(inputPayload),
       outputPayload = Value(outputPayload),
       displayContext = Value(displayContext),
       assumptions = Value(assumptions),
       warnings = Value(warnings),
       equipmentSnapshot = Value(equipmentSnapshot);
  static Insertable<CalculationSnapshot> custom({
    Expression<String>? id,
    Expression<String>? calculatorId,
    Expression<int>? formulaVersion,
    Expression<DateTime>? createdAt,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<int>? payloadVersion,
    Expression<String>? inputPayload,
    Expression<String>? outputPayload,
    Expression<String>? displayContext,
    Expression<String>? assumptions,
    Expression<String>? warnings,
    Expression<String>? equipmentSnapshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (calculatorId != null) 'calculator_id': calculatorId,
      if (formulaVersion != null) 'formula_version': formulaVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (payloadVersion != null) 'payload_version': payloadVersion,
      if (inputPayload != null) 'input_payload': inputPayload,
      if (outputPayload != null) 'output_payload': outputPayload,
      if (displayContext != null) 'display_context': displayContext,
      if (assumptions != null) 'assumptions': assumptions,
      if (warnings != null) 'warnings': warnings,
      if (equipmentSnapshot != null) 'equipment_snapshot': equipmentSnapshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalculationSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? calculatorId,
    Value<int>? formulaVersion,
    Value<DateTime>? createdAt,
    Value<String>? title,
    Value<String?>? notes,
    Value<int>? payloadVersion,
    Value<String>? inputPayload,
    Value<String>? outputPayload,
    Value<String>? displayContext,
    Value<String>? assumptions,
    Value<String>? warnings,
    Value<String>? equipmentSnapshot,
    Value<int>? rowid,
  }) {
    return CalculationSnapshotsCompanion(
      id: id ?? this.id,
      calculatorId: calculatorId ?? this.calculatorId,
      formulaVersion: formulaVersion ?? this.formulaVersion,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      payloadVersion: payloadVersion ?? this.payloadVersion,
      inputPayload: inputPayload ?? this.inputPayload,
      outputPayload: outputPayload ?? this.outputPayload,
      displayContext: displayContext ?? this.displayContext,
      assumptions: assumptions ?? this.assumptions,
      warnings: warnings ?? this.warnings,
      equipmentSnapshot: equipmentSnapshot ?? this.equipmentSnapshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (calculatorId.present) {
      map['calculator_id'] = Variable<String>(calculatorId.value);
    }
    if (formulaVersion.present) {
      map['formula_version'] = Variable<int>(formulaVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (payloadVersion.present) {
      map['payload_version'] = Variable<int>(payloadVersion.value);
    }
    if (inputPayload.present) {
      map['input_payload'] = Variable<String>(inputPayload.value);
    }
    if (outputPayload.present) {
      map['output_payload'] = Variable<String>(outputPayload.value);
    }
    if (displayContext.present) {
      map['display_context'] = Variable<String>(displayContext.value);
    }
    if (assumptions.present) {
      map['assumptions'] = Variable<String>(assumptions.value);
    }
    if (warnings.present) {
      map['warnings'] = Variable<String>(warnings.value);
    }
    if (equipmentSnapshot.present) {
      map['equipment_snapshot'] = Variable<String>(equipmentSnapshot.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalculationSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('calculatorId: $calculatorId, ')
          ..write('formulaVersion: $formulaVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('inputPayload: $inputPayload, ')
          ..write('outputPayload: $outputPayload, ')
          ..write('displayContext: $displayContext, ')
          ..write('assumptions: $assumptions, ')
          ..write('warnings: $warnings, ')
          ..write('equipmentSnapshot: $equipmentSnapshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnapshotEquipmentReferencesTable extends SnapshotEquipmentReferences
    with
        TableInfo<
          $SnapshotEquipmentReferencesTable,
          SnapshotEquipmentReference
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotEquipmentReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _snapshotIdMeta = const VerificationMeta(
    'snapshotId',
  );
  @override
  late final GeneratedColumn<String> snapshotId = GeneratedColumn<String>(
    'snapshot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calculation_snapshots (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _equipmentIdMeta = const VerificationMeta(
    'equipmentId',
  );
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
    'equipment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentTypeMeta = const VerificationMeta(
    'equipmentType',
  );
  @override
  late final GeneratedColumn<String> equipmentType = GeneratedColumn<String>(
    'equipment_type',
    aliasedName,
    false,
    check: () => equipmentType.isIn(_equipmentTypes),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    check: () => ComparableExpr(displayOrder).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    snapshotId,
    equipmentId,
    equipmentType,
    displayOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshot_equipment_references';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotEquipmentReference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('snapshot_id')) {
      context.handle(
        _snapshotIdMeta,
        snapshotId.isAcceptableOrUnknown(data['snapshot_id']!, _snapshotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotIdMeta);
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
        _equipmentIdMeta,
        equipmentId.isAcceptableOrUnknown(
          data['equipment_id']!,
          _equipmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_equipmentIdMeta);
    }
    if (data.containsKey('equipment_type')) {
      context.handle(
        _equipmentTypeMeta,
        equipmentType.isAcceptableOrUnknown(
          data['equipment_type']!,
          _equipmentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_equipmentTypeMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    snapshotId,
    equipmentId,
    equipmentType,
  };
  @override
  SnapshotEquipmentReference map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotEquipmentReference(
      snapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_id'],
      )!,
      equipmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_id'],
      )!,
      equipmentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_type'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
    );
  }

  @override
  $SnapshotEquipmentReferencesTable createAlias(String alias) {
    return $SnapshotEquipmentReferencesTable(attachedDatabase, alias);
  }
}

class SnapshotEquipmentReference extends DataClass
    implements Insertable<SnapshotEquipmentReference> {
  final String snapshotId;
  final String equipmentId;
  final String equipmentType;
  final int displayOrder;
  const SnapshotEquipmentReference({
    required this.snapshotId,
    required this.equipmentId,
    required this.equipmentType,
    required this.displayOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['snapshot_id'] = Variable<String>(snapshotId);
    map['equipment_id'] = Variable<String>(equipmentId);
    map['equipment_type'] = Variable<String>(equipmentType);
    map['display_order'] = Variable<int>(displayOrder);
    return map;
  }

  SnapshotEquipmentReferencesCompanion toCompanion(bool nullToAbsent) {
    return SnapshotEquipmentReferencesCompanion(
      snapshotId: Value(snapshotId),
      equipmentId: Value(equipmentId),
      equipmentType: Value(equipmentType),
      displayOrder: Value(displayOrder),
    );
  }

  factory SnapshotEquipmentReference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotEquipmentReference(
      snapshotId: serializer.fromJson<String>(json['snapshotId']),
      equipmentId: serializer.fromJson<String>(json['equipmentId']),
      equipmentType: serializer.fromJson<String>(json['equipmentType']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'snapshotId': serializer.toJson<String>(snapshotId),
      'equipmentId': serializer.toJson<String>(equipmentId),
      'equipmentType': serializer.toJson<String>(equipmentType),
      'displayOrder': serializer.toJson<int>(displayOrder),
    };
  }

  SnapshotEquipmentReference copyWith({
    String? snapshotId,
    String? equipmentId,
    String? equipmentType,
    int? displayOrder,
  }) => SnapshotEquipmentReference(
    snapshotId: snapshotId ?? this.snapshotId,
    equipmentId: equipmentId ?? this.equipmentId,
    equipmentType: equipmentType ?? this.equipmentType,
    displayOrder: displayOrder ?? this.displayOrder,
  );
  SnapshotEquipmentReference copyWithCompanion(
    SnapshotEquipmentReferencesCompanion data,
  ) {
    return SnapshotEquipmentReference(
      snapshotId: data.snapshotId.present
          ? data.snapshotId.value
          : this.snapshotId,
      equipmentId: data.equipmentId.present
          ? data.equipmentId.value
          : this.equipmentId,
      equipmentType: data.equipmentType.present
          ? data.equipmentType.value
          : this.equipmentType,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotEquipmentReference(')
          ..write('snapshotId: $snapshotId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('equipmentType: $equipmentType, ')
          ..write('displayOrder: $displayOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(snapshotId, equipmentId, equipmentType, displayOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotEquipmentReference &&
          other.snapshotId == this.snapshotId &&
          other.equipmentId == this.equipmentId &&
          other.equipmentType == this.equipmentType &&
          other.displayOrder == this.displayOrder);
}

class SnapshotEquipmentReferencesCompanion
    extends UpdateCompanion<SnapshotEquipmentReference> {
  final Value<String> snapshotId;
  final Value<String> equipmentId;
  final Value<String> equipmentType;
  final Value<int> displayOrder;
  final Value<int> rowid;
  const SnapshotEquipmentReferencesCompanion({
    this.snapshotId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.equipmentType = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotEquipmentReferencesCompanion.insert({
    required String snapshotId,
    required String equipmentId,
    required String equipmentType,
    required int displayOrder,
    this.rowid = const Value.absent(),
  }) : snapshotId = Value(snapshotId),
       equipmentId = Value(equipmentId),
       equipmentType = Value(equipmentType),
       displayOrder = Value(displayOrder);
  static Insertable<SnapshotEquipmentReference> custom({
    Expression<String>? snapshotId,
    Expression<String>? equipmentId,
    Expression<String>? equipmentType,
    Expression<int>? displayOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (equipmentType != null) 'equipment_type': equipmentType,
      if (displayOrder != null) 'display_order': displayOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotEquipmentReferencesCompanion copyWith({
    Value<String>? snapshotId,
    Value<String>? equipmentId,
    Value<String>? equipmentType,
    Value<int>? displayOrder,
    Value<int>? rowid,
  }) {
    return SnapshotEquipmentReferencesCompanion(
      snapshotId: snapshotId ?? this.snapshotId,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentType: equipmentType ?? this.equipmentType,
      displayOrder: displayOrder ?? this.displayOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<String>(snapshotId.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (equipmentType.present) {
      map['equipment_type'] = Variable<String>(equipmentType.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotEquipmentReferencesCompanion(')
          ..write('snapshotId: $snapshotId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('equipmentType: $equipmentType, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTable extends UserPreferences
    with TableInfo<$UserPreferencesTable, UserPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(1),
  );
  static const VerificationMeta _lengthDisplayMeta = const VerificationMeta(
    'lengthDisplay',
  );
  @override
  late final GeneratedColumn<String> lengthDisplay = GeneratedColumn<String>(
    'length_display',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('metric'),
  );
  static const VerificationMeta _shutterDisplayMeta = const VerificationMeta(
    'shutterDisplay',
  );
  @override
  late final GeneratedColumn<String> shutterDisplay = GeneratedColumn<String>(
    'shutter_display',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('exact'),
  );
  static const VerificationMeta _fractionStepMeta = const VerificationMeta(
    'fractionStep',
  );
  @override
  late final GeneratedColumn<String> fractionStep = GeneratedColumn<String>(
    'fraction_step',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('third'),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('system'),
  );
  static const VerificationMeta _favoriteToolIdsMeta = const VerificationMeta(
    'favoriteToolIds',
  );
  @override
  late final GeneratedColumn<String> favoriteToolIds = GeneratedColumn<String>(
    'favorite_tool_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('[]'),
  );
  static const VerificationMeta _northReferenceMeta = const VerificationMeta(
    'northReference',
  );
  @override
  late final GeneratedColumn<String> northReference = GeneratedColumn<String>(
    'north_reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('trueNorth'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lengthDisplay,
    shutterDisplay,
    fractionStep,
    themeMode,
    favoriteToolIds,
    northReference,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('length_display')) {
      context.handle(
        _lengthDisplayMeta,
        lengthDisplay.isAcceptableOrUnknown(
          data['length_display']!,
          _lengthDisplayMeta,
        ),
      );
    }
    if (data.containsKey('shutter_display')) {
      context.handle(
        _shutterDisplayMeta,
        shutterDisplay.isAcceptableOrUnknown(
          data['shutter_display']!,
          _shutterDisplayMeta,
        ),
      );
    }
    if (data.containsKey('fraction_step')) {
      context.handle(
        _fractionStepMeta,
        fractionStep.isAcceptableOrUnknown(
          data['fraction_step']!,
          _fractionStepMeta,
        ),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('favorite_tool_ids')) {
      context.handle(
        _favoriteToolIdsMeta,
        favoriteToolIds.isAcceptableOrUnknown(
          data['favorite_tool_ids']!,
          _favoriteToolIdsMeta,
        ),
      );
    }
    if (data.containsKey('north_reference')) {
      context.handle(
        _northReferenceMeta,
        northReference.isAcceptableOrUnknown(
          data['north_reference']!,
          _northReferenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lengthDisplay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}length_display'],
      )!,
      shutterDisplay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shutter_display'],
      )!,
      fractionStep: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fraction_step'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      favoriteToolIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}favorite_tool_ids'],
      )!,
      northReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}north_reference'],
      )!,
    );
  }

  @override
  $UserPreferencesTable createAlias(String alias) {
    return $UserPreferencesTable(attachedDatabase, alias);
  }
}

class UserPreference extends DataClass implements Insertable<UserPreference> {
  final int id;
  final String lengthDisplay;
  final String shutterDisplay;
  final String fractionStep;
  final String themeMode;
  final String favoriteToolIds;
  final String northReference;
  const UserPreference({
    required this.id,
    required this.lengthDisplay,
    required this.shutterDisplay,
    required this.fractionStep,
    required this.themeMode,
    required this.favoriteToolIds,
    required this.northReference,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['length_display'] = Variable<String>(lengthDisplay);
    map['shutter_display'] = Variable<String>(shutterDisplay);
    map['fraction_step'] = Variable<String>(fractionStep);
    map['theme_mode'] = Variable<String>(themeMode);
    map['favorite_tool_ids'] = Variable<String>(favoriteToolIds);
    map['north_reference'] = Variable<String>(northReference);
    return map;
  }

  UserPreferencesCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesCompanion(
      id: Value(id),
      lengthDisplay: Value(lengthDisplay),
      shutterDisplay: Value(shutterDisplay),
      fractionStep: Value(fractionStep),
      themeMode: Value(themeMode),
      favoriteToolIds: Value(favoriteToolIds),
      northReference: Value(northReference),
    );
  }

  factory UserPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreference(
      id: serializer.fromJson<int>(json['id']),
      lengthDisplay: serializer.fromJson<String>(json['lengthDisplay']),
      shutterDisplay: serializer.fromJson<String>(json['shutterDisplay']),
      fractionStep: serializer.fromJson<String>(json['fractionStep']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      favoriteToolIds: serializer.fromJson<String>(json['favoriteToolIds']),
      northReference: serializer.fromJson<String>(json['northReference']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lengthDisplay': serializer.toJson<String>(lengthDisplay),
      'shutterDisplay': serializer.toJson<String>(shutterDisplay),
      'fractionStep': serializer.toJson<String>(fractionStep),
      'themeMode': serializer.toJson<String>(themeMode),
      'favoriteToolIds': serializer.toJson<String>(favoriteToolIds),
      'northReference': serializer.toJson<String>(northReference),
    };
  }

  UserPreference copyWith({
    int? id,
    String? lengthDisplay,
    String? shutterDisplay,
    String? fractionStep,
    String? themeMode,
    String? favoriteToolIds,
    String? northReference,
  }) => UserPreference(
    id: id ?? this.id,
    lengthDisplay: lengthDisplay ?? this.lengthDisplay,
    shutterDisplay: shutterDisplay ?? this.shutterDisplay,
    fractionStep: fractionStep ?? this.fractionStep,
    themeMode: themeMode ?? this.themeMode,
    favoriteToolIds: favoriteToolIds ?? this.favoriteToolIds,
    northReference: northReference ?? this.northReference,
  );
  UserPreference copyWithCompanion(UserPreferencesCompanion data) {
    return UserPreference(
      id: data.id.present ? data.id.value : this.id,
      lengthDisplay: data.lengthDisplay.present
          ? data.lengthDisplay.value
          : this.lengthDisplay,
      shutterDisplay: data.shutterDisplay.present
          ? data.shutterDisplay.value
          : this.shutterDisplay,
      fractionStep: data.fractionStep.present
          ? data.fractionStep.value
          : this.fractionStep,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      favoriteToolIds: data.favoriteToolIds.present
          ? data.favoriteToolIds.value
          : this.favoriteToolIds,
      northReference: data.northReference.present
          ? data.northReference.value
          : this.northReference,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreference(')
          ..write('id: $id, ')
          ..write('lengthDisplay: $lengthDisplay, ')
          ..write('shutterDisplay: $shutterDisplay, ')
          ..write('fractionStep: $fractionStep, ')
          ..write('themeMode: $themeMode, ')
          ..write('favoriteToolIds: $favoriteToolIds, ')
          ..write('northReference: $northReference')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lengthDisplay,
    shutterDisplay,
    fractionStep,
    themeMode,
    favoriteToolIds,
    northReference,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreference &&
          other.id == this.id &&
          other.lengthDisplay == this.lengthDisplay &&
          other.shutterDisplay == this.shutterDisplay &&
          other.fractionStep == this.fractionStep &&
          other.themeMode == this.themeMode &&
          other.favoriteToolIds == this.favoriteToolIds &&
          other.northReference == this.northReference);
}

class UserPreferencesCompanion extends UpdateCompanion<UserPreference> {
  final Value<int> id;
  final Value<String> lengthDisplay;
  final Value<String> shutterDisplay;
  final Value<String> fractionStep;
  final Value<String> themeMode;
  final Value<String> favoriteToolIds;
  final Value<String> northReference;
  const UserPreferencesCompanion({
    this.id = const Value.absent(),
    this.lengthDisplay = const Value.absent(),
    this.shutterDisplay = const Value.absent(),
    this.fractionStep = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.favoriteToolIds = const Value.absent(),
    this.northReference = const Value.absent(),
  });
  UserPreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.lengthDisplay = const Value.absent(),
    this.shutterDisplay = const Value.absent(),
    this.fractionStep = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.favoriteToolIds = const Value.absent(),
    this.northReference = const Value.absent(),
  });
  static Insertable<UserPreference> custom({
    Expression<int>? id,
    Expression<String>? lengthDisplay,
    Expression<String>? shutterDisplay,
    Expression<String>? fractionStep,
    Expression<String>? themeMode,
    Expression<String>? favoriteToolIds,
    Expression<String>? northReference,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lengthDisplay != null) 'length_display': lengthDisplay,
      if (shutterDisplay != null) 'shutter_display': shutterDisplay,
      if (fractionStep != null) 'fraction_step': fractionStep,
      if (themeMode != null) 'theme_mode': themeMode,
      if (favoriteToolIds != null) 'favorite_tool_ids': favoriteToolIds,
      if (northReference != null) 'north_reference': northReference,
    });
  }

  UserPreferencesCompanion copyWith({
    Value<int>? id,
    Value<String>? lengthDisplay,
    Value<String>? shutterDisplay,
    Value<String>? fractionStep,
    Value<String>? themeMode,
    Value<String>? favoriteToolIds,
    Value<String>? northReference,
  }) {
    return UserPreferencesCompanion(
      id: id ?? this.id,
      lengthDisplay: lengthDisplay ?? this.lengthDisplay,
      shutterDisplay: shutterDisplay ?? this.shutterDisplay,
      fractionStep: fractionStep ?? this.fractionStep,
      themeMode: themeMode ?? this.themeMode,
      favoriteToolIds: favoriteToolIds ?? this.favoriteToolIds,
      northReference: northReference ?? this.northReference,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lengthDisplay.present) {
      map['length_display'] = Variable<String>(lengthDisplay.value);
    }
    if (shutterDisplay.present) {
      map['shutter_display'] = Variable<String>(shutterDisplay.value);
    }
    if (fractionStep.present) {
      map['fraction_step'] = Variable<String>(fractionStep.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (favoriteToolIds.present) {
      map['favorite_tool_ids'] = Variable<String>(favoriteToolIds.value);
    }
    if (northReference.present) {
      map['north_reference'] = Variable<String>(northReference.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('lengthDisplay: $lengthDisplay, ')
          ..write('shutterDisplay: $shutterDisplay, ')
          ..write('fractionStep: $fractionStep, ')
          ..write('themeMode: $themeMode, ')
          ..write('favoriteToolIds: $favoriteToolIds, ')
          ..write('northReference: $northReference')
          ..write(')'))
        .toString();
  }
}

class $SavedLocationsTable extends SavedLocations
    with TableInfo<$SavedLocationsTable, SavedLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeDegreesMeta = const VerificationMeta(
    'latitudeDegrees',
  );
  @override
  late final GeneratedColumn<double> latitudeDegrees = GeneratedColumn<double>(
    'latitude_degrees',
    aliasedName,
    false,
    check: () =>
        ComparableExpr(latitudeDegrees).isBiggerOrEqualValue(-90) &
        ComparableExpr(latitudeDegrees).isSmallerOrEqualValue(90),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeDegreesMeta = const VerificationMeta(
    'longitudeDegrees',
  );
  @override
  late final GeneratedColumn<double> longitudeDegrees = GeneratedColumn<double>(
    'longitude_degrees',
    aliasedName,
    false,
    check: () =>
        ComparableExpr(longitudeDegrees).isBiggerOrEqualValue(-180) &
        ComparableExpr(longitudeDegrees).isSmallerOrEqualValue(180),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationMetresMeta = const VerificationMeta(
    'elevationMetres',
  );
  @override
  late final GeneratedColumn<double> elevationMetres = GeneratedColumn<double>(
    'elevation_metres',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneIdMeta = const VerificationMeta(
    'timeZoneId',
  );
  @override
  late final GeneratedColumn<String> timeZoneId = GeneratedColumn<String>(
    'time_zone_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    check: () => source.isIn(const <String>['manual', 'device']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMetresMeta = const VerificationMeta(
    'accuracyMetres',
  );
  @override
  late final GeneratedColumn<double> accuracyMetres = GeneratedColumn<double>(
    'accuracy_metres',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    normalizedName,
    latitudeDegrees,
    longitudeDegrees,
    elevationMetres,
    timeZoneId,
    source,
    accuracyMetres,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedLocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('latitude_degrees')) {
      context.handle(
        _latitudeDegreesMeta,
        latitudeDegrees.isAcceptableOrUnknown(
          data['latitude_degrees']!,
          _latitudeDegreesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_latitudeDegreesMeta);
    }
    if (data.containsKey('longitude_degrees')) {
      context.handle(
        _longitudeDegreesMeta,
        longitudeDegrees.isAcceptableOrUnknown(
          data['longitude_degrees']!,
          _longitudeDegreesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_longitudeDegreesMeta);
    }
    if (data.containsKey('elevation_metres')) {
      context.handle(
        _elevationMetresMeta,
        elevationMetres.isAcceptableOrUnknown(
          data['elevation_metres']!,
          _elevationMetresMeta,
        ),
      );
    }
    if (data.containsKey('time_zone_id')) {
      context.handle(
        _timeZoneIdMeta,
        timeZoneId.isAcceptableOrUnknown(
          data['time_zone_id']!,
          _timeZoneIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeZoneIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('accuracy_metres')) {
      context.handle(
        _accuracyMetresMeta,
        accuracyMetres.isAcceptableOrUnknown(
          data['accuracy_metres']!,
          _accuracyMetresMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedLocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      latitudeDegrees: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude_degrees'],
      )!,
      longitudeDegrees: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude_degrees'],
      )!,
      elevationMetres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_metres'],
      ),
      timeZoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      accuracyMetres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_metres'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SavedLocationsTable createAlias(String alias) {
    return $SavedLocationsTable(attachedDatabase, alias);
  }
}

class SavedLocation extends DataClass implements Insertable<SavedLocation> {
  final String id;
  final String name;
  final String normalizedName;
  final double latitudeDegrees;
  final double longitudeDegrees;
  final double? elevationMetres;
  final String timeZoneId;
  final String source;
  final double? accuracyMetres;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SavedLocation({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.latitudeDegrees,
    required this.longitudeDegrees,
    this.elevationMetres,
    required this.timeZoneId,
    required this.source,
    this.accuracyMetres,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['latitude_degrees'] = Variable<double>(latitudeDegrees);
    map['longitude_degrees'] = Variable<double>(longitudeDegrees);
    if (!nullToAbsent || elevationMetres != null) {
      map['elevation_metres'] = Variable<double>(elevationMetres);
    }
    map['time_zone_id'] = Variable<String>(timeZoneId);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || accuracyMetres != null) {
      map['accuracy_metres'] = Variable<double>(accuracyMetres);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SavedLocationsCompanion toCompanion(bool nullToAbsent) {
    return SavedLocationsCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      latitudeDegrees: Value(latitudeDegrees),
      longitudeDegrees: Value(longitudeDegrees),
      elevationMetres: elevationMetres == null && nullToAbsent
          ? const Value.absent()
          : Value(elevationMetres),
      timeZoneId: Value(timeZoneId),
      source: Value(source),
      accuracyMetres: accuracyMetres == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyMetres),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedLocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedLocation(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      latitudeDegrees: serializer.fromJson<double>(json['latitudeDegrees']),
      longitudeDegrees: serializer.fromJson<double>(json['longitudeDegrees']),
      elevationMetres: serializer.fromJson<double?>(json['elevationMetres']),
      timeZoneId: serializer.fromJson<String>(json['timeZoneId']),
      source: serializer.fromJson<String>(json['source']),
      accuracyMetres: serializer.fromJson<double?>(json['accuracyMetres']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'latitudeDegrees': serializer.toJson<double>(latitudeDegrees),
      'longitudeDegrees': serializer.toJson<double>(longitudeDegrees),
      'elevationMetres': serializer.toJson<double?>(elevationMetres),
      'timeZoneId': serializer.toJson<String>(timeZoneId),
      'source': serializer.toJson<String>(source),
      'accuracyMetres': serializer.toJson<double?>(accuracyMetres),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavedLocation copyWith({
    String? id,
    String? name,
    String? normalizedName,
    double? latitudeDegrees,
    double? longitudeDegrees,
    Value<double?> elevationMetres = const Value.absent(),
    String? timeZoneId,
    String? source,
    Value<double?> accuracyMetres = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SavedLocation(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    latitudeDegrees: latitudeDegrees ?? this.latitudeDegrees,
    longitudeDegrees: longitudeDegrees ?? this.longitudeDegrees,
    elevationMetres: elevationMetres.present
        ? elevationMetres.value
        : this.elevationMetres,
    timeZoneId: timeZoneId ?? this.timeZoneId,
    source: source ?? this.source,
    accuracyMetres: accuracyMetres.present
        ? accuracyMetres.value
        : this.accuracyMetres,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SavedLocation copyWithCompanion(SavedLocationsCompanion data) {
    return SavedLocation(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      latitudeDegrees: data.latitudeDegrees.present
          ? data.latitudeDegrees.value
          : this.latitudeDegrees,
      longitudeDegrees: data.longitudeDegrees.present
          ? data.longitudeDegrees.value
          : this.longitudeDegrees,
      elevationMetres: data.elevationMetres.present
          ? data.elevationMetres.value
          : this.elevationMetres,
      timeZoneId: data.timeZoneId.present
          ? data.timeZoneId.value
          : this.timeZoneId,
      source: data.source.present ? data.source.value : this.source,
      accuracyMetres: data.accuracyMetres.present
          ? data.accuracyMetres.value
          : this.accuracyMetres,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedLocation(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('latitudeDegrees: $latitudeDegrees, ')
          ..write('longitudeDegrees: $longitudeDegrees, ')
          ..write('elevationMetres: $elevationMetres, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('source: $source, ')
          ..write('accuracyMetres: $accuracyMetres, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    normalizedName,
    latitudeDegrees,
    longitudeDegrees,
    elevationMetres,
    timeZoneId,
    source,
    accuracyMetres,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedLocation &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.latitudeDegrees == this.latitudeDegrees &&
          other.longitudeDegrees == this.longitudeDegrees &&
          other.elevationMetres == this.elevationMetres &&
          other.timeZoneId == this.timeZoneId &&
          other.source == this.source &&
          other.accuracyMetres == this.accuracyMetres &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SavedLocationsCompanion extends UpdateCompanion<SavedLocation> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<double> latitudeDegrees;
  final Value<double> longitudeDegrees;
  final Value<double?> elevationMetres;
  final Value<String> timeZoneId;
  final Value<String> source;
  final Value<double?> accuracyMetres;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SavedLocationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.latitudeDegrees = const Value.absent(),
    this.longitudeDegrees = const Value.absent(),
    this.elevationMetres = const Value.absent(),
    this.timeZoneId = const Value.absent(),
    this.source = const Value.absent(),
    this.accuracyMetres = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedLocationsCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    required double latitudeDegrees,
    required double longitudeDegrees,
    this.elevationMetres = const Value.absent(),
    required String timeZoneId,
    required String source,
    this.accuracyMetres = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName),
       latitudeDegrees = Value(latitudeDegrees),
       longitudeDegrees = Value(longitudeDegrees),
       timeZoneId = Value(timeZoneId),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SavedLocation> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<double>? latitudeDegrees,
    Expression<double>? longitudeDegrees,
    Expression<double>? elevationMetres,
    Expression<String>? timeZoneId,
    Expression<String>? source,
    Expression<double>? accuracyMetres,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (latitudeDegrees != null) 'latitude_degrees': latitudeDegrees,
      if (longitudeDegrees != null) 'longitude_degrees': longitudeDegrees,
      if (elevationMetres != null) 'elevation_metres': elevationMetres,
      if (timeZoneId != null) 'time_zone_id': timeZoneId,
      if (source != null) 'source': source,
      if (accuracyMetres != null) 'accuracy_metres': accuracyMetres,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedLocationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<double>? latitudeDegrees,
    Value<double>? longitudeDegrees,
    Value<double?>? elevationMetres,
    Value<String>? timeZoneId,
    Value<String>? source,
    Value<double?>? accuracyMetres,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SavedLocationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      latitudeDegrees: latitudeDegrees ?? this.latitudeDegrees,
      longitudeDegrees: longitudeDegrees ?? this.longitudeDegrees,
      elevationMetres: elevationMetres ?? this.elevationMetres,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      source: source ?? this.source,
      accuracyMetres: accuracyMetres ?? this.accuracyMetres,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (latitudeDegrees.present) {
      map['latitude_degrees'] = Variable<double>(latitudeDegrees.value);
    }
    if (longitudeDegrees.present) {
      map['longitude_degrees'] = Variable<double>(longitudeDegrees.value);
    }
    if (elevationMetres.present) {
      map['elevation_metres'] = Variable<double>(elevationMetres.value);
    }
    if (timeZoneId.present) {
      map['time_zone_id'] = Variable<String>(timeZoneId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (accuracyMetres.present) {
      map['accuracy_metres'] = Variable<double>(accuracyMetres.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedLocationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('latitudeDegrees: $latitudeDegrees, ')
          ..write('longitudeDegrees: $longitudeDegrees, ')
          ..write('elevationMetres: $elevationMetres, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('source: $source, ')
          ..write('accuracyMetres: $accuracyMetres, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CameraBodiesTable cameraBodies = $CameraBodiesTable(this);
  late final $LensesTable lenses = $LensesTable(this);
  late final $NdFiltersTable ndFilters = $NdFiltersTable(this);
  late final $OpticalAccessoriesTable opticalAccessories =
      $OpticalAccessoriesTable(this);
  late final $CalculationSnapshotsTable calculationSnapshots =
      $CalculationSnapshotsTable(this);
  late final $SnapshotEquipmentReferencesTable snapshotEquipmentReferences =
      $SnapshotEquipmentReferencesTable(this);
  late final $UserPreferencesTable userPreferences = $UserPreferencesTable(
    this,
  );
  late final $SavedLocationsTable savedLocations = $SavedLocationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cameraBodies,
    lenses,
    ndFilters,
    opticalAccessories,
    calculationSnapshots,
    snapshotEquipmentReferences,
    userPreferences,
    savedLocations,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'calculation_snapshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('snapshot_equipment_references', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$CameraBodiesTableCreateCompanionBuilder =
    CameraBodiesCompanion Function({
      required String id,
      required String name,
      required String normalizedName,
      required String sourceType,
      Value<String?> sourceNote,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> archivedAt,
      required double sensorWidthMm,
      required double sensorHeightMm,
      Value<double?> defaultCircleOfConfusionMm,
      Value<int> rowid,
    });
typedef $$CameraBodiesTableUpdateCompanionBuilder =
    CameraBodiesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<String> sourceType,
      Value<String?> sourceNote,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
      Value<double> sensorWidthMm,
      Value<double> sensorHeightMm,
      Value<double?> defaultCircleOfConfusionMm,
      Value<int> rowid,
    });

class $$CameraBodiesTableFilterComposer
    extends Composer<_$AppDatabase, $CameraBodiesTable> {
  $$CameraBodiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sensorWidthMm => $composableBuilder(
    column: $table.sensorWidthMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sensorHeightMm => $composableBuilder(
    column: $table.sensorHeightMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultCircleOfConfusionMm => $composableBuilder(
    column: $table.defaultCircleOfConfusionMm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CameraBodiesTableOrderingComposer
    extends Composer<_$AppDatabase, $CameraBodiesTable> {
  $$CameraBodiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sensorWidthMm => $composableBuilder(
    column: $table.sensorWidthMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sensorHeightMm => $composableBuilder(
    column: $table.sensorHeightMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultCircleOfConfusionMm => $composableBuilder(
    column: $table.defaultCircleOfConfusionMm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CameraBodiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CameraBodiesTable> {
  $$CameraBodiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sensorWidthMm => $composableBuilder(
    column: $table.sensorWidthMm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sensorHeightMm => $composableBuilder(
    column: $table.sensorHeightMm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get defaultCircleOfConfusionMm => $composableBuilder(
    column: $table.defaultCircleOfConfusionMm,
    builder: (column) => column,
  );
}

class $$CameraBodiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CameraBodiesTable,
          CameraBody,
          $$CameraBodiesTableFilterComposer,
          $$CameraBodiesTableOrderingComposer,
          $$CameraBodiesTableAnnotationComposer,
          $$CameraBodiesTableCreateCompanionBuilder,
          $$CameraBodiesTableUpdateCompanionBuilder,
          (
            CameraBody,
            BaseReferences<_$AppDatabase, $CameraBodiesTable, CameraBody>,
          ),
          CameraBody,
          PrefetchHooks Function()
        > {
  $$CameraBodiesTableTableManager(_$AppDatabase db, $CameraBodiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CameraBodiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CameraBodiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CameraBodiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourceNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<double> sensorWidthMm = const Value.absent(),
                Value<double> sensorHeightMm = const Value.absent(),
                Value<double?> defaultCircleOfConfusionMm =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CameraBodiesCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                sourceType: sourceType,
                sourceNote: sourceNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                sensorWidthMm: sensorWidthMm,
                sensorHeightMm: sensorHeightMm,
                defaultCircleOfConfusionMm: defaultCircleOfConfusionMm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalizedName,
                required String sourceType,
                Value<String?> sourceNote = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                required double sensorWidthMm,
                required double sensorHeightMm,
                Value<double?> defaultCircleOfConfusionMm =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CameraBodiesCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                sourceType: sourceType,
                sourceNote: sourceNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                sensorWidthMm: sensorWidthMm,
                sensorHeightMm: sensorHeightMm,
                defaultCircleOfConfusionMm: defaultCircleOfConfusionMm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CameraBodiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CameraBodiesTable,
      CameraBody,
      $$CameraBodiesTableFilterComposer,
      $$CameraBodiesTableOrderingComposer,
      $$CameraBodiesTableAnnotationComposer,
      $$CameraBodiesTableCreateCompanionBuilder,
      $$CameraBodiesTableUpdateCompanionBuilder,
      (
        CameraBody,
        BaseReferences<_$AppDatabase, $CameraBodiesTable, CameraBody>,
      ),
      CameraBody,
      PrefetchHooks Function()
    >;
typedef $$LensesTableCreateCompanionBuilder =
    LensesCompanion Function({
      required String id,
      required String name,
      required String normalizedName,
      required String sourceType,
      Value<String?> sourceNote,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> archivedAt,
      required double minimumFocalLengthMm,
      required double maximumFocalLengthMm,
      Value<double?> minimumAperture,
      Value<double?> maximumFocalLengthMinimumAperture,
      Value<double?> minimumFocusDistanceMm,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$LensesTableUpdateCompanionBuilder =
    LensesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<String> sourceType,
      Value<String?> sourceNote,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
      Value<double> minimumFocalLengthMm,
      Value<double> maximumFocalLengthMm,
      Value<double?> minimumAperture,
      Value<double?> maximumFocalLengthMinimumAperture,
      Value<double?> minimumFocusDistanceMm,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$LensesTableFilterComposer
    extends Composer<_$AppDatabase, $LensesTable> {
  $$LensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minimumFocalLengthMm => $composableBuilder(
    column: $table.minimumFocalLengthMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maximumFocalLengthMm => $composableBuilder(
    column: $table.maximumFocalLengthMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minimumAperture => $composableBuilder(
    column: $table.minimumAperture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maximumFocalLengthMinimumAperture =>
      $composableBuilder(
        column: $table.maximumFocalLengthMinimumAperture,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<double> get minimumFocusDistanceMm => $composableBuilder(
    column: $table.minimumFocusDistanceMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LensesTableOrderingComposer
    extends Composer<_$AppDatabase, $LensesTable> {
  $$LensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minimumFocalLengthMm => $composableBuilder(
    column: $table.minimumFocalLengthMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maximumFocalLengthMm => $composableBuilder(
    column: $table.maximumFocalLengthMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minimumAperture => $composableBuilder(
    column: $table.minimumAperture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maximumFocalLengthMinimumAperture =>
      $composableBuilder(
        column: $table.maximumFocalLengthMinimumAperture,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<double> get minimumFocusDistanceMm => $composableBuilder(
    column: $table.minimumFocusDistanceMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LensesTable> {
  $$LensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minimumFocalLengthMm => $composableBuilder(
    column: $table.minimumFocalLengthMm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maximumFocalLengthMm => $composableBuilder(
    column: $table.maximumFocalLengthMm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minimumAperture => $composableBuilder(
    column: $table.minimumAperture,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maximumFocalLengthMinimumAperture =>
      $composableBuilder(
        column: $table.maximumFocalLengthMinimumAperture,
        builder: (column) => column,
      );

  GeneratedColumn<double> get minimumFocusDistanceMm => $composableBuilder(
    column: $table.minimumFocusDistanceMm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$LensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LensesTable,
          Lense,
          $$LensesTableFilterComposer,
          $$LensesTableOrderingComposer,
          $$LensesTableAnnotationComposer,
          $$LensesTableCreateCompanionBuilder,
          $$LensesTableUpdateCompanionBuilder,
          (Lense, BaseReferences<_$AppDatabase, $LensesTable, Lense>),
          Lense,
          PrefetchHooks Function()
        > {
  $$LensesTableTableManager(_$AppDatabase db, $LensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourceNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<double> minimumFocalLengthMm = const Value.absent(),
                Value<double> maximumFocalLengthMm = const Value.absent(),
                Value<double?> minimumAperture = const Value.absent(),
                Value<double?> maximumFocalLengthMinimumAperture =
                    const Value.absent(),
                Value<double?> minimumFocusDistanceMm = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LensesCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                sourceType: sourceType,
                sourceNote: sourceNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                minimumFocalLengthMm: minimumFocalLengthMm,
                maximumFocalLengthMm: maximumFocalLengthMm,
                minimumAperture: minimumAperture,
                maximumFocalLengthMinimumAperture:
                    maximumFocalLengthMinimumAperture,
                minimumFocusDistanceMm: minimumFocusDistanceMm,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalizedName,
                required String sourceType,
                Value<String?> sourceNote = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                required double minimumFocalLengthMm,
                required double maximumFocalLengthMm,
                Value<double?> minimumAperture = const Value.absent(),
                Value<double?> maximumFocalLengthMinimumAperture =
                    const Value.absent(),
                Value<double?> minimumFocusDistanceMm = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LensesCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                sourceType: sourceType,
                sourceNote: sourceNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                minimumFocalLengthMm: minimumFocalLengthMm,
                maximumFocalLengthMm: maximumFocalLengthMm,
                minimumAperture: minimumAperture,
                maximumFocalLengthMinimumAperture:
                    maximumFocalLengthMinimumAperture,
                minimumFocusDistanceMm: minimumFocusDistanceMm,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LensesTable,
      Lense,
      $$LensesTableFilterComposer,
      $$LensesTableOrderingComposer,
      $$LensesTableAnnotationComposer,
      $$LensesTableCreateCompanionBuilder,
      $$LensesTableUpdateCompanionBuilder,
      (Lense, BaseReferences<_$AppDatabase, $LensesTable, Lense>),
      Lense,
      PrefetchHooks Function()
    >;
typedef $$NdFiltersTableCreateCompanionBuilder =
    NdFiltersCompanion Function({
      required String id,
      required String name,
      required String normalizedName,
      required String sourceType,
      Value<String?> sourceNote,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> archivedAt,
      required double strengthStops,
      Value<double?> opticalDensity,
      Value<double?> filterFactor,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$NdFiltersTableUpdateCompanionBuilder =
    NdFiltersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<String> sourceType,
      Value<String?> sourceNote,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
      Value<double> strengthStops,
      Value<double?> opticalDensity,
      Value<double?> filterFactor,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$NdFiltersTableFilterComposer
    extends Composer<_$AppDatabase, $NdFiltersTable> {
  $$NdFiltersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get strengthStops => $composableBuilder(
    column: $table.strengthStops,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get opticalDensity => $composableBuilder(
    column: $table.opticalDensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get filterFactor => $composableBuilder(
    column: $table.filterFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NdFiltersTableOrderingComposer
    extends Composer<_$AppDatabase, $NdFiltersTable> {
  $$NdFiltersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get strengthStops => $composableBuilder(
    column: $table.strengthStops,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get opticalDensity => $composableBuilder(
    column: $table.opticalDensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get filterFactor => $composableBuilder(
    column: $table.filterFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NdFiltersTableAnnotationComposer
    extends Composer<_$AppDatabase, $NdFiltersTable> {
  $$NdFiltersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get strengthStops => $composableBuilder(
    column: $table.strengthStops,
    builder: (column) => column,
  );

  GeneratedColumn<double> get opticalDensity => $composableBuilder(
    column: $table.opticalDensity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get filterFactor => $composableBuilder(
    column: $table.filterFactor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$NdFiltersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NdFiltersTable,
          NdFilter,
          $$NdFiltersTableFilterComposer,
          $$NdFiltersTableOrderingComposer,
          $$NdFiltersTableAnnotationComposer,
          $$NdFiltersTableCreateCompanionBuilder,
          $$NdFiltersTableUpdateCompanionBuilder,
          (NdFilter, BaseReferences<_$AppDatabase, $NdFiltersTable, NdFilter>),
          NdFilter,
          PrefetchHooks Function()
        > {
  $$NdFiltersTableTableManager(_$AppDatabase db, $NdFiltersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NdFiltersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NdFiltersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NdFiltersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourceNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<double> strengthStops = const Value.absent(),
                Value<double?> opticalDensity = const Value.absent(),
                Value<double?> filterFactor = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NdFiltersCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                sourceType: sourceType,
                sourceNote: sourceNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                strengthStops: strengthStops,
                opticalDensity: opticalDensity,
                filterFactor: filterFactor,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalizedName,
                required String sourceType,
                Value<String?> sourceNote = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                required double strengthStops,
                Value<double?> opticalDensity = const Value.absent(),
                Value<double?> filterFactor = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NdFiltersCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                sourceType: sourceType,
                sourceNote: sourceNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                strengthStops: strengthStops,
                opticalDensity: opticalDensity,
                filterFactor: filterFactor,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NdFiltersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NdFiltersTable,
      NdFilter,
      $$NdFiltersTableFilterComposer,
      $$NdFiltersTableOrderingComposer,
      $$NdFiltersTableAnnotationComposer,
      $$NdFiltersTableCreateCompanionBuilder,
      $$NdFiltersTableUpdateCompanionBuilder,
      (NdFilter, BaseReferences<_$AppDatabase, $NdFiltersTable, NdFilter>),
      NdFilter,
      PrefetchHooks Function()
    >;
typedef $$OpticalAccessoriesTableCreateCompanionBuilder =
    OpticalAccessoriesCompanion Function({
      required String id,
      required String name,
      required String normalizedName,
      required String sourceType,
      Value<String?> sourceNote,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> archivedAt,
      required String kind,
      required double value,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$OpticalAccessoriesTableUpdateCompanionBuilder =
    OpticalAccessoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<String> sourceType,
      Value<String?> sourceNote,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
      Value<String> kind,
      Value<double> value,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$OpticalAccessoriesTableFilterComposer
    extends Composer<_$AppDatabase, $OpticalAccessoriesTable> {
  $$OpticalAccessoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OpticalAccessoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OpticalAccessoriesTable> {
  $$OpticalAccessoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OpticalAccessoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OpticalAccessoriesTable> {
  $$OpticalAccessoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$OpticalAccessoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OpticalAccessoriesTable,
          OpticalAccessory,
          $$OpticalAccessoriesTableFilterComposer,
          $$OpticalAccessoriesTableOrderingComposer,
          $$OpticalAccessoriesTableAnnotationComposer,
          $$OpticalAccessoriesTableCreateCompanionBuilder,
          $$OpticalAccessoriesTableUpdateCompanionBuilder,
          (
            OpticalAccessory,
            BaseReferences<
              _$AppDatabase,
              $OpticalAccessoriesTable,
              OpticalAccessory
            >,
          ),
          OpticalAccessory,
          PrefetchHooks Function()
        > {
  $$OpticalAccessoriesTableTableManager(
    _$AppDatabase db,
    $OpticalAccessoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OpticalAccessoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OpticalAccessoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OpticalAccessoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourceNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OpticalAccessoriesCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                sourceType: sourceType,
                sourceNote: sourceNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                kind: kind,
                value: value,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalizedName,
                required String sourceType,
                Value<String?> sourceNote = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                required String kind,
                required double value,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OpticalAccessoriesCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                sourceType: sourceType,
                sourceNote: sourceNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                kind: kind,
                value: value,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OpticalAccessoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OpticalAccessoriesTable,
      OpticalAccessory,
      $$OpticalAccessoriesTableFilterComposer,
      $$OpticalAccessoriesTableOrderingComposer,
      $$OpticalAccessoriesTableAnnotationComposer,
      $$OpticalAccessoriesTableCreateCompanionBuilder,
      $$OpticalAccessoriesTableUpdateCompanionBuilder,
      (
        OpticalAccessory,
        BaseReferences<
          _$AppDatabase,
          $OpticalAccessoriesTable,
          OpticalAccessory
        >,
      ),
      OpticalAccessory,
      PrefetchHooks Function()
    >;
typedef $$CalculationSnapshotsTableCreateCompanionBuilder =
    CalculationSnapshotsCompanion Function({
      required String id,
      required String calculatorId,
      required int formulaVersion,
      required DateTime createdAt,
      required String title,
      Value<String?> notes,
      required int payloadVersion,
      required String inputPayload,
      required String outputPayload,
      required String displayContext,
      required String assumptions,
      required String warnings,
      required String equipmentSnapshot,
      Value<int> rowid,
    });
typedef $$CalculationSnapshotsTableUpdateCompanionBuilder =
    CalculationSnapshotsCompanion Function({
      Value<String> id,
      Value<String> calculatorId,
      Value<int> formulaVersion,
      Value<DateTime> createdAt,
      Value<String> title,
      Value<String?> notes,
      Value<int> payloadVersion,
      Value<String> inputPayload,
      Value<String> outputPayload,
      Value<String> displayContext,
      Value<String> assumptions,
      Value<String> warnings,
      Value<String> equipmentSnapshot,
      Value<int> rowid,
    });

final class $$CalculationSnapshotsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CalculationSnapshotsTable,
          CalculationSnapshot
        > {
  $$CalculationSnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $SnapshotEquipmentReferencesTable,
    List<SnapshotEquipmentReference>
  >
  _snapshotEquipmentReferencesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.snapshotEquipmentReferences,
    aliasName:
        'calculation_snapshots__id__snapshot_equipment_references__snapshot_id',
  );

  $$SnapshotEquipmentReferencesTableProcessedTableManager
  get snapshotEquipmentReferencesRefs {
    final manager = $$SnapshotEquipmentReferencesTableTableManager(
      $_db,
      $_db.snapshotEquipmentReferences,
    ).filter((f) => f.snapshotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _snapshotEquipmentReferencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CalculationSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $CalculationSnapshotsTable> {
  $$CalculationSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calculatorId => $composableBuilder(
    column: $table.calculatorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get formulaVersion => $composableBuilder(
    column: $table.formulaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputPayload => $composableBuilder(
    column: $table.inputPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputPayload => $composableBuilder(
    column: $table.outputPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayContext => $composableBuilder(
    column: $table.displayContext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assumptions => $composableBuilder(
    column: $table.assumptions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warnings => $composableBuilder(
    column: $table.warnings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentSnapshot => $composableBuilder(
    column: $table.equipmentSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> snapshotEquipmentReferencesRefs(
    Expression<bool> Function(
      $$SnapshotEquipmentReferencesTableFilterComposer f,
    )
    f,
  ) {
    final $$SnapshotEquipmentReferencesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.snapshotEquipmentReferences,
          getReferencedColumn: (t) => t.snapshotId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SnapshotEquipmentReferencesTableFilterComposer(
                $db: $db,
                $table: $db.snapshotEquipmentReferences,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CalculationSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalculationSnapshotsTable> {
  $$CalculationSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calculatorId => $composableBuilder(
    column: $table.calculatorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get formulaVersion => $composableBuilder(
    column: $table.formulaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputPayload => $composableBuilder(
    column: $table.inputPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputPayload => $composableBuilder(
    column: $table.outputPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayContext => $composableBuilder(
    column: $table.displayContext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assumptions => $composableBuilder(
    column: $table.assumptions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warnings => $composableBuilder(
    column: $table.warnings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentSnapshot => $composableBuilder(
    column: $table.equipmentSnapshot,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalculationSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalculationSnapshotsTable> {
  $$CalculationSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get calculatorId => $composableBuilder(
    column: $table.calculatorId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get formulaVersion => $composableBuilder(
    column: $table.formulaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inputPayload => $composableBuilder(
    column: $table.inputPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outputPayload => $composableBuilder(
    column: $table.outputPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayContext => $composableBuilder(
    column: $table.displayContext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assumptions => $composableBuilder(
    column: $table.assumptions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warnings =>
      $composableBuilder(column: $table.warnings, builder: (column) => column);

  GeneratedColumn<String> get equipmentSnapshot => $composableBuilder(
    column: $table.equipmentSnapshot,
    builder: (column) => column,
  );

  Expression<T> snapshotEquipmentReferencesRefs<T extends Object>(
    Expression<T> Function(
      $$SnapshotEquipmentReferencesTableAnnotationComposer a,
    )
    f,
  ) {
    final $$SnapshotEquipmentReferencesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.snapshotEquipmentReferences,
          getReferencedColumn: (t) => t.snapshotId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SnapshotEquipmentReferencesTableAnnotationComposer(
                $db: $db,
                $table: $db.snapshotEquipmentReferences,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CalculationSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalculationSnapshotsTable,
          CalculationSnapshot,
          $$CalculationSnapshotsTableFilterComposer,
          $$CalculationSnapshotsTableOrderingComposer,
          $$CalculationSnapshotsTableAnnotationComposer,
          $$CalculationSnapshotsTableCreateCompanionBuilder,
          $$CalculationSnapshotsTableUpdateCompanionBuilder,
          (CalculationSnapshot, $$CalculationSnapshotsTableReferences),
          CalculationSnapshot,
          PrefetchHooks Function({bool snapshotEquipmentReferencesRefs})
        > {
  $$CalculationSnapshotsTableTableManager(
    _$AppDatabase db,
    $CalculationSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalculationSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalculationSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CalculationSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> calculatorId = const Value.absent(),
                Value<int> formulaVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> payloadVersion = const Value.absent(),
                Value<String> inputPayload = const Value.absent(),
                Value<String> outputPayload = const Value.absent(),
                Value<String> displayContext = const Value.absent(),
                Value<String> assumptions = const Value.absent(),
                Value<String> warnings = const Value.absent(),
                Value<String> equipmentSnapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalculationSnapshotsCompanion(
                id: id,
                calculatorId: calculatorId,
                formulaVersion: formulaVersion,
                createdAt: createdAt,
                title: title,
                notes: notes,
                payloadVersion: payloadVersion,
                inputPayload: inputPayload,
                outputPayload: outputPayload,
                displayContext: displayContext,
                assumptions: assumptions,
                warnings: warnings,
                equipmentSnapshot: equipmentSnapshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String calculatorId,
                required int formulaVersion,
                required DateTime createdAt,
                required String title,
                Value<String?> notes = const Value.absent(),
                required int payloadVersion,
                required String inputPayload,
                required String outputPayload,
                required String displayContext,
                required String assumptions,
                required String warnings,
                required String equipmentSnapshot,
                Value<int> rowid = const Value.absent(),
              }) => CalculationSnapshotsCompanion.insert(
                id: id,
                calculatorId: calculatorId,
                formulaVersion: formulaVersion,
                createdAt: createdAt,
                title: title,
                notes: notes,
                payloadVersion: payloadVersion,
                inputPayload: inputPayload,
                outputPayload: outputPayload,
                displayContext: displayContext,
                assumptions: assumptions,
                warnings: warnings,
                equipmentSnapshot: equipmentSnapshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CalculationSnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({snapshotEquipmentReferencesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (snapshotEquipmentReferencesRefs)
                  db.snapshotEquipmentReferences,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (snapshotEquipmentReferencesRefs)
                    await $_getPrefetchedData<
                      CalculationSnapshot,
                      $CalculationSnapshotsTable,
                      SnapshotEquipmentReference
                    >(
                      currentTable: table,
                      referencedTable: $$CalculationSnapshotsTableReferences
                          ._snapshotEquipmentReferencesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CalculationSnapshotsTableReferences(
                            db,
                            table,
                            p0,
                          ).snapshotEquipmentReferencesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.snapshotId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CalculationSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalculationSnapshotsTable,
      CalculationSnapshot,
      $$CalculationSnapshotsTableFilterComposer,
      $$CalculationSnapshotsTableOrderingComposer,
      $$CalculationSnapshotsTableAnnotationComposer,
      $$CalculationSnapshotsTableCreateCompanionBuilder,
      $$CalculationSnapshotsTableUpdateCompanionBuilder,
      (CalculationSnapshot, $$CalculationSnapshotsTableReferences),
      CalculationSnapshot,
      PrefetchHooks Function({bool snapshotEquipmentReferencesRefs})
    >;
typedef $$SnapshotEquipmentReferencesTableCreateCompanionBuilder =
    SnapshotEquipmentReferencesCompanion Function({
      required String snapshotId,
      required String equipmentId,
      required String equipmentType,
      required int displayOrder,
      Value<int> rowid,
    });
typedef $$SnapshotEquipmentReferencesTableUpdateCompanionBuilder =
    SnapshotEquipmentReferencesCompanion Function({
      Value<String> snapshotId,
      Value<String> equipmentId,
      Value<String> equipmentType,
      Value<int> displayOrder,
      Value<int> rowid,
    });

final class $$SnapshotEquipmentReferencesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SnapshotEquipmentReferencesTable,
          SnapshotEquipmentReference
        > {
  $$SnapshotEquipmentReferencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CalculationSnapshotsTable _snapshotIdTable(_$AppDatabase db) =>
      db.calculationSnapshots.createAlias(
        'snapshot_equipment_references__snapshot_id__calculation_snapshots__id',
      );

  $$CalculationSnapshotsTableProcessedTableManager get snapshotId {
    final $_column = $_itemColumn<String>('snapshot_id')!;

    final manager = $$CalculationSnapshotsTableTableManager(
      $_db,
      $_db.calculationSnapshots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_snapshotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SnapshotEquipmentReferencesTableFilterComposer
    extends Composer<_$AppDatabase, $SnapshotEquipmentReferencesTable> {
  $$SnapshotEquipmentReferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentType => $composableBuilder(
    column: $table.equipmentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$CalculationSnapshotsTableFilterComposer get snapshotId {
    final $$CalculationSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.snapshotId,
      referencedTable: $db.calculationSnapshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalculationSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.calculationSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SnapshotEquipmentReferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $SnapshotEquipmentReferencesTable> {
  $$SnapshotEquipmentReferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentType => $composableBuilder(
    column: $table.equipmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$CalculationSnapshotsTableOrderingComposer get snapshotId {
    final $$CalculationSnapshotsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.snapshotId,
          referencedTable: $db.calculationSnapshots,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CalculationSnapshotsTableOrderingComposer(
                $db: $db,
                $table: $db.calculationSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$SnapshotEquipmentReferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SnapshotEquipmentReferencesTable> {
  $$SnapshotEquipmentReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipmentType => $composableBuilder(
    column: $table.equipmentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  $$CalculationSnapshotsTableAnnotationComposer get snapshotId {
    final $$CalculationSnapshotsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.snapshotId,
          referencedTable: $db.calculationSnapshots,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CalculationSnapshotsTableAnnotationComposer(
                $db: $db,
                $table: $db.calculationSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$SnapshotEquipmentReferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SnapshotEquipmentReferencesTable,
          SnapshotEquipmentReference,
          $$SnapshotEquipmentReferencesTableFilterComposer,
          $$SnapshotEquipmentReferencesTableOrderingComposer,
          $$SnapshotEquipmentReferencesTableAnnotationComposer,
          $$SnapshotEquipmentReferencesTableCreateCompanionBuilder,
          $$SnapshotEquipmentReferencesTableUpdateCompanionBuilder,
          (
            SnapshotEquipmentReference,
            $$SnapshotEquipmentReferencesTableReferences,
          ),
          SnapshotEquipmentReference,
          PrefetchHooks Function({bool snapshotId})
        > {
  $$SnapshotEquipmentReferencesTableTableManager(
    _$AppDatabase db,
    $SnapshotEquipmentReferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotEquipmentReferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SnapshotEquipmentReferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SnapshotEquipmentReferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> snapshotId = const Value.absent(),
                Value<String> equipmentId = const Value.absent(),
                Value<String> equipmentType = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotEquipmentReferencesCompanion(
                snapshotId: snapshotId,
                equipmentId: equipmentId,
                equipmentType: equipmentType,
                displayOrder: displayOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String snapshotId,
                required String equipmentId,
                required String equipmentType,
                required int displayOrder,
                Value<int> rowid = const Value.absent(),
              }) => SnapshotEquipmentReferencesCompanion.insert(
                snapshotId: snapshotId,
                equipmentId: equipmentId,
                equipmentType: equipmentType,
                displayOrder: displayOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SnapshotEquipmentReferencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({snapshotId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (snapshotId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.snapshotId,
                                referencedTable:
                                    $$SnapshotEquipmentReferencesTableReferences
                                        ._snapshotIdTable(db),
                                referencedColumn:
                                    $$SnapshotEquipmentReferencesTableReferences
                                        ._snapshotIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SnapshotEquipmentReferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SnapshotEquipmentReferencesTable,
      SnapshotEquipmentReference,
      $$SnapshotEquipmentReferencesTableFilterComposer,
      $$SnapshotEquipmentReferencesTableOrderingComposer,
      $$SnapshotEquipmentReferencesTableAnnotationComposer,
      $$SnapshotEquipmentReferencesTableCreateCompanionBuilder,
      $$SnapshotEquipmentReferencesTableUpdateCompanionBuilder,
      (
        SnapshotEquipmentReference,
        $$SnapshotEquipmentReferencesTableReferences,
      ),
      SnapshotEquipmentReference,
      PrefetchHooks Function({bool snapshotId})
    >;
typedef $$UserPreferencesTableCreateCompanionBuilder =
    UserPreferencesCompanion Function({
      Value<int> id,
      Value<String> lengthDisplay,
      Value<String> shutterDisplay,
      Value<String> fractionStep,
      Value<String> themeMode,
      Value<String> favoriteToolIds,
      Value<String> northReference,
    });
typedef $$UserPreferencesTableUpdateCompanionBuilder =
    UserPreferencesCompanion Function({
      Value<int> id,
      Value<String> lengthDisplay,
      Value<String> shutterDisplay,
      Value<String> fractionStep,
      Value<String> themeMode,
      Value<String> favoriteToolIds,
      Value<String> northReference,
    });

class $$UserPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lengthDisplay => $composableBuilder(
    column: $table.lengthDisplay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shutterDisplay => $composableBuilder(
    column: $table.shutterDisplay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fractionStep => $composableBuilder(
    column: $table.fractionStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get favoriteToolIds => $composableBuilder(
    column: $table.favoriteToolIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get northReference => $composableBuilder(
    column: $table.northReference,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lengthDisplay => $composableBuilder(
    column: $table.lengthDisplay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shutterDisplay => $composableBuilder(
    column: $table.shutterDisplay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fractionStep => $composableBuilder(
    column: $table.fractionStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get favoriteToolIds => $composableBuilder(
    column: $table.favoriteToolIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get northReference => $composableBuilder(
    column: $table.northReference,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lengthDisplay => $composableBuilder(
    column: $table.lengthDisplay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shutterDisplay => $composableBuilder(
    column: $table.shutterDisplay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fractionStep => $composableBuilder(
    column: $table.fractionStep,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get favoriteToolIds => $composableBuilder(
    column: $table.favoriteToolIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get northReference => $composableBuilder(
    column: $table.northReference,
    builder: (column) => column,
  );
}

class $$UserPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPreferencesTable,
          UserPreference,
          $$UserPreferencesTableFilterComposer,
          $$UserPreferencesTableOrderingComposer,
          $$UserPreferencesTableAnnotationComposer,
          $$UserPreferencesTableCreateCompanionBuilder,
          $$UserPreferencesTableUpdateCompanionBuilder,
          (
            UserPreference,
            BaseReferences<
              _$AppDatabase,
              $UserPreferencesTable,
              UserPreference
            >,
          ),
          UserPreference,
          PrefetchHooks Function()
        > {
  $$UserPreferencesTableTableManager(
    _$AppDatabase db,
    $UserPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> lengthDisplay = const Value.absent(),
                Value<String> shutterDisplay = const Value.absent(),
                Value<String> fractionStep = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> favoriteToolIds = const Value.absent(),
                Value<String> northReference = const Value.absent(),
              }) => UserPreferencesCompanion(
                id: id,
                lengthDisplay: lengthDisplay,
                shutterDisplay: shutterDisplay,
                fractionStep: fractionStep,
                themeMode: themeMode,
                favoriteToolIds: favoriteToolIds,
                northReference: northReference,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> lengthDisplay = const Value.absent(),
                Value<String> shutterDisplay = const Value.absent(),
                Value<String> fractionStep = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> favoriteToolIds = const Value.absent(),
                Value<String> northReference = const Value.absent(),
              }) => UserPreferencesCompanion.insert(
                id: id,
                lengthDisplay: lengthDisplay,
                shutterDisplay: shutterDisplay,
                fractionStep: fractionStep,
                themeMode: themeMode,
                favoriteToolIds: favoriteToolIds,
                northReference: northReference,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPreferencesTable,
      UserPreference,
      $$UserPreferencesTableFilterComposer,
      $$UserPreferencesTableOrderingComposer,
      $$UserPreferencesTableAnnotationComposer,
      $$UserPreferencesTableCreateCompanionBuilder,
      $$UserPreferencesTableUpdateCompanionBuilder,
      (
        UserPreference,
        BaseReferences<_$AppDatabase, $UserPreferencesTable, UserPreference>,
      ),
      UserPreference,
      PrefetchHooks Function()
    >;
typedef $$SavedLocationsTableCreateCompanionBuilder =
    SavedLocationsCompanion Function({
      required String id,
      required String name,
      required String normalizedName,
      required double latitudeDegrees,
      required double longitudeDegrees,
      Value<double?> elevationMetres,
      required String timeZoneId,
      required String source,
      Value<double?> accuracyMetres,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SavedLocationsTableUpdateCompanionBuilder =
    SavedLocationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<double> latitudeDegrees,
      Value<double> longitudeDegrees,
      Value<double?> elevationMetres,
      Value<String> timeZoneId,
      Value<String> source,
      Value<double?> accuracyMetres,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SavedLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedLocationsTable> {
  $$SavedLocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitudeDegrees => $composableBuilder(
    column: $table.latitudeDegrees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitudeDegrees => $composableBuilder(
    column: $table.longitudeDegrees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationMetres => $composableBuilder(
    column: $table.elevationMetres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyMetres => $composableBuilder(
    column: $table.accuracyMetres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedLocationsTable> {
  $$SavedLocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitudeDegrees => $composableBuilder(
    column: $table.latitudeDegrees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitudeDegrees => $composableBuilder(
    column: $table.longitudeDegrees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationMetres => $composableBuilder(
    column: $table.elevationMetres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyMetres => $composableBuilder(
    column: $table.accuracyMetres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedLocationsTable> {
  $$SavedLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitudeDegrees => $composableBuilder(
    column: $table.latitudeDegrees,
    builder: (column) => column,
  );

  GeneratedColumn<double> get longitudeDegrees => $composableBuilder(
    column: $table.longitudeDegrees,
    builder: (column) => column,
  );

  GeneratedColumn<double> get elevationMetres => $composableBuilder(
    column: $table.elevationMetres,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get accuracyMetres => $composableBuilder(
    column: $table.accuracyMetres,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SavedLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedLocationsTable,
          SavedLocation,
          $$SavedLocationsTableFilterComposer,
          $$SavedLocationsTableOrderingComposer,
          $$SavedLocationsTableAnnotationComposer,
          $$SavedLocationsTableCreateCompanionBuilder,
          $$SavedLocationsTableUpdateCompanionBuilder,
          (
            SavedLocation,
            BaseReferences<_$AppDatabase, $SavedLocationsTable, SavedLocation>,
          ),
          SavedLocation,
          PrefetchHooks Function()
        > {
  $$SavedLocationsTableTableManager(
    _$AppDatabase db,
    $SavedLocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<double> latitudeDegrees = const Value.absent(),
                Value<double> longitudeDegrees = const Value.absent(),
                Value<double?> elevationMetres = const Value.absent(),
                Value<String> timeZoneId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<double?> accuracyMetres = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedLocationsCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                latitudeDegrees: latitudeDegrees,
                longitudeDegrees: longitudeDegrees,
                elevationMetres: elevationMetres,
                timeZoneId: timeZoneId,
                source: source,
                accuracyMetres: accuracyMetres,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalizedName,
                required double latitudeDegrees,
                required double longitudeDegrees,
                Value<double?> elevationMetres = const Value.absent(),
                required String timeZoneId,
                required String source,
                Value<double?> accuracyMetres = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedLocationsCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                latitudeDegrees: latitudeDegrees,
                longitudeDegrees: longitudeDegrees,
                elevationMetres: elevationMetres,
                timeZoneId: timeZoneId,
                source: source,
                accuracyMetres: accuracyMetres,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedLocationsTable,
      SavedLocation,
      $$SavedLocationsTableFilterComposer,
      $$SavedLocationsTableOrderingComposer,
      $$SavedLocationsTableAnnotationComposer,
      $$SavedLocationsTableCreateCompanionBuilder,
      $$SavedLocationsTableUpdateCompanionBuilder,
      (
        SavedLocation,
        BaseReferences<_$AppDatabase, $SavedLocationsTable, SavedLocation>,
      ),
      SavedLocation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CameraBodiesTableTableManager get cameraBodies =>
      $$CameraBodiesTableTableManager(_db, _db.cameraBodies);
  $$LensesTableTableManager get lenses =>
      $$LensesTableTableManager(_db, _db.lenses);
  $$NdFiltersTableTableManager get ndFilters =>
      $$NdFiltersTableTableManager(_db, _db.ndFilters);
  $$OpticalAccessoriesTableTableManager get opticalAccessories =>
      $$OpticalAccessoriesTableTableManager(_db, _db.opticalAccessories);
  $$CalculationSnapshotsTableTableManager get calculationSnapshots =>
      $$CalculationSnapshotsTableTableManager(_db, _db.calculationSnapshots);
  $$SnapshotEquipmentReferencesTableTableManager
  get snapshotEquipmentReferences =>
      $$SnapshotEquipmentReferencesTableTableManager(
        _db,
        _db.snapshotEquipmentReferences,
      );
  $$UserPreferencesTableTableManager get userPreferences =>
      $$UserPreferencesTableTableManager(_db, _db.userPreferences);
  $$SavedLocationsTableTableManager get savedLocations =>
      $$SavedLocationsTableTableManager(_db, _db.savedLocations);
}
