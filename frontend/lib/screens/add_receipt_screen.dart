import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tripspending/models/receipt.dart';
import 'package:tripspending/models/category.dart';
import 'package:tripspending/providers/receipt_provider.dart';
import 'package:tripspending/providers/trip_provider.dart';
import 'package:tripspending/services/location_service.dart';
import 'package:tripspending/services/ocr_service.dart';
import 'package:intl/intl.dart';

/// Screen for adding a new receipt with OCR
class AddReceiptScreen extends StatefulWidget {
  final int tripId;

  const AddReceiptScreen({super.key, required this.tripId});

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationService = LocationService();
  final _imagePicker = ImagePicker();

  String? _imagePath;
  String _currency = 'USD';
  String _category = 'Other';
  DateTime _purchaseDate = DateTime.now();
  double? _latitude;
  double? _longitude;
  String? _address;
  String? _rawText;
  List<ReceiptItem>? _items;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final trip = context.read<TripProvider>().selectedTrip;
    if (trip != null) {
      _currency = trip.currency;
    }
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (address != null && mounted) {
        setState(() => _address = address);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Receipt'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image capture section
            _buildImageSection(),
            const SizedBox(height: 24),

            // Processing indicator
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Processing receipt...'),
                    ],
                  ),
                ),
              ),

            // Merchant Name
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant Name',
                hintText: 'e.g., Starbucks',
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),

            // Amount and Currency
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                      DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                      DropdownMenuItem(value: 'KRW', child: Text('KRW')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _currency = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: SpendingCategory.defaults.map((cat) {
                return DropdownMenuItem(
                  value: cat.name,
                  child: Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 20),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),

            // Date
            _buildDateField(),
            const SizedBox(height: 16),

            // Location
            _buildLocationField(),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Any additional notes',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _saveReceipt,
              icon: const Icon(Icons.save),
              label: const Text('Save Receipt'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: InkWell(
        onTap: _showImageSourceDialog,
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_imagePath!),
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to capture receipt',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _purchaseDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_purchaseDate),
          );
          setState(() {
            _purchaseDate = DateTime(
              date.year,
              date.month,
              date.day,
              time?.hour ?? _purchaseDate.hour,
              time?.minute ?? _purchaseDate.minute,
            );
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date & Time',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('MMM d, yyyy - HH:mm').format(_purchaseDate),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Location',
        prefixIcon: Icon(Icons.location_on),
      ),
      child: Text(
        _address ?? (_latitude != null ? 'Location captured' : 'Fetching location...'),
        style: _address == null ? TextStyle(color: Theme.of(context).hintColor) : null,
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _captureImage(source);
    }
  }

  Future<void> _captureImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _isProcessing = true;
      });

      // Process with OCR
      final receiptProvider = context.read<ReceiptProvider>();
      final result = await receiptProvider.processReceiptImage(image.path);

      if (result != null && mounted) {
        setState(() {
          _isProcessing = false;
          _rawText = result.rawText;
          _items = result.items;

          if (result.merchantName != null) {
            _merchantController.text = result.merchantName!;
          }
          if (result.totalAmount != null) {
            _amountController.text = result.totalAmount!.toStringAsFixed(2);
          }
          if (result.currency != null) {
            _currency = result.currency!;
          }
          if (result.date != null) {
            _purchaseDate = result.date!;
          }
          _category = result.suggestedCategory;
        });
      } else {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    final receipt = Receipt(
      tripId: widget.tripId,
      merchantName: _merchantController.text.trim().isEmpty
          ? null
          : _merchantController.text.trim(),
      totalAmount: double.parse(_amountController.text),
      currency: _currency,
      category: _category,
      purchaseDate: _purchaseDate,
      items: _items,
      rawText: _rawText,
      imagePath: _imagePath,
      latitude: _latitude,
      longitude: _longitude,
      address: _address,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final receiptProvider = context.read<ReceiptProvider>();
    final createdReceipt = await receiptProvider.createReceipt(receipt);

    if (createdReceipt != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt saved!')),
      );
    } else if (receiptProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(receiptProvider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
