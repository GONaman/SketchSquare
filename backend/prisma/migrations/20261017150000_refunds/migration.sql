-- Admin refunds (Part 3) + reserved TAX ledger values (docs/DECISIONS.md RF7). Additive only.

-- CreateEnum
CREATE TYPE "RefundProviderStatus" AS ENUM ('PENDING', 'SUCCEEDED', 'FAILED');

-- AlterEnum: reserved so GST/TCS/TDS can be booked later without another enum migration; nothing writes them yet.
ALTER TYPE "LedgerAccountType" ADD VALUE 'TAX';
ALTER TYPE "LedgerEntryType" ADD VALUE 'TAX';

-- CreateTable
CREATE TABLE "Refund" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "purchaseId" UUID NOT NULL,
    "adminId" UUID NOT NULL,
    "reason" TEXT NOT NULL,
    "amountPaise" INTEGER NOT NULL,
    "ledgerTxnId" UUID NOT NULL,
    "providerStatus" "RefundProviderStatus" NOT NULL DEFAULT 'PENDING',
    "providerRefundId" TEXT,
    "providerError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Refund_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Refund_purchaseId_key" ON "Refund"("purchaseId");

-- CreateIndex
CREATE INDEX "Refund_adminId_idx" ON "Refund"("adminId");

-- CreateIndex
CREATE INDEX "Refund_createdAt_idx" ON "Refund"("createdAt");

-- AddForeignKey
ALTER TABLE "Refund" ADD CONSTRAINT "Refund_purchaseId_fkey" FOREIGN KEY ("purchaseId") REFERENCES "Purchase"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Refund" ADD CONSTRAINT "Refund_adminId_fkey" FOREIGN KEY ("adminId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Refund" ADD CONSTRAINT "Refund_amountPaise_check" CHECK ("amountPaise" > 0);
