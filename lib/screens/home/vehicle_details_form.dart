import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/inspection_template_model.dart';
import '../../models/vehicle_model.dart';
import '../../routes/routes.dart';
import '../../services/api_services.dart';
import '../../widgets/fade_animation.dart';
import 'vehicle_details_form/components/vehicle_form_continue_button.dart';
import 'vehicle_details_form/components/vehicle_form_header_card.dart';
import 'vehicle_details_form/components/vehicle_form_text_field.dart';

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

  // API Data
  List<VehicleModel> _allModels = [];
  List<VehicleBrand> _brands = [];
  List<VehicleModel> _filteredModels = [];
  VehicleBrand? _selectedMake;
  VehicleModel? _selectedModel;
  bool _isLoadingModels = false;
  String? _modelError;

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

    // Load vehicle models from API
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoadingModels = true;
      _modelError = null;
    });

    try {
      final result = await ApiService.getModels();

      if (result['success'] && mounted) {
        setState(() {
          _allModels = List<VehicleModel>.from(result['data']);
          _brands = List<VehicleBrand>.from(result['brands']);
          _isLoadingModels = false;
        });
      } else if (mounted) {
        setState(() {
          _modelError = result['message'] ?? 'Failed to load models';
          _isLoadingModels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _modelError = 'Error loading models: ${e.toString()}';
          _isLoadingModels = false;
        });
      }
    }
  }

  void _onMakeChanged(VehicleBrand? newMake) {
    setState(() {
      _selectedMake = newMake;
      _selectedModel = null;
      _modelController.clear();

      if (newMake != null) {
        _filteredModels =
            _allModels.where((model) => model.brand.id == newMake.id).toList();
        // Sort models alphabetically
        _filteredModels.sort((a, b) => a.name.compareTo(b.name));
      } else {
        _filteredModels = [];
      }
    });
  }

  void _onModelChanged(VehicleModel? newModel) {
    setState(() {
      _selectedModel = newModel;
      if (newModel != null) {
        _modelController.text = newModel.name;
      } else {
        _modelController.clear();
      }
    });
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

  bool _isLoading = false;
  final TextInputFormatter _uppercaseFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
    final upperCaseText = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: upperCaseText,
      selection: TextSelection.collapsed(offset: upperCaseText.length),
    );
  });

  void _proceedToInspection() async {
    if (_formKey.currentState!.validate()) {
      // Validate that brand and model are selected
      if (_selectedMake == null || _selectedModel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both make and model'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final vehicleData = {
        'make': _selectedMake!.name,
        'model': _selectedModel!.name,
        'year': _yearController.text.trim(),
        'variant': _variantController.text.trim().toUpperCase(),
        'color': _colourController.text.trim().toUpperCase(),
        'transmission': _selectedTransmission,
        'brand_id': _selectedMake!.id,
        'model_id': _selectedModel!.id,
      };

      setState(() {
        _isLoading = true;
      });

      final result = await ApiService.initializeInspection(
        vehicleBrandId: _selectedMake!.id,
        vehicleModelId: _selectedModel!.id,
        year: _yearController.text.trim(),
        variant: _variantController.text.trim().toUpperCase(),
        colour: _colourController.text.trim().toUpperCase(),
        transmission: _selectedTransmission,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        final inspectionData = result['data'];

        // Merge server-returned vehicle_info into form fields and vehicleData
        if (inspectionData is InspectionInitializationResponse) {
          final vi = inspectionData.vehicleInfo;
          if (vi.year != null && vi.year!.isNotEmpty) {
            vehicleData['year'] = vi.year!;
            _yearController.text = vi.year!;
          }
          if (vi.variant != null && vi.variant!.isNotEmpty) {
            vehicleData['variant'] = vi.variant!.toUpperCase();
            _variantController.text = vi.variant!.toUpperCase();
          }
          if (vi.colour != null && vi.colour!.isNotEmpty) {
            vehicleData['color'] = vi.colour!.toUpperCase();
            _colourController.text = vi.colour!.toUpperCase();
          }
          if (vi.transmission != null && vi.transmission!.isNotEmpty) {
            vehicleData['transmission'] = vi.transmission!;
            if (_transmissionTypes.contains(vi.transmission)) {
              setState(() => _selectedTransmission = vi.transmission!);
            }
          }
        }

        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                Routes.inspection,
                arguments: {
                  'isNew': widget.isNewInspection,
                  'vehicleDetails': vehicleData,
                  'inspectionId': result['inspection_id'],
                  'inspectionTemplate': inspectionData,
                },
              );
            }
          });
        }
      } else {
        // Show error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Error',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                result['message'] ?? 'Failed to start inspection',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
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
    return VehicleFormTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
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

  Widget _buildMakeDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<VehicleBrand>(
            initialValue: _selectedMake,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            dropdownColor: const Color(0xFF2C2C2C),
            decoration: InputDecoration(
              labelText: 'Make',
              prefixIcon:
                  Icon(Icons.business, color: Colors.blueAccent.shade200),
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
                borderSide:
                    BorderSide(color: Colors.blueAccent.shade200, width: 2),
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
            items: _brands.map((VehicleBrand brand) {
              return DropdownMenuItem<VehicleBrand>(
                value: brand,
                child: Text(brand.name),
              );
            }).toList(),
            onChanged: _isLoadingModels ? null : _onMakeChanged,
            validator: (value) {
              if (value == null) {
                return 'Please select a make';
              }
              return null;
            },
            hint: _isLoadingModels
                ? const Text('Loading...')
                : const Text('Select Make'),
          ),
          if (_modelError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _modelError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<VehicleModel>(
        initialValue: _selectedModel,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        dropdownColor: const Color(0xFF2C2C2C),
        decoration: InputDecoration(
          labelText: 'Model',
          prefixIcon: Icon(Icons.car_rental, color: Colors.blueAccent.shade200),
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
        items: _filteredModels.map((VehicleModel model) {
          return DropdownMenuItem<VehicleModel>(
            value: model,
            child: Text(model.name),
          );
        }).toList(),
        onChanged: (_selectedMake == null || _isLoadingModels)
            ? null
            : _onModelChanged,
        validator: (value) {
          if (value == null) {
            return 'Please select a model';
          }
          return null;
        },
        hint: _selectedMake == null
            ? const Text('Select a make first')
            : _filteredModels.isEmpty
                ? const Text('No models available')
                : const Text('Select Model'),
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
                    const VehicleFormHeaderCard(),
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
                          // Make Dropdown
                          _buildMakeDropdown(),
                          // Model Dropdown
                          _buildModelDropdown(),
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
                              if (year == null ||
                                  year < 1900 ||
                                  year > currentYear + 1) {
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
                            inputFormatters: [_uppercaseFormatter],
                          ),
                          _buildTextField(
                            controller: _colourController,
                            label: 'Colour',
                            hint: 'e.g., White, Black, Silver',
                            icon: Icons.color_lens,
                            inputFormatters: [_uppercaseFormatter],
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
                    VehicleFormContinueButton(
                      isLoading: _isLoading,
                      onTap: _proceedToInspection,
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
