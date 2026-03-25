import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_user_capabilities.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';

void main() {
  const ownerCapabilities = PaperlessUserCapabilities(
    userId: 7,
    groupIds: <int>[3],
    permissionCodenames: <String>{'change_document', 'delete_document'},
    isStaff: false,
    isSuperuser: false,
  );

  const editorCapabilities = PaperlessUserCapabilities(
    userId: 9,
    groupIds: <int>[5],
    permissionCodenames: <String>{'change_document'},
    isStaff: false,
    isSuperuser: false,
  );

  const deleteOnlyNonOwnerCapabilities = PaperlessUserCapabilities(
    userId: 11,
    groupIds: <int>[8],
    permissionCodenames: <String>{'delete_document'},
    isStaff: false,
    isSuperuser: false,
  );

  const superuserCapabilities = PaperlessUserCapabilities(
    userId: 1,
    groupIds: <int>[],
    permissionCodenames: <String>{},
    isStaff: true,
    isSuperuser: true,
  );

  test('owner with change permission can edit the document', () {
    const document = PaperlessDocument(id: 42, title: 'Invoice', ownerId: 7);

    expect(document.canBeChangedBy(ownerCapabilities), isTrue);
  });

  test('shared editor with change permission can edit the document', () {
    const document = PaperlessDocument(
      id: 42,
      title: 'Invoice',
      ownerId: 7,
      permissions: PaperlessObjectPermissions(
        view: PaperlessPermissionAssignments(
          userIds: <int>[],
          groupIds: <int>[],
        ),
        change: PaperlessPermissionAssignments(
          userIds: <int>[],
          groupIds: <int>[5],
        ),
      ),
    );

    expect(document.canBeChangedBy(editorCapabilities), isTrue);
  });

  test('non-owner with delete permission cannot delete the document', () {
    const document = PaperlessDocument(id: 42, title: 'Invoice', ownerId: 7);

    expect(document.canBeDeletedBy(deleteOnlyNonOwnerCapabilities), isFalse);
  });

  test('owner with delete permission can delete the document', () {
    const document = PaperlessDocument(id: 42, title: 'Invoice', ownerId: 7);

    expect(document.canBeDeletedBy(ownerCapabilities), isTrue);
  });

  test('unowned document still requires explicit ownership for delete', () {
    const document = PaperlessDocument(id: 42, title: 'Invoice');

    expect(document.canBeDeletedBy(ownerCapabilities), isFalse);
  });

  test('superuser can edit and delete regardless of ownership', () {
    const document = PaperlessDocument(id: 42, title: 'Invoice', ownerId: 7);

    expect(document.canBeChangedBy(superuserCapabilities), isTrue);
    expect(document.canBeDeletedBy(superuserCapabilities), isTrue);
  });

  test('superuser can delete unowned documents', () {
    const document = PaperlessDocument(id: 42, title: 'Invoice');

    expect(document.canBeDeletedBy(superuserCapabilities), isTrue);
  });
}
