-- Search performance (see docs/data-model.md "Search indexes"). Partial on PUBLISHED because search never reads other statuses.
-- Only the indexes that EXPLAIN showed to matter at 50k rows; size search is already served by Drawing(plotLengthFt, plotBreadthFt).

-- Case-insensitive city filter: WHERE lower("city") IN (...)
CREATE INDEX "Drawing_published_lower_city_idx" ON "Drawing" (lower("city")) WHERE "status" = 'PUBLISHED';

-- sort=drawing_rating: ORDER BY avgRating DESC, ratingCount DESC, createdAt DESC, id
CREATE INDEX "Drawing_published_rating_sort_idx"
  ON "Drawing" ("avgRating" DESC, "ratingCount" DESC, "createdAt" DESC, "id") WHERE "status" = 'PUBLISHED';

-- sort=popularity: ORDER BY purchaseCount DESC, viewCount DESC, createdAt DESC, id
CREATE INDEX "Drawing_published_popularity_sort_idx"
  ON "Drawing" ("purchaseCount" DESC, "viewCount" DESC, "createdAt" DESC, "id") WHERE "status" = 'PUBLISHED';
