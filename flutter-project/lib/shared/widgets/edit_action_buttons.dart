import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EditActionButtons extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onBack;
  final VoidCallback onEditSave;
  
  const EditActionButtons({
    Key? key,
    required this.isEditing,
    required this.onBack,
    required this.onEditSave,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: onBack,
          child: Text("Back", style: TextStyle(fontSize: 17.5.sp)),
        ),
        ElevatedButton(
          onPressed: onEditSave,
          child: Text(
            isEditing ? "Save" : "Edit", 
            style: TextStyle(fontSize: 17.5.sp)
          ),
        ),
      ],
    );
  }
}