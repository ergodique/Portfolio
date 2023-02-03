SELECT ROUND((a.VALUE/b.VALUE) + 0.5,0) AS avg_redo_blks_per_write,
             ROUND((a.VALUE/b.VALUE) + 0.5,0) * c.lebsz AS avg_io_size
			 FROM v$sysstat a, v$sysstat b, x$kccle c
			 WHERE c.lenum=1
			 AND a.NAME='redo blocks written'
			 AND b.NAME='redo writes'
			 
			 
