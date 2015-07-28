--drop package plsql_tutorial.usuario_stats;

create or replace package plsql_tutorial.usuarios_stats as

  type usuario_stat_t is record (
    ultimo_id number,
    quantidade number
  );
  
  function usuario_stat_equals(este in usuario_stat_t, aquele in usuario_stat_t) return boolean; 
  
  procedure audit_vendas(p_usuario_id in number := null);
  procedure recalc_vendas(p_usuario_id in number := null);
  procedure audit_ligacoes(p_usuario_id in number := null);
  procedure recalc_ligacoes(p_usuario_id in number := null);
  
end;
/

create or replace package body plsql_tutorial.usuarios_stats as

  function usuario_stat_equals(este in usuario_stat_t, aquele in usuario_stat_t) return boolean
  is
  begin
    return (((este.quantidade = aquele.quantidade) or (este.quantidade is null and aquele.quantidade is null)) 
        and ((este.ultimo_id = aquele.ultimo_id) or (este.ultimo_id is null and aquele.ultimo_id is null)));
  end;
  

  function get_calc(p_tabela in varchar, p_coluna in varchar, p_usuario_id in number) return usuario_stat_t
  is
    v_stat usuario_stat_t;
  begin
    execute immediate 'select count(id), max(id) from '||p_tabela||' where '||p_coluna||' = :id'
    into v_stat.quantidade, v_stat.ultimo_id
    using p_usuario_id;
    
    return v_stat;
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
    v_stat_atual usuario_stat_t;
    v_stat_calc  usuario_stat_t;
  begin
    execute immediate 'select '||p_coluna_qt||', '||p_coluna_id||' from usuarios where id = :id'
    into v_stat_atual.quantidade, v_stat_atual.ultimo_id
    using p_usuario_id;
    
    v_stat_calc := get_calc(p_tabela, p_coluna, p_usuario_id);
    
    if not usuario_stat_equals(v_stat_atual, v_stat_calc) then
      insert into usuarios_stats_logs (usuario_id, log_name, campo, valor_atual, ultimo_id_atual, valor_calc, ultimo_id_calc)
      values (p_usuario_id, p_log_name, p_tabela, v_stat_atual.quantidade, v_stat_atual.ultimo_id, v_stat_calc.quantidade, v_stat_calc.ultimo_id);
      
      if p_update then
        execute immediate 'update usuarios set '||p_coluna_qt||' = :valor_calc, '||p_coluna_id||' = :ultimo_id_calc where id = :id'
        using v_stat_calc.quantidade, v_stat_calc.ultimo_id, p_usuario_id;
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