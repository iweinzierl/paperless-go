import 'dart:convert';

import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_saved_view.dart';

const int negativeNullFilterValue = -1;

const int _filterTitle = 0;
const int _filterContent = 1;
const int _filterAsn = 2;
const int _filterCorrespondent = 3;
const int _filterDocumentType = 4;
const int _filterIsInInbox = 5;
const int _filterHasTagsAll = 6;
const int _filterHasAnyTag = 7;
const int _filterCreatedBefore = 8;
const int _filterCreatedAfter = 9;
const int _filterCreatedYear = 10;
const int _filterCreatedMonth = 11;
const int _filterCreatedDay = 12;
const int _filterAddedBefore = 13;
const int _filterAddedAfter = 14;
const int _filterModifiedBefore = 15;
const int _filterModifiedAfter = 16;
const int _filterDoesNotHaveTag = 17;
const int _filterAsnIsNull = 18;
const int _filterTitleContent = 19;
const int _filterFullTextQuery = 20;
const int _filterFullTextMoreLike = 21;
const int _filterHasTagsAny = 22;
const int _filterAsnGt = 23;
const int _filterAsnLt = 24;
const int _filterStoragePath = 25;
const int _filterHasCorrespondentAny = 26;
const int _filterDoesNotHaveCorrespondent = 27;
const int _filterHasDocumentTypeAny = 28;
const int _filterDoesNotHaveDocumentType = 29;
const int _filterHasStoragePathAny = 30;
const int _filterDoesNotHaveStoragePath = 31;
const int _filterOwner = 32;
const int _filterOwnerAny = 33;
const int _filterOwnerIsNull = 34;
const int _filterOwnerDoesNotInclude = 35;
const int _filterCustomFieldsText = 36;
const int _filterSharedByUser = 37;
const int _filterHasCustomFieldsAll = 38;
const int _filterHasCustomFieldsAny = 39;
const int _filterDoesNotHaveCustomFields = 40;
const int _filterHasAnyCustomFields = 41;
const int _filterCustomFieldsQuery = 42;
const int _filterCreatedTo = 43;
const int _filterCreatedFrom = 44;
const int _filterAddedTo = 45;
const int _filterAddedFrom = 46;
const int _filterMimeType = 47;
const int _filterSimpleTitle = 48;
const int _filterSimpleText = 49;

const String _simpleTextParameter = 'text';
const String _simpleTitleParameter = 'title_search';

class _FilterRuleTypeDefinition {
  const _FilterRuleTypeDefinition({
    required this.id,
    required this.filterVar,
    required this.dataType,
    required this.multi,
    this.isNullFilterVar,
  });

  final int id;
  final String filterVar;
  final String? isNullFilterVar;
  final String dataType;
  final bool multi;
}

const List<_FilterRuleTypeDefinition> _filterRuleTypes =
    <_FilterRuleTypeDefinition>[
      _FilterRuleTypeDefinition(
        id: _filterTitle,
        filterVar: 'title__icontains',
        dataType: 'string',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterContent,
        filterVar: 'content__icontains',
        dataType: 'string',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterAsn,
        filterVar: 'archive_serial_number',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterCorrespondent,
        filterVar: 'correspondent__id',
        isNullFilterVar: 'correspondent__isnull',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterHasCorrespondentAny,
        filterVar: 'correspondent__id__in',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterDoesNotHaveCorrespondent,
        filterVar: 'correspondent__id__none',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterDocumentType,
        filterVar: 'document_type__id',
        isNullFilterVar: 'document_type__isnull',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterHasDocumentTypeAny,
        filterVar: 'document_type__id__in',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterDoesNotHaveDocumentType,
        filterVar: 'document_type__id__none',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterIsInInbox,
        filterVar: 'is_in_inbox',
        dataType: 'boolean',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterHasTagsAll,
        filterVar: 'tags__id__all',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterHasTagsAny,
        filterVar: 'tags__id__in',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterDoesNotHaveTag,
        filterVar: 'tags__id__none',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterHasAnyTag,
        filterVar: 'is_tagged',
        dataType: 'boolean',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterCreatedBefore,
        filterVar: 'created__date__lt',
        dataType: 'date',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterCreatedAfter,
        filterVar: 'created__date__gt',
        dataType: 'date',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterCreatedTo,
        filterVar: 'created__date__lte',
        dataType: 'date',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterCreatedFrom,
        filterVar: 'created__date__gte',
        dataType: 'date',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterCreatedYear,
        filterVar: 'created__year',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterCreatedMonth,
        filterVar: 'created__month',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterCreatedDay,
        filterVar: 'created__day',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterAddedBefore,
        filterVar: 'added__date__lt',
        dataType: 'date',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterAddedAfter,
        filterVar: 'added__date__gt',
        dataType: 'date',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterAddedTo,
        filterVar: 'added__date__lte',
        dataType: 'date',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterAddedFrom,
        filterVar: 'added__date__gte',
        dataType: 'date',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterModifiedBefore,
        filterVar: 'modified__date__lt',
        dataType: 'date',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterModifiedAfter,
        filterVar: 'modified__date__gt',
        dataType: 'date',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterAsnIsNull,
        filterVar: 'archive_serial_number__isnull',
        dataType: 'boolean',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterAsnGt,
        filterVar: 'archive_serial_number__gt',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterAsnLt,
        filterVar: 'archive_serial_number__lt',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterTitleContent,
        filterVar: 'title_content',
        dataType: 'string',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterSimpleText,
        filterVar: _simpleTextParameter,
        dataType: 'string',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterSimpleTitle,
        filterVar: _simpleTitleParameter,
        dataType: 'string',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterFullTextQuery,
        filterVar: 'query',
        dataType: 'string',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterFullTextMoreLike,
        filterVar: 'more_like_id',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterOwner,
        filterVar: 'owner__id',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterOwnerAny,
        filterVar: 'owner__id__in',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterOwnerIsNull,
        filterVar: 'owner__isnull',
        dataType: 'boolean',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterOwnerDoesNotInclude,
        filterVar: 'owner__id__none',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterSharedByUser,
        filterVar: 'shared_by__id',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterCustomFieldsText,
        filterVar: 'custom_fields__icontains',
        dataType: 'string',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterHasCustomFieldsAll,
        filterVar: 'custom_fields__id__all',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterHasCustomFieldsAny,
        filterVar: 'custom_fields__id__in',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterDoesNotHaveCustomFields,
        filterVar: 'custom_fields__id__none',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterHasAnyCustomFields,
        filterVar: 'has_custom_fields',
        dataType: 'boolean',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterCustomFieldsQuery,
        filterVar: 'custom_field_query',
        dataType: 'string',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterMimeType,
        filterVar: 'mime_type',
        dataType: 'string',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterStoragePath,
        filterVar: 'storage_path__id',
        isNullFilterVar: 'storage_path__isnull',
        dataType: 'number',
        multi: false,
      ),
      _FilterRuleTypeDefinition(
        id: _filterHasStoragePathAny,
        filterVar: 'storage_path__id__in',
        dataType: 'number',
        multi: true,
      ),
      _FilterRuleTypeDefinition(
        id: _filterDoesNotHaveStoragePath,
        filterVar: 'storage_path__id__none',
        dataType: 'number',
        multi: true,
      ),
    ];

List<PaperlessSavedViewFilterRule> transformLegacySavedViewFilterRules(
  List<PaperlessSavedViewFilterRule> filterRules,
) {
  final legacyAnyRules = filterRules
      .where((rule) => rule.ruleType == _filterHasCustomFieldsAny)
      .toList(growable: false);
  final legacyAllRules = filterRules
      .where((rule) => rule.ruleType == _filterHasCustomFieldsAll)
      .toList(growable: false);

  if (legacyAnyRules.isEmpty && legacyAllRules.isEmpty) {
    return filterRules.toList(growable: false);
  }

  final useAndOperator = legacyAllRules.isNotEmpty;
  final sourceRules = useAndOperator ? legacyAllRules : legacyAnyRules;
  final queryExpression = <Object?>[
    useAndOperator ? 'AND' : 'OR',
    sourceRules
        .map(
          (rule) => <Object?>[
            int.tryParse(rule.value ?? '') ?? 0,
            'exists',
            true,
          ],
        )
        .toList(growable: false),
  ];

  return <PaperlessSavedViewFilterRule>[
    ...filterRules.where(
      (rule) =>
          rule.ruleType != _filterHasCustomFieldsAny &&
          rule.ruleType != _filterHasCustomFieldsAll,
    ),
    PaperlessSavedViewFilterRule(
      ruleType: _filterCustomFieldsQuery,
      value: jsonEncode(queryExpression),
    ),
  ];
}

Map<String, String> queryParametersFromSavedViewFilterRules(
  List<PaperlessSavedViewFilterRule> filterRules,
) {
  final transformedRules = transformLegacySavedViewFilterRules(filterRules);
  final parameters = <String, String>{};

  for (final rule in transformedRules) {
    final ruleType = _filterRuleTypes
        .where((candidate) => candidate.id == rule.ruleType)
        .firstOrNull;
    if (ruleType == null) {
      continue;
    }

    if (rule.ruleType == _filterTitleContent ||
        rule.ruleType == _filterSimpleText) {
      if (rule.value != null) {
        parameters[_simpleTextParameter] = rule.value!;
      }
      continue;
    }

    if (rule.ruleType == _filterTitle || rule.ruleType == _filterSimpleTitle) {
      if (rule.value != null) {
        parameters[_simpleTitleParameter] = rule.value!;
      }
      continue;
    }

    if (ruleType.isNullFilterVar != null && rule.value == null) {
      parameters[ruleType.isNullFilterVar!] = '1';
      continue;
    }

    if (ruleType.isNullFilterVar != null &&
        rule.value == negativeNullFilterValue.toString()) {
      parameters[ruleType.isNullFilterVar!] = '0';
      continue;
    }

    final value = rule.value;
    if (value == null) {
      continue;
    }

    if (ruleType.multi) {
      parameters[ruleType.filterVar] =
          parameters.containsKey(ruleType.filterVar)
          ? '${parameters[ruleType.filterVar]},$value'
          : value;
      continue;
    }

    if (ruleType.dataType == 'boolean') {
      parameters[ruleType.filterVar] = value == 'true' || value == '1'
          ? '1'
          : '0';
      continue;
    }

    parameters[ruleType.filterVar] = value;
  }

  return parameters;
}
