select * from V$MEMORY_TARGET_ADVICE

select * from V$MEMORY_DYNAMIC_COMPONENTS

select * from V$MEMORY_RESIZE_OPS

select component,current_size/1024/1024 from V$MEMORY_DYNAMIC_COMPONENTS