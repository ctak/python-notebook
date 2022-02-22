select job_name, program_name, job_style, job_type, job_action, schedule_name, schedule_type, repeat_interval, 
    enabled, auto_drop, state, comments
  from user_scheduler_jobs
 order by job_name
;

-- AS-IS 운영의 job 목록을 확인하기 위하여.
select job_name, program_name, job_style, job_type, job_action, schedule_name, schedule_type, repeat_interval, 
    enabled, auto_drop, state, comments
  from user_scheduler_jobs@leg_asm
 order by job_name
;

begin

dbms_scheduler.disable('BATCH_ANA_DD_MEM_SCHE');
dbms_scheduler.disable('BATCH_ANA_MM_MEM_SCHE');
dbms_scheduler.disable('BATCH_CARD_MILEAGE_MMIO_SCHE');
dbms_scheduler.disable('BATCH_COUP_CMS_ISSUE_IF_SCHE');
dbms_scheduler.disable('BATCH_DESTROY_MEM_MST_SCHE');
dbms_scheduler.disable('BATCH_DESTROY_REST_INFO_SCHE');
dbms_scheduler.disable('BATCH_MEM_POINT_DD_MM_SCHE');
dbms_scheduler.disable('BATCH_MEM_REST_IF_SCHE');
dbms_scheduler.disable('BATCH_PROMOTION_EXE_SCHE');
dbms_scheduler.disable('JOB_BATCH_GRADE_ADJ_RUN_SCHE');
dbms_scheduler.disable('JOB_BATCH_MILEAGE_EX_SCHE');

end;
/