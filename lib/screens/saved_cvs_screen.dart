import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../models.dart';
import '../cv_provider.dart';
import 'form_screen.dart';

class SavedCVsScreen extends StatelessWidget {
  const SavedCVsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedCVs = context.watch<CVProvider>().savedCVs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Saved CVs'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: savedCVs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: isDark ? Colors.white12 : AppTheme.divider.withOpacity(0.5), shape: BoxShape.circle),
              child: Icon(Icons.folder_open_outlined, size: 48, color: isDark ? Colors.white54 : AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            Text('No saved CVs yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Create and generate a CV to see it here.', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: savedCVs.length,
        itemBuilder: (context, index) {
          final cv = savedCVs[index];
          final templateColor = AppConstants.templates.firstWhere(
                (t) => t.name == cv.templateName,
            orElse: () => AppConstants.templates.first,
          ).primaryColor;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : AppTheme.divider),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: cv.isDraft ? AppTheme.accentGold.withOpacity(0.12) : templateColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cv.isDraft ? Icons.edit_document : Icons.description, color: cv.isDraft ? AppTheme.accentGold : templateColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cv.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : AppTheme.textPrimary)),
                        const SizedBox(height: 3),
                        Text(
                          cv.isDraft ? 'Draft · Last saved: ${cv.savedAt}' : '${cv.templateName} · ${cv.savedAt}',
                          style: TextStyle(fontSize: 11, color: cv.isDraft ? AppTheme.accentGold : (isDark ? Colors.white54 : AppTheme.textSecondary), fontWeight: cv.isDraft ? FontWeight.w600 : FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconAction(
                        icon: Icons.edit_document, color: AppTheme.primaryBlue, tooltip: 'Resume Editing',
                        onTap: () {
                          context.read<CVProvider>().loadCV(cv);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen()));
                        },
                      ),
                      if (cv.filePath != null)
                        _IconAction(
                          icon: Icons.share_outlined, color: AppTheme.primaryBlue, tooltip: 'Share PDF',
                          onTap: () async {
                            final file = File(cv.filePath!);
                            if (await file.exists()) {
                              await Printing.sharePdf(bytes: await file.readAsBytes(), filename: '${cv.name}.pdf');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found')));
                            }
                          },
                        ),
                      _IconAction(
                        icon: Icons.delete_outline, color: Colors.red, tooltip: 'Delete',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              backgroundColor: Theme.of(context).cardColor,
                              title: Text('Delete CV', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                              content: Text('Are you sure you want to delete "${cv.name}"?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () { context.read<CVProvider>().removeSavedCV(cv.id); Navigator.pop(ctx); },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon; final Color color; final String tooltip; final VoidCallback onTap;
  const _IconAction({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}