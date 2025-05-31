class ApiError {
  final String message;
  final String code;
  final int statusCode;
  final Map<String, List<String>>? errors;

  ApiError({
    required this.message,
    required this.code,
    required this.statusCode,
    this.errors,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? parsedErrors;
    
    if (json['errors'] != null) {
      parsedErrors = {};
      final errorsData = json['errors'] as Map<String, dynamic>;
      
      errorsData.forEach((key, value) {
        if (value is List) {
          parsedErrors![key] = value.map((e) => e.toString()).toList();
        } else if (value is String) {
          parsedErrors![key] = [value];
        }
      });
    }

    return ApiError(
      message: json['message'] ?? 'Erro desconhecido',
      code: json['code'] ?? '',
      statusCode: json['status_code'] ?? 0,
      errors: parsedErrors,
    );
  }

  bool get isValidationError => code == 'validation' && statusCode == 422;
  
  bool get hasFieldErrors => errors != null && errors!.isNotEmpty;
  
  List<String> getFieldErrors(String fieldName) {
    return errors?[fieldName] ?? [];
  }
  
  List<String> get allErrorMessages {
    if (!hasFieldErrors) return [message];
    
    List<String> allMessages = [];
    errors!.forEach((field, messages) {
      allMessages.addAll(messages);
    });
    return allMessages;
  }
  
  String get summaryMessage {
    if (!hasFieldErrors) return message;
    
    final errorCount = allErrorMessages.length;
    if (errorCount == 1) {
      return allErrorMessages.first;
    } else if (errorCount <= 3) {
      return allErrorMessages.join('\n');
    } else {
      return '${allErrorMessages.take(2).join('\n')}\n... e mais ${errorCount - 2} erro(s)';
    }
  }
} 