import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/api_error.dart';

class ValidationErrorHandler {

  static ApiError? handleResponse(http.Response response, BuildContext context) {
    if (response.statusCode == 422) {
      try {
        final responseData = jsonDecode(response.body);
        final apiError = ApiError.fromJson(responseData);
        
        if (apiError.isValidationError) {
          _showValidationError(apiError, context);
          return apiError;
        }
      } catch (e) {

        _showGenericError(context, 'Erro de validação');
      }
    }
    return null;
  }
  
  static void _showValidationError(ApiError apiError, BuildContext context) {
    String errorMessage;
    
    if (!apiError.hasFieldErrors) {
      errorMessage = apiError.message;
    } else {
      errorMessage = apiError.allErrorMessages.first;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  static void _showGenericError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  static String? Function(String?) createFieldValidator({
    String? Function(String?)? customValidator
  }) {
    return (String? value) {
      return customValidator?.call(value);
    };
  }
} 