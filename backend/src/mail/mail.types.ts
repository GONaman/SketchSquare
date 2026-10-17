export const EMAIL_QUEUE = 'email';

export type EmailJob =
  | { name: 'welcome'; data: { to: string; fullName: string } }
  | {
      name: 'verification-rejected';
      data: { to: string; fullName: string; note: string };
    }
  | {
      name: 'password-reset';
      data: { to: string; fullName: string; token: string; resetUrl: string };
    }
  | {
      name: 'drawing-under-review';
      data: { to: string; fullName: string; title: string };
    };

export type EmailJobName = EmailJob['name'];
