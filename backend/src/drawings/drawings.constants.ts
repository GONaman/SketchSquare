export const DRAWING_PROCESSING_QUEUE = 'drawing-processing';
export const PROCESS_DRAWING_JOB = 'process-drawing';
export const PROCESSING_ATTEMPTS = 3;
export const MIN_PREVIEW_SHEETS = 1;
export const MAX_PREVIEW_SHEETS = 2;

export interface ProcessDrawingJob {
  drawingId: string;
}
