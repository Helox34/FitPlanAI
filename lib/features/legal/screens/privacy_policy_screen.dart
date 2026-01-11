import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Polityka Prywatności',
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
              'Data ostatniej aktualizacji',
              'Niniejsza Polityka Prywatności obowiązuje od 11 stycznia 2026 r.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Wprowadzenie',
              'FitPlan AI ("my", "nas", "nasz") szanuje Twoją prywatność i zobowiązuje się do ochrony Twoich danych osobowych. '
              'Niniejsza Polityka Prywatności wyjaśnia, jakie dane zbieramy, jak je wykorzystujemy i jakie masz prawa.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '2. Zbierane dane',
              '2.1. Dane podawane przez użytkownika:\n'
              '   • Imię i nazwisko\n'
              '   • Adres email\n'
              '   • Wiek, płeć\n'
              '   • Pomiary ciała (waga, wzrost)\n'
              '   • Cele fitness\n'
              '   • Preferencje żywieniowe\n\n'
              '2.2. Dane zbierane automatycznie:\n'
              '   • Adres IP\n'
              '   • Typ urządzenia i system operacyjny\n'
              '   • Dane o korzystaniu z Aplikacji\n'
              '   • Logi aktywności\n\n'
              '2.3. Dane z kont społecznościowych:\n'
              '   • Przy logowaniu przez Google: email, imię, zdjęcie profilowe\n'
              '   • Przy logowaniu przez Facebook: email, imię, zdjęcie profilowe',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '3. Cel przetwarzania danych',
              '3.1. Wykorzystujemy Twoje dane do:\n'
              '   • Tworzenia i zarządzania kontem użytkownika\n'
              '   • Generowania spersonalizowanych planów treningowych i diet\n'
              '   • Śledzenia postępów i celów fitness\n'
              '   • Ulepszania algorytmów AI\n'
              '   • Komunikacji z użytkownikiem\n'
              '   • Zapewnienia bezpieczeństwa Aplikacji\n'
              '   • Analizy i statystyk\n\n'
              '3.2. Podstawa prawna:\n'
              '   • Zgoda użytkownika (RODO Art. 6.1.a)\n'
              '   • Wykonanie umowy (RODO Art. 6.1.b)\n'
              '   • Prawnie uzasadniony interes (RODO Art. 6.1.f)',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '4. Przechowywanie danych',
              '4.1. Dane są przechowywane w:\n'
              '   • Firebase (Google Cloud Platform)\n'
              '   • Lokalnej pamięci urządzenia (SharedPreferences)\n\n'
              '4.2. Lokalizacja serwerów:\n'
              '   • Unia Europejska (zgodnie z RODO)\n\n'
              '4.3. Okres przechowywania:\n'
              '   • Dane konta: do momentu usunięcia konta\n'
              '   • Dane treningowe: do momentu usunięcia przez użytkownika\n'
              '   • Logi: 90 dni',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '5. Udostępnianie danych',
              '5.1. Nie sprzedajemy Twoich danych osobowych.\n\n'
              '5.2. Udostępniamy dane następującym podmiotom:\n'
              '   • Google Firebase (hosting, autentykacja)\n'
              '   • Google Cloud AI (generowanie planów)\n'
              '   • Dostawcy usług płatniczych (tylko dane transakcyjne)\n\n'
              '5.3. Wszystkie podmioty trzecie są zobowiązane do ochrony danych zgodnie z RODO.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '6. Twoje prawa',
              'Zgodnie z RODO masz prawo do:\n\n'
              '6.1. Dostępu do danych - możesz zobaczyć swoje dane w profilu\n\n'
              '6.2. Poprawiania danych - możesz edytować dane w ustawieniach\n\n'
              '6.3. Usunięcia danych - możesz usunąć konto w każdej chwili\n\n'
              '6.4. Ograniczenia przetwarzania - możesz wyłączyć niektóre funkcje\n\n'
              '6.5. Przenoszenia danych - możesz wyeksportować swoje dane\n\n'
              '6.6. Sprzeciwu - możesz sprzeciwić się przetwarzaniu danych\n\n'
              '6.7. Cofnięcia zgody - w każdej chwili bez wpływu na dotychczasowe przetwarzanie',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '7. Bezpieczeństwo danych',
              '7.1. Stosujemy środki bezpieczeństwa:\n'
              '   • Szyfrowanie danych w tranzycie (HTTPS/TLS)\n'
              '   • Szyfrowanie danych w spoczynku (Firebase)\n'
              '   • Bezpieczne uwierzytelnianie (Firebase Auth)\n'
              '   • Regularne audyty bezpieczeństwa\n'
              '   • Ograniczony dostęp do danych\n\n'
              '7.2. Mimo stosowania najlepszych praktyk, żadna metoda transmisji przez Internet nie jest w 100% bezpieczna.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '8. Pliki cookies i technologie śledzące',
              '8.1. Aplikacja wykorzystuje:\n'
              '   • SharedPreferences do przechowywania preferencji\n'
              '   • Firebase Analytics do analizy użytkowania\n'
              '   • Google Sign-In cookies (przy logowaniu przez Google)\n\n'
              '8.2. Możesz zarządzać cookies w ustawieniach przeglądarki/urządzenia.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '9. Dane dzieci',
              'Aplikacja nie jest przeznaczona dla osób poniżej 16. roku życia. '
              'Nie zbieramy świadomie danych od dzieci. Jeśli dowiesz się, że dziecko podało nam dane, skontaktuj się z nami.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '10. Zmiany w Polityce Prywatności',
              '10.1. Możemy aktualizować Politykę Prywatności.\n\n'
              '10.2. Istotne zmiany zostaną zakomunikowane przez:\n'
              '   • Powiadomienie w Aplikacji\n'
              '   • Email na zarejestrowany adres\n\n'
              '10.3. Data ostatniej aktualizacji znajduje się na górze dokumentu.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '11. Kontakt',
              'W sprawach dotyczących prywatności i danych osobowych:\n\n'
              'Email: privacy@fitplanai.com\n'
              'Adres: [Adres firmy]\n\n'
              'Inspektor Ochrony Danych (DPO): dpo@fitplanai.com\n\n'
              'Masz również prawo złożyć skargę do organu nadzorczego:\n'
              'Urząd Ochrony Danych Osobowych (UODO)\n'
              'ul. Stawki 2, 00-193 Warszawa',
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
