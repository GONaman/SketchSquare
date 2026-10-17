import { renderEmail } from './email.templates';

describe('renderEmail', () => {
  it('renders the welcome email', () => {
    const r = renderEmail({
      name: 'welcome',
      data: { to: 'a@b.c', fullName: 'Asha Rao' },
    });
    expect(r.subject).toBe('Welcome to SketchSquare');
    expect(r.html).toContain('Hi Asha Rao');
    expect(r.text).toContain('verified');
  });

  it('includes the rejection reason and escapes HTML', () => {
    const r = renderEmail({
      name: 'verification-rejected',
      data: { to: 'a@b.c', fullName: '<b>X</b>', note: 'Blurry "ID" <script>' },
    });
    expect(r.html).toContain('Blurry &quot;ID&quot; &lt;script&gt;');
    expect(r.html).not.toContain('<script>');
    expect(r.html).toContain('&lt;b&gt;X&lt;/b&gt;');
    expect(r.text).toContain('Reason: Blurry "ID" <script>');
  });

  it('includes both the reset link and the code', () => {
    const r = renderEmail({
      name: 'password-reset',
      data: {
        to: 'a@b.c',
        fullName: 'A',
        token: 'tok123',
        resetUrl: 'http://x/reset-password?token=tok123',
      },
    });
    expect(r.html).toContain('href="http://x/reset-password?token=tok123"');
    expect(r.text).toContain('Reset code: tok123');
  });

  it('renders the under-review email and escapes the title', () => {
    const r = renderEmail({
      name: 'drawing-under-review',
      data: { to: 'a@b.c', fullName: 'Asha', title: '<i>Villa</i>' },
    });
    expect(r.subject).toContain('under review');
    expect(r.html).toContain('&lt;i&gt;Villa&lt;/i&gt;');
    expect(r.html).not.toContain('<i>Villa');
    expect(r.text).toContain('"<i>Villa</i>"');
  });
});
