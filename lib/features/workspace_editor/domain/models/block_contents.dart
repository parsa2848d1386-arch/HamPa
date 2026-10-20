/// Value objects representing type-safe content JSON structures
abstract class BlockContentPayload {
  Map<String, dynamic> toJson();
}

class TextBlockContent implements BlockContentPayload {
  final String text;

  const TextBlockContent({required this.text});

  factory TextBlockContent.fromJson(Map<String, dynamic> json) {
    return TextBlockContent(text: json['text'] as String? ?? '');
  }

  @override
  Map<String, dynamic> toJson() => {'text': text};
}

class ChecklistBlockContent implements BlockContentPayload {
  final String text;
  final bool isCompleted;
  final int? checkedAt;

  const ChecklistBlockContent({
    required this.text,
    this.isCompleted = false,
    this.checkedAt,
  });

  factory ChecklistBlockContent.fromJson(Map<String, dynamic> json) {
    return ChecklistBlockContent(
      text: json['text'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      checkedAt: json['checkedAt'] as int?,
    );
  }

  ChecklistBlockContent copyWith({
    String? text,
    bool? isCompleted,
    int? checkedAt,
  }) {
    return ChecklistBlockContent(
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'text': text,
    'isCompleted': isCompleted,
    if (checkedAt != null) 'checkedAt': checkedAt,
  };
}

class CalloutBlockContent implements BlockContentPayload {
  final String text;
  final String icon; // Emoji or identifier
  final String colorTheme; // 'amber', 'blue', 'green', 'rose', 'purple'

  const CalloutBlockContent({
    required this.text,
    this.icon = '💡',
    this.colorTheme = 'amber',
  });

  factory CalloutBlockContent.fromJson(Map<String, dynamic> json) {
    return CalloutBlockContent(
      text: json['text'] as String? ?? '',
      icon: json['icon'] as String? ?? '💡',
      colorTheme: json['colorTheme'] as String? ?? 'amber',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'text': text,
    'icon': icon,
    'colorTheme': colorTheme,
  };
}

class ToggleBlockContent implements BlockContentPayload {
  final String title;
  final bool isOpen;

  const ToggleBlockContent({
    required this.title,
    this.isOpen = false,
  });

  factory ToggleBlockContent.fromJson(Map<String, dynamic> json) {
    return ToggleBlockContent(
      title: json['title'] as String? ?? '',
      isOpen: json['isOpen'] as bool? ?? false,
    );
  }

  ToggleBlockContent copyWith({String? title, bool? isOpen}) {
    return ToggleBlockContent(
      title: title ?? this.title,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'isOpen': isOpen,
  };
}

class CodeBlockContent implements BlockContentPayload {
  final String code;
  final String language;
  final bool showLineNumbers;

  const CodeBlockContent({
    required this.code,
    this.language = 'dart',
    this.showLineNumbers = true,
  });

  factory CodeBlockContent.fromJson(Map<String, dynamic> json) {
    return CodeBlockContent(
      code: json['code'] as String? ?? '',
      language: json['language'] as String? ?? 'dart',
      showLineNumbers: json['showLineNumbers'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'code': code,
    'language': language,
    'showLineNumbers': showLineNumbers,
  };
}

class MathBlockContent implements BlockContentPayload {
  final String latex;
  final bool isDisplayMode;

  const MathBlockContent({
    required this.latex,
    this.isDisplayMode = true,
  });

  factory MathBlockContent.fromJson(Map<String, dynamic> json) {
    return MathBlockContent(
      latex: json['latex'] as String? ?? '',
      isDisplayMode: json['isDisplayMode'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'latex': latex,
    'isDisplayMode': isDisplayMode,
  };
}
