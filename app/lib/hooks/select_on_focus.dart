import "package:flutter/material.dart";
import "package:typewriter/widgets/inspector/current_editing_field.dart";

void useSelectOnFocus(FocusNode focus, TextEditingController controller) {
  useFocusedChange(focus, ({required hasFocus}) {
    if (!hasFocus) return;
    // When we focus, we want to select the whole text
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: controller.text.length);
  });
}
