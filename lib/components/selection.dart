import 'package:flutter_hooks/flutter_hooks.dart';

typedef SelectionState = ({
  bool selecting,
  Set<String> selectedIds,
  void Function() enter,
  void Function(String id) toggle,
  void Function() exit,
  void Function(Set<String> ids) replace,
});

SelectionState useSelectionState() {
  final selecting = useState(false);
  final selectedIds = useState<Set<String>>({});

  void enter() => selecting.value = true;
  void toggle(String id) {
    final next = Set<String>.from(selectedIds.value);
    if (!next.add(id)) next.remove(id);
    selectedIds.value = next;
  }

  void exit() {
    selecting.value = false;
    selectedIds.value = {};
  }

  void replace(Set<String> ids) => selectedIds.value = ids;

  return (
    selecting: selecting.value,
    selectedIds: selectedIds.value,
    enter: enter,
    toggle: toggle,
    exit: exit,
    replace: replace,
  );
}
