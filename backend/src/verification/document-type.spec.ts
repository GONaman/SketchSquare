import { detectDocument } from './document-type';

describe('detectDocument', () => {
  it('detects PDF, JPEG and PNG by magic bytes', () => {
    expect(detectDocument(Buffer.from('%PDF-1.7 ...'))?.ext).toBe('pdf');
    expect(detectDocument(Buffer.from([0xff, 0xd8, 0xff, 0xe0]))?.ext).toBe(
      'jpg',
    );
    expect(
      detectDocument(
        Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0]),
      )?.mime,
    ).toBe('image/png');
  });

  it('rejects everything else', () => {
    expect(detectDocument(Buffer.from('MZ\x90\x00 an exe'))).toBeNull();
    expect(detectDocument(Buffer.from('<html>'))).toBeNull();
    expect(detectDocument(Buffer.alloc(0))).toBeNull();
  });
});
