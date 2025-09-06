import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../routes/routes.dart';
import '../../widgets/fade_animation.dart';

class VehicleDetailsForm extends StatefulWidget {
  final bool isNewInspection;

  const VehicleDetailsForm({
    super.key,
    this.isNewInspection = true,
  });

  @override
  State<VehicleDetailsForm> createState() => _VehicleDetailsFormState();
}

class _VehicleDetailsFormState extends State<VehicleDetailsForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _variantController = TextEditingController();
  final _colourController = TextEditingController();
  String _selectedTransmission = 'Manual';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<String> _transmissionTypes = [
    'Manual',
    'Automatic',
    'CVT',
    'AMT',
    'DCT'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _variantController.dispose();
    _colourController.dispose();
    super.dispose();
  }

  void _proceedToInspection() {
    if (_formKey.currentState!.validate()) {
      final vehicleData = {
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': _yearController.text.trim(),
        'variant': _variantController.text.trim(),
        'colour': _colourController.text.trim(),
        'transmission': _selectedTransmission,
      };

      Navigator.pushReplacementNamed(
        context,
        Routes.inspection,
        arguments: {
          'isNew': widget.isNewInspection,
          'vehicleDetails': vehicleData,
        },
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blueAccent.shade200),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent.shade200, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedTransmission,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        dropdownColor: const Color(0xFF2C2C2C),
        decoration: InputDecoration(
          labelText: 'Transmission',
          prefixIcon: Icon(Icons.settings, color: Colors.blueAccent.shade200),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent.shade200, width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: _transmissionTypes.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedTransmission = newValue;
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select transmission type';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Vehicle Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blueAccent.shade200),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  FadeAnimation(
                    1.0,
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A73E8), Color(0xFF1557B0)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Enter Vehicle Information',
                            
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please provide the vehicle details to begin inspection',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Form Fields
                  FadeAnimation(
                    1.2,
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _makeController,
                            label: 'Make',
                            hint: 'e.g., Toyota, Honda, Ford',
                            icon: Icons.business,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter vehicle make';
                              }
                              return null;
                            },
                          ),
                          
                          _buildTextField(
                            controller: _modelController,
                            label: 'Model',
                            hint: 'e.g., Camry, Civic, Mustang',
                            icon: Icons.car_rental,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter vehicle model';
                              }
                              return null;
                            },
                          ),
                          
                          _buildTextField(
                            controller: _yearController,
                            label: 'Year',
                            hint: 'e.g., 2020',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter vehicle year';
                              }
                              final year = int.tryParse(value);
                              final currentYear = DateTime.now().year;
                              if (year == null || year < 1900 || year > currentYear + 1) {
                                return 'Please enter a valid year';
                              }
                              return null;
                            },
                          ),
                          
                          _buildTextField(
                            controller: _variantController,
                            label: 'Variant',
                            hint: 'e.g., LX, EX, SE (Optional)',
                            icon: Icons.tune,
                          ),
                          
                          _buildTextField(
                            controller: _colourController,
                            label: 'Colour',
                            hint: 'e.g., White, Black, Silver',
                            icon: Icons.color_lens,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter vehicle colour';
                              }
                              return null;
                            },
                          ),
                          
                          _buildDropdownField(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Continue Button
                  FadeAnimation(
                    1.4,
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _proceedToInspection,
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Start Inspection',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}