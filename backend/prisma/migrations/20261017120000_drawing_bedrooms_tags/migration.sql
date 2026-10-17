-- Additive: optional bedrooms/tags on Drawing (U1) and one registration per stored object per drawing (idempotent sheet registration).
ALTER TABLE "Drawing"
  ADD COLUMN "bedrooms" INTEGER,
  ADD COLUMN "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
  ADD CONSTRAINT "Drawing_bedrooms_check" CHECK ("bedrooms" IS NULL OR ("bedrooms" >= 0 AND "bedrooms" <= 20));

CREATE UNIQUE INDEX "DrawingSheet_drawingId_originalKey_key" ON "DrawingSheet"("drawingId", "originalKey");
