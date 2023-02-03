select gs.* from gv$transaction gt, gv$session gs
where gt.addr=gs.taddr 
and gt.inst_id=gs.inst_id




exec isbdba.kill_session (521,12939)