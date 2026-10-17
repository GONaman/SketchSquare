class LegalSection {
  const LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

/// Placeholder legal copy. TODO(owner): replace with counsel-reviewed text
/// before launch (tracked in docs/PROGRESS.md "Needs manual check").
abstract final class LegalContent {
  static const placeholderNotice =
      'Placeholder text, not legal advice. It will be replaced by the final '
      'document before public launch.';

  static const termsTitle = 'Terms of Service';
  static const privacyTitle = 'Privacy Policy';

  static const terms = <LegalSection>[
    LegalSection(
      '1. Who can use SketchSquare',
      'SketchSquare is a marketplace for architectural drawings. Accounts are '
          'limited to architects whose registration with the Council of '
          'Architecture has been verified by us. You are responsible for the '
          'accuracy of the details and documents you submit.',
    ),
    LegalSection(
      '2. Drawing licence granted to buyers',
      'When you buy or download a drawing you receive a non-exclusive, '
          'non-transferable licence to use it for your own projects. You may '
          'not resell, sublicense, redistribute or re-upload the drawing, in '
          'whole or in part, to SketchSquare or anywhere else. Copyright and '
          'all other rights stay with the architect who uploaded the drawing.',
    ),
    LegalSection(
      '3. Licence granted by sellers',
      'By publishing a drawing you confirm that you own it or have the right '
          'to sell it, and you allow SketchSquare to store it, show watermarked '
          'previews, and deliver licensed copies to buyers. Uploading work '
          'that belongs to someone else is prohibited and may lead to removal '
          'and account suspension.',
    ),
    LegalSection(
      '4. Watermarks and traceability',
      'Previews carry a SketchSquare watermark. Purchased files carry a '
          'footer naming the licensee and the purchase, so leaked copies can be '
          'traced. Removing or altering these marks is not allowed.',
    ),
    LegalSection(
      '5. Payments, fees and payouts',
      'Prices are in Indian rupees. SketchSquare keeps a platform fee from '
          'each sale and credits the rest to the seller wallet. Withdrawals '
          'are subject to a minimum amount and to verification of your bank '
          'account. Taxes are your responsibility unless stated otherwise.',
    ),
    LegalSection(
      '6. Refunds and disputes',
      'Refunds are handled by SketchSquare administrators on a case by case '
          'basis. A refunded purchase ends the buyer\'s licence and download '
          'access.',
    ),
    LegalSection(
      '7. Suspension',
      'We may suspend or remove accounts and listings that break these terms '
          'or the law.',
    ),
  ];

  static const privacy = <LegalSection>[
    LegalSection(
      'What we collect',
      'Account details (name, email, phone, address, city), your architect '
          'registration number and verification document, the drawings you '
          'upload, purchase and download history, wallet and payout details '
          '(we only keep the last four digits of your bank account), and basic '
          'usage and crash data.',
    ),
    LegalSection(
      'How we use it',
      'To verify architects, run the marketplace, process payments and '
          'payouts, send service emails, prevent fraud and plagiarism, and '
          'improve the app.',
    ),
    LegalSection(
      'Who can see it',
      'Your name, city, rating and published drawings are visible to other '
          'verified architects. Sellers see the name, city and purchase date '
          'of their buyers. Your verification document is visible only to '
          'SketchSquare administrators.',
    ),
    LegalSection(
      'Service providers',
      'We use payment, email, storage and error-reporting providers to run '
          'the service. They only receive the data needed for their task.',
    ),
    LegalSection(
      'Your choices',
      'Name and address cannot be changed after signup; contact support to '
          'correct them. You can update your phone, city and photo in the '
          'app, and ask support to delete your account.',
    ),
  ];
}
