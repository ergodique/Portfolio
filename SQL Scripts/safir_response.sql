select 
trunc(vs.elapsed_time/vs.executions)/1000 msec,
vs.executions,sql_id
 from gv$sql vs
where sql_id in ('gspjyn8m7gmyd','dy4f1w2fvawvm','49hpphwkttrg6','8z7kjkxu29a43','ch44s8y3w5bv5','7n83badx12tj2','0dm48z45s95c0','dj408rwsqdyt3','6rqk6c01taj2d','aj7mcf5b0wnta') 
order by 1 desc
