import 'package:flutter/material.dart';

import '../../models/inspector.dart';
import '../../services/api_services.dart';

class AddCreditsPage extends StatefulWidget {
  const AddCreditsPage({super.key});

  @override
  State<AddCreditsPage> createState() => _AddCreditsPageState();
}

class _AddCreditsPageState extends State<AddCreditsPage> {
  Inspector? selectedInspector;
  int selectedCredits = 0;
  final TextEditingController _customCreditsController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Inspector> inspectors = [];
  bool isLoading = true;

  final List<int> predefinedCredits = [1, 5, 10];

  @override
  void initState() {
    super.initState();
    refreshInspectorsList();
  }

  Future<void> refreshInspectorsList() async {
    await _loadInspectors();
  }

  Future<void> _loadInspectors() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.getInspectors();
      if (mounted) {
        setState(() {
          if (result['success']) {
            inspectors = result['data'];
          }
          isLoading = false;
        });

        if (!result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inspectors: $e')),
        );
      }
    }
  }

  List<Inspector> get filteredInspectors {
    if (_searchController.text.isEmpty) {
      return inspectors;
    }
    return inspectors.where((inspector) {
      return inspector.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          inspector.id.toString().contains(_searchController.text) ||
          inspector.email
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
    }).toList();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Credit Allocation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please confirm the following details:'),
            const SizedBox(height: 16),
            Text(
              'Inspector: ${selectedInspector!.name.isNotEmpty ? selectedInspector!.name : 'Inspector ${selectedInspector!.id}'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Email: ${selectedInspector!.email}'),
            const SizedBox(height: 8),
            Text(
              'Current Balance: ${selectedInspector!.availableTokens} credits',
            ),
            const SizedBox(height: 16),
            Text(
              'Credits to Add: $selectedCredits',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New Balance will be: ${selectedInspector!.availableTokens + selectedCredits} credits',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processCreditAllocation();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCredits() async {
    if (selectedInspector == null) {
      _showErrorSnackBar('Please select an inspector');
      return;
    }
    if (selectedCredits <= 0) {
      _showErrorSnackBar('Please select or enter credits amount');
      return;
    }

    _showConfirmationDialog();
  }

  Future<void> _processCreditAllocation() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await ApiService.allocateTokens(
        userId: selectedInspector!.id.toString(),
        tokens: selectedCredits.toString(),
      );

      if (mounted) {
        Navigator.pop(context); // Hide loading indicator

        if (result['success']) {
          _showSuccessDialog();
        } else {
          _showErrorSnackBar(result['message'] ?? 'Failed to allocate tokens');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Hide loading indicator
        _showErrorSnackBar('Error sending credits: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Successfully sent $selectedCredits credits to ${selectedInspector!.name.isNotEmpty ? selectedInspector!.name : 'Inspector ${selectedInspector!.id}'}',
            ),
            const SizedBox(height: 8),
            Text(
              'New balance: ${selectedInspector!.availableTokens + selectedCredits} credits',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                selectedInspector = null;
                selectedCredits = 0;
                _customCreditsController.clear();
              });
              refreshInspectorsList(); // Refresh the list after allocation
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCustomCreditsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Custom Credits'),
        content: TextField(
          controller: _customCreditsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Credits Amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final credits = int.tryParse(_customCreditsController.text);
              if (credits != null && credits > 0) {
                setState(() {
                  selectedCredits = credits;
                });
                Navigator.of(context).pop();
              } else {
                _showErrorSnackBar('Please enter a valid amount');
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Add Credits',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
            onPressed: refreshInspectorsList,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Left side - Inspector List (Desktop)
          if (MediaQuery.of(context).size.width > 600)
            SizedBox(
              width: 350,
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                shadowColor: colorScheme.shadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search inspectors...',
                          prefixIcon: Icon(Icons.search,
                              color: colorScheme.onSurfaceVariant),
                          filled: true,
                          fillColor:
                              colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredInspectors.length,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemBuilder: (context, index) {
                                final inspector = filteredInspectors[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedInspector?.id == inspector.id
                                        ? colorScheme.primary.withValues(alpha: 0.1)
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: colorScheme.primary,
                                      child: Text(
                                        inspector.name.isNotEmpty
                                            ? inspector.name[0]
                                            : '#',
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      inspector.name.isNotEmpty
                                          ? inspector.name
                                          : 'Inspector ${inspector.id}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    subtitle: Text(
                                      inspector.email,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${inspector.availableTokens} credits',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    selected:
                                        selectedInspector?.id == inspector.id,
                                    onTap: () {
                                      setState(() {
                                        selectedInspector = inspector;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

          // Right side - Credits Selection
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mobile Inspector Selection
                  if (MediaQuery.of(context).size.width <= 600)
                    Card(
                      elevation: 2,
                      shadowColor: colorScheme.shadow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: InkWell(
                          onTap: () {
                            _loadInspectors();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Select Inspector',
                                  style:
                                      TextStyle(color: colorScheme.onSurface),
                                ),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: inspectors.length,
                                    itemBuilder: (context, index) {
                                      final inspector = inspectors[index];
                                      return ListTile(
                                        title: Text(
                                          inspector.name.isNotEmpty
                                              ? inspector.name
                                              : 'Inspector ${inspector.id}',
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${inspector.availableTokens} credits',
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            selectedInspector = inspector;
                                          });
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedInspector != null
                                      ? '${selectedInspector!.name.isNotEmpty ? selectedInspector!.name : 'Inspector ${selectedInspector!.id}'} (${selectedInspector!.availableTokens} credits)'
                                      : 'Select Inspector',
                                  style: TextStyle(
                                    color: selectedInspector != null
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Credits Selection Section
                  Card(
                    elevation: 5,
                    shadowColor: colorScheme.shadow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Credit Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Divider(),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: predefinedCredits.map((credits) {
                              final isSelected = selectedCredits == credits;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedCredits = credits;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHighest,
                                    elevation: isSelected ? 2 : 1,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    '$credits Credits',
                                    style: TextStyle(
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _showCustomCreditsDialog,
                            icon: Icon(Icons.add, color: colorScheme.primary),
                            label: Text(
                              'Custom Amount',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (selectedCredits > 0) ...[
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      shadowColor: colorScheme.shadow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$selectedCredits Credits',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _sendCredits,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Send Credits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customCreditsController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
