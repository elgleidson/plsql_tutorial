--drop package plsql_tutorial.usuario_stats;

create or replace package plsql_tutorial.usuarios_stats as
  
  procedure audit_vendas(p_usuario_id in number := null);
  procedure recalc_vendas(p_usuario_id in number := null);
  procedure audit_ligacoes(p_usuario_id in number := null);
  procedure recalc_ligacoes(p_usuario_id in number := null);
  
end;
/

create or replace package body plsql_tutorial.usuarios_stats as

  function get_calc(p_tabela in varchar, p_coluna in varchar, p_usuario_id in number, o_ultimo_id out number) return number
  is
    v_valor number := 0;
  begin
    execute immediate 'select count(id), max(id) from '||p_tabela||' where '||p_coluna||' = :id'
    into v_valor, o_ultimo_id
    using p_usuario_id;
    
    return v_valor;
  end;
  
  procedure trata_divergentes(
    p_tabela      in varchar2,
    p_coluna      in varchar2,
    p_coluna_qt   in varchar2,
    p_coluna_id   in varchar2,
    p_usuario_id  in number, 
    p_log_name    in varchar2, 
    p_update      in boolean
  )
  is
    v_valor_atual number := 0;
    v_valor_calc  number := 0;
    v_ultimo_id_atual number;
    v_ultimo_id_calc  number;
  begin
    execute immediate 'select '||p_coluna_qt||', '||p_coluna_id||' from usuarios where id = :id'
    into v_valor_atual, v_ultimo_id_atual
    using p_usuario_id;
    
    v_valor_calc := get_calc(p_tabela, p_coluna, p_usuario_id, v_ultimo_id_calc);
    
    if (v_valor_atual <> v_valor_calc or nvl(v_ultimo_id_atual, -1) <> nvl(v_ultimo_id_calc, -2)) then
      insert into usuarios_stats_logs (usuario_id, log_name, campo, valor_atual, ultimo_id_atual, valor_calc, ultimo_id_calc)
      values (p_usuario_id, p_log_name, p_tabela, v_valor_atual, v_ultimo_id_atual, v_valor_calc, v_ultimo_id_calc);
      
      if p_update then
        execute immediate 'update usuarios set '||p_coluna_qt||' = :valor_calc, '||p_coluna_id||' = :ultimo_id_calc where id = :id'
        using v_valor_calc, v_ultimo_id_calc, p_usuario_id;
      end if;
    end if;
  exception 
    when no_data_found then
      null;
    when too_many_rows then
      null;
  end;
  
  
  procedure audit_vendas(p_usuario_id in number := null)
  is
  begin
    if p_usuario_id is not null then
      trata_divergentes('vendas', 'vendedor_id', 'vendas', 'ultima_venda', p_usuario_id, 'audit_vendas', false);
    else
      for vendedor in (select id from usuarios) 
      loop
        audit_vendas(p_usuario_id => vendedor.id);
      end loop;
    end if;
  end;
  
  
  procedure recalc_vendas(p_usuario_id in number := null)
  is
  begin
    if p_usuario_id is not null then
      trata_divergentes('vendas', 'vendedor_id', 'vendas', 'ultima_venda', p_usuario_id, 'recalc_vendas', true);
    else
      for vendedor in (select id from usuarios) 
      loop
        recalc_vendas(p_usuario_id => vendedor.id);
      end loop;
    end if;
  end;
  
  
  procedure audit_ligacoes(p_usuario_id in number := null)
  is
  begin
    if p_usuario_id is not null then
      trata_divergentes('ligacoes', 'atendente_id', 'ligacoes', 'ultima_ligacao', p_usuario_id, 'audit_ligacoes', false);
    else
      for atendente in (select id from usuarios) 
      loop
        audit_ligacoes(p_usuario_id => atendente.id);
      end loop;
    end if;
  end;
  
  
  procedure recalc_ligacoes(p_usuario_id in number := null)
  is
  begin
    if p_usuario_id is not null then
      trata_divergentes('ligacoes', 'atendente_id', 'ligacoes', 'ultima_ligacao', p_usuario_id, 'recalc_ligacoes', true);
    else
      for atendente in (select id from usuarios) 
      loop
        recalc_ligacoes(p_usuario_id => atendente.id);
      end loop;
    end if;
  end;
    
end;
/