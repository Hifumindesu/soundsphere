ALTER TABLE scores RENAME TO temp;
CREATE TABLE IF NOT EXISTS `scores` (
	`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	...
);
INSERT INTO scores(
	id,
	...
)
SELECT
	id,
	...
FROM temp;
DROP TABLE temp;
