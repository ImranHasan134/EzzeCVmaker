import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'models.dart';
import 'cv_provider.dart';

Future<void> generateAndSavePDF(BuildContext context, CVProvider provider) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Container(
        margin: const EdgeInsets.all(32), padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 8))]),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            SizedBox(height: 16),
            Text('Rendering Professional PDF...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, decoration: TextDecoration.none)),
          ],
        ),
      ),
    ),
  );

  try {
    final Uint8List pdfBytes = await buildPDF(provider);
    final name = provider.personalInfo.fullName.isNotEmpty ? provider.personalInfo.fullName.replaceAll(' ', '_') : 'EzzeCV';
    final fileName = '${name}_CV_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final jsonFileName = fileName.replaceAll('.pdf', '.json');
    final jsonString = provider.exportToJson();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    await File('${dir.path}/$jsonFileName').writeAsString(jsonString);

    provider.addSavedCV(SavedCV(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: provider.personalInfo.fullName.isNotEmpty ? '${provider.personalInfo.fullName}\'s CV' : 'My CV',
      templateName: provider.selectedTemplate.name,
      savedAt: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      filePath: file.path, isDraft: false, personalInfo: provider.personalInfo.copyWith(),
      workExperiences: provider.workExperiences.map((e) => e.copy()).toList(), educations: provider.educations.map((e) => e.copy()).toList(),
      projects: provider.projects.map((e) => e.copy()).toList(), certifications: provider.certifications.map((e) => e.copy()).toList(),
      skills: provider.skills.map((e) => e.copy()).toList(), languages: List.from(provider.languages), templateIndex: provider.selectedTemplateIndex,
      pdfColorHex: provider.pdfColor.value, pdfFont: provider.pdfFont,
    ));

    if (context.mounted) Navigator.of(context).pop();

    if (context.mounted) {
      final resultPath = await FilePicker.platform.saveFile(dialogTitle: 'Save CV Backup Data', fileName: jsonFileName, type: FileType.custom, allowedExtensions: ['json'], bytes: Uint8List.fromList(utf8.encode(jsonString)));
      if (resultPath != null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON Backup saved successfully!'), backgroundColor: Colors.green));
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red));
    }
  }
}

Future<pw.Font> _getFont(String fontName, bool isBold, bool isItalic) async {
  if (fontName == 'Merriweather') {
    if (isBold) return await PdfGoogleFonts.merriweatherBold();
    if (isItalic) return await PdfGoogleFonts.merriweatherItalic();
    return await PdfGoogleFonts.merriweatherRegular();
  } else if (fontName == 'Open Sans') {
    if (isBold) return await PdfGoogleFonts.openSansBold();
    if (isItalic) return await PdfGoogleFonts.openSansItalic();
    return await PdfGoogleFonts.openSansRegular();
  } else {
    if (isBold) return await PdfGoogleFonts.robotoBold();
    if (isItalic) return await PdfGoogleFonts.robotoItalic();
    return await PdfGoogleFonts.robotoRegular();
  }
}

Future<Uint8List> buildPDF(CVProvider provider) async {
  final fontReg = await _getFont(provider.pdfFont, false, false);
  final fontBold = await _getFont(provider.pdfFont, true, false);
  final fontItalic = await _getFont(provider.pdfFont, false, true);

  pw.ImageProvider? profileImage;
  if (provider.personalInfo.photoPath != null && File(provider.personalInfo.photoPath!).existsSync()) {
    profileImage = pw.MemoryImage(File(provider.personalInfo.photoPath!).readAsBytesSync());
  }

  PdfColor dynamicColor = PdfColor.fromInt(provider.pdfColor.value);

  switch (provider.selectedTemplate.id) {
    case 'classic_ats': return _buildExecutiveATS(provider, fontReg, fontBold, fontItalic);
    case 'modern_clean': return _buildCorporateModern(provider, fontReg, fontBold, fontItalic, dynamicColor, profileImage);
    case 'student_fresher': return _buildAcademicStandard(provider, fontReg, fontBold, fontItalic, dynamicColor, profileImage);
    case 'hybrid': return _buildTechMinimalist(provider, fontReg, fontBold, fontItalic, dynamicColor);
    case 'one_page': return _buildManagerialCompact(provider, fontReg, fontBold, fontItalic, dynamicColor);
    default: return _buildExecutiveATS(provider, fontReg, fontBold, fontItalic);
  }
}

const _svgPhone = 'M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z';
const _svgMail = 'M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z';
const _svgLoc = 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z';
const _svgLink = 'M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z';

pw.Widget _drawIcon(String path, PdfColor color, {double size = 10}) => pw.SvgImage(svg: '<svg viewBox="0 0 24 24"><path d="$path" fill="${color.toHex()}"/></svg>', width: size, height: size);

Future<Uint8List> _buildExecutiveATS(CVProvider p, pw.Font font, pw.Font fontBold, pw.Font fontItalic) async {
  final pdf = pw.Document();
  List<String> contactParts = [];
  if (p.personalInfo.location.isNotEmpty) contactParts.add(p.personalInfo.location);
  if (p.personalInfo.phone.isNotEmpty) contactParts.add(p.personalInfo.phone);
  if (p.personalInfo.email.isNotEmpty) contactParts.add(p.personalInfo.email);
  if (p.personalInfo.linkedin.isNotEmpty) contactParts.add(p.personalInfo.linkedin);
  String contactString = contactParts.join('  |  ');

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.symmetric(horizontal: 54, vertical: 48),
    build: (ctx) => [
      pw.Center(
        child: pw.Column(
          children: [
            pw.Text(p.personalInfo.fullName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 20)),
            if (p.personalInfo.jobTitle.isNotEmpty) ...[pw.SizedBox(height: 4), pw.Text(p.personalInfo.jobTitle, style: pw.TextStyle(font: font, fontSize: 12))],
            pw.SizedBox(height: 6), pw.Text(contactString, style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ),
      ),
      pw.SizedBox(height: 18),
      if (p.personalInfo.summary.isNotEmpty) ...[
        _atsHeader('PROFESSIONAL SUMMARY', fontBold),
        pw.Text(p.personalInfo.summary, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 11, lineSpacing: 1.5)), pw.SizedBox(height: 16),
      ],
      if (p.workExperiences.isNotEmpty) ...[
        _atsHeader('PROFESSIONAL EXPERIENCE', fontBold),
        ...p.workExperiences.map((exp) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text(exp.position, style: pw.TextStyle(font: fontBold, fontSize: 11)), pw.Text('${exp.startDate} - ${exp.isCurrentJob ? 'Present' : exp.endDate}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
            ]),
            pw.SizedBox(height: 2), pw.Text(exp.company, style: pw.TextStyle(font: fontItalic, fontSize: 11)), pw.SizedBox(height: 6),
            if (exp.description.isNotEmpty) pw.Text(exp.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5)),
          ]),
        )), pw.SizedBox(height: 6),
      ],
      if (p.educations.isNotEmpty) ...[
        _atsHeader('EDUCATION', fontBold),
        ...p.educations.map((edu) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(edu.institution, style: pw.TextStyle(font: fontBold, fontSize: 11)), pw.SizedBox(height: 2),
              pw.Text('${edu.degree}${edu.field.isNotEmpty ? ' in ${edu.field}' : ''}', style: pw.TextStyle(font: fontItalic, fontSize: 11)),
            ])),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('${edu.startYear} - ${edu.endYear}', style: pw.TextStyle(font: font, fontSize: 10)),
              if (edu.grade.isNotEmpty) pw.Text('GPA: ${edu.grade}', style: pw.TextStyle(font: font, fontSize: 10)),
            ]),
          ]),
        )), pw.SizedBox(height: 6),
      ],
      if (p.projects.isNotEmpty) ...[
        _atsHeader('PROJECTS', fontBold),
        ...p.projects.map((proj) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.RichText(text: pw.TextSpan(children: [
              pw.TextSpan(text: '${proj.name} ', style: pw.TextStyle(font: fontBold, fontSize: 11)),
              if (proj.technologies.isNotEmpty) pw.TextSpan(text: '| ${proj.technologies}', style: pw.TextStyle(font: fontItalic, fontSize: 10)),
            ])),
            pw.SizedBox(height: 4), if (proj.description.isNotEmpty) pw.Text(proj.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5)),
          ]),
        )), pw.SizedBox(height: 6),
      ],
      if (p.skills.isNotEmpty || p.languages.isNotEmpty) ...[
        _atsHeader('ADDITIONAL INFORMATION', fontBold),
        if (p.skills.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.RichText(text: pw.TextSpan(children: [
          pw.TextSpan(text: 'Skills: ', style: pw.TextStyle(font: fontBold, fontSize: 11)), pw.TextSpan(text: p.skills.map((s) => s.name).join(', '), style: pw.TextStyle(font: font, fontSize: 11)),
        ]))),
        if (p.languages.isNotEmpty) pw.RichText(text: pw.TextSpan(children: [
          pw.TextSpan(text: 'Languages: ', style: pw.TextStyle(font: fontBold, fontSize: 11)), pw.TextSpan(text: p.languages.join(', '), style: pw.TextStyle(font: font, fontSize: 11)),
        ])),
      ],
    ],
  ));
  return pdf.save();
}

pw.Widget _atsHeader(String title, pw.Font fontBold) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
  pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11, letterSpacing: 0.5)),
  pw.Container(height: 1, color: PdfColors.black, margin: const pw.EdgeInsets.only(top: 4, bottom: 12)),
]);


Future<Uint8List> _buildCorporateModern(CVProvider p, pw.Font font, pw.Font fontBold, pw.Font fontItalic, PdfColor primaryColor, pw.ImageProvider? image) async {
  final pdf = pw.Document();
  const secondaryText = PdfColor.fromInt(0xFF5D6D7E);
  const sidebarBg = PdfColor.fromInt(0xFFF4F6F7);
  const emptyDotColor = PdfColor.fromInt(0xFFD5DBDB);

  pdf.addPage(pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
      buildBackground: (ctx) => pw.FullPage(ignoreMargins: true, child: pw.Row(children: [pw.Container(width: 190, color: sidebarBg), pw.Expanded(child: pw.Container(color: PdfColors.white))])),
    ),
    build: (ctx) => [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 190, padding: const pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (image != null) pw.Center(child: pw.Container(width: 100, height: 100, margin: const pw.EdgeInsets.only(bottom: 24), decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, image: pw.DecorationImage(image: image, fit: pw.BoxFit.cover)))),
                pw.SizedBox(height: 10),
                pw.Text('CONTACT', style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor, letterSpacing: 1.5)),
                pw.Container(height: 1.5, width: 24, color: primaryColor, margin: const pw.EdgeInsets.only(top: 4, bottom: 16)),
                if (p.personalInfo.email.isNotEmpty) _modContact(_svgMail, p.personalInfo.email, font, primaryColor),
                if (p.personalInfo.phone.isNotEmpty) _modContact(_svgPhone, p.personalInfo.phone, font, primaryColor),
                if (p.personalInfo.location.isNotEmpty) _modContact(_svgLoc, p.personalInfo.location, font, primaryColor),
                if (p.personalInfo.linkedin.isNotEmpty) _modContact(_svgLink, p.personalInfo.linkedin, font, primaryColor),
                if (p.skills.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  pw.Text('SKILLS', style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor, letterSpacing: 1.5)),
                  pw.Container(height: 1.5, width: 24, color: primaryColor, margin: const pw.EdgeInsets.only(top: 4, bottom: 16)),
                  ...p.skills.map((s) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 12), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(s.name, style: pw.TextStyle(font: font, fontSize: 10, color: primaryColor)), pw.SizedBox(height: 4), _buildSkillMeter(s.level, primaryColor, emptyDotColor),
                  ]))),
                ],
                if (p.languages.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Text('LANGUAGES', style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor, letterSpacing: 1.5)),
                  pw.Container(height: 1.5, width: 24, color: primaryColor, margin: const pw.EdgeInsets.only(top: 4, bottom: 16)),
                  ...p.languages.map((l) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.Text(l, style: pw.TextStyle(font: font, fontSize: 10, color: primaryColor)))),
                ],
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(36, 40, 40, 40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(p.personalInfo.fullName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 26, color: primaryColor)),
                  pw.SizedBox(height: 4), pw.Text(p.personalInfo.jobTitle, style: pw.TextStyle(font: font, fontSize: 13, color: secondaryText, letterSpacing: 1.2)),
                  pw.SizedBox(height: 24),
                  if (p.personalInfo.summary.isNotEmpty) ...[
                    pw.Text(p.personalInfo.summary, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, color: primaryColor, lineSpacing: 1.5)), pw.SizedBox(height: 28),
                  ],
                  if (p.workExperiences.isNotEmpty) ...[
                    _modHeader('EXPERIENCE', fontBold, primaryColor),
                    ...p.workExperiences.map((exp) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 18), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(exp.position, style: pw.TextStyle(font: fontBold, fontSize: 12, color: primaryColor)), pw.SizedBox(height: 2),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                        pw.Text(exp.company, style: pw.TextStyle(font: fontBold, fontSize: 10, color: secondaryText)),
                        pw.Text('${exp.startDate} - ${exp.isCurrentJob ? 'Present' : exp.endDate}', style: pw.TextStyle(font: font, fontSize: 10, color: secondaryText)),
                      ]),
                      pw.SizedBox(height: 8), if (exp.description.isNotEmpty) pw.Text(exp.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, color: primaryColor, lineSpacing: 1.5)),
                    ]))),
                  ],
                  if (p.educations.isNotEmpty) ...[
                    pw.SizedBox(height: 10), _modHeader('EDUCATION', fontBold, primaryColor),
                    ...p.educations.map((edu) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 14), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(edu.degree, style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor)), pw.SizedBox(height: 2),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                        pw.Text(edu.institution, style: pw.TextStyle(font: font, fontSize: 10, color: secondaryText)), pw.Text('${edu.startYear} - ${edu.endYear}', style: pw.TextStyle(font: font, fontSize: 10, color: secondaryText)),
                      ]),
                    ]))),
                  ],
                  if (p.projects.isNotEmpty) ...[
                    pw.SizedBox(height: 10), _modHeader('PROJECTS', fontBold, primaryColor),
                    ...p.projects.map((proj) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 14), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(proj.name, style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor)), pw.SizedBox(height: 2),
                      if (proj.technologies.isNotEmpty) pw.Text('Tech: ${proj.technologies}', style: pw.TextStyle(font: font, fontSize: 9, color: secondaryText)), pw.SizedBox(height: 4),
                      if (proj.description.isNotEmpty) pw.Text(proj.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, color: primaryColor, lineSpacing: 1.5)),
                    ]))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  ));
  return pdf.save();
}

pw.Widget _buildSkillMeter(int level, PdfColor filledColor, PdfColor emptyColor) => pw.Row(
  mainAxisSize: pw.MainAxisSize.min,
  children: List.generate(5, (index) => pw.Container(margin: const pw.EdgeInsets.only(right: 5), width: 14, height: 4, decoration: pw.BoxDecoration(color: index < level ? filledColor : emptyColor))),
);

pw.Widget _modContact(String iconSvg, String text, pw.Font font, PdfColor color) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Padding(padding: const pw.EdgeInsets.only(top: 1), child: _drawIcon(iconSvg, color, size: 10)), pw.SizedBox(width: 8),
      pw.Expanded(child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, color: color, lineSpacing: 1.3))),
    ])
);

pw.Widget _modHeader(String title, pw.Font fontBold, PdfColor color) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
  pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 14, color: color, letterSpacing: 1.2)),
  pw.Container(height: 1.5, color: color, margin: const pw.EdgeInsets.only(top: 6, bottom: 18)),
]
);

Future<Uint8List> _buildAcademicStandard(CVProvider p, pw.Font font, pw.Font fontBold, pw.Font fontItalic, PdfColor primaryColor, pw.ImageProvider? image) async {
  final pdf = pw.Document();
  const subtleGray = PdfColor.fromInt(0xFFEEEEEE);

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
    build: (ctx) => [
      pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(p.personalInfo.fullName, style: pw.TextStyle(font: fontBold, fontSize: 24, color: primaryColor)), pw.SizedBox(height: 4),
              pw.Text(p.personalInfo.jobTitle, style: pw.TextStyle(font: fontBold, fontSize: 12)), pw.SizedBox(height: 12),
              pw.Wrap(spacing: 12, runSpacing: 6, children: [
                if (p.personalInfo.email.isNotEmpty) _acadIcon(_svgMail, p.personalInfo.email, font),
                if (p.personalInfo.phone.isNotEmpty) _acadIcon(_svgPhone, p.personalInfo.phone, font),
                if (p.personalInfo.linkedin.isNotEmpty) _acadIcon(_svgLink, p.personalInfo.linkedin, font),
                if (p.personalInfo.location.isNotEmpty) _acadIcon(_svgLoc, p.personalInfo.location, font),
              ])
            ]),
            if (image != null) pw.Container(width: 80, height: 80, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, image: pw.DecorationImage(image: image, fit: pw.BoxFit.cover)))
          ]
      ),
      pw.SizedBox(height: 20),
      if (p.personalInfo.summary.isNotEmpty) ...[
        _acadHeader('PROFILE', fontBold, primaryColor, subtleGray),
        pw.Text(p.personalInfo.summary, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5)), pw.SizedBox(height: 16),
      ],
      if (p.educations.isNotEmpty) ...[
        _acadHeader('EDUCATION', fontBold, primaryColor, subtleGray),
        ...p.educations.map((edu) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 12), child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(edu.institution, style: pw.TextStyle(font: fontBold, fontSize: 11)), pw.SizedBox(height: 2),
            pw.Text('${edu.degree}${edu.field.isNotEmpty ? ' in ${edu.field}' : ''}', style: pw.TextStyle(font: font, fontSize: 10)),
            if (edu.grade.isNotEmpty) pw.Text('GPA: ${edu.grade}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor)),
          ])),
          pw.Text('${edu.startYear} - ${edu.endYear}', style: pw.TextStyle(font: fontItalic, fontSize: 10)),
        ]))), pw.SizedBox(height: 8),
      ],
      if (p.projects.isNotEmpty) ...[
        _acadHeader('ACADEMIC & PERSONAL PROJECTS', fontBold, primaryColor, subtleGray),
        ...p.projects.map((proj) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 14), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(proj.name, style: pw.TextStyle(font: fontBold, fontSize: 11)),
          if (proj.technologies.isNotEmpty) pw.Text('Tools: ${proj.technologies}', style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey700)), pw.SizedBox(height: 6),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Padding(padding: const pw.EdgeInsets.only(top: 4, right: 8), child: pw.Container(width: 3, height: 3, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle))),
            pw.Expanded(child: pw.Text(proj.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4))),
          ])
        ]))), pw.SizedBox(height: 8),
      ],
      if (p.workExperiences.isNotEmpty) ...[
        _acadHeader('EXPERIENCE', fontBold, primaryColor, subtleGray),
        ...p.workExperiences.map((exp) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 14), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(exp.position, style: pw.TextStyle(font: fontBold, fontSize: 11)),
            pw.Text('${exp.startDate} - ${exp.isCurrentJob ? 'Present' : exp.endDate}', style: pw.TextStyle(font: fontItalic, fontSize: 10)),
          ]),
          pw.SizedBox(height: 2), pw.Text(exp.company, style: pw.TextStyle(font: font, fontSize: 10)), pw.SizedBox(height: 6),
          if (exp.description.isNotEmpty) pw.Text(exp.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4)),
        ]))), pw.SizedBox(height: 8),
      ],
      if (p.skills.isNotEmpty) ...[
        _acadHeader('TECHNICAL SKILLS', fontBold, primaryColor, subtleGray),
        pw.Wrap(spacing: 12, runSpacing: 8, children: p.skills.map((s) => pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: pw.BoxDecoration(color: subtleGray, borderRadius: pw.BorderRadius.circular(12)), child: pw.Text(s.name, style: pw.TextStyle(font: fontBold, fontSize: 9, color: primaryColor)))).toList()),
      ],
    ],
  ));
  return pdf.save();
}

pw.Widget _acadIcon(String svg, String text, pw.Font font) => pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [_drawIcon(svg, PdfColors.grey700, size: 10), pw.SizedBox(width: 6), pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey800))]);
pw.Widget _acadHeader(String title, pw.Font fontBold, PdfColor primary, PdfColor bg) => pw.Container(margin: const pw.EdgeInsets.only(bottom: 12), padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(2)), child: pw.Row(children: [pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11, color: primary, letterSpacing: 1.1))]));

Future<Uint8List> _buildTechMinimalist(CVProvider p, pw.Font font, pw.Font fontBold, pw.Font fontItalic, PdfColor primaryColor) async {
  final pdf = pw.Document();
  const secondary = PdfColor.fromInt(0xFF546E7A);

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(48),
    build: (ctx) => [
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(p.personalInfo.fullName, style: pw.TextStyle(font: fontBold, fontSize: 26, color: primaryColor)), pw.SizedBox(height: 6),
        pw.Text(p.personalInfo.jobTitle.toUpperCase(), style: pw.TextStyle(font: font, fontSize: 11, color: secondary, letterSpacing: 1.5)), pw.SizedBox(height: 16),
        pw.Wrap(spacing: 16, runSpacing: 8, children: [
          if (p.personalInfo.email.isNotEmpty) _techContact(_svgMail, p.personalInfo.email, font), if (p.personalInfo.phone.isNotEmpty) _techContact(_svgPhone, p.personalInfo.phone, font),
          if (p.personalInfo.location.isNotEmpty) _techContact(_svgLoc, p.personalInfo.location, font), if (p.personalInfo.linkedin.isNotEmpty) _techContact(_svgLink, p.personalInfo.linkedin, font),
        ]), pw.SizedBox(height: 24),
      ]),
      if (p.personalInfo.summary.isNotEmpty) ...[
        _techHeader('PROFILE', fontBold, primaryColor),
        pw.Text(p.personalInfo.summary, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5)), pw.SizedBox(height: 24),
      ],
      if (p.skills.isNotEmpty) ...[
        _techHeader('TECHNICAL EXPERTISE', fontBold, primaryColor),
        pw.Wrap(spacing: 6, runSpacing: 6, children: p.skills.map((s) => pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: pw.BoxDecoration(border: pw.Border.all(color: primaryColor, width: 1.5), borderRadius: pw.BorderRadius.circular(4)), child: pw.Text(s.name, style: pw.TextStyle(font: fontBold, fontSize: 9, color: primaryColor)))).toList()),
        pw.SizedBox(height: 24),
      ],
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(flex: 5, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (p.workExperiences.isNotEmpty) ...[
            _techHeader('EXPERIENCE', fontBold, primaryColor),
            ...p.workExperiences.map((exp) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 16), child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Container(width: 2, height: 40, color: primaryColor, margin: const pw.EdgeInsets.only(right: 12, top: -2)),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(exp.position, style: pw.TextStyle(font: fontBold, fontSize: 11)), pw.SizedBox(height: 4),
                pw.Text('${exp.company}  |  ${exp.startDate} - ${exp.isCurrentJob ? 'Present' : exp.endDate}', style: pw.TextStyle(font: font, fontSize: 9, color: secondary)), pw.SizedBox(height: 6),
                if (exp.description.isNotEmpty) pw.Text(exp.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4)),
              ]))
            ]))),
          ],
        ])),
        pw.SizedBox(width: 32),
        pw.Expanded(flex: 4, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (p.projects.isNotEmpty) ...[
            _techHeader('PROJECTS', fontBold, primaryColor),
            ...p.projects.map((proj) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 14), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(proj.name, style: pw.TextStyle(font: fontBold, fontSize: 10)), pw.SizedBox(height: 2),
              if (proj.technologies.isNotEmpty) pw.Text(proj.technologies, style: pw.TextStyle(font: font, fontSize: 9, color: primaryColor)), pw.SizedBox(height: 4),
              if (proj.description.isNotEmpty) pw.Text(proj.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 9, lineSpacing: 1.4)),
            ]))), pw.SizedBox(height: 12),
          ],
          if (p.educations.isNotEmpty) ...[
            _techHeader('EDUCATION', fontBold, primaryColor),
            ...p.educations.map((edu) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 12), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(edu.degree, style: pw.TextStyle(font: fontBold, fontSize: 10)), pw.SizedBox(height: 2),
              pw.Text(edu.institution, style: pw.TextStyle(font: font, fontSize: 9)), pw.Text('${edu.startYear} - ${edu.endYear}', style: pw.TextStyle(font: font, fontSize: 9, color: secondary)),
            ]))),
          ],
        ])),
      ])
    ],
  ));
  return pdf.save();
}

pw.Widget _techContact(String svg, String text, pw.Font font) => pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [_drawIcon(svg, PdfColors.grey900, size: 11), pw.SizedBox(width: 8), pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9))]);
pw.Widget _techHeader(String title, pw.Font fontBold, PdfColor color) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 14), child: pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 12, color: color, letterSpacing: 1.5)));

Future<Uint8List> _buildManagerialCompact(CVProvider p, pw.Font font, pw.Font fontBold, pw.Font fontItalic, PdfColor primaryColor) async {
  final pdf = pw.Document();
  const darkText = PdfColor.fromInt(0xFF263238);

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.symmetric(horizontal: 46, vertical: 46),
    build: (ctx) => [
      pw.Center(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Text(p.personalInfo.fullName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 22, color: primaryColor, letterSpacing: 1.2)), pw.SizedBox(height: 4),
          pw.Text(p.personalInfo.jobTitle, style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.grey700, letterSpacing: 1.5)), pw.SizedBox(height: 12),
          pw.Wrap(alignment: pw.WrapAlignment.center, spacing: 14, runSpacing: 6, children: [
            if (p.personalInfo.email.isNotEmpty) _compactContact(_svgMail, p.personalInfo.email, font), if (p.personalInfo.phone.isNotEmpty) _compactContact(_svgPhone, p.personalInfo.phone, font),
            if (p.personalInfo.location.isNotEmpty) _compactContact(_svgLoc, p.personalInfo.location, font), if (p.personalInfo.linkedin.isNotEmpty) _compactContact(_svgLink, p.personalInfo.linkedin, font),
          ]),
        ]),
      ),
      pw.SizedBox(height: 16), pw.Divider(color: primaryColor, thickness: 1.5), pw.SizedBox(height: 16),
      if (p.personalInfo.summary.isNotEmpty) ...[
        pw.Text(p.personalInfo.summary, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4, color: darkText)), pw.SizedBox(height: 18),
      ],
      if (p.skills.isNotEmpty || p.languages.isNotEmpty) ...[
        _compactHeader('CORE COMPETENCIES', fontBold, primaryColor),
        if (p.skills.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.RichText(text: pw.TextSpan(children: [
          pw.TextSpan(text: 'Technical Skills: ', style: pw.TextStyle(font: fontBold, fontSize: 10, color: darkText)), pw.TextSpan(text: p.skills.map((s) => s.name).join(' . '), style: pw.TextStyle(font: font, fontSize: 10, color: darkText)),
        ]))),
        if (p.languages.isNotEmpty) pw.RichText(text: pw.TextSpan(children: [
          pw.TextSpan(text: 'Languages: ', style: pw.TextStyle(font: fontBold, fontSize: 10, color: darkText)), pw.TextSpan(text: p.languages.join(' . '), style: pw.TextStyle(font: font, fontSize: 10, color: darkText)),
        ])), pw.SizedBox(height: 18),
      ],
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(flex: 6, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (p.workExperiences.isNotEmpty) ...[
            _compactHeader('PROFESSIONAL EXPERIENCE', fontBold, primaryColor),
            ...p.workExperiences.map((exp) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 14), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text(exp.position, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkText)), pw.Text('${exp.startDate} - ${exp.isCurrentJob ? 'Present' : exp.endDate}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor)),
              ]),
              pw.SizedBox(height: 2), pw.Text(exp.company, style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey800)), pw.SizedBox(height: 6),
              if (exp.description.isNotEmpty) pw.Text(exp.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4, color: darkText)),
            ]))), pw.SizedBox(height: 4),
          ],
        ])),
        pw.SizedBox(width: 24),
        pw.Expanded(flex: 4, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (p.projects.isNotEmpty) ...[
            _compactHeader('SELECTED PROJECTS', fontBold, primaryColor),
            ...p.projects.map((proj) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 14), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('${proj.name} ', style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkText)), if (proj.technologies.isNotEmpty) pw.Text('| ${proj.technologies}', style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey700)),
              ]), pw.SizedBox(height: 4),
              if (proj.description.isNotEmpty) pw.Text(proj.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4, color: darkText)),
            ]))), pw.SizedBox(height: 4),
          ],
          if (p.educations.isNotEmpty) ...[
            _compactHeader('EDUCATION', fontBold, primaryColor),
            ...p.educations.map((edu) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 12), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(edu.degree, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkText)), pw.SizedBox(height: 2), pw.Text(edu.institution, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)),
              ])),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('${edu.startYear} - ${edu.endYear}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor)), if (edu.grade.isNotEmpty) pw.Text('GPA: ${edu.grade}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
              ]),
            ]))),
          ],
        ]))
      ]),
    ],
  ));
  return pdf.save();
}

pw.Widget _compactContact(String svg, String text, pw.Font font) => pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [_drawIcon(svg, PdfColors.grey800, size: 10), pw.SizedBox(width: 6), pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromInt(0xFF263238)))]);
pw.Widget _compactHeader(String title, pw.Font fontBold, PdfColor color) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11, color: color, letterSpacing: 1.2)), pw.Container(height: 1, color: color, margin: const pw.EdgeInsets.only(top: 4, bottom: 12))]);
String _formatDate(DateTime dt) => '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month - 1]} ${dt.day}, ${dt.year}';