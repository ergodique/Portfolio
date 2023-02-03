SELECT u.username, u.PROFILE, p.LIMIT
  FROM dba_users u, dba_profiles p
 WHERE u.PROFILE = p.PROFILE AND 
 (u.username LIKE ('SFR%') OR u.username LIKE ('SAFIR%'))
 and p.RESOURCE_NAME = 'SESSIONS_PER_USER'
 order by 1