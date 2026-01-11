import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Regulamin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Data wejścia w życie',
              'Niniejszy Regulamin obowiązuje od 11 stycznia 2026 r.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Postanowienia ogólne',
              '1.1. FitPlan AI ("Aplikacja") to platforma fitness wykorzystująca sztuczną inteligencję do tworzenia spersonalizowanych planów treningowych i diet.\n\n'
              '1.2. Właścicielem i operatorem Aplikacji jest [Nazwa firmy].\n\n'
              '1.3. Korzystanie z Aplikacji oznacza akceptację niniejszego Regulaminu.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '2. Konto użytkownika',
              '2.1. Aby korzystać z pełnej funkcjonalności Aplikacji, należy utworzyć konto użytkownika.\n\n'
              '2.2. Użytkownik może zarejestrować się poprzez:\n'
              '   • Email i hasło\n'
              '   • Konto Google\n'
              '   • Konto Facebook\n\n'
              '2.3. Użytkownik zobowiązuje się do:\n'
              '   • Podania prawdziwych danych\n'
              '   • Zachowania poufności hasła\n'
              '   • Niezwłocznego powiadomienia o nieautoryzowanym dostępie\n\n'
              '2.4. Użytkownik ponosi pełną odpowiedzialność za działania wykonane na swoim koncie.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '3. Opis usług',
              '3.1. Aplikacja oferuje:\n'
              '   • Spersonalizowane plany treningowe generowane przez AI\n'
              '   • Plany żywieniowe dostosowane do celów użytkownika\n'
              '   • Śledzenie postępów i pomiarów ciała\n'
              '   • Chatbot AI do konsultacji fitness\n'
              '   • Bibliotekę ćwiczeń z instrukcjami\n\n'
              '3.2. Funkcje mogą być aktualizowane lub modyfikowane bez wcześniejszego powiadomienia.\n\n'
              '3.3. Aplikacja nie zastępuje profesjonalnej porady medycznej lub dietetycznej.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '4. Subskrypcje i płatności',
              '4.1. Aplikacja oferuje model freemium:\n'
              '   • Podstawowe funkcje dostępne bezpłatnie\n'
              '   • Zaawansowane funkcje wymagają subskrypcji Premium\n\n'
              '4.2. Subskrypcja odnawia się automatycznie, chyba że zostanie anulowana przed końcem okresu rozliczeniowego.\n\n'
              '4.3. Ceny mogą ulec zmianie z 30-dniowym wyprzedzeniem.\n\n'
              '4.4. Zwroty są możliwe zgodnie z polityką zwrotów dostępną w Aplikacji.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '5. Własność intelektualna',
              '5.1. Wszystkie treści w Aplikacji (teksty, grafiki, logo, kod) są własnością operatora lub licencjonowane.\n\n'
              '5.2. Użytkownik nie może:\n'
              '   • Kopiować, modyfikować lub dystrybuować treści\n'
              '   • Dekompilować lub inżynierować wstecz Aplikacji\n'
              '   • Wykorzystywać Aplikacji do celów komercyjnych bez zgody',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '6. Ograniczenie odpowiedzialności',
              '6.1. Aplikacja jest dostarczana "TAK JAK JEST" bez gwarancji.\n\n'
              '6.2. Operator nie ponosi odpowiedzialności za:\n'
              '   • Kontuzje powstałe w wyniku wykonywania ćwiczeń\n'
              '   • Problemy zdrowotne wynikające z diet\n'
              '   • Utratę danych\n'
              '   • Przerwy w działaniu Aplikacji\n\n'
              '6.3. Przed rozpoczęciem programu treningowego zaleca się konsultację z lekarzem.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '7. Zakończenie korzystania',
              '7.1. Użytkownik może w każdej chwili usunąć konto w ustawieniach profilu.\n\n'
              '7.2. Operator zastrzega sobie prawo do zawieszenia lub usunięcia konta w przypadku:\n'
              '   • Naruszenia Regulaminu\n'
              '   • Niewłaściwego zachowania\n'
              '   • Podejrzenia oszustwa',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '8. Zmiany w Regulaminie',
              '8.1. Operator zastrzega sobie prawo do zmiany Regulaminu.\n\n'
              '8.2. Użytkownicy zostaną powiadomieni o istotnych zmianach.\n\n'
              '8.3. Kontynuowanie korzystania z Aplikacji po zmianach oznacza akceptację nowego Regulaminu.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '9. Kontakt',
              'W przypadku pytań dotyczących Regulaminu, prosimy o kontakt:\n\n'
              'Email: support@fitplanai.com\n'
              'Adres: [Adres firmy]',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
