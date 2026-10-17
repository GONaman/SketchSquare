-- Constraints Prisma cannot express: CHECKs, partial unique index, triggers.

-- ---------- CHECK constraints ----------
ALTER TABLE "User"
  ADD CONSTRAINT "User_freeDownloadsUsed_check" CHECK ("freeDownloadsUsed" >= 0),
  ADD CONSTRAINT "User_architectRating_check" CHECK ("architectRating" >= 0 AND "architectRating" <= 5),
  ADD CONSTRAINT "User_architectRatingCount_check" CHECK ("architectRatingCount" >= 0);

ALTER TABLE "Drawing"
  ADD CONSTRAINT "Drawing_pricePaise_check" CHECK ("pricePaise" >= 0),
  ADD CONSTRAINT "Drawing_plotLengthFt_check" CHECK ("plotLengthFt" > 0),
  ADD CONSTRAINT "Drawing_plotBreadthFt_check" CHECK ("plotBreadthFt" > 0),
  ADD CONSTRAINT "Drawing_floors_check" CHECK ("floors" >= 1),
  ADD CONSTRAINT "Drawing_avgRating_check" CHECK ("avgRating" >= 0 AND "avgRating" <= 5),
  ADD CONSTRAINT "Drawing_counts_check" CHECK ("ratingCount" >= 0 AND "viewCount" >= 0 AND "purchaseCount" >= 0);

ALTER TABLE "DrawingSheet"
  ADD CONSTRAINT "DrawingSheet_sizeBytes_check" CHECK ("sizeBytes" >= 0);

ALTER TABLE "Purchase"
  ADD CONSTRAINT "Purchase_pricePaise_check" CHECK ("pricePaise" >= 0),
  ADD CONSTRAINT "Purchase_platformFeePaise_check" CHECK ("platformFeePaise" >= 0 AND "platformFeePaise" <= "pricePaise");

ALTER TABLE "Review"
  ADD CONSTRAINT "Review_rating_check" CHECK ("rating" BETWEEN 1 AND 5);

ALTER TABLE "Withdrawal"
  ADD CONSTRAINT "Withdrawal_amountPaise_check" CHECK ("amountPaise" > 0);

ALTER TABLE "LedgerEntry"
  ADD CONSTRAINT "LedgerEntry_amountPaise_check" CHECK ("amountPaise" <> 0),
  ADD CONSTRAINT "LedgerEntry_wallet_owner_check" CHECK ("accountType" <> 'USER_WALLET' OR "accountOwnerId" IS NOT NULL);

-- ---------- One PAID purchase per (buyer, drawing) ----------
CREATE UNIQUE INDEX "Purchase_buyerId_drawingId_paid_key"
  ON "Purchase" ("buyerId", "drawingId")
  WHERE "status" = 'PAID';

-- ---------- Drawing.plotAreaSqft is always length * breadth ----------
CREATE FUNCTION set_drawing_plot_area() RETURNS trigger AS $$
BEGIN
  NEW."plotAreaSqft" := NEW."plotLengthFt" * NEW."plotBreadthFt";
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "Drawing_plot_area_trg"
  BEFORE INSERT OR UPDATE ON "Drawing"
  FOR EACH ROW EXECUTE FUNCTION set_drawing_plot_area();

-- ---------- Ledger: append-only ----------
CREATE FUNCTION ledger_forbid_mutation() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'LedgerEntry is append-only (% not allowed)', TG_OP
    USING ERRCODE = 'integrity_constraint_violation';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "LedgerEntry_append_only_trg"
  BEFORE UPDATE OR DELETE ON "LedgerEntry"
  FOR EACH ROW EXECUTE FUNCTION ledger_forbid_mutation();

-- ---------- Ledger: every txnId must sum to zero at commit ----------
CREATE FUNCTION ledger_assert_balanced() RETURNS trigger AS $$
DECLARE
  total bigint;
BEGIN
  SELECT COALESCE(SUM("amountPaise"), 0) INTO total FROM "LedgerEntry" WHERE "txnId" = NEW."txnId";
  IF total <> 0 THEN
    RAISE EXCEPTION 'Ledger transaction % is unbalanced (sum = % paise)', NEW."txnId", total
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER "LedgerEntry_balanced_trg"
  AFTER INSERT ON "LedgerEntry"
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION ledger_assert_balanced();
