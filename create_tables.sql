/*
alter table plsql_tutorial.ligacoes drop constraint ligacoes_atendente_fk;
alter table plsql_tutorial.vendas drop constraint vendas_vendedor_fk;
alter table plsql_tutorial.usuarios drop constraint usuarios_ligacoes_fk;
alter table plsql_tutorial.usuarios drop constraint usuarios_vendas_fk;
drop table plsql_tutorial.vendas;
drop table plsql_tutorial.ligacoes;
drop table plsql_tutorial.usuarios;
*/


create table plsql_tutorial.usuarios (
  id              number,
  nome            varchar2(100),
  ligacoes        number,
  ultima_ligacao  number,
  vendas          number,
  ultima_venda    number
);

alter table plsql_tutorial.usuarios add constraint usuarios_pk primary key (id);


create table plsql_tutorial.ligacoes (
  id            number,
  data          timestamp,
  status        number,
  duracao       number,
  atendente_id  number
);

alter table plsql_tutorial.ligacoes add constraint ligacoes_pk primary key (id);
alter table plsql_tutorial.ligacoes add constraint ligacoes_atendente_fk foreign key (atendente_id) references plsql_tutorial.usuarios (id); 


create table plsql_tutorial.vendas (
  id           number,
  data         date,
  status       number,
  valor        number,
  vendedor_id  number
);

alter table plsql_tutorial.vendas add constraint vendas_pk primary key (id);
alter table plsql_tutorial.vendas add constraint vendas_vendedor_fk foreign key (vendedor_id) references plsql_tutorial.usuarios (id);

alter table plsql_tutorial.usuarios add constraint usuarios_vendas_fk foreign key (ultima_ligacao) references plsql_tutorial.ligacoes (id);
alter table plsql_tutorial.usuarios add constraint usuarios_ligacoes_fk foreign key (ultima_venda) references plsql_tutorial.vendas (id);