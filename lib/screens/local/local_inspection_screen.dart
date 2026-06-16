import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/local_inspection.dart';
import '../../providers/inspection_provider.dart';

class LocalInspectionsScreen extends ConsumerStatefulWidget {
  const LocalInspectionsScreen({super.key});

  @override
  ConsumerState<LocalInspectionsScreen> createState() =>
      _LocalInspectionsScreenState();
}

class _LocalInspectionsScreenState
    extends ConsumerState<LocalInspectionsScreen> {
  bool _isInitialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    try {
      // Ensure the provider is ready before loading
      await Future.microtask(() {
        ref.read(inspectionNotifierProvider.notifier).loadInspections();
      });

      // Set a flag to indicate initial load is complete
      setState(() {
        _isInitialLoadComplete = true;
      });
    } catch (e) {
      log('Error in initial load: $e');
      setState(() {
        _isInitialLoadComplete = true;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
  }

  void _showCooldownMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please wait a few seconds before refreshing again'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSubmission(
    BuildContext context,
    LocalInspection inspection,
  ) async {
    try {
      final success = await ref
          .read(inspectionNotifierProvider.notifier)
          .retrySubmission(inspection);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit inspection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting inspection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInspectionDetailsDialog(
      BuildContext context, LocalInspection inspection) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Inspection Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Inspection ID: ${inspection.id}'),
                Text('Created: ${_formatDateTime(inspection.createdAt)}'),
                Text('Status: ${inspection.status}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(
      inspectionNotifierProvider.select(
        (s) => (
          inspections: s.inspections,
          isLoading: s.isLoading,
          refreshCooldown: s.refreshCooldown,
          submittingStates: s.submittingStates,
        ),
      ),
    );
    return Builder(
      builder: (context) {
        // Check if initial load is in progress
        if (!_isInitialLoadComplete) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Pending Inspections'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading inspections...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Pending Inspections'),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: (provider.isLoading || provider.refreshCooldown)
                        ? () => _showCooldownMessage(context)
                        : () => ref
                            .read(inspectionNotifierProvider.notifier)
                            .loadInspections(),
                    color: provider.refreshCooldown ? Colors.grey : null,
                    tooltip: provider.refreshCooldown
                        ? 'Please wait before refreshing again'
                        : 'Refresh inspections',
                  ),
                  if (provider.refreshCooldown)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress indicator for submissions
              if (provider.inspections.any((inspection) =>
                  provider.submittingStates[inspection.id] == true))
                const LinearProgressIndicator(),

              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading inspections...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : provider.inspections.isEmpty
                        ? const Center(
                            child: Text(
                              'No pending inspections',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: provider.inspections.length,
                            itemBuilder: (context, index) {
                              final inspection = provider.inspections[index];
                              final displayId = inspection.id.length > 8
                                  ? inspection.id.substring(0, 8)
                                  : inspection.id;
                              final isSubmitting =
                                  provider.submittingStates[inspection.id] ??
                                      false;

                              return Card(
                                margin: const EdgeInsets.all(8),
                                child: ListTile(
                                  title: Text(
                                    'Inspection $displayId',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Created: ${_formatDateTime(inspection.createdAt)}\n'
                                    'Status: ${inspection.status}${isSubmitting ? ' Submitting...' : ''}',
                                  ),
                                  leading: IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () =>
                                        _showInspectionDetailsDialog(
                                            context, inspection),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.refresh),
                                        onPressed: isSubmitting
                                            ? null
                                            : () => _handleSubmission(
                                                  context,
                                                  inspection,
                                                ),
                                        tooltip: isSubmitting
                                            ? 'Submitting...'
                                            : 'Retry submission',
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
