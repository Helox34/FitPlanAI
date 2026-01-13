class AppErrorHelper {
  static String getFriendlyErrorMessage(String error) {
    final lowerError = error.toLowerCase();
    
    // Auth Errors
    if (lowerError.contains('invalid-credential') || 
        lowerError.contains('wrong-password') || 
        lowerError.contains('user-not-found')) {
      return 'Błędny email lub hasło.';
    }
    if (lowerError.contains('invalid-email')) {
      return 'Podany adres email jest nieprawidłowy.';
    }
    if (lowerError.contains('email-already-in-use')) {
      return 'Ten adres email jest już zajęty.';
    }
    if (lowerError.contains('weak-password')) {
      return 'Hasło jest zbyt słabe.';
    }
    if (lowerError.contains('operation-not-allowed')) {
      return 'Logowanie zablokowane. Skontaktuj się z pomocą techniczną.';
    }
    if (lowerError.contains('too-many-requests')) {
      return 'Zbyt wiele prób logowania. Spróbuj ponownie później.';
    }
    if (lowerError.contains('network-request-failed')) {
      return 'Problem z połączeniem internetowym.';
    }
    if (lowerError.contains('account-exists-with-different-credential')) {
      return 'Konto już istnieje. Zaloguj się inną metodą.';
    }
    if (lowerError.contains('cancelled') || lowerError.contains('adb') || lowerError.contains('canceled')) {
      return 'Logowanie anulowane.';
    }

    // Default
    return 'Wystąpił błąd: $error';
  }
}
