import 'package:flutter/material.dart';

class PersonalInfo {
  String fullName;
  String jobTitle;
  String email;
  String phone;
  String location;
  String website;
  String linkedin;
  String summary;

  PersonalInfo({
    this.fullName = '', this.jobTitle = '', this.email = '',
    this.phone = '', this.location = '', this.website = '',
    this.linkedin = '', this.summary = '',
  });

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

  PersonalInfo copyWith({
    String? fullName, String? jobTitle, String? email, String? phone,
    String? location, String? website, String? linkedin, String? summary,
  }) {
    return PersonalInfo(
      fullName: fullName ?? this.fullName, jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email, phone: phone ?? this.phone,
      location: location ?? this.location, website: website ?? this.website,
      linkedin: linkedin ?? this.linkedin, summary: summary ?? this.summary,
    );
  }
}

class WorkExperience {
  String company;
  String position;
  String startDate;
  String endDate;
  bool isCurrentJob;
  String description;

  WorkExperience({
    this.company = '', this.position = '', this.startDate = '',
    this.endDate = '', this.isCurrentJob = false, this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'company': company, 'position': position, 'startDate': startDate,
    'endDate': endDate, 'isCurrentJob': isCurrentJob, 'description': description,
  };

  factory WorkExperience.fromJson(Map<String, dynamic> json) => WorkExperience(
    company: json['company'] ?? '', position: json['position'] ?? '',
    startDate: json['startDate'] ?? '', endDate: json['endDate'] ?? '',
    isCurrentJob: json['isCurrentJob'] ?? false, description: json['description'] ?? '',
  );

  WorkExperience copy() => WorkExperience(
    company: company, position: position, startDate: startDate,
    endDate: endDate, isCurrentJob: isCurrentJob, description: description,
  );
}

class Education {
  String institution;
  String degree;
  String field;
  String startYear;
  String endYear;
  String grade;

  Education({
    this.institution = '', this.degree = '', this.field = '',
    this.startYear = '', this.endYear = '', this.grade = '',
  });

  Map<String, dynamic> toJson() => {
    'institution': institution, 'degree': degree, 'field': field,
    'startYear': startYear, 'endYear': endYear, 'grade': grade,
  };

  factory Education.fromJson(Map<String, dynamic> json) => Education(
    institution: json['institution'] ?? '', degree: json['degree'] ?? '',
    field: json['field'] ?? '', startYear: json['startYear'] ?? '',
    endYear: json['endYear'] ?? '', grade: json['grade'] ?? '',
  );

  Education copy() => Education(
    institution: institution, degree: degree, field: field,
    startYear: startYear, endYear: endYear, grade: grade,
  );
}

class Project {
  String name;
  String description;
  String technologies;
  String link;

  Project({this.name = '', this.description = '', this.technologies = '', this.link = ''});

  Map<String, dynamic> toJson() => {
    'name': name, 'description': description, 'technologies': technologies, 'link': link,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    name: json['name'] ?? '', description: json['description'] ?? '',
    technologies: json['technologies'] ?? '', link: json['link'] ?? '',
  );

  Project copy() => Project(name: name, description: description, technologies: technologies, link: link);
}

class Certification {
  String name;
  String issuer;
  String year;

  Certification({this.name = '', this.issuer = '', this.year = ''});

  Map<String, dynamic> toJson() => { 'name': name, 'issuer': issuer, 'year': year };

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
    name: json['name'] ?? '', issuer: json['issuer'] ?? '', year: json['year'] ?? '',
  );

  Certification copy() => Certification(name: name, issuer: issuer, year: year);
}

class Skill {
  String name;
  int level;

  Skill({this.name = '', this.level = 3});

  Skill copy() => Skill(name: name, level: level);
  Map<String, dynamic> toJson() => { 'name': name, 'level': level };
  factory Skill.fromJson(Map<String, dynamic> json) => Skill(name: json['name'] ?? '', level: json['level'] ?? 3);
}

class SavedCV {
  final String id;
  final String name;
  final String templateName;
  final String savedAt;
  late final String? filePath;
  final bool isDraft;
  final PersonalInfo personalInfo;
  final List<WorkExperience> workExperiences;
  final List<Education> educations;
  final List<Project> projects;
  final List<Certification> certifications;
  final List<Skill> skills;
  final List<String> languages;
  final int templateIndex;

  SavedCV({
    required this.id, required this.name, required this.templateName,
    required this.savedAt, this.filePath, this.isDraft = false,
    required this.personalInfo, required this.workExperiences, required this.educations,
    required this.projects, required this.certifications, required this.skills,
    required this.languages, required this.templateIndex,
  });
}

class CVTemplate {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;

  const CVTemplate({
    required this.id, required this.name, required this.description,
    required this.primaryColor, required this.accentColor, required this.icon,
  });
}

class AppConstants {
  static const String appName = 'EzzeCV';
  static const String appTagline = 'Build Your Career Story';

  static const List<CVTemplate> templates = [
    CVTemplate(
      id: 'classic_ats', name: 'Executive ATS',
      description: 'Strictly black & white, highly optimized for corporate ATS.',
      primaryColor: Color(0xFF212121), accentColor: Color(0xFF424242), icon: Icons.article_outlined,
    ),
    CVTemplate(
      id: 'modern_clean', name: 'Corporate Modern',
      description: 'Clean two-column layout with elegant typography.',
      primaryColor: Color(0xFF2C3E50), accentColor: Color(0xFF34495E), icon: Icons.view_sidebar_outlined,
    ),
    CVTemplate(
      id: 'student_fresher', name: 'Academic Standard',
      description: 'Structured hierarchy ideal for graduates and academia.',
      primaryColor: Color(0xFF1B365D), accentColor: Color(0xFF335280), icon: Icons.school_outlined,
    ),
    CVTemplate(
      id: 'hybrid', name: 'Tech Minimalist',
      description: 'Grid-based layout emphasizing technical skills.',
      primaryColor: Color(0xFF37474F), accentColor: Color(0xFF546E7A), icon: Icons.grid_view_rounded,
    ),
    CVTemplate(
      id: 'one_page', name: 'Managerial Compact',
      description: 'Space-efficient executive layout.',
      primaryColor: Color(0xFF455A64), accentColor: Color(0xFF607D8B), icon: Icons.view_agenda_outlined,
    ),
  ];

  static const List<String> formSteps = [
    'Personal Info', 'Experience', 'Education', 'Skills', 'Projects', 'Certifications',
  ];
}

class AppTheme {
  static const Color bgDeep = Color(0xFF0A0F1E);
  static const Color bgMid = Color(0xFF111827);
  static const Color bgSurface = Color(0xFFF5F7FA);
  static const Color bgCard = Colors.white;

  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentCyanLight = Color(0xFF67E8F9);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentGoldLight = Color(0xFFFCD34D);

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFF60A5FA);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, brightness: Brightness.light),
      scaffoldBackgroundColor: bgSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDeep, foregroundColor: Colors.white, elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
      cardTheme: CardThemeData(
        color: bgCard, elevation: 0, shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: divider, width: 1)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2), elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue, side: const BorderSide(color: primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}