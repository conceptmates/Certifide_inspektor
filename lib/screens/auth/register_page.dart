// import 'package:flutter/material.dart';
// import '../main.dart';
// import '../services/api_services.dart';

// class RegisterPage extends StatefulWidget {
//   const RegisterPage({super.key});

//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   bool _isPasswordVisible = false;
//   bool _isConfirmPasswordVisible = false;
//   bool _isLoading = false;
//   String? _errorMessage;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   // Password validation
//   bool _isPasswordValid(String password) {
//     return password.length >= 8 && // at least 8 characters
//         RegExp(r'[A-Z]').hasMatch(password) && // at least one uppercase
//         RegExp(r'[a-z]').hasMatch(password) && // at least one lowercase
//         RegExp(r'[0-9]').hasMatch(password); // at least one number
//   }

//   Future<void> _handleRegister() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });

//       try {
//         final result = await ApiService.register(
//           name: _nameController.text,
//           email: _emailController.text,
//           password: _passwordController.text,
//           passwordConfirmation: _confirmPasswordController.text,
//         );

//         if (mounted) {
//           setState(() => _isLoading = false);

//           if (result['success']) {
//             // Show success message
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Registration successful!'),
//                 backgroundColor: Colors.green,
//                 duration: Duration(seconds: 2),
//               ),
//             );

//             // Navigate to home or login page
//             Navigator.of(context).push(MaterialPageRoute(
//               builder: (context) => MainScreen(),
//             ));
//           } else {
//             setState(() {
//               _errorMessage = result['message'];
//             });
//           }
//         }
//       } catch (e) {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//             _errorMessage = 'An unexpected error occurred. Please try again.';
//           });
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Icon(
//                     Icons.person_outline,
//                     size: 40,
//                     color: Colors.black87,
//                   ),
//                   SizedBox(height: 24),

//                   Text(
//                     'Create Account',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Please fill in the form to continue',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   SizedBox(height: 32),

//                   // Name Field
//                   TextFormField(
//                     controller: _nameController,
//                     decoration: InputDecoration(
//                       hintText: 'Full Name',
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: EdgeInsets.all(16),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your name';
//                       }
//                       if (value.length < 2) {
//                         return 'Name must be at least 2 characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 16),

//                   // Email Field
//                   TextFormField(
//                     controller: _emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     decoration: InputDecoration(
//                       hintText: 'Email',
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: EdgeInsets.all(16),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your email';
//                       }
//                       if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                           .hasMatch(value)) {
//                         return 'Please enter a valid email';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 16),

//                   // Password Field
//                   TextFormField(
//                     controller: _passwordController,
//                     obscureText: !_isPasswordVisible,
//                     decoration: InputDecoration(
//                       hintText: 'Password',
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: EdgeInsets.all(16),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _isPasswordVisible
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                           color: Colors.grey,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _isPasswordVisible = !_isPasswordVisible;
//                           });
//                         },
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a password';
//                       }
//                       if (!_isPasswordValid(value)) {
//                         return 'Password must be at least 8 characters with uppercase, lowercase, and number';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 16),

//                   // Confirm Password Field
//                   TextFormField(
//                     controller: _confirmPasswordController,
//                     obscureText: !_isConfirmPasswordVisible,
//                     decoration: InputDecoration(
//                       hintText: 'Confirm Password',
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: EdgeInsets.all(16),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _isConfirmPasswordVisible
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                           color: Colors.grey,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _isConfirmPasswordVisible =
//                                 !_isConfirmPasswordVisible;
//                           });
//                         },
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please confirm your password';
//                       }
//                       if (value != _passwordController.text) {
//                         return 'Passwords do not match';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 24),

//                   // Error Message
//                   if (_errorMessage != null)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 16),
//                       child: Text(
//                         _errorMessage!,
//                         style: TextStyle(
//                           color: Colors.red[400],
//                           fontSize: 14,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),

//                   // Register Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _isLoading ? null : _handleRegister,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.black87,
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: _isLoading
//                           ? SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor:
//                                     AlwaysStoppedAnimation<Color>(Colors.white),
//                               ),
//                             )
//                           : Text(
//                               'Create Account',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.white,
//                               ),
//                             ),
//                     ),
//                   ),
//                   SizedBox(height: 24),

//                   // Login Link
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Already have an account? ',
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                         child: Text(
//                           'Login',
//                           style: TextStyle(
//                             color: Colors.black87,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
