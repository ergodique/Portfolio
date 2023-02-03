SELECT (SELECT COUNT (*)
          FROM fnd_logins a
         WHERE TO_CHAR (start_time, 'mm.rrrr') =
                                   TO_CHAR (SYSDATE, 'mm.rrrr')
           AND login_type IS NOT NULL) "Monthly Hit",
       (SELECT SUM (counter)
          FROM icx_sessions a
         WHERE TO_CHAR (last_connect, 'mm.rrrr') =
                            TO_CHAR (SYSDATE, 'mm.rrrr'))
                                                         "Monthly Surf",
       (SELECT COUNT (*)
          FROM fnd_logins a
         WHERE TO_CHAR (start_time, 'dd/mm/rrrr hh24:mi:ss') >
                     NEXT_DAY (TO_CHAR (SYSDATE - 7, 'dd/mm/rrrr'),
                               'pazartesi'
                              )
                  || ' 00:00:00'
           AND login_type IS NOT NULL) "Weekly Hit",
       (SELECT SUM (counter)
          FROM icx_sessions a
         WHERE TO_CHAR (last_connect,
                        'dd/mm/rrrr hh24:mi:ss'
                       ) >
                     NEXT_DAY (TO_CHAR (SYSDATE - 7, 'dd/mm/rrrr'),
                               'pazartesi'
                              )
                  || ' 00:00:00') "Weekly Surf",
       (SELECT COUNT (*)
          FROM fnd_logins a
         WHERE TRUNC (start_time) = TRUNC (SYSDATE)
           AND login_type IS NOT NULL) "Daily Hit",
       (SELECT SUM (counter)
          FROM icx_sessions a
         WHERE TRUNC (last_connect) = TRUNC (SYSDATE)) "Daily Surf",
       (SELECT COUNT (*)
          FROM fnd_logins a
         WHERE TO_CHAR (start_time, 'dd.mm.rrrr hh24') =
                            TO_CHAR (SYSDATE, 'dd.mm.rrrr hh24')
           AND login_type IS NOT NULL) "Hourly Hit",
       (SELECT SUM (counter)
          FROM icx_sessions a
         WHERE TO_CHAR (last_connect, 'dd.mm.rrrr hh24') =
                     TO_CHAR (SYSDATE, 'dd.mm.rrrr hh24'))
                                                          "Hourly Surf",
       (SELECT COUNT (*)
          FROM fnd_logins a, icx_sessions b
         WHERE a.login_id = b.login_id
           AND a.login_type IS NOT NULL
           AND a.end_time IS NULL
           AND (b.last_connect + (time_out / 1440)) > SYSDATE) "Active Users"
  FROM DUAL;
