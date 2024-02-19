CREATE TABLE IF NOT EXISTS `chartfiles` (
	`id` INTEGER PRIMARY KEY,
	`name` TEXT NOT NULL,
	`hash` TEXT,
	`set_id` INTEGER NOT NULL,
	`modified_at` INTEGER NOT NULL,
	`size` INTEGER,
	FOREIGN KEY (set_id) REFERENCES chartfile_sets(id) ON DELETE CASCADE,
	UNIQUE(`set_id`, `name`)
);

CREATE INDEX IF NOT EXISTS chartfiles_hash_idx ON chartfiles (`hash`);

CREATE TABLE IF NOT EXISTS `chartfile_sets` (
	`id` INTEGER PRIMARY KEY,
	`dir` TEXT,
	`name` TEXT NOT NULL,
	`modified_at` INTEGER NOT NULL,
	`is_file` INTEGER NOT NULL,
	`location_id` INTEGER NOT NULL,
	FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
	UNIQUE(`location_id`, `dir`, `name`)
);

CREATE TABLE IF NOT EXISTS `locations` (
	`id` INTEGER PRIMARY KEY,
	`path` TEXT NOT NULL UNIQUE,
	`name` TEXT NOT NULL,
	`is_relative` INTEGER NOT NULL,
	`is_internal` INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS `chartmetas` (
	`id` INTEGER PRIMARY KEY,
	`hash` TEXT NOT NULL,
	`index` INTEGER NOT NULL,
	`title` TEXT,
	`artist` TEXT,
	`name` TEXT,
	`creator` TEXT,
	`level` REAL,
	`inputmode` TEXT,
	`source` TEXT,
	`tags` TEXT,
	`format` TEXT,
	`audio_path` TEXT,
	`background_path` TEXT,
	`preview_time` REAL,
	`osu_beatmap_id` INTEGER,
	`osu_beatmapset_id` INTEGER,
	`osu_ranked_status` INTEGER,
	`tempo` REAL,
	`duration` REAL,
	`has_video` INTEGER,
	`has_storyboard` INTEGER,
	`has_subtitles` INTEGER,
	`has_negative_speed` INTEGER,
	`has_stacked_notes` INTEGER,
	`breaks_count` INTEGER,
	`played_at` INTEGER,
	`added_at` INTEGER,
	`created_at` INTEGER,
	`plays_count` INTEGER,
	`pitch` REAL,
	`audio_channels` INTEGER,
	`used_columns` INTEGER,
	`comment` TEXT,
	`chart_preview` TEXT,
	UNIQUE(`hash`, `index`)
);

CREATE INDEX IF NOT EXISTS chartmetas_inputmode_idx ON chartmetas (`inputmode`);
CREATE INDEX IF NOT EXISTS chartmetas_name_idx ON chartmetas (`name`);

CREATE TABLE IF NOT EXISTS `chartdiffs` (
	`id` INTEGER PRIMARY KEY,
	`hash` TEXT NOT NULL,
	`index` INTEGER NOT NULL,
	`modifiers` TEXT DEFAULT "",
	`rate` REAL DEFAULT 1.0,

	`inputmode` TEXT,
	`notes_count` INTEGER,
	`long_notes_count` INTEGER,
	`density_data` TEXT,
	`sv_data` TEXT,
	`enps_diff` REAL,
	`osu_diff` REAL,
	`msd_diff` REAL,
	`msd_diff_data` TEXT,
	`user_diff` REAL,
	`user_diff_data` TEXT,
	UNIQUE(`hash`, `index`, `modifiers`, `rate`)
);

CREATE TABLE IF NOT EXISTS `scores` (
	`id` INTEGER PRIMARY KEY,
	`hash` TEXT NOT NULL,
	`index` INTEGER NOT NULL,
	`modifiers` TEXT DEFAULT "",
	`rate` REAL DEFAULT 1.0,

	`const` INTEGER,
	`timings` TEXT,
	`single` INTEGER,

	`is_top` REAL DEFAULT 0,
	`time` REAL,
	`accuracy` REAL,
	`max_combo` REAL,
	`replay_hash` TEXT,
	`ratio` REAL,
	`perfect` REAL,
	`not_perfect` REAL,
	`miss` REAL,
	`mean` REAL,
	`earlylate` REAL,
	`pauses` REAL
);

CREATE INDEX IF NOT EXISTS scores_hash_index_idx ON scores (`hash`, `index`, `is_top`)
WHERE is_top = 1;

CREATE TABLE IF NOT EXISTS `collections` (
	`id` INTEGER PRIMARY KEY,
	`name` TEXT
);

CREATE TABLE IF NOT EXISTS `chart_collections` (
	`id` INTEGER PRIMARY KEY,
	`collection_id` INTEGER,
	`chartdiff_id` INTEGER
);

CREATE TEMP VIEW IF NOT EXISTS located_chartfiles AS
SELECT
chartfile_sets.location_id,
chartfile_sets.is_file AS set_is_file,
chartfile_sets.dir AS set_dir,
chartfile_sets.name AS set_name,
chartfiles.name AS chartfile_name,
chartfiles.*
FROM chartfiles
INNER JOIN chartfile_sets ON
chartfiles.set_id = chartfile_sets.id
;

CREATE TEMP VIEW IF NOT EXISTS chartviews AS
SELECT
chartmetas.id AS chartmeta_id,
chartfiles.id AS chartfile_id,
chartdiffs.id AS chartdiff_id,
chartfiles.set_id AS chartfile_set_id,
chartfile_sets.location_id,
chartfile_sets.is_file AS set_is_file,
chartfile_sets.dir AS set_dir,
chartfile_sets.name AS set_name,
chartfile_sets.modified_at AS set_modified_at,
chartfiles.name AS chartfile_name,
chartfiles.modified_at,
chartfiles.hash,
scores.accuracy,
scores.miss,
scores.time AS score_time,
chartmetas.*,
chartdiffs.modifiers,
chartdiffs.rate,
chartdiffs.inputmode AS chartdiff_inputmode,
chartdiffs.notes_count,
chartdiffs.long_notes_count,
chartdiffs.density_data,
chartdiffs.sv_data,
chartdiffs.enps_diff,
chartdiffs.osu_diff,
chartdiffs.msd_diff,
chartdiffs.msd_diff_data,
chartdiffs.user_diff,
chartdiffs.user_diff_data
FROM chartfiles
LEFT JOIN chartmetas ON
chartfiles.hash = chartmetas.hash
INNER JOIN chartfile_sets ON
chartfiles.set_id = chartfile_sets.id
LEFT JOIN chartdiffs ON
chartmetas.hash = chartdiffs.hash AND
chartmetas.`index` = chartdiffs.`index` AND
chartdiffs.modifiers = "" AND
chartdiffs.rate = 1.0
LEFT JOIN (
	SELECT
	hash, `index`, modifiers, rate,
	MIN(accuracy) AS accuracy,
	MIN(miss) AS miss,
	MAX(time) AS time
	FROM scores
	GROUP BY hash, `index`, modifiers, rate
) scores ON
chartmetas.hash = scores.hash AND
chartmetas.`index` = scores.`index` AND
scores.modifiers = "" AND
scores.rate = 1.0
;

CREATE TEMP VIEW IF NOT EXISTS chartdiffviews AS
SELECT
chartmetas.id AS chartmeta_id,
chartfiles.id AS chartfile_id,
chartdiffs.id AS chartdiff_id,
chartfiles.set_id AS chartfile_set_id,
chartfile_sets.location_id,
chartfile_sets.is_file AS set_is_file,
chartfile_sets.dir AS set_dir,
chartfile_sets.name AS set_name,
chartfile_sets.modified_at AS set_modified_at,
chartfiles.name AS chartfile_name,
chartfiles.modified_at,
chartfiles.hash,
scores.accuracy,
scores.miss,
scores.time AS score_time,
chartmetas.*,
chartdiffs.modifiers,
chartdiffs.rate,
chartdiffs.inputmode AS chartdiff_inputmode,
chartdiffs.notes_count,
chartdiffs.long_notes_count,
chartdiffs.density_data,
chartdiffs.sv_data,
chartdiffs.enps_diff,
chartdiffs.osu_diff,
chartdiffs.msd_diff,
chartdiffs.msd_diff_data,
chartdiffs.user_diff,
chartdiffs.user_diff_data
FROM chartfiles
LEFT JOIN chartmetas ON
chartfiles.hash = chartmetas.hash
INNER JOIN chartfile_sets ON
chartfiles.set_id = chartfile_sets.id
LEFT JOIN chartdiffs ON
chartmetas.hash = chartdiffs.hash AND
chartmetas.`index` = chartdiffs.`index`
LEFT JOIN (
	SELECT
	hash, `index`, modifiers, rate,
	MIN(accuracy) AS accuracy,
	MIN(miss) AS miss,
	MAX(time) AS time
	FROM scores
	GROUP BY hash, `index`, modifiers, rate
) scores ON
chartmetas.hash = scores.hash AND
chartmetas.`index` = scores.`index` AND
chartdiffs.modifiers = scores.modifiers AND
chartdiffs.rate = scores.rate
;

CREATE TEMP VIEW IF NOT EXISTS scores_list AS
SELECT
scores.id AS score_id,
scores.*,
chartdiffs.enps_diff AS difficulty,
chartdiffs.hash,
chartdiffs.`index`,
chartdiffs.modifiers,
chartdiffs.rate,
chartdiffs.inputmode,
chartdiffs.notes_count,
chartdiffs.long_notes_count,
chartdiffs.density_data,
chartdiffs.sv_data,
chartdiffs.enps_diff,
chartdiffs.osu_diff,
chartdiffs.msd_diff,
chartdiffs.msd_diff_data,
chartdiffs.user_diff,
chartdiffs.user_diff_data
FROM scores
LEFT JOIN chartdiffs ON
scores.hash = chartdiffs.hash AND
scores.`index` = chartdiffs.`index` AND
scores.modifiers = chartdiffs.modifiers AND
scores.rate = chartdiffs.rate
;
