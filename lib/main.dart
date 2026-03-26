// =============================================================================
// EzzeCV - Offline CV Builder App
// main.dart — Complete single-file Flutter application
// =============================================================================
// Structure:
//  1. Imports & Main Entry
//  2. Data Models
//  3. CV Provider (State Management)
//  4. App Theme & Constants
//  5. Home Screen
//  6. Multi-Step Form Screen
//  7. Template Selection Screen
//  8. CV Preview Screen
//  9. Saved CVs Screen
// 10. PDF Generation Logic (5 Templates)
// 11. Shared Widgets & Utilities
// =============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:file_picker/file_picker.dart'; // For the import button

// =============================================================================
// SECTION 1 — ENTRY POINT
// =============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => CVProvider(),
      child: const EzzeCVApp(),
    ),
  );
}

// =============================================================================
// SECTION 2 — DATA MODELS
// =============================================================================

/// Personal information of the CV owner
class PersonalInfo {
  String fullName;
  String jobTitle;
  String email;
  String phone;
  String location;
  String website;
  String linkedin;
  String summary;
  Map<String, dynamic> toJson() => {
    'fullName': fullName, 'jobTitle': jobTitle, 'email': email,
    'phone': phone, 'location': location, 'website': website,
    'linkedin': linkedin, 'summary': summary,
  };

  factory PersonalInfo.fromJson(Map<String, dynamic> json) => PersonalInfo(
    fullName: json['fullName'] ?? '', jobTitle: json['jobTitle'] ?? '',
    email: json['email'] ?? '', phone: json['phone'] ?? '',
    location: json['location'] ?? '', website: json['website'] ?? '',
    linkedin: json['linkedin'] ?? '', summary: json['summary'] ?? '',
  );

  PersonalInfo({
    this.fullName = '',
    this.jobTitle = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.website = '',
    this.linkedin = '',
    this.summary = '',
  });

  PersonalInfo copyWith({
    String? fullName,
    String? jobTitle,
    String? email,
    String? phone,
    String? location,
    String? website,
    String? linkedin,
    String? summary,
  }) {
    return PersonalInfo(
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
      linkedin: linkedin ?? this.linkedin,
      summary: summary ?? this.summary,
    );
  }
}

/// A single work experience entry
class WorkExperience {
  String company;
  String position;
  String startDate;
  String endDate;
  bool isCurrentJob;
  String description;

  Map<String, dynamic> toJson() => {
    'company': company, 'position': position, 'startDate': startDate,
    'endDate': endDate, 'isCurrentJob': isCurrentJob, 'description': description,
  };

  factory WorkExperience.fromJson(Map<String, dynamic> json) => WorkExperience(
    company: json['company'] ?? '', position: json['position'] ?? '',
    startDate: json['startDate'] ?? '', endDate: json['endDate'] ?? '',
    isCurrentJob: json['isCurrentJob'] ?? false, description: json['description'] ?? '',
  );

  WorkExperience({
    this.company = '',
    this.position = '',
    this.startDate = '',
    this.endDate = '',
    this.isCurrentJob = false,
    this.description = '',
  });

  WorkExperience copy() => WorkExperience(
    company: company,
    position: position,
    startDate: startDate,
    endDate: endDate,
    isCurrentJob: isCurrentJob,
    description: description,
  );
}

/// A single education entry
class Education {
  String institution;
  String degree;
  String field;
  String startYear;
  String endYear;
  String grade;

  Map<String, dynamic> toJson() => {
    'institution': institution, 'degree': degree, 'field': field,
    'startYear': startYear, 'endYear': endYear, 'grade': grade,
  };

  factory Education.fromJson(Map<String, dynamic> json) => Education(
    institution: json['institution'] ?? '', degree: json['degree'] ?? '',
    field: json['field'] ?? '', startYear: json['startYear'] ?? '',
    endYear: json['endYear'] ?? '', grade: json['grade'] ?? '',
  );

  Education({
    this.institution = '',
    this.degree = '',
    this.field = '',
    this.startYear = '',
    this.endYear = '',
    this.grade = '',
  });

  Education copy() => Education(
    institution: institution,
    degree: degree,
    field: field,
    startYear: startYear,
    endYear: endYear,
    grade: grade,
  );
}

/// A single project entry
class Project {
  String name;
  String description;
  String technologies;
  String link;

  Map<String, dynamic> toJson() => {
    'name': name, 'description': description, 'technologies': technologies, 'link': link,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    name: json['name'] ?? '', description: json['description'] ?? '',
    technologies: json['technologies'] ?? '', link: json['link'] ?? '',
  );

  Project({
    this.name = '',
    this.description = '',
    this.technologies = '',
    this.link = '',
  });

  Project copy() => Project(
    name: name,
    description: description,
    technologies: technologies,
    link: link,
  );
}

/// A single certification entry
class Certification {
  String name;
  String issuer;
  String year;

  Map<String, dynamic> toJson() => { 'name': name, 'issuer': issuer, 'year': year };

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
    name: json['name'] ?? '', issuer: json['issuer'] ?? '', year: json['year'] ?? '',
  );

  Certification({
    this.name = '',
    this.issuer = '',
    this.year = '',
  });

  Certification copy() => Certification(
    name: name,
    issuer: issuer,
    year: year,
  );
}

/// Skill model with proficiency level
class Skill {
  String name;
  int level; // 1-5

  Skill({this.name = '', this.level = 3});

  Skill copy() => Skill(name: name, level: level);

  Map<String, dynamic> toJson() => { 'name': name, 'level': level };

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    name: json['name'] ?? '', level: json['level'] ?? 3,
  );
}


/// Saved CV record for the Saved CVs screen
class SavedCV {
  final String id;
  final String name;
  final String templateName;
  final String savedAt;
  late final String? filePath; // Made nullable because drafts don't have PDFs yet
  final bool isDraft; // Flag to identify drafts

  // The raw data needed to resume editing
  final PersonalInfo personalInfo;
  final List<WorkExperience> workExperiences;
  final List<Education> educations;
  final List<Project> projects;
  final List<Certification> certifications;
  final List<Skill> skills;
  final List<String> languages;
  final int templateIndex;

  SavedCV({
    required this.id,
    required this.name,
    required this.templateName,
    required this.savedAt,
    this.filePath,
    this.isDraft = false,
    required this.personalInfo,
    required this.workExperiences,
    required this.educations,
    required this.projects,
    required this.certifications,
    required this.skills,
    required this.languages,
    required this.templateIndex,
  });
}

/// CV Template model
class CVTemplate {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;

  const CVTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
    required this.icon,
  });
}

// =============================================================================
// SECTION 3 — CV PROVIDER (STATE MANAGEMENT)
// =============================================================================

class CVProvider extends ChangeNotifier {
  // Form data
  PersonalInfo _personalInfo = PersonalInfo();
  List<WorkExperience> _workExperiences = [];
  List<Education> _educations = [];
  List<Project> _projects = [];
  List<Certification> _certifications = [];
  List<Skill> _skills = [];
  List<String> _languages = [];

  // Selected template index (0-4)
  int _selectedTemplateIndex = 0;

  // Current form step
  int _currentStep = 0;

  // Saved CVs list
  List<SavedCV> _savedCVs = [];

  // Dark mode for preview
  bool _previewDarkMode = false;

  // Getters
  PersonalInfo get personalInfo => _personalInfo;
  List<WorkExperience> get workExperiences => _workExperiences;
  List<Education> get educations => _educations;
  List<Project> get projects => _projects;
  List<Certification> get certifications => _certifications;
  List<Skill> get skills => _skills;
  List<String> get languages => _languages;
  int get selectedTemplateIndex => _selectedTemplateIndex;
  int get currentStep => _currentStep;
  List<SavedCV> get savedCVs => _savedCVs;
  bool get previewDarkMode => _previewDarkMode;

  CVTemplate get selectedTemplate => AppConstants.templates[_selectedTemplateIndex];

  // --- Personal Info ---
  void updatePersonalInfo(PersonalInfo info) {
    _personalInfo = info;
    notifyListeners();
  }

  // --- Work Experience ---
  void addWorkExperience() {
    _workExperiences.add(WorkExperience());
    notifyListeners();
  }

  void updateWorkExperience(int index, WorkExperience exp) {
    _workExperiences[index] = exp;
    notifyListeners();
  }

  void removeWorkExperience(int index) {
    _workExperiences.removeAt(index);
    notifyListeners();
  }

  // --- Education ---
  void addEducation() {
    _educations.add(Education());
    notifyListeners();
  }

  void updateEducation(int index, Education edu) {
    _educations[index] = edu;
    notifyListeners();
  }

  void removeEducation(int index) {
    _educations.removeAt(index);
    notifyListeners();
  }

  // --- Projects ---
  void addProject() {
    _projects.add(Project());
    notifyListeners();
  }

  void updateProject(int index, Project proj) {
    _projects[index] = proj;
    notifyListeners();
  }

  void removeProject(int index) {
    _projects.removeAt(index);
    notifyListeners();
  }

  // --- Certifications ---
  void addCertification() {
    _certifications.add(Certification());
    notifyListeners();
  }

  void updateCertification(int index, Certification cert) {
    _certifications[index] = cert;
    notifyListeners();
  }

  void removeCertification(int index) {
    _certifications.removeAt(index);
    notifyListeners();
  }

  // --- Skills ---
  void addSkill() {
    _skills.add(Skill());
    notifyListeners();
  }

  void updateSkill(int index, Skill skill) {
    _skills[index] = skill;
    notifyListeners();
  }

  void removeSkill(int index) {
    _skills.removeAt(index);
    notifyListeners();
  }

  // --- Languages ---
  void addLanguage(String lang) {
    if (lang.isNotEmpty) _languages.add(lang);
    notifyListeners();
  }

  void removeLanguage(int index) {
    _languages.removeAt(index);
    notifyListeners();
  }

  // --- Template ---
  void selectTemplate(int index) {
    _selectedTemplateIndex = index;
    notifyListeners();
  }

  // --- Step ---
  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  // --- Preview Theme ---
  void togglePreviewDarkMode() {
    _previewDarkMode = !_previewDarkMode;
    notifyListeners();
  }

  // --- Saved CVs ---
  void addSavedCV(SavedCV cv) {
    _savedCVs.insert(0, cv);
    notifyListeners();
  }

  void removeSavedCV(String id) {
    _savedCVs.removeWhere((cv) => cv.id == id);
    notifyListeners();
  }
  /// Saves the current progress as a draft
  void saveDraft() {
    final dt = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';

    final draft = SavedCV(
      id: dt.millisecondsSinceEpoch.toString(),
      name: _personalInfo.fullName.isNotEmpty ? '${_personalInfo.fullName} (Draft)' : 'Untitled Draft',
      templateName: AppConstants.templates[_selectedTemplateIndex].name,
      savedAt: dateStr,
      filePath: null, // No PDF generated yet
      isDraft: true,
      // Deep copy all data to prevent the active form from altering the saved draft
      personalInfo: _personalInfo.copyWith(),
      workExperiences: _workExperiences.map((e) => e.copy()).toList(),
      educations: _educations.map((e) => e.copy()).toList(),
      projects: _projects.map((e) => e.copy()).toList(),
      certifications: _certifications.map((e) => e.copy()).toList(),
      skills: _skills.map((e) => e.copy()).toList(),
      languages: List.from(_languages),
      templateIndex: _selectedTemplateIndex,
    );

    addSavedCV(draft);
  }

  /// Loads a saved CV (draft or generated) back into the active form for editing
  void loadCV(SavedCV cv) {
    _personalInfo = cv.personalInfo.copyWith();
    _workExperiences = cv.workExperiences.map((e) => e.copy()).toList();
    _educations = cv.educations.map((e) => e.copy()).toList();
    _projects = cv.projects.map((e) => e.copy()).toList();
    _certifications = cv.certifications.map((e) => e.copy()).toList();
    _skills = cv.skills.map((e) => e.copy()).toList();
    _languages = List.from(cv.languages);
    _selectedTemplateIndex = cv.templateIndex;
    _currentStep = 0;
    notifyListeners();
  }

  /// Reset all form data for a fresh CV
  void resetForm() {
    _personalInfo = PersonalInfo();
    _workExperiences = [];
    _educations = [];
    _projects = [];
    _certifications = [];
    _skills = [];
    _languages = [];
    _selectedTemplateIndex = 0;
    _currentStep = 0;
    notifyListeners();
  }
  /// Exports all current data to a JSON string
  String exportToJson() {
    final data = {
      'personalInfo': _personalInfo.toJson(),
      'workExperiences': _workExperiences.map((e) => e.toJson()).toList(),
      'educations': _educations.map((e) => e.toJson()).toList(),
      'projects': _projects.map((e) => e.toJson()).toList(),
      'certifications': _certifications.map((e) => e.toJson()).toList(),
      'skills': _skills.map((e) => e.toJson()).toList(),
      'languages': _languages,
      'templateIndex': _selectedTemplateIndex,
    };
    return jsonEncode(data);
  }

  /// Imports data from a JSON string and updates the form
  void importFromJson(String jsonString) {
    final data = jsonDecode(jsonString);
    _personalInfo = PersonalInfo.fromJson(data['personalInfo'] ?? {});

    _workExperiences = (data['workExperiences'] as List?)
        ?.map((e) => WorkExperience.fromJson(e))
        .toList() ?? [];

    _educations = (data['educations'] as List?)
        ?.map((e) => Education.fromJson(e))
        .toList() ?? [];

    _projects = (data['projects'] as List?)
        ?.map((e) => Project.fromJson(e))
        .toList() ?? [];

    _certifications = (data['certifications'] as List?)
        ?.map((e) => Certification.fromJson(e))
        .toList() ?? [];

    _skills = (data['skills'] as List?)
        ?.map((e) => Skill.fromJson(e))
        .toList() ?? [];

    _languages = List<String>.from(data['languages'] ?? []);
    _selectedTemplateIndex = data['templateIndex'] ?? 0;
    _currentStep = 0;

    notifyListeners();
  }

}

// =============================================================================
// SECTION 4 — APP CONSTANTS & THEME
// =============================================================================

class AppConstants {
  static const String appName = 'EzzeCV';
  static const String appTagline = 'Build Your Career Story';

  /// The 5 built-in CV templates
  static const List<CVTemplate> templates = [
    CVTemplate(
      id: 'classic_ats',
      name: 'Executive ATS', // Harvard-style, strict B&W
      description: 'Strictly black & white, highly optimized for corporate ATS.',
      primaryColor: Color(0xFF212121), // Charcoal
      accentColor: Color(0xFF424242),
      icon: Icons.article_outlined,
    ),
    CVTemplate(
      id: 'modern_clean',
      name: 'Corporate Modern', // Light gray sidebar, dark text
      description: 'Clean two-column layout with elegant typography.',
      primaryColor: Color(0xFF2C3E50), // Navy/Slate
      accentColor: Color(0xFF34495E),
      icon: Icons.view_sidebar_outlined,
    ),
    CVTemplate(
      id: 'student_fresher',
      name: 'Academic Standard', // Clean navy accents, education first
      description: 'Structured hierarchy ideal for graduates and academia.',
      primaryColor: Color(0xFF1B365D), // Classic Oxford Blue
      accentColor: Color(0xFF335280),
      icon: Icons.school_outlined,
    ),
    CVTemplate(
      id: 'hybrid',
      name: 'Tech Minimalist', // Clean matrix, dark gray
      description: 'Grid-based layout emphasizing technical skills.',
      primaryColor: Color(0xFF37474F), // Blue Grey
      accentColor: Color(0xFF546E7A),
      icon: Icons.grid_view_rounded,
    ),
    CVTemplate(
      id: 'one_page',
      name: 'Managerial Compact', // Dense but readable, steel blue
      description: 'Space-efficient executive layout.',
      primaryColor: Color(0xFF455A64), // Steel
      accentColor: Color(0xFF607D8B),
      icon: Icons.view_agenda_outlined,
    ),
  ];

  // Form steps
  static const List<String> formSteps = [
    'Personal Info',
    'Experience',
    'Education',
    'Skills',
    'Projects',
    'Certifications',
  ];
}

class AppTheme {
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color accentGold = Color(0xFFFFC107);
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color dividerColor = Color(0xFFE9ECEF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// =============================================================================
// SECTION 5 — ROOT APP WIDGET
// =============================================================================

class EzzeCVApp extends StatelessWidget {
  const EzzeCVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}

// =============================================================================
// SECTION 6 — HOME SCREEN
// =============================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedCVs = context.watch<CVProvider>().savedCVs;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Hero Header ----
            _buildHeader(context),

            // ---- Main Content ----
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildQuickActions(context),
                      const SizedBox(height: 32),
                      _buildTemplatesPreview(context),
                      const SizedBox(height: 32),
                      if (savedCVs.isNotEmpty) ...[
                        _buildSavedCVsSection(context, savedCVs),
                        const SizedBox(height: 24),
                      ],
                      _buildTipsCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded,
                        color: AppTheme.primaryDark, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'EzzeCV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () async {
                  try {
                    // 1. Open File Picker restricted to .json files
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );

                    if (result != null && result.files.single.path != null) {
                      // 2. Read the file
                      File file = File(result.files.single.path!);
                      String jsonString = await file.readAsString();

                      // 3. Load it into the Provider
                      if (context.mounted) {
                        context.read<CVProvider>().importFromJson(jsonString);

                        // 4. Navigate straight to the Form to edit
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FormScreen()),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CV Imported Successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to import file. Make sure it is a valid EzzeCV .json backup.'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.file_upload_outlined, color: Colors.white70),
                tooltip: 'Import CV (.json)',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Build Your Career Story',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create professional CVs with ATS-friendly templates — 100% offline.',
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Get Started',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.add_circle_outline_rounded,
                label: 'Create New CV',
                color: AppTheme.primaryBlue,
                onTap: () {
                  context.read<CVProvider>().resetForm();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FormScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.folder_open_rounded,
                label: 'Saved CVs',
                color: const Color(0xFF00695C),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedCVsScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplatesPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Templates',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            TextButton(
              onPressed: () {
                context.read<CVProvider>().resetForm();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TemplateSelectionScreen()),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final template = AppConstants.templates[index];
              return _MiniTemplateCard(template: template, index: index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedCVsSection(BuildContext context, List<SavedCV> savedCVs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent CVs',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ...savedCVs.take(3).map((cv) => _SavedCVTile(cv: cv)),
      ],
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: Color(0xFFF57F17), size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro Tip',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF57F17),
                        fontSize: 13)),
                SizedBox(height: 3),
                Text(
                  'Use the Classic ATS template when applying to large companies — it ensures your CV passes automated screening systems.',
                  style: TextStyle(
                      color: Color(0xFF795548),
                      fontSize: 12,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _MiniTemplateCard extends StatelessWidget {
  final CVTemplate template;
  final int index;

  const _MiniTemplateCard({required this.template, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<CVProvider>()
          ..resetForm()
          ..selectTemplate(index);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: template.primaryColor.withOpacity(0.3)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: template.primaryColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: template.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
              Icon(template.icon, color: template.primaryColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              template.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: template.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCVTile extends StatelessWidget {
  final SavedCV cv;
  const _SavedCVTile({required this.cv});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue,
          // Show a different icon if it's a draft
          child: Icon(cv.isDraft ? Icons.edit_document : Icons.description, color: Colors.white, size: 20),
        ),
        title: Text(cv.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          cv.isDraft
              ? 'Draft-${cv.savedAt}'
              : '${cv.templateName}-${cv.savedAt}',
          style: TextStyle(
            fontSize: 12,
            color: cv.isDraft ? AppTheme.accentGold : AppTheme.textSecondary,
            fontWeight: cv.isDraft ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: cv.filePath != null
        // If it has a PDF file, show the Share button
            ? IconButton(
          icon: const Icon(Icons.share_outlined, size: 20),
          onPressed: () async {
            // The exclamation mark (!) tells Dart we know it's not null here
            final file = File(cv.filePath!);
            if (await file.exists()) {
              await Printing.sharePdf(bytes: await file.readAsBytes(), filename: '${cv.name}.pdf');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File not found on device')),
              );
            }
          },
        )
        // If it's a draft (no PDF), show a quick Edit button instead
            : IconButton(
          icon: const Icon(Icons.edit, size: 20, color: AppTheme.primaryBlue),
          tooltip: 'Resume Editing',
          onPressed: () {
            context.read<CVProvider>().loadCV(cv);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen()));
          },
        ),
      ),
    );
  }
}

// =============================================================================
// SECTION 7 — MULTI-STEP FORM SCREEN
// =============================================================================

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final provider = context.read<CVProvider>();
    if (provider.currentStep < AppConstants.formSteps.length - 1) {
      provider.setStep(provider.currentStep + 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Go to template selection
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TemplateSelectionScreen()),
      );
    }
  }

  void _prevStep() {
    final provider = context.read<CVProvider>();
    if (provider.currentStep > 0) {
      provider.setStep(provider.currentStep - 1);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final step = provider.currentStep;
    final totalSteps = AppConstants.formSteps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Your CV'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: _prevStep,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemplateSelectionScreen()),
            ),
            child: const Text('Skip to Templates',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          _StepProgressBar(current: step, total: totalSteps),

          // Step Label
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Step ${step + 1} of $totalSteps',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppConstants.formSteps[step],
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),

          // Form Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                PersonalInfoStep(),
                WorkExperienceStep(),
                EducationStep(),
                SkillsStep(),
                ProjectsStep(),
                CertificationsStep(),
              ],
            ),
          ),

          // Navigation Buttons
          _FormNavBar(
            onBack: _prevStep,
            onNext: _nextStep,
            isLastStep: step == totalSteps - 1,
            isFirstStep: step == 0,
          ),
        ],
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _StepProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(total, (index) {
          final isCompleted = index < current;
          final isCurrent = index == current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppTheme.primaryBlue
                          : AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < total - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _FormNavBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isLastStep;
  final bool isFirstStep;

  const _FormNavBar({
    required this.onBack,
    required this.onNext,
    required this.isLastStep,
    required this.isFirstStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          if (!isFirstStep)
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onNext,
            icon: Icon(
                isLastStep ? Icons.palette_outlined : Icons.arrow_forward,
                size: 18),
            label: Text(isLastStep ? 'Choose Template' : 'Continue'),
          ),
        ],
      ),
    );
  }
}

// ---- STEP 1: Personal Info ----
class PersonalInfoStep extends StatefulWidget {
  const PersonalInfoStep({super.key});

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  late PersonalInfo _info;

  @override
  void initState() {
    super.initState();
    _info = context.read<CVProvider>().personalInfo;
  }

  void _update() {
    context.read<CVProvider>().updatePersonalInfo(_info);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            subtitle: 'Tell us about yourself',
          ),
          const SizedBox(height: 20),
          _FormField(
            label: 'Full Name *',
            hint: 'e.g. Sarah Johnson',
            initialValue: _info.fullName,
            onChanged: (v) {
              _info.fullName = v;
              _update();
            },
          ),
          _FormField(
            label: 'Job Title / Role *',
            hint: 'e.g. Senior Software Engineer',
            initialValue: _info.jobTitle,
            onChanged: (v) {
              _info.jobTitle = v;
              _update();
            },
          ),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Email *',
                  hint: 'email@example.com',
                  initialValue: _info.email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) {
                    _info.email = v;
                    _update();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  label: 'Phone',
                  hint: '+1 234 567 8900',
                  initialValue: _info.phone,
                  keyboardType: TextInputType.phone,
                  onChanged: (v) {
                    _info.phone = v;
                    _update();
                  },
                ),
              ),
            ],
          ),
          _FormField(
            label: 'Location',
            hint: 'City, Country',
            initialValue: _info.location,
            onChanged: (v) {
              _info.location = v;
              _update();
            },
          ),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'LinkedIn',
                  hint: 'linkedin.com/in/...',
                  initialValue: _info.linkedin,
                  onChanged: (v) {
                    _info.linkedin = v;
                    _update();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  label: 'Website / Portfolio',
                  hint: 'yourwebsite.com',
                  initialValue: _info.website,
                  onChanged: (v) {
                    _info.website = v;
                    _update();
                  },
                ),
              ),
            ],
          ),
          _FormField(
            label: 'Professional Summary',
            hint:
            'A brief 2-3 sentence overview of your professional background and key strengths...',
            initialValue: _info.summary,
            maxLines: 4,
            onChanged: (v) {
              _info.summary = v;
              _update();
            },
          ),
        ],
      ),
    );
  }
}

// ---- STEP 2: Work Experience ----
class WorkExperienceStep extends StatelessWidget {
  const WorkExperienceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final exps = provider.workExperiences;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SectionHeader(
            icon: Icons.work_outline_rounded,
            title: 'Work Experience',
            subtitle: 'Add your professional history',
          ),
          const SizedBox(height: 20),
          ...exps.asMap().entries.map(
                (entry) => _WorkExpCard(
              index: entry.key,
              experience: entry.value,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => provider.addWorkExperience(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Work Experience'),
          ),
          if (exps.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: _EmptyStateHint(
                icon: Icons.work_history_outlined,
                text: 'No experience added yet.\nTap the button above to add your work history.',
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkExpCard extends StatefulWidget {
  final int index;
  final WorkExperience experience;
  const _WorkExpCard({required this.index, required this.experience});

  @override
  State<_WorkExpCard> createState() => _WorkExpCardState();
}

class _WorkExpCardState extends State<_WorkExpCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final exp = widget.experience;

    return _CollapsibleCard(
      title: exp.company.isNotEmpty ? exp.company : 'New Experience',
      subtitle: exp.position,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      onDelete: () => context.read<CVProvider>().removeWorkExperience(widget.index),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Company',
                  hint: 'Company Name',
                  initialValue: exp.company,
                  onChanged: (v) {
                    exp.company = v;
                    context.read<CVProvider>().updateWorkExperience(widget.index, exp);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  label: 'Position',
                  hint: 'Your Job Title',
                  initialValue: exp.position,
                  onChanged: (v) {
                    exp.position = v;
                    context.read<CVProvider>().updateWorkExperience(widget.index, exp);
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Start Date',
                  hint: 'Jan 2022',
                  initialValue: exp.startDate,
                  onChanged: (v) {
                    exp.startDate = v;
                    context.read<CVProvider>().updateWorkExperience(widget.index, exp);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: exp.isCurrentJob
                    ? const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Present',
                      style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600)),
                )
                    : _FormField(
                  label: 'End Date',
                  hint: 'Dec 2023',
                  initialValue: exp.endDate,
                  onChanged: (v) {
                    exp.endDate = v;
                    context.read<CVProvider>().updateWorkExperience(widget.index, exp);
                  },
                ),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Current Job',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            value: exp.isCurrentJob,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) {
              exp.isCurrentJob = v;
              context.read<CVProvider>().updateWorkExperience(widget.index, exp);
            },
          ),
          _FormField(
            label: 'Key Responsibilities & Achievements',
            hint: '- Led a team of 5 engineers\n- Increased performance by 40%\n- Launched 3 major features',
            initialValue: exp.description,
            maxLines: 4,
            onChanged: (v) {
              exp.description = v;
              context.read<CVProvider>().updateWorkExperience(widget.index, exp);
            },
          ),
        ],
      ),
    );
  }
}

// ---- STEP 3: Education ----
class EducationStep extends StatelessWidget {
  const EducationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final edus = provider.educations;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SectionHeader(
            icon: Icons.school_outlined,
            title: 'Education',
            subtitle: 'Add your academic background',
          ),
          const SizedBox(height: 20),
          ...edus.asMap().entries.map(
                (e) => _EducationCard(index: e.key, education: e.value),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => provider.addEducation(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Education'),
          ),
          if (edus.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: _EmptyStateHint(
                icon: Icons.school_outlined,
                text: 'No education added yet.\nTap the button above to add your qualifications.',
              ),
            ),
        ],
      ),
    );
  }
}

class _EducationCard extends StatefulWidget {
  final int index;
  final Education education;
  const _EducationCard({required this.index, required this.education});

  @override
  State<_EducationCard> createState() => _EducationCardState();
}

class _EducationCardState extends State<_EducationCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final edu = widget.education;

    return _CollapsibleCard(
      title: edu.institution.isNotEmpty ? edu.institution : 'New Education',
      subtitle: edu.degree,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      onDelete: () => context.read<CVProvider>().removeEducation(widget.index),
      child: Column(
        children: [
          _FormField(
            label: 'Institution',
            hint: 'University / College Name',
            initialValue: edu.institution,
            onChanged: (v) {
              edu.institution = v;
              context.read<CVProvider>().updateEducation(widget.index, edu);
            },
          ),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Degree',
                  hint: 'B.Sc. / M.Sc. / MBA',
                  initialValue: edu.degree,
                  onChanged: (v) {
                    edu.degree = v;
                    context.read<CVProvider>().updateEducation(widget.index, edu);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  label: 'Field of Study',
                  hint: 'Computer Science',
                  initialValue: edu.field,
                  onChanged: (v) {
                    edu.field = v;
                    context.read<CVProvider>().updateEducation(widget.index, edu);
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Start Year',
                  hint: '2018',
                  initialValue: edu.startYear,
                  onChanged: (v) {
                    edu.startYear = v;
                    context.read<CVProvider>().updateEducation(widget.index, edu);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  label: 'End Year',
                  hint: '2022',
                  initialValue: edu.endYear,
                  onChanged: (v) {
                    edu.endYear = v;
                    context.read<CVProvider>().updateEducation(widget.index, edu);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  label: 'Grade / GPA',
                  hint: '3.8 / 4.0',
                  initialValue: edu.grade,
                  onChanged: (v) {
                    edu.grade = v;
                    context.read<CVProvider>().updateEducation(widget.index, edu);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- STEP 4: Skills ----
class SkillsStep extends StatefulWidget {
  const SkillsStep({super.key});

  @override
  State<SkillsStep> createState() => _SkillsStepState();
}

class _SkillsStepState extends State<SkillsStep> {
  final _langController = TextEditingController();

  @override
  void dispose() {
    _langController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.psychology_outlined,
            title: 'Skills & Languages',
            subtitle: 'Highlight your expertise',
          ),
          const SizedBox(height: 20),

          // Skills
          const Text('Technical & Soft Skills',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          ...provider.skills.asMap().entries.map(
                (e) => _SkillRow(index: e.key, skill: e.value),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => provider.addSkill(),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Add Skill'),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Languages
          const Text('Languages',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...provider.languages.asMap().entries.map(
                    (e) => Chip(
                  label: Text(e.value),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => provider.removeLanguage(e.key),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _langController,
                  decoration: const InputDecoration(
                    labelText: 'Add Language',
                    hintText: 'e.g. Spanish (Fluent)',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  provider.addLanguage(_langController.text.trim());
                  _langController.clear();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatefulWidget {
  final int index;
  final Skill skill;

  const _SkillRow({required this.index, required this.skill});

  @override
  State<_SkillRow> createState() => _SkillRowState();
}

class _SkillRowState extends State<_SkillRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller only once
    _controller = TextEditingController(text: widget.skill.name);
  }

  @override
  void dispose() {
    // Always dispose controllers to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _controller, // Use the stateful controller here
              decoration: const InputDecoration(
                hintText: 'Skill name (e.g. Python)',
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (v) {
                widget.skill.name = v;
                context.read<CVProvider>().updateSkill(widget.index, widget.skill);
              },
            ),
          ),
          const SizedBox(width: 10),
          // Skill level 1-5
          Row(
            children: List.generate(5, (i) {
              final filled = i < widget.skill.level;
              return GestureDetector(
                onTap: () {
                  widget.skill.level = i + 1;
                  context.read<CVProvider>().updateSkill(widget.index, widget.skill);
                },
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppTheme.primaryBlue : AppTheme.dividerColor,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => context.read<CVProvider>().removeSkill(widget.index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}

// ---- STEP 5: Projects ----
class ProjectsStep extends StatelessWidget {
  const ProjectsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final projects = provider.projects;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SectionHeader(
            icon: Icons.code_rounded,
            title: 'Projects',
            subtitle: 'Showcase your work',
          ),
          const SizedBox(height: 20),
          ...projects.asMap().entries.map(
                (e) => _ProjectCard(index: e.key, project: e.value),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => provider.addProject(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Project'),
          ),
          if (projects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: _EmptyStateHint(
                icon: Icons.rocket_launch_outlined,
                text: 'No projects added yet.\nShowcase your personal or professional projects here.',
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final int index;
  final Project project;
  const _ProjectCard({required this.index, required this.project});

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final proj = widget.project;

    return _CollapsibleCard(
      title: proj.name.isNotEmpty ? proj.name : 'New Project',
      subtitle: proj.technologies,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      onDelete: () => context.read<CVProvider>().removeProject(widget.index),
      child: Column(
        children: [
          _FormField(
            label: 'Project Name',
            hint: 'e.g. E-Commerce Platform',
            initialValue: proj.name,
            onChanged: (v) {
              proj.name = v;
              context.read<CVProvider>().updateProject(widget.index, proj);
            },
          ),
          _FormField(
            label: 'Technologies Used',
            hint: 'Flutter, Firebase, Node.js',
            initialValue: proj.technologies,
            onChanged: (v) {
              proj.technologies = v;
              context.read<CVProvider>().updateProject(widget.index, proj);
            },
          ),
          _FormField(
            label: 'Project Link (optional)',
            hint: 'github.com/username/project',
            initialValue: proj.link,
            onChanged: (v) {
              proj.link = v;
              context.read<CVProvider>().updateProject(widget.index, proj);
            },
          ),
          _FormField(
            label: 'Description',
            hint: 'Briefly describe the project, your role, and impact...',
            initialValue: proj.description,
            maxLines: 3,
            onChanged: (v) {
              proj.description = v;
              context.read<CVProvider>().updateProject(widget.index, proj);
            },
          ),
        ],
      ),
    );
  }
}

// ---- STEP 6: Certifications ----
class CertificationsStep extends StatelessWidget {
  const CertificationsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final certs = provider.certifications;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SectionHeader(
            icon: Icons.verified_outlined,
            title: 'Certifications',
            subtitle: 'Add your credentials and achievements',
          ),
          const SizedBox(height: 20),
          ...certs.asMap().entries.map(
                (e) => _CertCard(index: e.key, cert: e.value),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => provider.addCertification(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Certification'),
          ),
          if (certs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: _EmptyStateHint(
                icon: Icons.military_tech_outlined,
                text: 'No certifications added yet.\nAdd your professional certifications and credentials.',
              ),
            ),
        ],
      ),
    );
  }
}

class _CertCard extends StatelessWidget {
  final int index;
  final Certification cert;
  const _CertCard({required this.index, required this.cert});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    label: 'Certification Name',
                    hint: 'AWS Certified Developer',
                    initialValue: cert.name,
                    onChanged: (v) {
                      cert.name = v;
                      context.read<CVProvider>().updateCertification(index, cert);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: _FormField(
                    label: 'Year',
                    hint: '2023',
                    initialValue: cert.year,
                    onChanged: (v) {
                      cert.year = v;
                      context.read<CVProvider>().updateCertification(index, cert);
                    },
                  ),
                ),
              ],
            ),
            _FormField(
              label: 'Issuing Organisation',
              hint: 'Amazon Web Services',
              initialValue: cert.issuer,
              onChanged: (v) {
                cert.issuer = v;
                context.read<CVProvider>().updateCertification(index, cert);
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.read<CVProvider>().removeCertification(index),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SECTION 8 — TEMPLATE SELECTION SCREEN
// =============================================================================

class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final selected = provider.selectedTemplateIndex;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Template')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Text(
              'Select a template that best fits your profile. You can change it anytime.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: AppConstants.templates.length,
              itemBuilder: (context, index) {
                final template = AppConstants.templates[index];
                final isSelected = index == selected;

                return GestureDetector(
                  onTap: () => provider.selectTemplate(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? template.primaryColor
                            : AppTheme.dividerColor,
                        width: isSelected ? 2.5 : 1,
                      ),
                      color: isSelected
                          ? template.primaryColor.withOpacity(0.04)
                          : Colors.white,
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: template.primaryColor.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                          : [
                        const BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 72,
                            decoration: BoxDecoration(
                              color: template.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(template.icon,
                                    color: Colors.white, size: 24),
                                const SizedBox(height: 4),
                                Container(
                                    height: 2,
                                    width: 30,
                                    color: Colors.white54),
                                const SizedBox(height: 3),
                                Container(
                                    height: 2,
                                    width: 24,
                                    color: Colors.white38),
                                const SizedBox(height: 3),
                                Container(
                                    height: 2,
                                    width: 28,
                                    color: Colors.white38),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // ---- ADD FLEXIBLE HERE ----
                                    Flexible(
                                      child: Text(
                                        template.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: isSelected
                                              ? template.primaryColor
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    // ---------------------------
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: template.primaryColor,
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                        child: const Text('Selected',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  template.description,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? template.primaryColor
                                : AppTheme.dividerColor,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CVPreviewScreen()),
                ),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Preview CV'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 9 — CV PREVIEW SCREEN
// =============================================================================

class CVPreviewScreen extends StatefulWidget {
  const CVPreviewScreen({super.key});

  @override
  State<CVPreviewScreen> createState() => _CVPreviewScreenState();
}

class _CVPreviewScreenState extends State<CVPreviewScreen> {
  // We will store the generated PDF bytes here
  late Future<Uint8List> _pdfBytesFuture;

  @override
  void initState() {
    super.initState();
    // 1. Grab the provider data ONCE when the screen first loads
    final provider = context.read<CVProvider>();

    // 2. Start building the PDF immediately and save the Future
    _pdfBytesFuture = _buildPDF(provider);
  }

  @override
  Widget build(BuildContext context) {
    // We still watch the provider for the UI (like the AppBar title)
    final provider = context.watch<CVProvider>();
    final template = provider.selectedTemplate;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
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
          // Top action hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: template.primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: template.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is the actual A4 PDF rendering. Zoom and pan to review.',
                    style: TextStyle(
                        fontSize: 12, color: template.primaryColor),
                  ),
                ),
              ],
            ),
          ),

          // ---- REAL PDF PREVIEW ----
          Expanded(
            child: PdfPreview(
              // 3. Hand it the CACHED future, so it never rebuilds the PDF on scroll!
              build: (format) => _pdfBytesFuture,
              useActions: false,
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              maxPageWidth: 700,
              scrollViewDecoration: const BoxDecoration(
                color: Color(0xFFE8EAED),
              ),
            ),
          ),

          // Bottom Action Bar
          _PreviewActionBar(provider: provider),
        ],
      ),
    );
  }
}

/// Renders the actual CV preview matching the selected template
class _CVPreviewWidget extends StatelessWidget {
  final CVProvider provider;
  final bool isDark;

  const _CVPreviewWidget({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final templateId = provider.selectedTemplate.id;
    switch (templateId) {
      case 'classic_ats':
        return _ClassicATSPreview(provider: provider, isDark: isDark);
      case 'modern_clean':
        return _ModernCleanPreview(provider: provider, isDark: isDark);
      case 'student_fresher':
        return _StudentFresherPreview(provider: provider, isDark: isDark);
      case 'hybrid':
        return _HybridPreview(provider: provider, isDark: isDark);
      case 'one_page':
        return _OnePageCompactPreview(provider: provider, isDark: isDark);
      default:
        return _ClassicATSPreview(provider: provider, isDark: isDark);
    }
  }
}

// ---- Template Preview Widgets ----

/// Classic ATS: Simple single-column, black & white, highly ATS-friendly
class _ClassicATSPreview extends StatelessWidget {
  final CVProvider provider;
  final bool isDark;
  const _ClassicATSPreview({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final info = provider.personalInfo;
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final borderColor = isDark ? Colors.white24 : const Color(0xFF1A237E);
    final subColor = isDark ? Colors.white60 : const Color(0xFF3F51B5);

    return Container(
      padding: const EdgeInsets.all(28),
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  info.fullName.isNotEmpty ? info.fullName : 'Your Full Name',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  info.jobTitle.isNotEmpty ? info.jobTitle : 'Your Professional Title',
                  style: TextStyle(fontSize: 14, color: subColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    if (info.email.isNotEmpty) _ContactChip(text: info.email, isDark: isDark),
                    if (info.phone.isNotEmpty) _ContactChip(text: info.phone, isDark: isDark),
                    if (info.location.isNotEmpty) _ContactChip(text: info.location, isDark: isDark),
                    if (info.linkedin.isNotEmpty) _ContactChip(text: info.linkedin, isDark: isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor, thickness: 2),
          const SizedBox(height: 12),

          if (info.summary.isNotEmpty) ...[
            _PreviewSectionTitle(title: 'PROFESSIONAL SUMMARY', color: borderColor),
            const SizedBox(height: 8),
            Text(info.summary, style: TextStyle(fontSize: 12, color: textColor, height: 1.5)),
            const SizedBox(height: 16),
          ],

          if (provider.workExperiences.isNotEmpty) ...[
            _PreviewSectionTitle(title: 'WORK EXPERIENCE', color: borderColor),
            ...provider.workExperiences.map((exp) => _ClassicExpEntry(exp: exp, textColor: textColor, subColor: subColor)),
          ],

          if (provider.educations.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PreviewSectionTitle(title: 'EDUCATION', color: borderColor),
            ...provider.educations.map((edu) => _ClassicEduEntry(edu: edu, textColor: textColor, subColor: subColor)),
          ],

          if (provider.skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PreviewSectionTitle(title: 'SKILLS', color: borderColor),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: provider.skills.map((s) => _SkillPill(skill: s, color: borderColor)).toList(),
            ),
          ],

          if (provider.certifications.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PreviewSectionTitle(title: 'CERTIFICATIONS', color: borderColor),
            ...provider.certifications.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(Icons.verified, size: 14, color: subColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${c.name}${c.issuer.isNotEmpty ? ' — ${c.issuer}' : ''}${c.year.isNotEmpty ? ' (${c.year})' : ''}',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ),
                ],
              ),
            )),
          ],

          if (provider.projects.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PreviewSectionTitle(title: 'PROJECTS', color: borderColor),
            ...provider.projects.map((p) => _ClassicProjectEntry(project: p, textColor: textColor, subColor: subColor)),
          ],
        ],
      ),
    );
  }
}

/// Modern Clean: Two-column sidebar layout
class _ModernCleanPreview extends StatelessWidget {
  final CVProvider provider;
  final bool isDark;
  const _ModernCleanPreview({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final info = provider.personalInfo;
    final sidebarColor = isDark ? const Color(0xFF004D40) : const Color(0xFF00695C);
    final bodyBg = isDark ? const Color(0xFF1B2621) : Colors.white;
    final bodyText = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar
        SizedBox(
          width: 160,
          child: Container(
            color: sidebarColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white24,
                    child: Text(
                      info.fullName.isNotEmpty
                          ? info.fullName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SidebarSection(title: 'CONTACT', color: Colors.white, children: [
                  if (info.email.isNotEmpty) _SidebarItem(text: info.email),
                  if (info.phone.isNotEmpty) _SidebarItem(text: info.phone),
                  if (info.location.isNotEmpty) _SidebarItem(text: info.location),
                  if (info.linkedin.isNotEmpty) _SidebarItem(text: info.linkedin),
                ]),
                if (provider.skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SidebarSection(title: 'SKILLS', color: Colors.white, children: [
                    ...provider.skills.map((s) => _SidebarSkillItem(skill: s)),
                  ]),
                ],
                if (provider.languages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SidebarSection(title: 'LANGUAGES', color: Colors.white, children: [
                    ...provider.languages.map((l) => _SidebarItem(text: l)),
                  ]),
                ],
                if (provider.certifications.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SidebarSection(title: 'CERTS', color: Colors.white, children: [
                    ...provider.certifications.map((c) => _SidebarItem(text: c.name)),
                  ]),
                ],
              ],
            ),
          ),
        ),
        // Main Body
        Expanded(
          child: Container(
            color: bodyBg,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.fullName.isNotEmpty ? info.fullName : 'Your Full Name',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: sidebarColor),
                ),
                Text(
                  info.jobTitle.isNotEmpty ? info.jobTitle : 'Your Title',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                if (info.summary.isNotEmpty) ...[
                  Text(info.summary,
                      style: TextStyle(
                          fontSize: 11, color: bodyText, height: 1.5)),
                  const SizedBox(height: 12),
                ],
                if (provider.workExperiences.isNotEmpty) ...[
                  _ModernSectionTitle(title: 'Experience', color: sidebarColor),
                  ...provider.workExperiences.map((exp) =>
                      _ClassicExpEntry(exp: exp, textColor: bodyText, subColor: sidebarColor)),
                ],
                if (provider.educations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ModernSectionTitle(title: 'Education', color: sidebarColor),
                  ...provider.educations.map((edu) =>
                      _ClassicEduEntry(edu: edu, textColor: bodyText, subColor: sidebarColor)),
                ],
                if (provider.projects.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ModernSectionTitle(title: 'Projects', color: sidebarColor),
                  ...provider.projects.map((p) =>
                      _ClassicProjectEntry(project: p, textColor: bodyText, subColor: sidebarColor)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Student/Fresher: Education first, colourful, highlights projects
class _StudentFresherPreview extends StatelessWidget {
  final CVProvider provider;
  final bool isDark;
  const _StudentFresherPreview({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final info = provider.personalInfo;
    final headerColor = isDark ? const Color(0xFF4A148C) : const Color(0xFF6A1B9A);
    final accentColor = isDark ? const Color(0xFFCE93D8) : const Color(0xFFAB47BC);
    final bg = isDark ? const Color(0xFF1C1B2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloured Header
          Container(
            color: headerColor,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.fullName.isNotEmpty ? info.fullName : 'Your Name',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  info.jobTitle.isNotEmpty
                      ? info.jobTitle
                      : 'Student / Graduate',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (info.email.isNotEmpty)
                      _WhiteChip(text: info.email, icon: Icons.email_outlined),
                    if (info.phone.isNotEmpty)
                      _WhiteChip(text: info.phone, icon: Icons.phone_outlined),
                    if (info.location.isNotEmpty)
                      _WhiteChip(text: info.location, icon: Icons.location_on_outlined),
                    if (info.linkedin.isNotEmpty)
                      _WhiteChip(text: info.linkedin, icon: Icons.link),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.summary.isNotEmpty) ...[
                  _ColorSectionTitle(title: 'ABOUT ME', color: accentColor),
                  const SizedBox(height: 6),
                  Text(info.summary,
                      style: TextStyle(fontSize: 12, color: textColor, height: 1.5)),
                  const SizedBox(height: 16),
                ],

                // Education First for Student
                if (provider.educations.isNotEmpty) ...[
                  _ColorSectionTitle(title: 'EDUCATION', color: accentColor),
                  ...provider.educations.map((edu) =>
                      _ClassicEduEntry(edu: edu, textColor: textColor, subColor: accentColor)),
                  const SizedBox(height: 16),
                ],

                if (provider.skills.isNotEmpty) ...[
                  _ColorSectionTitle(title: 'SKILLS', color: accentColor),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: provider.skills.map((s) => _SkillPill(skill: s, color: headerColor)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (provider.projects.isNotEmpty) ...[
                  _ColorSectionTitle(title: 'PROJECTS', color: accentColor),
                  ...provider.projects.map((p) =>
                      _ClassicProjectEntry(project: p, textColor: textColor, subColor: accentColor)),
                  const SizedBox(height: 16),
                ],

                if (provider.workExperiences.isNotEmpty) ...[
                  _ColorSectionTitle(title: 'EXPERIENCE', color: accentColor),
                  ...provider.workExperiences.map((exp) =>
                      _ClassicExpEntry(exp: exp, textColor: textColor, subColor: accentColor)),
                  const SizedBox(height: 16),
                ],

                if (provider.certifications.isNotEmpty) ...[
                  _ColorSectionTitle(title: 'CERTIFICATIONS', color: accentColor),
                  ...provider.certifications.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.verified, size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${c.name}${c.issuer.isNotEmpty ? ' — ${c.issuer}' : ''}${c.year.isNotEmpty ? ' (${c.year})' : ''}',
                            style: TextStyle(fontSize: 12, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hybrid Pro: Two columns, skills-first
class _HybridPreview extends StatelessWidget {
  final CVProvider provider;
  final bool isDark;
  const _HybridPreview({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final info = provider.personalInfo;
    final primary = isDark ? const Color(0xFFBF360C) : const Color(0xFFBF360C);
    final bg = isDark ? const Color(0xFF1C1A18) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? const Color(0xFFFFCC80) : const Color(0xFFEF6C00);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            color: primary,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.fullName.isNotEmpty ? info.fullName : 'Your Name',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                      Text(
                        info.jobTitle.isNotEmpty ? info.jobTitle : 'Your Title',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (info.email.isNotEmpty)
                      Text(info.email,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    if (info.phone.isNotEmpty)
                      Text(info.phone,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    if (info.location.isNotEmpty)
                      Text(info.location,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Skills + Certs
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider.skills.isNotEmpty) ...[
                        _HybridSectionTitle(title: 'SKILLS', color: subColor),
                        ...provider.skills.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: textColor,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              LinearProgressIndicator(
                                value: s.level / 5,
                                backgroundColor:
                                Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation(subColor),
                                minHeight: 3,
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        )),
                      ],
                      if (provider.languages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _HybridSectionTitle(title: 'LANGUAGES', color: subColor),
                        ...provider.languages.map((l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(l,
                              style: TextStyle(
                                  fontSize: 11, color: textColor)),
                        )),
                      ],
                      if (provider.certifications.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _HybridSectionTitle(title: 'CERTS', color: subColor),
                        ...provider.certifications.map((c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(c.name,
                              style: TextStyle(
                                  fontSize: 10, color: textColor)),
                        )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 1, color: Colors.grey.withOpacity(0.2)),
                const SizedBox(width: 16),
                // Right column: Experience + Education + Projects
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (info.summary.isNotEmpty) ...[
                        _HybridSectionTitle(title: 'PROFILE', color: subColor),
                        Text(info.summary,
                            style: TextStyle(
                                fontSize: 11, color: textColor, height: 1.5)),
                        const SizedBox(height: 12),
                      ],
                      if (provider.workExperiences.isNotEmpty) ...[
                        _HybridSectionTitle(title: 'EXPERIENCE', color: subColor),
                        ...provider.workExperiences.map((exp) =>
                            _ClassicExpEntry(exp: exp, textColor: textColor, subColor: subColor)),
                      ],
                      if (provider.educations.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _HybridSectionTitle(title: 'EDUCATION', color: subColor),
                        ...provider.educations.map((edu) =>
                            _ClassicEduEntry(edu: edu, textColor: textColor, subColor: subColor)),
                      ],
                      if (provider.projects.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _HybridSectionTitle(title: 'PROJECTS', color: subColor),
                        ...provider.projects.map((p) =>
                            _ClassicProjectEntry(project: p, textColor: textColor, subColor: subColor)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One-Page Compact: Dense layout, minimal spacing
class _OnePageCompactPreview extends StatelessWidget {
  final CVProvider provider;
  final bool isDark;
  const _OnePageCompactPreview({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final info = provider.personalInfo;
    final primary = isDark ? const Color(0xFF607D8B) : const Color(0xFF37474F);
    final bg = isDark ? const Color(0xFF1A1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? const Color(0xFF90A4AE) : const Color(0xFF78909C);

    return Container(
      color: bg,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.fullName.isNotEmpty ? info.fullName : 'Your Name',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: primary),
                    ),
                    Text(
                      info.jobTitle.isNotEmpty ? info.jobTitle : 'Professional Title',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (info.email.isNotEmpty)
                    Text(info.email, style: TextStyle(fontSize: 10, color: textColor)),
                  if (info.phone.isNotEmpty)
                    Text(info.phone, style: TextStyle(fontSize: 10, color: textColor)),
                  if (info.location.isNotEmpty)
                    Text(info.location, style: TextStyle(fontSize: 10, color: textColor)),
                  if (info.linkedin.isNotEmpty)
                    Text(info.linkedin, style: TextStyle(fontSize: 10, color: textColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: primary, thickness: 1.5),
          const SizedBox(height: 4),

          if (info.summary.isNotEmpty) ...[
            Text(info.summary,
                style: TextStyle(fontSize: 11, color: textColor, height: 1.4)),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.withOpacity(0.2)),
          ],

          // Two columns for compact layout
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider.workExperiences.isNotEmpty) ...[
                        _CompactSectionTitle(title: 'EXPERIENCE', color: primary),
                        ...provider.workExperiences.map((exp) => _CompactExpEntry(exp: exp, textColor: textColor, subColor: subColor)),
                      ],
                      if (provider.projects.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _CompactSectionTitle(title: 'PROJECTS', color: primary),
                        ...provider.projects.map((p) => _CompactProjectEntry(project: p, textColor: textColor, subColor: subColor)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right column
                SizedBox(
                  width: 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider.educations.isNotEmpty) ...[
                        _CompactSectionTitle(title: 'EDUCATION', color: primary),
                        ...provider.educations.map((edu) => _CompactEduEntry(edu: edu, textColor: textColor, subColor: subColor)),
                      ],
                      if (provider.skills.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _CompactSectionTitle(title: 'SKILLS', color: primary),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: provider.skills.take(12).map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(s.name,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: primary,
                                    fontWeight: FontWeight.w600)),
                          )).toList(),
                        ),
                      ],
                      if (provider.languages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _CompactSectionTitle(title: 'LANGUAGES', color: primary),
                        ...provider.languages.map((l) =>
                            Text(l, style: TextStyle(fontSize: 10, color: textColor))),
                      ],
                      if (provider.certifications.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _CompactSectionTitle(title: 'CERTS', color: primary),
                        ...provider.certifications.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(c.name,
                              style: TextStyle(fontSize: 10, color: textColor)),
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Shared Preview Widgets ----

class _ContactChip extends StatelessWidget {
  final String text;
  final bool isDark;
  const _ContactChip({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white60 : AppTheme.textSecondary),
    );
  }
}

class _WhiteChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _WhiteChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _PreviewSectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _PreviewSectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 1.2)),
        Container(height: 1.5, color: color, margin: const EdgeInsets.only(top: 2, bottom: 8)),
      ],
    );
  }
}

class _ModernSectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _ModernSectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color)),
    );
  }
}

class _ColorSectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _ColorSectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(title,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1)),
    );
  }
}

class _HybridSectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _HybridSectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1)),
    );
  }
}

class _CompactSectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _CompactSectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 1)),
        Container(
            height: 1, color: color.withOpacity(0.5), margin: const EdgeInsets.only(bottom: 4)),
      ],
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;
  const _SidebarSection(
      {required this.title, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String text;
  const _SidebarItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 10)),
    );
  }
}

class _SidebarSkillItem extends StatelessWidget {
  final Skill skill;
  const _SidebarSkillItem({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(skill.name,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: skill.level / 5,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 3,
          ),
        ],
      ),
    );
  }
}

class _SkillPill extends StatelessWidget {
  final Skill skill;
  final Color color;
  const _SkillPill({required this.skill, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(skill.name,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _ClassicExpEntry extends StatelessWidget {
  final WorkExperience exp;
  final Color textColor;
  final Color subColor;
  const _ClassicExpEntry(
      {required this.exp, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(exp.position,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              Text(
                '${exp.startDate}${exp.startDate.isNotEmpty ? ' — ' : ''}${exp.isCurrentJob ? 'Present' : exp.endDate}',
                style: TextStyle(fontSize: 10, color: subColor),
              ),
            ],
          ),
          Text(exp.company,
              style: TextStyle(
                  fontSize: 11, color: subColor, fontWeight: FontWeight.w600)),
          if (exp.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(exp.description,
                  style: TextStyle(fontSize: 11, color: textColor, height: 1.4)),
            ),
        ],
      ),
    );
  }
}

class _ClassicEduEntry extends StatelessWidget {
  final Education edu;
  final Color textColor;
  final Color subColor;
  const _ClassicEduEntry(
      {required this.edu, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${edu.degree}${edu.field.isNotEmpty ? ' in ${edu.field}' : ''}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor),
                ),
              ),
              Text(
                '${edu.startYear}${edu.startYear.isNotEmpty ? ' — ' : ''}${edu.endYear}',
                style: TextStyle(fontSize: 10, color: subColor),
              ),
            ],
          ),
          Text(edu.institution,
              style: TextStyle(
                  fontSize: 11, color: subColor, fontWeight: FontWeight.w600)),
          if (edu.grade.isNotEmpty)
            Text('Grade: ${edu.grade}',
                style: TextStyle(fontSize: 10, color: textColor)),
        ],
      ),
    );
  }
}

class _ClassicProjectEntry extends StatelessWidget {
  final Project project;
  final Color textColor;
  final Color subColor;
  const _ClassicProjectEntry(
      {required this.project, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.name,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          if (project.technologies.isNotEmpty)
            Text('Tech: ${project.technologies}',
                style: TextStyle(fontSize: 10, color: subColor, fontStyle: FontStyle.italic)),
          if (project.description.isNotEmpty)
            Text(project.description,
                style: TextStyle(fontSize: 11, color: textColor, height: 1.4)),
          if (project.link.isNotEmpty)
            Text(project.link,
                style: TextStyle(fontSize: 10, color: subColor)),
        ],
      ),
    );
  }
}

class _CompactExpEntry extends StatelessWidget {
  final WorkExperience exp;
  final Color textColor;
  final Color subColor;
  const _CompactExpEntry({required this.exp, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exp.position,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
          Text('${exp.company} | ${exp.startDate}-${exp.isCurrentJob ? 'Present' : exp.endDate}',
              style: TextStyle(fontSize: 10, color: subColor)),
          if (exp.description.isNotEmpty)
            Text(exp.description,
                style: TextStyle(fontSize: 10, color: textColor, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _CompactEduEntry extends StatelessWidget {
  final Education edu;
  final Color textColor;
  final Color subColor;
  const _CompactEduEntry({required this.edu, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(edu.degree, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
          Text(edu.institution, style: TextStyle(fontSize: 10, color: subColor)),
          Text('${edu.startYear}-${edu.endYear}', style: TextStyle(fontSize: 10, color: subColor)),
        ],
      ),
    );
  }
}

class _CompactProjectEntry extends StatelessWidget {
  final Project project;
  final Color textColor;
  final Color subColor;
  const _CompactProjectEntry({required this.project, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
          if (project.technologies.isNotEmpty)
            Text(project.technologies, style: TextStyle(fontSize: 10, color: subColor)),
          if (project.description.isNotEmpty)
            Text(project.description,
                style: TextStyle(fontSize: 10, color: textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: SafeArea(
        top: false, // Only protect the bottom from the home indicator
        child: Wrap(

          alignment: WrapAlignment.center, // Centers the buttons
          spacing: 12.0, // Horizontal gap between buttons
          runSpacing: 12.0, // Vertical gap if they wrap to the next line
          children: [
              // ---- NEW SAVE DRAFT BUTTON ----
              OutlinedButton.icon(
                onPressed: () {
                  provider.saveDraft();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved to drafts!')),
                  );
                  // Pop back to the Home Screen so they can see it in "Saved CVs"
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Draft'),
              ),
              ElevatedButton.icon(
                onPressed: () => _generateAndSavePDF(context, provider),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Generate PDF'),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SECTION 10 — PDF GENERATION (ULTIMATE PROFESSIONAL SUITE)
// =============================================================================

Future<void> _generateAndSavePDF(BuildContext context, CVProvider provider) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Rendering Professional PDF...'),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final Uint8List pdfBytes = await _buildPDF(provider);
    final name = provider.personalInfo.fullName.isNotEmpty
        ? provider.personalInfo.fullName.replaceAll(' ', '_')
        : 'EzzeCV';
    final fileName = '${name}_CV_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final jsonFileName = fileName.replaceAll('.pdf', '.json');
    final jsonString = provider.exportToJson();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    final internalJsonFile = File('${dir.path}/$jsonFileName');
    await internalJsonFile.writeAsString(jsonString);

    provider.addSavedCV(SavedCV(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: provider.personalInfo.fullName.isNotEmpty
          ? '${provider.personalInfo.fullName}\'s CV'
          : 'My CV',
      templateName: provider.selectedTemplate.name,
      savedAt: _formatDate(DateTime.now()),
      filePath: file.path,
      isDraft: false,
      personalInfo: provider.personalInfo.copyWith(),
      workExperiences: provider.workExperiences.map((e) => e.copy()).toList(),
      educations: provider.educations.map((e) => e.copy()).toList(),
      projects: provider.projects.map((e) => e.copy()).toList(),
      certifications: provider.certifications.map((e) => e.copy()).toList(),
      skills: provider.skills.map((e) => e.copy()).toList(),
      languages: List.from(provider.languages),
      templateIndex: provider.selectedTemplateIndex,
    ));

    if (context.mounted) Navigator.of(context).pop();

    if (context.mounted) {
      final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));
      String? resultPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CV Backup Data',
        fileName: jsonFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: jsonBytes,
      );

      if (resultPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON Backup saved successfully!'), backgroundColor: Colors.green),
        );
      }

      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

Future<Uint8List> _buildPDF(CVProvider provider) async {
  switch (provider.selectedTemplate.id) {
    case 'classic_ats': return _buildExecutiveATS(provider);
    case 'modern_clean': return _buildCorporateModern(provider);
    case 'student_fresher': return _buildAcademicStandard(provider);
    case 'hybrid': return _buildTechMinimalist(provider);
    case 'one_page': return _buildManagerialCompact(provider);
    default: return _buildExecutiveATS(provider);
  }
}

// ---- NATIVE SVG ICONS HELPER (100% Offline) ----
const _svgPhone = 'M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z';
const _svgMail = 'M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z';
const _svgLoc = 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z';
const _svgLink = 'M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z';
const _svgEdu = 'M12 3L1 9l11 6 9-4.91V17h2V9L12 3zm6.83 5.37L12 11.22 5.17 7.5 12 3.78l6.83 4.59zM12 17.5l-6-3.27V17l6 3.5 6-3.5v-2.77l-6 3.27z';
const _svgWork = 'M20 6h-4V4c0-1.11-.89-2-2-2h-4c-1.11 0-2 .89-2 2v2H4c-1.11 0-1.99.89-1.99 2L2 19c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V8c0-1.11-.89-2-2-2zm-6 0h-4V4h4v2z';

pw.Widget _drawIcon(String path, PdfColor color, {double size = 10}) {
  return pw.SvgImage(
    svg: '<svg viewBox="0 0 24 24"><path d="$path" fill="${color.toHex()}"/></svg>',
    width: size, height: size,
  );
}

// =============================================================================
// TEMPLATE 1: EXECUTIVE ATS (Harvard Standard)
// =============================================================================
Future<Uint8List> _buildExecutiveATS(CVProvider p) async {
  final pdf = pw.Document();
  final font = pw.Font.times();
  final fontBold = pw.Font.timesBold();
  final fontItalic = pw.Font.timesItalic();

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 54, vertical: 48),
    build: (ctx) => [
      pw.Center(
        child: pw.Column(
          children: [
            pw.Text(p.personalInfo.fullName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 18)),
            pw.SizedBox(height: 6),
            pw.Wrap(
              alignment: pw.WrapAlignment.center,
              spacing: 8, runSpacing: 4,
              children: [
                if (p.personalInfo.location.isNotEmpty)
                  pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                    _drawIcon(_svgLoc, PdfColors.grey800, size: 9),
                    pw.SizedBox(width: 4),
                    pw.Text(p.personalInfo.location, style: pw.TextStyle(font: font, fontSize: 10)),
                  ]),

                if (p.personalInfo.phone.isNotEmpty)
                  pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                    _drawIcon(_svgPhone, PdfColors.grey800, size: 9),
                    pw.SizedBox(width: 4),
                    pw.Text(p.personalInfo.phone, style: pw.TextStyle(font: font, fontSize: 10)),
                  ]),

                if (p.personalInfo.email.isNotEmpty)
                  pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                    _drawIcon(_svgMail, PdfColors.grey800, size: 9),
                    pw.SizedBox(width: 4),
                    pw.Text(p.personalInfo.email, style: pw.TextStyle(font: font, fontSize: 10)),
                  ]),

                if (p.personalInfo.linkedin.isNotEmpty)
                  pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                    _drawIcon(_svgLink, PdfColors.grey800, size: 9),
                    pw.SizedBox(width: 4),
                    pw.Text(p.personalInfo.linkedin, style: pw.TextStyle(font: font, fontSize: 10)),
                  ]),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 18),

      if (p.personalInfo.summary.isNotEmpty) ...[
        _atsHeader('SUMMARY', fontBold),
        pw.Text(p.personalInfo.summary, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 11, lineSpacing: 1.5)),
        pw.SizedBox(height: 16),
      ],

      if (p.workExperiences.isNotEmpty) ...[
        _atsHeader('PROFESSIONAL EXPERIENCE', fontBold),
        ...p.workExperiences.map((exp) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(exp.position, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                  pw.Text('${exp.startDate} - ${exp.isCurrentJob ? 'Present' : exp.endDate}', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(exp.company, style: pw.TextStyle(font: fontItalic, fontSize: 11)),
              pw.SizedBox(height: 6),
              if (exp.description.isNotEmpty)
                pw.Text(exp.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5)),
            ],
          ),
        )),
        pw.SizedBox(height: 6),
      ],

      if (p.educations.isNotEmpty) ...[
        _atsHeader('EDUCATION', fontBold),
        ...p.educations.map((edu) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(edu.institution, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    pw.SizedBox(height: 2),
                    pw.Text('${edu.degree}${edu.field.isNotEmpty ? ' in ${edu.field}' : ''}', style: pw.TextStyle(font: fontItalic, fontSize: 11)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('${edu.startYear} - ${edu.endYear}', style: pw.TextStyle(font: font, fontSize: 10)),
                  if (edu.grade.isNotEmpty) pw.Text('GPA: ${edu.grade}', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
            ],
          ),
        )),
        pw.SizedBox(height: 6),
      ],

      if (p.projects.isNotEmpty) ...[
        _atsHeader('PROJECTS', fontBold),
        ...p.projects.map((proj) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.RichText(text: pw.TextSpan(children: [
                pw.TextSpan(text: '${proj.name} ', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                if (proj.technologies.isNotEmpty) pw.TextSpan(text: '| ${proj.technologies}', style: pw.TextStyle(font: fontItalic, fontSize: 10)),
              ])),
              pw.SizedBox(height: 4),
              if (proj.description.isNotEmpty)
                pw.Text(proj.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5)),
            ],
          ),
        )),
        pw.SizedBox(height: 6),
      ],

      if (p.skills.isNotEmpty || p.languages.isNotEmpty) ...[
        _atsHeader('ADDITIONAL INFORMATION', fontBold),
        if (p.skills.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.RichText(text: pw.TextSpan(children: [
              pw.TextSpan(text: 'Technical Skills: ', style: pw.TextStyle(font: fontBold, fontSize: 11)),
              pw.TextSpan(text: p.skills.map((s) => s.name).join(', '), style: pw.TextStyle(font: font, fontSize: 11)),
            ])),
          ),
        if (p.languages.isNotEmpty)
          pw.RichText(text: pw.TextSpan(children: [
            pw.TextSpan(text: 'Languages: ', style: pw.TextStyle(font: fontBold, fontSize: 11)),
            pw.TextSpan(text: p.languages.join(', '), style: pw.TextStyle(font: font, fontSize: 11)),
          ])),
      ],
    ],
  ));
  return pdf.save();
}

pw.Widget _atsHeader(String title, pw.Font fontBold) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 12, letterSpacing: 0.5)),
    pw.Container(height: 1, color: PdfColors.black, margin: const pw.EdgeInsets.only(top: 4, bottom: 12)),
  ],
);

/// =============================================================================
// TEMPLATE 2: CORPORATE MODERN (Full Sidebar with Skill Meters)
// =============================================================================
Future<Uint8List> _buildCorporateModern(CVProvider p) async {
  final pdf = pw.Document();
  final font = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();
  const primaryText = PdfColor.fromInt(0xFF2C3E50);
  const secondaryText = PdfColor.fromInt(0xFF5D6D7E);
  const sidebarBg = PdfColor.fromInt(0xFFF4F6F7);
  const emptyDotColor = PdfColor.fromInt(0xFFD5DBDB); // Subtle light gray for empty dots

  pdf.addPage(pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      // Forces the sidebar background to seamlessly paint to the bottom of EVERY page
      buildBackground: (ctx) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Row(children: [
          pw.Container(width: 190, color: sidebarBg),
          pw.Expanded(child: pw.Container(color: PdfColors.white)),
        ]),
      ),
    ),
    build: (ctx) => [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Sidebar Content
          pw.Container(
            width: 200,
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CONTACT', style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryText, letterSpacing: 1.5)),
                pw.SizedBox(height: 16),
                if (p.personalInfo.email.isNotEmpty) _modContact(_svgMail, p.personalInfo.email, font, primaryText),
                if (p.personalInfo.phone.isNotEmpty) _modContact(_svgPhone, p.personalInfo.phone, font, primaryText),
                if (p.personalInfo.location.isNotEmpty) _modContact(_svgLoc, p.personalInfo.location, font, primaryText),
                if (p.personalInfo.linkedin.isNotEmpty) _modContact(_svgLink, p.personalInfo.linkedin, font, primaryText),

                if (p.skills.isNotEmpty) ...[
                  pw.SizedBox(height: 30),
                  pw.Text('SKILLS', style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryText, letterSpacing: 1.5)),
                  pw.SizedBox(height: 16),
                  ...p.skills.map((s) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(s.name, style: pw.TextStyle(font: font, fontSize: 10, color: primaryText)),
                            pw.SizedBox(height: 4),
                            // ---- NEW: Visual Skill Meter ----
                            _buildSkillMeter(s.level, primaryText, emptyDotColor),
                          ]
                      )
                  )),
                ],

                if (p.languages.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  pw.Text('LANGUAGES', style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryText, letterSpacing: 1.5)),
                  pw.SizedBox(height: 16),
                  ...p.languages.map((l) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(l, style: pw.TextStyle(font: font, fontSize: 10, color: primaryText)),
                  )),
                ],
              ],
            ),
          ),

          // Main Content
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(p.personalInfo.fullName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 26, color: primaryText)),
                  pw.SizedBox(height: 6),
                  pw.Text(p.personalInfo.jobTitle, style: pw.TextStyle(font: fontBold, fontSize: 12, color: secondaryText, letterSpacing: 1.2)),
                  pw.SizedBox(height: 24),

                  if (p.personalInfo.summary.isNotEmpty) ...[
                    pw.Text(p.personalInfo.summary, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, color: primaryText, lineSpacing: 1.5)),
                    pw.SizedBox(height: 28),
                  ],

                  if (p.workExperiences.isNotEmpty) ...[
                    _modHeader('EXPERIENCE', fontBold, primaryText),
                    ...p.workExperiences.map((exp) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 18),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(exp.position, style: pw.TextStyle(font: fontBold, fontSize: 12, color: primaryText)),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(exp.company, style: pw.TextStyle(font: fontBold, fontSize: 10, color: secondaryText)),
                              pw.Text('${exp.startDate} - ${exp.isCurrentJob ? 'Present' : exp.endDate}', style: pw.TextStyle(font: font, fontSize: 10, color: secondaryText)),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          if (exp.description.isNotEmpty)
                            pw.Text(exp.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, color: primaryText, lineSpacing: 1.5)),
                        ],
                      ),
                    )),
                  ],

                  if (p.educations.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    _modHeader('EDUCATION', fontBold, primaryText),
                    ...p.educations.map((edu) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 14),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(edu.degree, style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryText)),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(edu.institution, style: pw.TextStyle(font: font, fontSize: 10, color: secondaryText)),
                              pw.Text('${edu.startYear} - ${edu.endYear}', style: pw.TextStyle(font: font, fontSize: 10, color: secondaryText)),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],

                  if (p.projects.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    _modHeader('PROJECTS', fontBold, primaryText),
                    ...p.projects.map((proj) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 14),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(proj.name, style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryText)),
                          pw.SizedBox(height: 4),
                          if (proj.technologies.isNotEmpty) pw.Text('Tech: ${proj.technologies}', style: pw.TextStyle(font: font, fontSize: 9, color: secondaryText)),
                          pw.SizedBox(height: 4),
                          if (proj.description.isNotEmpty)
                            pw.Text(proj.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, color: primaryText, lineSpacing: 1.5)),
                        ],
                      ),
                    )),
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

// ---- NEW HELPER WIDGET FOR SKILL METERS ----
pw.Widget _buildSkillMeter(int level, PdfColor filledColor, PdfColor emptyColor) {
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: List.generate(5, (index) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(right: 5),
        width: 4, // Diameter of the dot
        height: 4,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          color: index < level ? filledColor : emptyColor,
        ),
      );
    }),
  );
}
// --------------------------------------------

pw.Widget _modContact(String iconSvg, String text, pw.Font font, PdfColor color) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(padding: const pw.EdgeInsets.only(top: 1), child: _drawIcon(iconSvg, color, size: 10)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, color: color, lineSpacing: 1.3))),
        ]
    )
);

pw.Widget _modHeader(String title, pw.Font fontBold, PdfColor color) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 12, color: color, letterSpacing: 1.2)),
    pw.Container(height: 1.5, color: color, margin: const pw.EdgeInsets.only(top: 6, bottom: 18)),
  ],
);

// =============================================================================
// TEMPLATE 3: ACADEMIC STANDARD (Stanford Engineering Style)
// =============================================================================
Future<Uint8List> _buildAcademicStandard(CVProvider p) async {
  final pdf = pw.Document();
  final font = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();
  final fontItalic = pw.Font.helveticaOblique();
  const primary = PdfColor.fromInt(0xFF1B365D);
  const subtleGray = PdfColor.fromInt(0xFFEEEEEE);

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
    build: (ctx) => [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.personalInfo.fullName, style: pw.TextStyle(font: fontBold, fontSize: 24, color: primary)),
          pw.SizedBox(height: 4),
          pw.Text(p.personalInfo.jobTitle, style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 12, runSpacing: 6,
            children: [
              if (p.personalInfo.email.isNotEmpty) _acadIcon(_svgMail, p.personalInfo.email, font),
              if (p.personalInfo.phone.isNotEmpty) _acadIcon(_svgPhone, p.personalInfo.phone, font),
              if (p.personalInfo.linkedin.isNotEmpty) _acadIcon(_svgLink, p.personalInfo.linkedin, font),
              if (p.personalInfo.location.isNotEmpty) _acadIcon(_svgLoc, p.personalInfo.location, font),
            ],
          )
        ],
      ),
      pw.SizedBox(height: 20),

      if (p.personalInfo.summary.isNotEmpty) ...[
        _acadHeader('PROFILE', fontBold, primary, subtleGray),
        pw.Text(p.personalInfo.summary, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5)),
        pw.SizedBox(height: 16),
      ],

      if (p.educations.isNotEmpty) ...[
        _acadHeader('EDUCATION', fontBold, primary, subtleGray),
        ...p.educations.map((edu) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(edu.institution, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    pw.SizedBox(height: 2),
                    pw.Text('${edu.degree}${edu.field.isNotEmpty ? ' in ${edu.field}' : ''}', style: pw.TextStyle(font: font, fontSize: 10)),
                    if (edu.grade.isNotEmpty) pw.Text('GPA: ${edu.grade}', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ),
              pw.Text('${edu.startYear} - ${edu.endYear}', style: pw.TextStyle(font: fontItalic, fontSize: 10)),
            ],
          ),
        )),
        pw.SizedBox(height: 8),
      ],

      if (p.projects.isNotEmpty) ...[
        _acadHeader('ACADEMIC & PERSONAL PROJECTS', fontBold, primary, subtleGray),
        ...p.projects.map((proj) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(proj.name, style: pw.TextStyle(font: fontBold, fontSize: 11)),
              if (proj.technologies.isNotEmpty) pw.Text('Tools: ${proj.technologies}', style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 6),
              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.only(top: 4, right: 8), child: pw.Container(width: 3, height: 3, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle))),
                    pw.Expanded(child: pw.Text(proj.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4))),
                  ]
              )
            ],
          ),
        )),
        pw.SizedBox(height: 8),
      ],

      if (p.workExperiences.isNotEmpty) ...[
        _acadHeader('EXPERIENCE', fontBold, primary, subtleGray),
        ...p.workExperiences.map((exp) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(exp.position, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                  pw.Text('${exp.startDate} - ${exp.isCurrentJob ? 'Present' : exp.endDate}', style: pw.TextStyle(font: fontItalic, fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(exp.company, style: pw.TextStyle(font: font, fontSize: 10)),
              pw.SizedBox(height: 6),
              if (exp.description.isNotEmpty)
                pw.Text(exp.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4)),
            ],
          ),
        )),
        pw.SizedBox(height: 8),
      ],

      if (p.skills.isNotEmpty) ...[
        _acadHeader('TECHNICAL SKILLS', fontBold, primary, subtleGray),
        // ---- NEW: Wrapped Grid Layout for Skills with Meters ----
        pw.Wrap(
          spacing: 32, // Horizontal space between skills
          runSpacing: 12, // Vertical space between rows
          children: p.skills.map((s) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(s.name, style: pw.TextStyle(font: fontBold, fontSize: 10, color: primary)),
              pw.SizedBox(height: 4),
              _buildSkillMeter(s.level, primary, PdfColors.grey300), // Uses the same helper as Template 2
            ],
          )).toList(),
        ),
        // ---------------------------------------------------------
      ],
    ],
  ));
  return pdf.save();
}

pw.Widget _acadIcon(String svg, String text, pw.Font font) => pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      _drawIcon(svg, PdfColors.grey700, size: 10),
      pw.SizedBox(width: 6),
      pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey800)),
    ]
);

pw.Widget _acadHeader(String title, pw.Font fontBold, PdfColor primary, PdfColor bg) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(2)),
    child: pw.Row(children: [pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11, color: primary, letterSpacing: 1.1))])
);

// =============================================================================
// TEMPLATE 4: TECH MINIMALIST (Timeline Grid)
// =============================================================================
Future<Uint8List> _buildTechMinimalist(CVProvider p) async {
  final pdf = pw.Document();
  final font = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();
  const primary = PdfColor.fromInt(0xFF263238);

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(40),
    build: (ctx) => [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.personalInfo.fullName, style: pw.TextStyle(font: fontBold, fontSize: 26, color: primary)),
          pw.SizedBox(height: 6),
          pw.Text(p.personalInfo.jobTitle.toUpperCase(), style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey900, letterSpacing: 1.5)),
          pw.SizedBox(height: 16),
          pw.Wrap(
            spacing: 16, runSpacing: 8,
            children: [
              if (p.personalInfo.email.isNotEmpty) _techContact(_svgMail, p.personalInfo.email, font),
              if (p.personalInfo.phone.isNotEmpty) _techContact(_svgPhone, p.personalInfo.phone, font),
              if (p.personalInfo.location.isNotEmpty) _techContact(_svgLoc, p.personalInfo.location, font),
              if (p.personalInfo.linkedin.isNotEmpty) _techContact(_svgLink, p.personalInfo.linkedin, font),
            ],
          ),
          pw.SizedBox(height: 24),
        ],
      ),

      if (p.personalInfo.summary.isNotEmpty) ...[
        _techHeader('PROFILE', fontBold, primary),
        pw.Text(p.personalInfo.summary, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5)),
        pw.SizedBox(height: 24),
      ],

      // Timeline Experience
      if (p.workExperiences.isNotEmpty) ...[
        _techHeader('EXPERIENCE', fontBold, primary),
        ...p.workExperiences.map((exp) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 2, height: 40, color: primary, margin: const pw.EdgeInsets.only(right: 12, top: -2)),
                  pw.Expanded(
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(exp.position, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                            pw.SizedBox(height: 4),
                            pw.Text('${exp.company}  |  ${exp.startDate} - ${exp.isCurrentJob ? 'Present' : exp.endDate}', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
                            pw.SizedBox(height: 6),
                            if (exp.description.isNotEmpty)
                              pw.Text(exp.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4)),
                          ]
                      )
                  )
                ]
            )
        )),
        pw.SizedBox(height: 8),
      ],

      // 2-Column Section for Details
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (p.projects.isNotEmpty) ...[
                  _techHeader('PROJECTS', fontBold, primary),
                  ...p.projects.map((proj) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 14),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(proj.name, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        pw.SizedBox(height: 2),
                        if (proj.technologies.isNotEmpty) pw.Text(proj.technologies, style: pw.TextStyle(font: font, fontSize: 9, color: primary)),
                        pw.SizedBox(height: 4),
                        if (proj.description.isNotEmpty) pw.Text(proj.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 9, lineSpacing: 1.4)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 32),
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (p.educations.isNotEmpty) ...[
                  _techHeader('EDUCATION', fontBold, primary),
                  ...p.educations.map((edu) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(edu.degree, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        pw.SizedBox(height: 2),
                        pw.Text(edu.institution, style: pw.TextStyle(font: font, fontSize: 9)),
                        pw.Text('${edu.startYear} - ${edu.endYear}', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  )),
                  pw.SizedBox(height: 12),
                ],
                if (p.skills.isNotEmpty) ...[
                  _techHeader('SKILLS', fontBold, primary),
                  pw.Wrap(
                    spacing: 6, runSpacing: 6,
                    children: p.skills.map((s) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey700), borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text(s.name, style: pw.TextStyle(font: font, fontSize: 9)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      )
    ],
  ));
  return pdf.save();
}

pw.Widget _techContact(String svg, String text, pw.Font font) => pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      _drawIcon(svg, PdfColors.grey900, size: 11),
      pw.SizedBox(width: 8),
      pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9)),
    ]
);

pw.Widget _techHeader(String title, pw.Font fontBold, PdfColor color) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 14),
  child: pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 12, color: color, letterSpacing: 1.5)),
);

// =============================================================================
// TEMPLATE 5: MANAGERIAL COMPACT (Executive Summary)
// =============================================================================
Future<Uint8List> _buildManagerialCompact(CVProvider p) async {
  final pdf = pw.Document();
  final font = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();
  final fontItalic = pw.Font.helveticaOblique();
  const primary = PdfColor.fromInt(0xFF37474F); // Steel Blue
  const darkText = PdfColor.fromInt(0xFF263238);

  // Changed to MultiPage so it breathes properly and doesn't crush text
  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 46, vertical: 46),
    build: (ctx) => [
      // ---- EXECUTIVE HEADER ----
      pw.Center(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(p.personalInfo.fullName.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 22, color: primary, letterSpacing: 1.2)),
            pw.SizedBox(height: 4),
            pw.Text(p.personalInfo.jobTitle, style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.grey700, letterSpacing: 1.5)),
            pw.SizedBox(height: 12),
            pw.Wrap(
              alignment: pw.WrapAlignment.center,
              spacing: 14, runSpacing: 6,
              children: [
                if (p.personalInfo.email.isNotEmpty) _compactContact(_svgMail, p.personalInfo.email, font),
                if (p.personalInfo.phone.isNotEmpty) _compactContact(_svgPhone, p.personalInfo.phone, font),
                if (p.personalInfo.location.isNotEmpty) _compactContact(_svgLoc, p.personalInfo.location, font),
                if (p.personalInfo.linkedin.isNotEmpty) _compactContact(_svgLink, p.personalInfo.linkedin, font),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 16),
      pw.Divider(color: primary, thickness: 1.5),
      pw.SizedBox(height: 16),

      // ---- SUMMARY ----
      if (p.personalInfo.summary.isNotEmpty) ...[
        pw.Text(p.personalInfo.summary, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5, color: darkText)),
        pw.SizedBox(height: 18),
      ],

      // ---- SKILLS (Moved up to act as a core competencies block) ----
      if (p.skills.isNotEmpty || p.languages.isNotEmpty) ...[
        _compactHeader('CORE COMPETENCIES', fontBold, primary),
        if (p.skills.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.RichText(text: pw.TextSpan(children: [
              pw.TextSpan(text: 'Technical Skills: ', style: pw.TextStyle(font: fontBold, fontSize: 10, color: darkText)),
              pw.TextSpan(text: p.skills.map((s) => s.name).join(' . '), style: pw.TextStyle(font: font, fontSize: 10, color: darkText)),
            ])),
          ),
        if (p.languages.isNotEmpty)
          pw.RichText(text: pw.TextSpan(children: [
            pw.TextSpan(text: 'Languages: ', style: pw.TextStyle(font: fontBold, fontSize: 10, color: darkText)),
            pw.TextSpan(text: p.languages.join(' . '), style: pw.TextStyle(font: font, fontSize: 10, color: darkText)),
          ])),
        pw.SizedBox(height: 18),
      ],

      // ---- EXPERIENCE ----
      if (p.workExperiences.isNotEmpty) ...[
        _compactHeader('PROFESSIONAL EXPERIENCE', fontBold, primary),
        ...p.workExperiences.map((exp) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(exp.position, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkText)),
                  pw.Text('${exp.startDate} - ${exp.isCurrentJob ? 'Present' : exp.endDate}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: primary)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(exp.company, style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey800)),
              pw.SizedBox(height: 6),
              if (exp.description.isNotEmpty)
                pw.Text(exp.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4, color: darkText)),
            ],
          ),
        )),
        pw.SizedBox(height: 4),
      ],

      // ---- PROJECTS ----
      if (p.projects.isNotEmpty) ...[
        _compactHeader('SELECTED PROJECTS', fontBold, primary),
        ...p.projects.map((proj) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${proj.name} ', style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkText)),
                    if (proj.technologies.isNotEmpty) pw.Text('| ${proj.technologies}', style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey700)),
                  ]
              ),
              pw.SizedBox(height: 4),
              if (proj.description.isNotEmpty)
                pw.Text(proj.description, textAlign: pw.TextAlign.justify, style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.4, color: darkText)),
            ],
          ),
        )),
        pw.SizedBox(height: 4),
      ],

      // ---- EDUCATION ----
      if (p.educations.isNotEmpty) ...[
        _compactHeader('EDUCATION', fontBold, primary),
        ...p.educations.map((edu) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(edu.degree, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkText)),
                    pw.SizedBox(height: 2),
                    pw.Text(edu.institution, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('${edu.startYear} - ${edu.endYear}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: primary)),
                  if (edu.grade.isNotEmpty) pw.Text('GPA: ${edu.grade}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        )),
      ],
    ],
  ));
  return pdf.save();
}

pw.Widget _compactContact(String svg, String text, pw.Font font) => pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      _drawIcon(svg, PdfColors.grey800, size: 10),
      pw.SizedBox(width: 6),
      pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromInt(0xFF263238))),
    ]
);

pw.Widget _compactHeader(String title, pw.Font fontBold, PdfColor color) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11, color: color, letterSpacing: 1.2)),
    pw.Container(height: 1, color: color, margin: const pw.EdgeInsets.only(top: 4, bottom: 12)),
  ],
);

String _formatDate(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

// =============================================================================
// SECTION 11 — SAVED CVs SCREEN
// =============================================================================

class SavedCVsScreen extends StatelessWidget {
  const SavedCVsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedCVs = context.watch<CVProvider>().savedCVs;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved CVs')),
      body: savedCVs.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'No saved CVs yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'Create and generate a CV to see it here.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: savedCVs.length,
        itemBuilder: (context, index) {
          final cv = savedCVs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppConstants.templates.firstWhere(
                      (t) => t.name == cv.templateName,
                  orElse: () => AppConstants.templates.first,
                ).primaryColor,
                child: const Icon(Icons.description,
                    color: Colors.white, size: 20),
              ),
              title: Text(cv.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(
                cv.isDraft
                    ? 'Draft-Last saved: ${cv.savedAt}'
                    : '${cv.templateName}-${cv.savedAt}',
                style: TextStyle(
                  fontSize: 12,
                  color: cv.isDraft ? AppTheme.accentGold : AppTheme.textSecondary,
                  fontWeight: cv.isDraft ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---- RESUME EDITING BUTTON ----
                  IconButton(
                    icon: const Icon(Icons.edit_document, size: 20, color: AppTheme.primaryBlue),
                    tooltip: 'Resume Editing',
                    onPressed: () {
                      context.read<CVProvider>().loadCV(cv);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen()));
                    },
                  ),

                  // ---- SHARE BUTTON (Only if it has a PDF file) ----
                  if (cv.filePath != null)
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20, color: AppTheme.primaryBlue),
                      tooltip: 'Share PDF',
                      onPressed: () async {
                        final file = File(cv.filePath!);
                        if (await file.exists()) {
                          await Printing.sharePdf(
                            bytes: await file.readAsBytes(),
                            filename: '${cv.name}.pdf',
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File not found')),
                          );
                        }
                      },
                    ),

                  // ---- DELETE BUTTON ----
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete CV'),
                          content: Text('Are you sure you want to delete "${cv.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                context.read<CVProvider>().removeSavedCV(cv.id);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
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

// =============================================================================
// SECTION 12 — SHARED / UTILITY WIDGETS
// =============================================================================

/// Reusable section header for form steps
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.08),
            AppTheme.primaryBlue.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Persistent text field with proper controller handling
class _FormField extends StatefulWidget {
  final String label;
  final String hint;
  final String initialValue;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _FormField({
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    super.key,
  });

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          border: const OutlineInputBorder(),
        ),
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        textDirection: TextDirection.ltr, // ensures left-to-right typing
      ),
    );
  }
}



/// Collapsible card for experience, education, project entries
class _CollapsibleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Widget child;

  const _CollapsibleCard({
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.onDelete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.textPrimary)),
                        if (subtitle.isNotEmpty)
                          Text(subtitle,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Empty state hint displayed when a list is empty
class _EmptyStateHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyStateHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 48, color: AppTheme.dividerColor),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }
}