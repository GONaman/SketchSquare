import { DrawingStatus } from '@prisma/client';
import { Job } from 'bullmq';
import { DrawingProcessingService } from './drawing-processing.service';
import { DrawingProcessor } from './drawing.processor';
import { ProcessDrawingJob } from './drawings.constants';

function makeProcessing(drawing: unknown) {
  const prisma = {
    drawing: {
      findUnique: jest.fn().mockResolvedValue(drawing),
      updateMany: jest.fn().mockResolvedValue({ count: 1 }),
    },
    $transaction: jest.fn(),
  };
  const storage = {
    getOriginalBuffer: jest.fn(),
    putPreview: jest.fn(),
  };
  const watermark = {
    renderImagePreview: jest.fn(),
    renderPdfPreview: jest.fn(),
  };
  const svc = new DrawingProcessingService(
    prisma as never,
    storage as never,
    watermark as never,
  );
  return { svc, prisma, storage, watermark };
}

describe('DrawingProcessingService', () => {
  it('skips drawings that are no longer PROCESSING', async () => {
    for (const d of [
      null,
      { status: DrawingStatus.REMOVED, sheets: [] },
      { status: DrawingStatus.PUBLISHED, sheets: [] },
    ]) {
      const { svc, storage } = makeProcessing(d);
      await expect(svc.process('d1')).resolves.toBe('skipped');
      expect(storage.getOriginalBuffer).not.toHaveBeenCalled();
    }
  });

  it('throws when there is no preview sheet', async () => {
    const { svc } = makeProcessing({
      status: DrawingStatus.PROCESSING,
      sheets: [{ id: 's', isPreview: false }],
      architect: { fullName: 'A' },
    });
    await expect(svc.process('d1')).rejects.toThrow('No preview sheets');
  });

  it('propagates render errors without touching the drawing status', async () => {
    const { svc, storage, prisma } = makeProcessing({
      status: DrawingStatus.PROCESSING,
      sheets: [
        {
          id: 's',
          isPreview: true,
          originalKey: 'k',
          originalMime: 'image/png',
        },
      ],
      architect: { fullName: 'A' },
    });
    storage.getOriginalBuffer.mockRejectedValue(new Error('NoSuchKey'));
    await expect(svc.process('d1')).rejects.toThrow('NoSuchKey');
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(storage.putPreview).not.toHaveBeenCalled();
  });

  it('markFailed only moves PROCESSING drawings and truncates the reason', async () => {
    const { svc, prisma } = makeProcessing(null);
    await svc.markFailed('d1', new Error('x'.repeat(900)));
    expect(prisma.drawing.updateMany).toHaveBeenCalledWith({
      where: { id: 'd1', status: 'PROCESSING' },
      data: { status: 'FAILED', failureReason: 'x'.repeat(500) },
    });
  });
});

describe('DrawingProcessor', () => {
  const job = (attemptsMade: number, attempts = 3) =>
    ({
      id: 'j1',
      attemptsMade,
      opts: { attempts },
      data: { drawingId: 'd1' },
    }) as unknown as Job<ProcessDrawingJob>;

  it('marks the drawing FAILED only after the last attempt', async () => {
    const processing = { markFailed: jest.fn(), process: jest.fn() };
    const processor = new DrawingProcessor(processing as never);
    await processor.onFailed(job(1), new Error('transient'));
    await processor.onFailed(job(2), new Error('transient'));
    expect(processing.markFailed).not.toHaveBeenCalled();
    await processor.onFailed(job(3), new Error('final'));
    expect(processing.markFailed).toHaveBeenCalledWith('d1', expect.any(Error));
  });

  it('delegates processing to the service', async () => {
    const processing = {
      process: jest.fn().mockResolvedValue('published'),
      markFailed: jest.fn(),
    };
    const processor = new DrawingProcessor(processing as never);
    await expect(processor.process(job(0))).resolves.toBe('published');
    expect(processing.process).toHaveBeenCalledWith('d1');
  });
});
