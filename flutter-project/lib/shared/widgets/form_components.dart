import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

/// A utility class that provides reusable form components.
/// 
/// This class includes methods to create:
/// - Text fields with optional icons.
/// - Date and time pickers.
/// - Checkboxes.
/// - Dropdown selectors.
/// - Toggle buttons.
/// - Numeric steppers with up/down buttons.
class FormComponents {
  
  /// Builds a standard text field.
  /// 
  /// Parameters:
  /// - `label`: The label displayed above the text field.
  /// - `controller`: A `TextEditingController` to manage the field's text.
  /// - `isReadOnly`: Whether the field is read-only.
  /// - `onTapIcon`: A callback triggered when the optional icon is tapped.
  /// - `keyboardType`: Defines the keyboard type (default is text).
  /// - `inputFormatters`: Optional formatters to restrict input values.
  /// - `icon`: An optional icon to display in the field (e.g., a search icon).
  /// - `onChanged`: Callback triggered when the text changes.
  static Widget buildTextField({
    required String label,
    required TextEditingController controller,
    bool isReadOnly = false,
    VoidCallback? onTapIcon, 
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    IconData? icon, // Optional icon (e.g., search icon)
    Function(String)? onChanged, // Add onChanged parameter
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly, // Allows manual entry unless explicitly read-only.
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        // Pass the onChanged callback to TextFormField
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
          suffixIcon: icon != null
              ? IconButton(
                  icon: Icon(icon),
                  onPressed: onTapIcon, 
                )
              : null, // No icon if none provided.
        ),
        validator: (value) => (value == null || value.isEmpty) ? "This field cannot be empty" : null,
      ),
    );
  }

  

  /// Builds a date picker field.
  ///   
  /// Parameters:
  /// - `label`: The label displayed above the field.
  /// - `value`: The currently selected date.
  /// - `onTap`: Callback to open the date picker.
  static Widget buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: GestureDetector(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value != null ? "${value.day}/${value.month}/${value.year}" : "Select Date",
                style: TextStyle(fontSize: 16.sp),
              ),
              const Icon(Icons.calendar_today, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a time picker field. 
  /// 
  /// Parameters:
  /// - `label`: The label displayed above the field.
  /// - `value`: The currently selected time.
  /// - `onTap`: Callback to open the time picker.
  static Widget buildTimeField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: GestureDetector(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value != null ? "${value.hour}:${value.minute.toString().padLeft(2, '0')}" : "Select Time",
                style: TextStyle(fontSize: 16.sp),
              ),
              const Icon(Icons.access_time, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a checkbox field.
  /// 
  /// Parameters:
  /// - `label`: The text displayed next to the checkbox.
  /// - `value`: The current state of the checkbox.
  /// - `onChanged`: Callback triggered when the checkbox state changes.
  static Widget buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Text(label, style: TextStyle(fontSize: 16.sp)),
        ],
      ),
    );
  }

  /// Builds a dropdown field.
  /// 
  /// Parameters:
  /// - `label`: The label displayed above the dropdown.
  /// - `value`: The currently selected item.
  /// - `items`: A list of selectable items.
  /// - `onChanged`: Callback triggered when a new item is selected.
  /// - `hint`: Optional hint text.
  static Widget buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? hint,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        value: (value != null && items.contains(value)) ? value : null, // Ensures the value exists in the items list.
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? "Please select a valid option" : null,
      ),
    );
  }

  /// Builds a togglable button 
  /// 
  /// Parameters:
  /// -`label`: The text displayed inside the button.
  /// - `isSelected`: Whether the button is currently active.
  /// - `onTap`: Callback triggered when the button is tapped.  
  static Widget buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a numeric stepper field with up/down buttons.  
  /// 
  /// Parameters:
  /// - `label`: The label above the field.
  /// - `controller`: The `TextEditingController` managing the field.
  /// - `isEnabled`: Whether the field is editable.
  /// - `onIncrement`: Callback triggered when the increment button is pressed.
  /// - `onDecrement`: Callback triggered when the decrement button is pressed.
  /// - `onChanged`: Callback triggered when the text is manually edited, receiving the new value.
  /// - `step`: The increment/decrement step size.
  /// - `minValue`: The minimum allowed value.
  /// - `allowDecimals`: Whether decimal values are allowed.
  static Widget buildNumericStepperField({
  required String label,
  required TextEditingController controller,
  required bool isEnabled,
  required VoidCallback onIncrement,
  required VoidCallback onDecrement,
  Function(String)? onChanged, 
  double step = 1.0, // Default step is 1 (for duration & frequency).
  double minValue = 1.0, // Flexible minimum (0.0 for dose, 1.0 for duration/frequency).
  bool allowDecimals = false, // Allows different behavior for integers vs decimals.
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: 2.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),

        Row(
          children: [
            // Numeric Input Field.
            Expanded(
              child: TextFormField(
                controller: controller,
                textAlign: TextAlign.center, // Center-align inout for better UI.
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
                ),
                keyboardType: allowDecimals
                    ? TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    allowDecimals ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'), // Allows decimals if needed.
                  ),
                ],
                enabled: isEnabled,
                // Add onChanged handler to capture text input
                onChanged: onChanged,
                validator: (value) {
                  if (isEnabled && (value == null || value.isEmpty)) {
                    return 'Please enter a value';
                  }
                  final parsedValue = double.tryParse(value ?? '');
                  if (parsedValue == null || parsedValue < minValue) {
                    return 'Value must be at least $minValue';
                  }
                  return null;
                },
              ),
            ),

            // Up/Down Buttons.
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_drop_up, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  // Use the provided callback instead of inline logic
                  onPressed: isEnabled ? onIncrement : null,
                ),

                Container(
                  width: 30,
                  height: 1,
                  color: Colors.grey[400],
                ),

                IconButton(
                  icon: Icon(Icons.arrow_drop_down, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  // Use the provided callback instead of inline logic
                  onPressed: isEnabled ? onDecrement : null,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

}
