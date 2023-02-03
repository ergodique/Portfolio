SELECT component, current_size/1024/1024/1024 size_gb
FROM V$MEMORY_DYNAMIC_COMPONENTS 
WHERE current_size <> 0 
ORDER BY 2 DESC;
