export const MAX_SHEET_BYTES = 50 * 1024 * 1024;
export const MAX_SHEETS_PER_DRAWING = 30;
export const SNIFF_BYTES = 4096;

export type SheetFileKind = 'pdf' | 'png' | 'jpg' | 'dwg' | 'dxf';

interface KindInfo {
  mime: string;
  extensions: string[];
  /** Content types a client may declare when requesting an upload URL. */
  declared: string[];
  previewable: boolean;
}

export const SHEET_KINDS: Record<SheetFileKind, KindInfo> = {
  pdf: {
    mime: 'application/pdf',
    extensions: ['pdf'],
    declared: ['application/pdf'],
    previewable: true,
  },
  png: {
    mime: 'image/png',
    extensions: ['png'],
    declared: ['image/png'],
    previewable: true,
  },
  jpg: {
    mime: 'image/jpeg',
    extensions: ['jpg', 'jpeg'],
    declared: ['image/jpeg', 'image/jpg'],
    previewable: true,
  },
  dwg: {
    mime: 'application/acad',
    extensions: ['dwg'],
    declared: [
      'application/acad',
      'application/x-acad',
      'application/dwg',
      'image/vnd.dwg',
      'application/octet-stream',
    ],
    previewable: false,
  },
  dxf: {
    mime: 'image/vnd.dxf',
    extensions: ['dxf'],
    declared: [
      'image/vnd.dxf',
      'application/dxf',
      'application/x-dxf',
      'application/octet-stream',
      'text/plain',
    ],
    previewable: false,
  },
};

export function extensionOf(fileName: string): string {
  const dot = fileName.lastIndexOf('.');
  return dot < 0 ? '' : fileName.slice(dot + 1).toLowerCase();
}

/** Kind implied by a file name's extension, or null when unsupported. */
export function kindFromFileName(fileName: string): SheetFileKind | null {
  const ext = extensionOf(fileName);
  const entry = (
    Object.entries(SHEET_KINDS) as [SheetFileKind, KindInfo][]
  ).find(([, info]) => info.extensions.includes(ext));
  return entry ? entry[0] : null;
}

/** Checks a client-declared content type against the kind implied by the file name. */
export function declaredTypeMatches(
  kind: SheetFileKind,
  contentType: string,
): boolean {
  return SHEET_KINDS[kind].declared.includes(contentType.toLowerCase());
}

/** Identifies a file by its leading bytes; never trusts the name or declared type. */
export function detectKind(head: Buffer): SheetFileKind | null {
  if (head.subarray(0, 5).toString('latin1') === '%PDF-') return 'pdf';
  if (
    head.length >= 8 &&
    head
      .subarray(0, 8)
      .equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))
  ) {
    return 'png';
  }
  if (
    head.length >= 3 &&
    head[0] === 0xff &&
    head[1] === 0xd8 &&
    head[2] === 0xff
  ) {
    return 'jpg';
  }
  // DWG: "AC" + 4-digit version (AC1015, AC1032, …)
  if (/^AC\d{4}/.test(head.subarray(0, 6).toString('latin1'))) return 'dwg';
  if (head.subarray(0, 18).toString('latin1') === 'AutoCAD Binary DXF') {
    return 'dxf';
  }
  const text = head.toString('latin1');
  if (/^\s*0\s*\r?\n\s*SECTION\b/.test(text)) return 'dxf';
  return null;
}

/** Strips path parts and unsafe characters so the name is safe inside an object key and a Content-Disposition. */
export function sanitizeFileName(fileName: string): string {
  const base = fileName.split(/[\\/]/).pop() ?? '';
  const cleaned = base
    .normalize('NFKD')
    .replace(/[^A-Za-z0-9._-]+/g, '_')
    .replace(/^[._]+/, '')
    .slice(-100);
  return cleaned || 'file';
}
