--drop package plsql_tutorial.usuario_stats;

create or replace package plsql_tutorial.usuarios_stats as
  
  procedure audit_vendas(p_usuario_id in number);
  procedure recalc_vendas(p_usuario_id in number);
  
end;
/

create or replace package body plsql_tutorial.usuarios_stats as

  function get_vendas_calc(p_usuario_id in number, o_ultimo_id out number) return number
  is
    v_valor number := 0;
  begin
    select count(v.id), max(v.id) into v_valor, o_ultimo_id from vendas v where v.vendedor_id = p_usuario_id;
    
    return v_valor;
  end;
  
  
  procedure trata_vendas_divergentes(p_usuario_id in number, p_log_name in varchar2, p_update in boolean)
  is
    v_valor_atual number := 0;
    v_valor_calc  number := 0;
    v_ultimo_id_atual number;
    v_ultimo_id_calc  number;
  begin
    select u.vendas, u.ultima_venda
    into v_valor_atual, v_ultimo_id_atual
    from usuarios u
    where u.id = p_usuario_id;
    
    v_valor_calc := get_vendas_calc(p_usuario_id, v_ultimo_id_calc);
    
    if (v_valor_atual <> v_valor_calc or nvl(v_ultimo_id_atual, -1) <> nvl(v_ultimo_id_calc, -2)) then
      insert into usuarios_stats_logs (usuario_id, log_name, campo, valor_atual, ultimo_id_atual, valor_calc, ultimo_id_calc)
      values (p_usuario_id, p_log_name, 'vendas', v_valor_atual, v_ultimo_id_atual, v_valor_calc, v_ultimo_id_calc);
      
      if p_update then
        update usuarios set
          vendas = v_valor_calc,
          ultima_venda = v_ultimo_id_calc
        where id = p_usuario_id;
      end if;
    end if;
  exception 
    when no_data_found then
      null;
    when too_many_rows then
      null;
  end;
  
  
  procedure audit_vendas(p_usuario_id in number)
  is
  begin
    trata_vendas_divergentes(p_usuario_id, 'audit_vendas', false);
  end;
  
  
  procedure recalc_vendas(p_usuario_id in number)
  is
  begin
    trata_vendas_divergentes(p_usuario_id, 'recalc_vendas', true);
  end;
  
end;
/