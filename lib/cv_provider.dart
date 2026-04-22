import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models.dart';

class CVProvider extends ChangeNotifier {
  PersonalInfo _personalInfo = PersonalInfo();
  List<WorkExperience> _workExperiences = [];
  List<Education> _educations = [];
  List<Project> _projects = [];
  List<Certification> _certifications = [];
  List<Skill> _skills = [];
  List<String> _languages = [];

  int _selectedTemplateIndex = 0;
  int _currentStep = 0;
  List<SavedCV> _savedCVs = [];

  bool _isAppDarkMode = false;
  String _appLanguage = 'EN';
  Color _pdfColor = const Color(0xFF2C3E50);
  String _pdfFont = 'Roboto';

  CVProvider() { _loadSavedDraftsFromDevice(); }

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

  bool get isAppDarkMode => _isAppDarkMode;
  String get appLanguage => _appLanguage;
  Color get pdfColor => _pdfColor;
  String get pdfFont => _pdfFont;

  CVTemplate get selectedTemplate => AppConstants.templates[_selectedTemplateIndex];

  void toggleTheme() { _isAppDarkMode = !_isAppDarkMode; notifyListeners(); }
  void toggleLanguage() { _appLanguage = _appLanguage == 'EN' ? 'BN' : 'EN'; notifyListeners(); }
  void updatePdfColor(Color color) { _pdfColor = color; notifyListeners(); }
  void updatePdfFont(String font) { _pdfFont = font; notifyListeners(); }

  void updatePersonalInfo(PersonalInfo info) { _personalInfo = info; notifyListeners(); }
  void addWorkExperience() { _workExperiences.add(WorkExperience()); notifyListeners(); }
  void updateWorkExperience(int index, WorkExperience exp) { _workExperiences[index] = exp; notifyListeners(); }
  void removeWorkExperience(int index) { _workExperiences.removeAt(index); notifyListeners(); }
  void addEducation() { _educations.add(Education()); notifyListeners(); }
  void updateEducation(int index, Education edu) { _educations[index] = edu; notifyListeners(); }
  void removeEducation(int index) { _educations.removeAt(index); notifyListeners(); }
  void addProject() { _projects.add(Project()); notifyListeners(); }
  void updateProject(int index, Project proj) { _projects[index] = proj; notifyListeners(); }
  void removeProject(int index) { _projects.removeAt(index); notifyListeners(); }
  void addCertification() { _certifications.add(Certification()); notifyListeners(); }
  void updateCertification(int index, Certification cert) { _certifications[index] = cert; notifyListeners(); }
  void removeCertification(int index) { _certifications.removeAt(index); notifyListeners(); }
  void addSkill() { _skills.add(Skill()); notifyListeners(); }
  void updateSkill(int index, Skill skill) { _skills[index] = skill; notifyListeners(); }
  void removeSkill(int index) { _skills.removeAt(index); notifyListeners(); }
  void addLanguage(String lang) { if (lang.isNotEmpty) _languages.add(lang); notifyListeners(); }
  void removeLanguage(int index) { _languages.removeAt(index); notifyListeners(); }
  void selectTemplate(int index) { _selectedTemplateIndex = index; notifyListeners(); }
  void setStep(int step) { _currentStep = step; notifyListeners(); }

  void addSavedCV(SavedCV cv) { _savedCVs.insert(0, cv); notifyListeners(); }

  Future<Directory> _getPublicDirectory() async {
    if (Platform.isAndroid) return Directory('/storage/emulated/0/Download/EzzeCV_Drafts');
    final directory = await getApplicationDocumentsDirectory();
    return Directory('${directory.path}/EzzeCV_Drafts');
  }

  Future<void> _loadSavedDraftsFromDevice() async {
    try {
      final dir = await _getPublicDirectory();
      if (!await dir.exists()) return;
      List<SavedCV> loadedCVs = [];
      for (var file in dir.listSync()) {
        if (file is File && file.path.endsWith('.json')) {
          Map<String, dynamic> data = jsonDecode(await file.readAsString());
          loadedCVs.add(SavedCV(
            id: file.path, name: data['name'] ?? 'Untitled Draft',
            templateName: AppConstants.templates[data['templateIndex'] ?? 0].name,
            savedAt: data['savedAt'] ?? '', filePath: null, isDraft: true,
            personalInfo: PersonalInfo.fromJson(data['personalInfo'] ?? {}),
            workExperiences: (data['workExperiences'] as List?)?.map((e) => WorkExperience.fromJson(e)).toList() ?? [],
            educations: (data['educations'] as List?)?.map((e) => Education.fromJson(e)).toList() ?? [],
            projects: (data['projects'] as List?)?.map((e) => Project.fromJson(e)).toList() ?? [],
            certifications: (data['certifications'] as List?)?.map((e) => Certification.fromJson(e)).toList() ?? [],
            skills: (data['skills'] as List?)?.map((e) => Skill.fromJson(e)).toList() ?? [],
            languages: List<String>.from(data['languages'] ?? []), templateIndex: data['templateIndex'] ?? 0,
            pdfColorHex: data['pdfColorHex'] ?? 0xFF2C3E50, pdfFont: data['pdfFont'] ?? 'Roboto',
          ));
        }
      }
      final existingPdfs = _savedCVs.where((cv) => !cv.isDraft).toList();
      loadedCVs.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      _savedCVs = [...existingPdfs, ...loadedCVs];
      notifyListeners();
    } catch (e) { debugPrint("Error loading drafts: $e"); }
  }

  Future<bool> saveDraft() async {
    if (Platform.isAndroid && !await Permission.storage.request().isGranted && !await Permission.manageExternalStorage.request().isGranted) return false;
    try {
      final dir = await _getPublicDirectory();
      if (!await dir.exists()) await dir.create(recursive: true);
      final dt = DateTime.now();
      final dateStr = '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month - 1]} ${dt.day}, ${dt.year}';
      final draftName = _personalInfo.fullName.isNotEmpty ? '${_personalInfo.fullName} (Draft)' : 'Untitled Draft';
      final dataToSave = {
        'name': draftName, 'savedAt': dateStr, 'personalInfo': _personalInfo.toJson(),
        'workExperiences': _workExperiences.map((e) => e.toJson()).toList(), 'educations': _educations.map((e) => e.toJson()).toList(),
        'projects': _projects.map((e) => e.toJson()).toList(), 'certifications': _certifications.map((e) => e.toJson()).toList(),
        'skills': _skills.map((e) => e.toJson()).toList(), 'languages': _languages, 'templateIndex': _selectedTemplateIndex,
        'pdfColorHex': _pdfColor.value, 'pdfFont': _pdfFont,
      };
      await File('${dir.path}/${draftName.replaceAll(' ', '_')}_${dt.millisecondsSinceEpoch}.json').writeAsString(jsonEncode(dataToSave));
      await _loadSavedDraftsFromDevice();
      return true;
    } catch (e) { return false; }
  }

  void removeSavedCV(String pathId) {
    try {
      final file = File(pathId);
      if (file.existsSync()) file.deleteSync();
      _savedCVs.removeWhere((cv) => cv.id == pathId);
      notifyListeners();
    } catch (e) {}
  }

  void loadCV(SavedCV cv) {
    _personalInfo = cv.personalInfo.copyWith(); _workExperiences = cv.workExperiences.map((e) => e.copy()).toList();
    _educations = cv.educations.map((e) => e.copy()).toList(); _projects = cv.projects.map((e) => e.copy()).toList();
    _certifications = cv.certifications.map((e) => e.copy()).toList(); _skills = cv.skills.map((e) => e.copy()).toList();
    _languages = List.from(cv.languages); _selectedTemplateIndex = cv.templateIndex;
    _pdfColor = Color(cv.pdfColorHex); _pdfFont = cv.pdfFont; _currentStep = 0;
    notifyListeners();
  }

  void resetForm() {
    _personalInfo = PersonalInfo(); _workExperiences = []; _educations = []; _projects = []; _certifications = []; _skills = []; _languages = [];
    _selectedTemplateIndex = 0; _pdfColor = const Color(0xFF2C3E50); _pdfFont = 'Roboto'; _currentStep = 0;
    notifyListeners();
  }

  String exportToJson() => jsonEncode({
    'personalInfo': _personalInfo.toJson(), 'workExperiences': _workExperiences.map((e) => e.toJson()).toList(),
    'educations': _educations.map((e) => e.toJson()).toList(), 'projects': _projects.map((e) => e.toJson()).toList(),
    'certifications': _certifications.map((e) => e.toJson()).toList(), 'skills': _skills.map((e) => e.toJson()).toList(),
    'languages': _languages, 'templateIndex': _selectedTemplateIndex, 'pdfColorHex': _pdfColor.value, 'pdfFont': _pdfFont,
  });

  void importFromJson(String jsonString) {
    final data = jsonDecode(jsonString);
    _personalInfo = PersonalInfo.fromJson(data['personalInfo'] ?? {});
    _workExperiences = (data['workExperiences'] as List?)?.map((e) => WorkExperience.fromJson(e)).toList() ?? [];
    _educations = (data['educations'] as List?)?.map((e) => Education.fromJson(e)).toList() ?? [];
    _projects = (data['projects'] as List?)?.map((e) => Project.fromJson(e)).toList() ?? [];
    _certifications = (data['certifications'] as List?)?.map((e) => Certification.fromJson(e)).toList() ?? [];
    _skills = (data['skills'] as List?)?.map((e) => Skill.fromJson(e)).toList() ?? [];
    _languages = List<String>.from(data['languages'] ?? []);
    _selectedTemplateIndex = data['templateIndex'] ?? 0;
    _pdfColor = Color(data['pdfColorHex'] ?? 0xFF2C3E50);
    _pdfFont = data['pdfFont'] ?? 'Roboto';
    _currentStep = 0;
    notifyListeners();
  }
}