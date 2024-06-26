SELECT *
FROM TICKER
         MATCH_RECOGNIZE (
             PARTITION BY SYMBOL
             ORDER BY TSTAMP
             MEASURES
                 INIT.TSTAMP AS INIT_STAMP,
                 LAST(PEAK1.TSTAMP) AS FIRST_PEAK_STAMP,
                 LAST(FALL1.TSTAMP) AS FIRST_FALL_STAMP,
                 LAST(PEAK2.TSTAMP) AS SECOND_PEAK_STAMP,
                 LAST(FALL2.TSTAMP) AS SECOND_FALL_STAMP,
                 INIT.PRICE AS INITIAL_PRICE,
                 LAST(PEAK1.PRICE) AS FIRST_PEAK_PRICE,
                 LAST(FALL1.PRICE) AS FIRST_FALL_PRICE,
                 LAST(PEAK2.PRICE) AS SECOND_PEAK_PRICE,
                 LAST(FALL2.PRICE) AS LAST_FALL_PRICE
             ONE ROW PER MATCH
             AFTER MATCH SKIP TO LAST PEAK2
             PATTERN (INIT PEAK1+ FALL1+ PEAK2+ FALL2+)
             DEFINE
                 FALL1 AS FALL1.PRICE < PREV(FALL1.PRICE),
                 FALL2 AS FALL2.PRICE < PREV(FALL2.PRICE),
                 PEAK1 AS PEAK1.PRICE > PREV(PEAK1.PRICE),
                 PEAK2 AS PEAK2.PRICE > PREV(PEAK2.PRICE)
             );

