-- CreateEnum
CREATE TYPE "PlagiarismFlagStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateTable
CREATE TABLE "PlagiarismFlag" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "drawingId" UUID NOT NULL,
    "matchedDrawingId" UUID NOT NULL,
    "sheetId" UUID NOT NULL,
    "matchedSheetId" UUID NOT NULL,
    "hammingDistance" INTEGER NOT NULL,
    "status" "PlagiarismFlagStatus" NOT NULL DEFAULT 'PENDING',
    "reviewNote" TEXT,
    "reviewedById" UUID,
    "reviewedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PlagiarismFlag_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "PlagiarismFlag_drawingId_idx" ON "PlagiarismFlag"("drawingId");

-- CreateIndex
CREATE INDEX "PlagiarismFlag_status_createdAt_idx" ON "PlagiarismFlag"("status", "createdAt");

-- AddForeignKey
ALTER TABLE "PlagiarismFlag" ADD CONSTRAINT "PlagiarismFlag_drawingId_fkey" FOREIGN KEY ("drawingId") REFERENCES "Drawing"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlagiarismFlag" ADD CONSTRAINT "PlagiarismFlag_matchedDrawingId_fkey" FOREIGN KEY ("matchedDrawingId") REFERENCES "Drawing"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlagiarismFlag" ADD CONSTRAINT "PlagiarismFlag_sheetId_fkey" FOREIGN KEY ("sheetId") REFERENCES "DrawingSheet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlagiarismFlag" ADD CONSTRAINT "PlagiarismFlag_matchedSheetId_fkey" FOREIGN KEY ("matchedSheetId") REFERENCES "DrawingSheet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlagiarismFlag" ADD CONSTRAINT "PlagiarismFlag_reviewedById_fkey" FOREIGN KEY ("reviewedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

