import {
  declaredTypeMatches,
  detectKind,
  kindFromFileName,
  sanitizeFileName,
} from './sheet-files';

const buf = (...parts: (string | number[])[]) =>
  Buffer.concat(
    parts.map((p) =>
      typeof p === 'string' ? Buffer.from(p, 'latin1') : Buffer.from(p),
    ),
  );

describe('sheet file helpers', () => {
  it('detects kinds from magic bytes', () => {
    expect(detectKind(buf('%PDF-1.7\n'))).toBe('pdf');
    expect(
      detectKind(buf([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0])),
    ).toBe('png');
    expect(detectKind(buf([0xff, 0xd8, 0xff, 0xe0, 0]))).toBe('jpg');
    expect(detectKind(buf('AC1032\0\0\0'))).toBe('dwg');
    expect(detectKind(buf('  0\r\nSECTION\r\n  2\r\nHEADER'))).toBe('dxf');
    expect(detectKind(buf('AutoCAD Binary DXF\r\n\x1a\0'))).toBe('dxf');
  });

  it('rejects unknown or spoofed content', () => {
    expect(detectKind(buf('<html>%PDF-</html>'))).toBeNull();
    expect(detectKind(buf('MZ\x90\0'))).toBeNull();
    expect(detectKind(Buffer.alloc(0))).toBeNull();
    expect(detectKind(buf('ACXXXX'))).toBeNull();
    expect(detectKind(buf([0x89, 0x50, 0x4e]))).toBeNull();
  });

  it('maps extensions and declared types', () => {
    expect(kindFromFileName('Plan.PDF')).toBe('pdf');
    expect(kindFromFileName('a.b.jpeg')).toBe('jpg');
    expect(kindFromFileName('x.exe')).toBeNull();
    expect(kindFromFileName('noext')).toBeNull();
    expect(declaredTypeMatches('pdf', 'application/pdf')).toBe(true);
    expect(declaredTypeMatches('pdf', 'image/png')).toBe(false);
    expect(declaredTypeMatches('dwg', 'application/octet-stream')).toBe(true);
  });

  it('sanitises file names', () => {
    expect(sanitizeFileName('../../etc/pass wd.pdf')).toBe('pass_wd.pdf');
    expect(sanitizeFileName('C:\\x\\Floor plan (1).PNG')).toBe(
      'Floor_plan_1_.PNG',
    );
    expect(sanitizeFileName('...')).toBe('file');
    expect(sanitizeFileName('a'.repeat(300) + '.pdf').length).toBe(100);
  });
});
