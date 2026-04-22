import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../models.dart';
import '../cv_provider.dart';
import '../pdf_generator.dart';
import 'form_screen.dart';

class CVPreviewScreen extends StatefulWidget {
  const CVPreviewScreen({super.key});

  @override
  State<CVPreviewScreen> createState() => _CVPreviewScreenState();
}

class _CVPreviewScreenState extends State<CVPreviewScreen> {
  late Future<Uint8List> _pdfBytesFuture;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CVProvider>();
    _pdfBytesFuture = buildPDF(provider); // Pulled from pdf_generator.dart
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final template = provider.selectedTemplate;

    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: Text('Preview — ${template.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FormScreen()),
            ),
            tooltip: 'Edit Information',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: template.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, size: 14, color: template.primaryColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is the actual A4 PDF rendering. Zoom and pan to review.',
                    style: TextStyle(fontSize: 12, color: template.primaryColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => _pdfBytesFuture,
              useActions: false, allowPrinting: false, allowSharing: false,
              canChangeOrientation: false, canChangePageFormat: false,
              maxPageWidth: 700,
              scrollViewDecoration: const BoxDecoration(color: Color(0xFFECEFF1)),
            ),
          ),
          _PreviewActionBar(provider: provider),
        ],
      ),
    );
  }
}

class _PreviewActionBar extends StatelessWidget {
  final CVProvider provider;
  const _PreviewActionBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white, border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0, runSpacing: 12.0,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                provider.saveDraft();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to drafts!')));
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.save_outlined, size: 16), label: const Text('Save Draft'),
            ),
            ElevatedButton.icon(
              // Passed context and provider to pdf_generator.dart logic
              onPressed: () => generateAndSavePDF(context, provider),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16), label: const Text('Generate PDF'),
            ),
          ],
        ),
      ),
    );
  }
}