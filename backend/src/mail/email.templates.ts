import { EmailJob } from './mail.types';

export interface RenderedEmail {
  subject: string;
  html: string;
  text: string;
}

const esc = (s: string) =>
  s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

function layout(title: string, bodyHtml: string): string {
  return `<!doctype html>
<html><body style="margin:0;background:#f4f6fb;font-family:Arial,Helvetica,sans-serif;color:#1b2430">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:24px">
<table role="presentation" width="560" cellpadding="0" cellspacing="0" style="background:#fff;border-radius:8px;overflow:hidden">
<tr><td style="background:#1F3A93;color:#fff;padding:20px 28px;font-size:20px;font-weight:bold">SketchSquare</td></tr>
<tr><td style="padding:28px"><h1 style="font-size:20px;margin:0 0 16px">${esc(title)}</h1>${bodyHtml}</td></tr>
<tr><td style="padding:16px 28px;font-size:12px;color:#6b7686">Architectural drawings, by architects, for architects.</td></tr>
</table></td></tr></table></body></html>`;
}

export function renderEmail(job: EmailJob): RenderedEmail {
  switch (job.name) {
    case 'welcome': {
      const { fullName } = job.data;
      return {
        subject: 'Welcome to SketchSquare',
        html: layout(
          'Welcome to SketchSquare',
          `<p>Hi ${esc(fullName)},</p>
<p>Your architect profile has been <strong>verified</strong>. You can now browse, buy and sell architectural drawings on SketchSquare.</p>
<p>Open the app and sign in to get started.</p>`,
        ),
        text: `Hi ${fullName},\n\nYour architect profile has been verified. You can now browse, buy and sell architectural drawings on SketchSquare.\nOpen the app and sign in to get started.`,
      };
    }
    case 'verification-rejected': {
      const { fullName, note } = job.data;
      return {
        subject: 'Your SketchSquare verification needs attention',
        html: layout(
          'We could not verify your profile',
          `<p>Hi ${esc(fullName)},</p>
<p>Unfortunately we could not verify your architect registration.</p>
<p style="background:#fdf2f2;border-left:4px solid #c0392b;padding:12px 16px"><strong>Reason:</strong> ${esc(note)}</p>
<p>Open the app, go to the verification screen and submit your details again.</p>`,
        ),
        text: `Hi ${fullName},\n\nUnfortunately we could not verify your architect registration.\nReason: ${note}\n\nOpen the app, go to the verification screen and submit your details again.`,
      };
    }
    case 'password-reset': {
      const { fullName, token, resetUrl } = job.data;
      return {
        subject: 'Reset your SketchSquare password',
        html: layout(
          'Reset your password',
          `<p>Hi ${esc(fullName)},</p>
<p>We received a request to reset your password. This link expires soon.</p>
<p><a href="${esc(resetUrl)}" style="background:#1F3A93;color:#fff;padding:10px 18px;border-radius:6px;text-decoration:none;display:inline-block">Reset password</a></p>
<p>Or enter this reset code in the app:</p>
<p style="font-family:monospace;font-size:14px;background:#f4f6fb;padding:10px;word-break:break-all">${esc(token)}</p>
<p>If you did not request this, you can ignore this email.</p>`,
        ),
        text: `Hi ${fullName},\n\nWe received a request to reset your password.\nLink: ${resetUrl}\nReset code: ${token}\n\nIf you did not request this, ignore this email.`,
      };
    }
  }
}
