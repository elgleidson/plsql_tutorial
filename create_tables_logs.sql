--drop table plsql_tutorial.usuarios_stats_logs;

create table plsql_tutorial.usuarios_stats_logs (
  data_auditoria         timestamp default current_timestamp,
  usuario_id             number,
  log_name               varchar2(30),             
  campo                  varchar2(30),
  valor_atual            number,
  ultimo_id_atual        number,
  valor_calc             number,
  ultimo_id_calc         number
);
