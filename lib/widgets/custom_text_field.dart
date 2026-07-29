// import 'package:flutter/material.dart';

// class CustomTextField extends StatelessWidget {
//   final String label;
//   final String? hint;
//   final TextEditingController controller;
//   final TextInputType keyboardType;
//   final bool obscureText;
//   final String? Function(String?)? validator;
//   final IconData? prefixIcon;
//   final Widget? suffixIcon;
//   final int maxLines;

//   const CustomTextField({
//     super.key,
//     required this.label,
//     required this.controller,
//     this.hint,
//     this.keyboardType = TextInputType.text,
//     this.obscureText = false,
//     this.validator,
//     this.prefixIcon,
//     this.suffixIcon,
//     this.maxLines = 1,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                   color: Theme.of(context).colorScheme.onSurface,
//                 ),
//           ),
//           const SizedBox(height: 8),
//           TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             obscureText: obscureText,
//             validator: validator,
//             maxLines: maxLines,
//             decoration: InputDecoration(
//               hintText: hint,
//               prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
//               suffixIcon: suffixIcon,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            readOnly: readOnly,
            validator: validator,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
              suffixIcon: suffixIcon,
              filled: readOnly,
              fillColor: readOnly ? Colors.grey.shade100 : null,
            ),
          ),
        ],
      ),
    );
  }
}
