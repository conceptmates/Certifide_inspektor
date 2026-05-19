import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../services/api_services.dart';
import 'car_spy_data.dart';

/// Vehicle RC lookup using [ApiService.getVehicleDetails].
class RcDetailsVerifyPage extends StatefulWidget {
  const RcDetailsVerifyPage({super.key});

  @override
  State<RcDetailsVerifyPage> createState() => _RcDetailsVerifyPageState();
}

class _RcDetailsVerifyPageState extends State<RcDetailsVerifyPage> {
  final TextEditingController _rcController = TextEditingController();
  bool _loading = false;
  String? _responseText;

  @override
  void dispose() {
    _rcController.dispose();
    super.dispose();
  }

  Future<void> _onVerify() async {
    final raw = _rcController.text.trim();
    if (raw.isEmpty) {
      setState(() => _responseText = 'not found');
      return;
    }

    setState(() {
      _loading = true;
      _responseText = null;
    });

    final result = await ApiService.getVehicleDetails(vehicleNumber: raw);

    if (!mounted) return;

    setState(() {
      _loading = false;
      final success = result['success'] == true;
      final data = result['data'];
      if (success && data != null && _hasUsableData(data)) {
        if (data is Map || data is List) {
          _responseText = const JsonEncoder.withIndent('  ').convert(data);
        } else {
          _responseText = data.toString();
        }
      } else {
        _responseText = 'not found';
      }
    });
  }

  bool _hasUsableData(dynamic data) {
    if (data is Map && data.isEmpty) return false;
    if (data is List && data.isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CarSpyColors.onSurface,
        elevation: 0,
        title: const Text(
          'RC Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CarSpyColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _rcController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'RC number',
                  hintText: 'Enter vehicle registration number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: CarSpyColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CarSpyColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        CarSpyColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'verify',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              if (_responseText != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Response',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _responseText!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: CarSpyColors.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
