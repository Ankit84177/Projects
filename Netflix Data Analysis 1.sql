-- ******************************************
# Netflix Data Analysis
-- ******************************************

Create database Netflix;
use netflix;

select * from netflix_movies;

SELECT * FROM netflix_movies LIMIT 10;

-- =========================================
# List all Movies
-- =========================================

SELECT * FROM netflix_movies WHERE type = 'Movie';

-- ==============================================
# Count of TV Shows and Movies
-- ===============================================

SELECT type, COUNT(*) AS total FROM netflix_movies GROUP BY type;

-- ================================================
# List distinct countries
-- =================================================

SELECT DISTINCT country FROM netflix_movies ORDER BY country;

-- =========================================================
# Top 10 Most Frequent Directors
-- ==========================================================

SELECT director, COUNT(*) AS total
FROM netflix_movies
WHERE director IS NOT NULL
GROUP BY director
ORDER BY total DESC
LIMIT 10;

-- ======================================================
# Shows added in 2020
-- ========================================================

SELECT * FROM netflix_movies
WHERE YEAR(date_added) = 2020;

-- =======================================================
# Show count per year
-- ========================================================

SELECT release_year, COUNT(*) AS total
FROM netflix_movies
GROUP BY release_year
ORDER BY release_year;

-- ======================================================
# Most popular genre
-- ======================================================

SELECT listed_in, COUNT(*) AS total
FROM netflix_movies
GROUP BY listed_in
ORDER BY total DESC
LIMIT 1;

-- =======================================================
# Find movies longer than 2 hours
-- =========================================================

SELECT title, duration
FROM netflix_movies
WHERE type = 'Movie' AND duration LIKE '%min'
AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 120;

-- ===========================================================
# Find all shows without a listed director
-- =============================================================

SELECT * FROM netflix_movies
WHERE director IS NULL;

-- =============================================================
# Shows available in India
-- ===========================================================

SELECT * FROM netflix_movies
WHERE country LIKE '%India%';

-- ==============================================================
# Recent Additions
-- ===============================================================

SELECT title, date_added
FROM netflix_movies
ORDER BY date_added DESC
LIMIT 5;

-- ===============================================================
# Which year saw the highest number of show releases on Netflix?
-- ===============================================================

SELECT release_year, COUNT(*) AS total_releases
FROM netflix_movies
GROUP BY release_year
ORDER BY total_releases DESC
LIMIT 5;

-- ====================================================================
# Top 10 Actors appearing in the greatest number of shows and movies.
-- ====================================================================

SELECT actor, COUNT(*) as total_appearances
FROM (
  SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(cast, ',', numbers.n), ',', -1)) AS actor
  FROM netflix_movies
  JOIN (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
    SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
    SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
  ) numbers ON CHAR_LENGTH(cast) - CHAR_LENGTH(REPLACE(cast, ',', '')) >= numbers.n - 1
  WHERE cast IS NOT NULL
) AS actors
GROUP BY actor
ORDER BY total_appearances DESC
LIMIT 10;

-- =================================================================================================================
#📌 Insight: Extract and count multiple actors from a column in MySQL using a dynamic string-splitting approach.
-- ==========================================================================
# Top 10 Countries where the highest number of shows/movies are available."
-- ===========================================================================

SELECT country, COUNT(*) AS total
FROM netflix_movies
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total DESC
LIMIT 10;

-- =========================================================================
# Movies with runtime greater than 2 hours
-- =========================================================================

SELECT title, duration
FROM netflix_movies
WHERE type = 'Movie' AND duration LIKE '%min'
AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 120;

-- ===========================================================================
# TV Shows with more than 3 seasons
-- ===========================================================================

SELECT title, duration
FROM netflix_movies
WHERE type = 'TV Show' AND duration LIKE '%Season%'
AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 3;

-- =========================================================================
# Kids-friendly content (rating = 'TV-Y' or 'G')
-- ==========================================================================

SELECT title, rating
FROM netflix_movies
WHERE rating IN ('TV-Y', 'G', 'TV-G', 'PG')
ORDER BY release_year DESC;

-- ==========================================================================
# Shows with "Crime" genre
-- =========================================================================

SELECT title, listed_in
FROM netflix_movies
WHERE listed_in LIKE '%Crime%';

-- ============================================================================
# Count by Rating Category 
-- ============================================================================

SELECT rating, COUNT(*) AS total
FROM netflix_movies
GROUP BY rating
ORDER BY total DESC;

-- =========================================================================
# Missing values profile (counts & percentages)
-- ==========================================================================

WITH total AS (
  SELECT COUNT(*) AS n FROM netflix_movies
)
SELECT
  'director' AS column_name,
  SUM(CASE WHEN director IS NULL OR director = '' THEN 1 ELSE 0 END) AS null_count,
  ROUND(100 * SUM(CASE WHEN director IS NULL OR director = '' THEN 1 ELSE 0 END) / (SELECT n FROM total), 2) AS null_pct
FROM netflix_movies
UNION ALL
SELECT
  'cast',
  SUM(CASE WHEN cast IS NULL OR cast = '' THEN 1 ELSE 0 END) AS null_count,
  ROUND(100 * SUM(CASE WHEN cast IS NULL OR cast = '' THEN 1 ELSE 0 END) / (SELECT n FROM total), 2) AS null_pct
FROM netflix_movies
UNION ALL
SELECT
  'country',
  SUM(CASE WHEN country IS NULL OR country = '' THEN 1 ELSE 0 END) AS null_count,
  ROUND(100 * SUM(CASE WHEN country IS NULL OR country = '' THEN 1 ELSE 0 END) / (SELECT n FROM total), 2) AS null_pct
FROM netflix_movies
UNION ALL
SELECT
  'listed_in (genres)',
  SUM(CASE WHEN listed_in IS NULL OR listed_in = '' THEN 1 ELSE 0 END) AS null_count,
  ROUND(100 * SUM(CASE WHEN listed_in IS NULL OR listed_in = '' THEN 1 ELSE 0 END) / (SELECT n FROM total), 2) AS null_pct
FROM netflix_movies;

-- ================================================================================
# Normalize country names: trim spaces; unify 'United States' variants, etc.
-- ================================================================================

-- ************************************************************************
-- (Preview only; adapt updates based on your data)
-- ************************************************************************

SELECT DISTINCT TRIM(country) AS country_norm, COUNT(*) AS cnt
FROM netflix_movies
GROUP BY TRIM(country)
ORDER BY cnt DESC;


# $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example update (commented; enable carefully after verifying values)
-- UPDATE netflix_movies SET country = TRIM(country);
-- UPDATE netflix_movies SET country = 'United States'
-- WHERE country IN ('USA','U.S.A.','United States of America');
# $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


-- 1.3 Build normalized GENRE table from `listed_in` (comma-separated)
--    - Titles can have multiple genres; we create a bridge table.

-- ************************************************************************
-- Drop helper objects if re-running
-- ************************************************************************

# SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS title_genres;
DROP TABLE IF EXISTS genres_dim;
# SET FOREIGN_KEY_CHECKS = 1;

SHOW TABLES LIKE 'title_genres';

-- ************************************************************************
-- Create target tables
-- ************************************************************************

CREATE TABLE genres_dim (
  genre_id INT AUTO_INCREMENT PRIMARY KEY,
  genre_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE title_genres (
  show_id VARCHAR(15),
  genre_id INT,
  PRIMARY KEY (show_id, genre_id),
  FOREIGN KEY (genre_id) REFERENCES genres_dim(genre_id)
);

-- ************************************************************************
-- Insert distinct genres into genres_dim using a recursive splitter
-- ************************************************************************

WITH RECURSIVE split AS (
  SELECT show_id, TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
         SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS rest
  FROM netflix_movies
  WHERE listed_in IS NOT NULL AND listed_in <> ''

  UNION ALL

  SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS genre,
         SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
  FROM split
  WHERE rest IS NOT NULL AND rest <> ''
)
SELECT 1;   -- anchor for some clients

INSERT IGNORE INTO genres_dim (genre_name)
SELECT DISTINCT genre FROM (
  WITH RECURSIVE split AS (
    SELECT show_id, TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
           SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS rest
    FROM netflix_movies
    WHERE listed_in IS NOT NULL AND listed_in <> ''

    UNION ALL

    SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS genre,
           SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
    FROM split
    WHERE rest IS NOT NULL AND rest <> ''
  )
  SELECT genre FROM split WHERE genre IS NOT NULL AND genre <> ''
) g;

-- ************************************************************************
-- Populate bridge table title_genres
-- ************************************************************************

INSERT IGNORE INTO title_genres (show_id, genre_id)
SELECT s.show_id, d.genre_id
FROM (
  WITH RECURSIVE split AS (
    SELECT show_id, TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
           SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS rest
    FROM netflix_movies
    WHERE listed_in IS NOT NULL AND listed_in <> ''

    UNION ALL

    SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS genre,
           SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
    FROM split
    WHERE rest IS NOT NULL AND rest <> ''
  )
  SELECT show_id, genre FROM split WHERE genre IS NOT NULL AND genre <> ''
) s
JOIN genres_dim d ON d.genre_name = s.genre;

-- =============================================================
-- 2) CORE EXPLORATORY QUERIES (enriched)
-- =============================================================

-- ************************************************************************
-- 2.1 Count of TV Shows vs Movies
-- ************************************************************************

SELECT type, COUNT(*) AS total
FROM netflix_movies
GROUP BY type
ORDER BY total DESC;

-- ************************************************************************
-- 2.2 Country-wise content count (top 10)
-- ************************************************************************

SELECT country, COUNT(*) AS total
FROM netflix_movies
WHERE country IS NOT NULL AND country <> ''
GROUP BY country
ORDER BY total DESC
LIMIT 10;

-- ************************************************************************
-- 2.3 Year-wise additions (by date_added) & releases (by release_year)
-- ************************************************************************

SELECT YEAR(date_added) AS added_year, COUNT(*) AS titles_added
FROM netflix_movies
WHERE date_added IS NOT NULL
GROUP BY YEAR(date_added)
ORDER BY added_year;

SELECT release_year, COUNT(*) AS titles_released
FROM netflix_movies
GROUP BY release_year
ORDER BY release_year;

-- ************************************************************************
-- 2.4 Longest Movies (> 120 mins)
-- ************************************************************************

SELECT title, duration
FROM netflix_movies
WHERE type = 'Movie' AND duration LIKE '%min'
  AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 120
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC;

-- =============================================================
-- 3) ADVANCED ANALYTICS (CTEs & WINDOW FUNCTIONS)
-- =============================================================

-- ************************************************************************
-- 3.1 Top Genres Overall (using normalized tables)
-- ************************************************************************

SELECT d.genre_name, COUNT(*) AS total_titles
FROM title_genres tg
JOIN genres_dim d ON d.genre_id = tg.genre_id
GROUP BY d.genre_name
ORDER BY total_titles DESC
LIMIT 15;

-- ************************************************************************
-- 3.2 Top Genre per Year (by release_year)
-- ************************************************************************

WITH genre_year AS (
  SELECT m.release_year, d.genre_name, COUNT(*) AS cnt
  FROM title_genres tg
  JOIN genres_dim d ON d.genre_id = tg.genre_id
  JOIN netflix_movies m ON m.show_id = tg.show_id
  WHERE m.release_year IS NOT NULL
  GROUP BY m.release_year, d.genre_name
),
ranked AS (
  SELECT
    release_year, genre_name, cnt,
    DENSE_RANK() OVER (PARTITION BY release_year ORDER BY cnt DESC) AS rnk
  FROM genre_year
)
SELECT release_year, genre_name, cnt
FROM ranked
WHERE rnk = 1
ORDER BY release_year;

-- ************************************************************************
-- 3.3 Monthly Additions Trend (across all years)
-- ************************************************************************

SELECT DATE_FORMAT(date_added, '%Y-%m') AS yyyymm, COUNT(*) AS titles_added
FROM netflix_movies
WHERE date_added IS NOT NULL
GROUP BY DATE_FORMAT(date_added, '%Y-%m')
ORDER BY yyyymm;

-- ************************************************************************
-- 3.4 Running Total of Releases (by release_year)
-- ************************************************************************

WITH by_year AS (
  SELECT release_year, COUNT(*) AS cnt
  FROM netflix_movies
  GROUP BY release_year
)
SELECT
  release_year,
  cnt,
  SUM(cnt) OVER (ORDER BY release_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM by_year
ORDER BY release_year;

-- ************************************************************************
-- 3.5 Director Rankings (by number of titles) + Percent Contribution
-- ************************************************************************

WITH counts AS (
  SELECT director, COUNT(*) AS n
  FROM netflix_movies
  WHERE director IS NOT NULL AND director <> ''
  GROUP BY director
),
tot AS (SELECT SUM(n) AS s FROM counts)
SELECT
  director, n,
  ROUND(100 * n / (SELECT s FROM tot), 2) AS pct_of_all_titles,
  DENSE_RANK() OVER (ORDER BY n DESC) AS director_rank
FROM counts
ORDER BY n DESC
LIMIT 25;

-- ************************************************************************
-- 3.6 Country-wise Genre Preference (top genre by country)
-- ************************************************************************

WITH country_genre AS (
  SELECT m.country, d.genre_name, COUNT(*) AS cnt
  FROM netflix_movies m
  JOIN title_genres tg ON tg.show_id = m.show_id
  JOIN genres_dim d ON d.genre_id = tg.genre_id
  WHERE m.country IS NOT NULL AND m.country <> ''
  GROUP BY m.country, d.genre_name
),
r AS (
  SELECT
    country, genre_name, cnt,
    DENSE_RANK() OVER (PARTITION BY country ORDER BY cnt DESC) AS rnk
  FROM country_genre
)
SELECT country, genre_name AS top_genre, cnt
FROM r
WHERE rnk = 1
ORDER BY cnt DESC;

-- ************************************************************************
-- 3.7 Longest & Shortest Content per Type (Movie/TV Show)
-- ************************************************************************

WITH dur AS (
  SELECT
    show_id, title, type,
    CASE
      WHEN duration LIKE '%min' THEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED)
      WHEN duration LIKE '%Season%' OR duration LIKE '%Seasons%' THEN NULL
      ELSE NULL
    END AS minutes
  FROM netflix_movies
)
SELECT type, title, minutes
FROM (
  SELECT
    type, title, minutes,
    ROW_NUMBER() OVER (PARTITION BY type ORDER BY minutes DESC) AS rn_desc,
    ROW_NUMBER() OVER (PARTITION BY type ORDER BY minutes ASC)  AS rn_asc
  FROM dur
  WHERE minutes IS NOT NULL
) x
WHERE rn_desc = 1 OR rn_asc = 1
ORDER BY type, minutes DESC;

-- =============================================================
-- 4) ACTOR/DIRECTOR COLLABORATIONS (string split via recursive CTE)
-- =============================================================

-- ************************************************************************
-- Build PEOPLE bridge: split `cast` into individual names
-- ************************************************************************
DROP TABLE IF EXISTS people_dim;
DROP TABLE IF EXISTS title_people;

CREATE TABLE people_dim (
  person_id INT AUTO_INCREMENT PRIMARY KEY,
  person_name VARCHAR(200) NOT NULL UNIQUE
);

CREATE TABLE title_people (
  show_id VARCHAR(15),
  person_id INT,
  role_type ENUM('Actor','Director') DEFAULT 'Actor',
  PRIMARY KEY (show_id, person_id, role_type),
  FOREIGN KEY (person_id) REFERENCES people_dim(person_id)
);
-- ************************************************************************
-- Insert actors from `cast`
-- ************************************************************************

INSERT IGNORE INTO people_dim (person_name)
SELECT DISTINCT TRIM(actor) FROM (
  WITH RECURSIVE split_cast AS (
    SELECT show_id, TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS actor,
           SUBSTRING(cast, LENGTH(SUBSTRING_INDEX(cast, ',', 1)) + 2) AS rest
    FROM netflix_movies
    WHERE cast IS NOT NULL AND cast <> ''

    UNION ALL

    SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS actor,
           SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
    FROM split_cast
    WHERE rest IS NOT NULL AND rest <> ''
  )
  SELECT actor FROM split_cast WHERE actor IS NOT NULL AND actor <> ''
) a;
-- ************************************************************************
-- Insert director names
-- ************************************************************************

INSERT IGNORE INTO people_dim (person_name)
SELECT DISTINCT TRIM(director) FROM netflix_movies
WHERE director IS NOT NULL AND director <> '';
-- ************************************************************************
-- Map actors to titles
-- ************************************************************************

INSERT IGNORE INTO title_people (show_id, person_id, role_type)
SELECT s.show_id, p.person_id, 'Actor'
FROM (
  WITH RECURSIVE split_cast AS (
    SELECT show_id, TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS actor,
           SUBSTRING(cast, LENGTH(SUBSTRING_INDEX(cast, ',', 1)) + 2) AS rest
    FROM netflix_movies
    WHERE cast IS NOT NULL AND cast <> ''

    UNION ALL

    SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS actor,
           SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
    FROM split_cast
    WHERE rest IS NOT NULL AND rest <> ''
  )
  SELECT show_id, actor FROM split_cast WHERE actor IS NOT NULL AND actor <> ''
) s
JOIN people_dim p ON p.person_name = s.actor;

-- ************************************************************************
-- Map directors to titles
-- ************************************************************************

INSERT IGNORE INTO title_people (show_id, person_id, role_type)
SELECT m.show_id, p.person_id, 'Director'
FROM netflix_movies m
JOIN people_dim p ON p.person_name = m.director
WHERE m.director IS NOT NULL AND m.director <> '';

-- ************************************************************************
-- 4.1 Most frequent Director–Actor collaborations
-- ************************************************************************

WITH da AS (
  SELECT tpD.person_id AS director_id, tpA.person_id AS actor_id, COUNT(*) AS cnt
  FROM title_people tpD
  JOIN title_people tpA
    ON tpD.show_id = tpA.show_id
   AND tpD.role_type = 'Director'
   AND tpA.role_type = 'Actor'
  GROUP BY tpD.person_id, tpA.person_id
)
SELECT d.person_name AS director, a.person_name AS actor, cnt AS titles_together
FROM da
JOIN people_dim d ON d.person_id = director_id
JOIN people_dim a ON a.person_id = actor_id
ORDER BY cnt DESC
LIMIT 20;

-- =============================================================
-- 5) RECENT ADDITIONS & SNAPSHOTS
-- =============================================================

-- ************************************************************************
-- 5.1 Latest 20 additions by date_added
-- ************************************************************************

SELECT title, type, date_added, rating
FROM netflix_movies
WHERE date_added IS NOT NULL
ORDER BY date_added DESC
LIMIT 20;

-- ************************************************************************
-- 5.2 Content available in India (sample)
-- ************************************************************************

SELECT * FROM netflix_movies
WHERE country LIKE '%India%';

-- ************************************************************************
-- 5.3 Directors with most Movies vs TV Shows (pivot-like)
-- ************************************************************************

WITH counts AS (
  SELECT director, type, COUNT(*) AS n
  FROM netflix_movies
  WHERE director IS NOT NULL AND director <> ''
  GROUP BY director, type
)
SELECT
  director,
  SUM(CASE WHEN type = 'Movie' THEN n ELSE 0 END) AS movie_count,
  SUM(CASE WHEN type = 'TV Show' THEN n ELSE 0 END) AS tv_count,
  (SUM(CASE WHEN type = 'Movie' THEN n ELSE 0 END) +
   SUM(CASE WHEN type = 'TV Show' THEN n ELSE 0 END)) AS total_titles
FROM counts
GROUP BY director
ORDER BY total_titles DESC
LIMIT 20;


 SELECT release_year, COUNT(*) AS titles FROM netflix_movies GROUP BY release_year;
 
 -- ************************************************************************
 -- Optional but recommended for speed
 -- ************************************************************************
 
CREATE INDEX ix_nm_release_year ON netflix_movies (release_year);
CREATE INDEX ix_nm_date_added   ON netflix_movies (date_added);
CREATE INDEX ix_nm_country      ON netflix_movies (country(100));
CREATE INDEX ix_nm_rating       ON netflix_movies (rating);
CREATE INDEX ix_nm_type         ON netflix_movies (type);

-- =====================================================================
# 1) Rating Distribution & Trends
-- =====================================================================

-- ************************************************************************
-- 1.1 Overall rating distribution
-- ************************************************************************

SELECT rating, COUNT(*) AS total
FROM netflix_movies
GROUP BY rating
ORDER BY total DESC;

-- ************************************************************************
-- 1.2 Country-wise most common rating (top rating per country)
-- ************************************************************************

WITH cnt AS (
  SELECT country, rating, COUNT(*) AS n
  FROM netflix_movies
  WHERE country IS NOT NULL AND country <> ''
  GROUP BY country, rating
),
r AS (
  SELECT country, rating, n,
         DENSE_RANK() OVER (PARTITION BY country ORDER BY n DESC) AS rnk
  FROM cnt
)
SELECT country, rating AS top_rating, n AS titles
FROM r
WHERE rnk = 1
ORDER BY titles DESC;

-- ************************************************************************
-- 1.3 Year-wise rating trend
-- ************************************************************************

SELECT release_year, rating, COUNT(*) AS titles
FROM netflix_movies
WHERE release_year IS NOT NULL
GROUP BY release_year, rating
ORDER BY release_year, titles DESC;

-- ==========================================================================
# 2) Release vs Added Date: Gap Analysis
-- ==========================================================================

-- ************************************************************************
-- 2.1 Year gap (release_year → added year)
-- ************************************************************************

SELECT
  title, release_year,
  YEAR(date_added) AS added_year,
  (YEAR(date_added) - release_year) AS year_gap
FROM netflix_movies
WHERE date_added IS NOT NULL AND release_year IS NOT NULL
ORDER BY year_gap DESC, added_year DESC;

-- ***********************************************************************************
-- 2.2 Average gap by genre (using listed_in direct; normalized tables not required)
-- ***********************************************************************************

WITH RECURSIVE g AS (
  SELECT show_id, TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
         SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS rest
  FROM netflix_movies WHERE listed_in IS NOT NULL AND listed_in <> ''
  UNION ALL
  SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS genre,
         SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
  FROM g WHERE rest IS NOT NULL AND rest <> ''
)
SELECT
  g.genre,
  AVG(YEAR(m.date_added) - m.release_year) AS avg_year_gap,
  COUNT(*) AS titles
FROM g
JOIN netflix_movies m USING (show_id)
WHERE m.date_added IS NOT NULL AND m.release_year IS NOT NULL AND g.genre <> ''
GROUP BY g.genre
HAVING COUNT(*) >= 5
ORDER BY avg_year_gap DESC;

-- =========================================================================
# 3) Genre Combination Analysis
-- =========================================================================

-- *************************************
-- 3.1 Multi-genre titles count
-- ************************************

SELECT
  title,
  listed_in,
  (LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', '')) + 1) AS genre_count
FROM netflix_movies
WHERE listed_in IS NOT NULL AND listed_in <> ''
ORDER BY genre_count DESC, title;

-- **********************************************
-- 3.2 Most common genre pairs (unordered)
-- **********************************************

WITH RECURSIVE split AS (
  SELECT show_id, TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS g1,
         SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS rest
  FROM netflix_movies WHERE listed_in IS NOT NULL AND listed_in <> ''
  UNION ALL
  SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS g1,
         SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
  FROM split WHERE rest IS NOT NULL AND rest <> ''
),
dedup AS (
  SELECT show_id, g1 FROM split WHERE g1 <> ''
),
pairs AS (
  SELECT a.show_id,
         LEAST(a.g1, b.g1) AS g_small,
         GREATEST(a.g1, b.g1) AS g_big
  FROM dedup a
  JOIN dedup b ON a.show_id = b.show_id AND a.g1 < b.g1
)
SELECT g_small AS genre_a, g_big AS genre_b, COUNT(*) AS pair_count
FROM pairs
GROUP BY g_small, g_big
ORDER BY pair_count DESC
LIMIT 25;

-- ====================================================================
# 4) Seasonal / Monthly Trends
-- ====================================================================

-- *****************************************************
-- 4.1 Titles added by month across years (YYYY-MM)
-- *****************************************************

SELECT DATE_FORMAT(date_added, '%Y-%m') AS ym, COUNT(*) AS titles_added
FROM netflix_movies
WHERE date_added IS NOT NULL
GROUP BY DATE_FORMAT(date_added, '%Y-%m')
ORDER BY ym;

-- *******************************************
-- 4.2 Month-of-year seasonality (Jan..Dec)
-- *******************************************

SELECT MONTH(date_added) AS month_num, COUNT(*) AS titles_added
FROM netflix_movies
WHERE date_added IS NOT NULL
GROUP BY MONTH(date_added)
ORDER BY month_num;

-- ==================================================================
#  Cast Popularity Ranking (most frequent actors)
-- ==================================================================

WITH RECURSIVE split_cast AS (
  SELECT show_id, TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS actor,
         SUBSTRING(cast, LENGTH(SUBSTRING_INDEX(cast, ',', 1)) + 2) AS rest
  FROM netflix_movies WHERE cast IS NOT NULL AND cast <> ''
  UNION ALL
  SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS actor,
         SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
  FROM split_cast WHERE rest IS NOT NULL AND rest <> ''
)
SELECT actor, COUNT(*) AS titles
FROM split_cast
WHERE actor IS NOT NULL AND actor <> ''
GROUP BY actor
ORDER BY titles DESC
LIMIT 50;

-- ========================================================================
#  Actor-wise Genre Preference
-- ========================================================================

WITH RECURSIVE a AS (
  SELECT show_id, TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS actor,
         SUBSTRING(cast, LENGTH(SUBSTRING_INDEX(cast, ',', 1)) + 2) AS rest
  FROM netflix_movies WHERE cast IS NOT NULL AND cast <> ''
  UNION ALL
  SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS actor,
         SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
  FROM a WHERE rest IS NOT NULL AND rest <> ''
),
g AS (
  SELECT show_id, TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
         SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS rest
  FROM netflix_movies WHERE listed_in IS NOT NULL AND listed_in <> ''
  UNION ALL
  SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS genre,
         SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
  FROM g WHERE rest IS NOT NULL AND rest <> ''
),
ag AS (
  SELECT a.actor, g.genre FROM a JOIN g USING (show_id)
  WHERE a.actor <> '' AND g.genre <> ''
)
SELECT actor, genre, COUNT(*) AS titles
FROM ag
GROUP BY actor, genre
HAVING COUNT(*) >= 3
ORDER BY titles DESC
LIMIT 50;

-- ===================================================================================
#  Country-wise Genre Preference (top genre for each country)
-- ===================================================================================

WITH RECURSIVE g AS (
  SELECT show_id, TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
         SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS rest
  FROM netflix_movies WHERE listed_in IS NOT NULL AND listed_in <> ''
  UNION ALL
  SELECT show_id, TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS genre,
         SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
  FROM g WHERE rest IS NOT NULL AND rest <> ''
),
cg AS (
  SELECT m.country, g.genre, COUNT(*) AS n
  FROM netflix_movies m
  JOIN g USING (show_id)
  WHERE m.country IS NOT NULL AND m.country <> '' AND g.genre <> ''
  GROUP BY m.country, g.genre
),
r AS (
  SELECT country, genre, n,
         DENSE_RANK() OVER (PARTITION BY country ORDER BY n DESC) AS rnk
  FROM cg
)
SELECT country, genre AS top_genre, n AS titles
FROM r
WHERE rnk = 1
ORDER BY titles DESC;

-- ====================================================================================
#  Longest / Shortest Movies (minutes)
-- ====================================================================================

WITH dur AS (
  SELECT
    show_id, title, type, duration,
    CASE
      WHEN type = 'Movie' AND duration LIKE '%min'
        THEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED)
      ELSE NULL
    END AS minutes
  FROM netflix_movies
)
SELECT *
FROM (
  SELECT type, title, minutes,
         ROW_NUMBER() OVER (PARTITION BY type ORDER BY minutes DESC) AS rn_max,
         ROW_NUMBER() OVER (PARTITION BY type ORDER BY minutes ASC)  AS rn_min
  FROM dur WHERE minutes IS NOT NULL
) x
WHERE rn_max = 1 OR rn_min = 1
ORDER BY type, minutes DESC;




















