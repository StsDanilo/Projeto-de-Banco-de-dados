SET search_path = cinema;
\pset border 2
\echo '### C01 faturamento por filme (top 5)'
SELECT f.titulo, g.nome AS genero, count(*) AS ingressos, sum(i.valor_pago) AS faturamento
FROM ingresso i JOIN sessao s USING (sessao_id) JOIN filme f USING (filme_id) JOIN genero g USING (genero_id)
WHERE i.status='VENDIDO' GROUP BY f.titulo, g.nome ORDER BY faturamento DESC LIMIT 5;
\echo '### C02 ocupacao media por sala'
SELECT sa.nome, sa.tipo, sa.capacidade, round(100.0*count(*) FILTER (WHERE i.status='VENDIDO')/(count(DISTINCT s.sessao_id)*sa.capacidade),1) AS ocupacao_pct
FROM sala sa JOIN sessao s USING (sala_id) LEFT JOIN ingresso i USING (sessao_id) GROUP BY sa.sala_id ORDER BY sa.nome;
\echo '### C03 filmes sem nenhuma sessao (LEFT JOIN)'
SELECT f.filme_id, f.titulo, f.em_cartaz FROM filme f LEFT JOIN sessao s USING (filme_id) WHERE s.sessao_id IS NULL ORDER BY 1;
\echo '### C04 clientes com mais ingressos (top 5)'
SELECT c.cliente_id, c.nome, count(*) AS ingressos, sum(i.valor_pago) AS gasto
FROM cliente c JOIN ingresso i USING (cliente_id) WHERE i.status='VENDIDO' GROUP BY c.cliente_id ORDER BY ingressos DESC, c.cliente_id LIMIT 5;
\echo '### C05 sessoes de um dia com poltronas livres'
SELECT s.sessao_id, sa.nome AS sala, s.inicio, s.idioma, sa.capacidade - count(i.*) FILTER (WHERE i.status='VENDIDO') AS livres
FROM sessao s JOIN sala sa USING (sala_id) LEFT JOIN ingresso i USING (sessao_id)
WHERE s.inicio::date = '2026-11-20' GROUP BY s.sessao_id, sa.nome, sa.capacidade ORDER BY s.inicio, sa.nome LIMIT 6;
\echo '### C06 proporcao meia x inteira por genero'
SELECT g.nome AS genero, round(100.0*count(*) FILTER (WHERE i.tipo='MEIA')/count(*),1) AS meia_pct, count(*) AS total
FROM ingresso i JOIN sessao s USING (sessao_id) JOIN filme f USING (filme_id) JOIN genero g USING (genero_id)
WHERE i.status='VENDIDO' GROUP BY g.nome ORDER BY g.nome;
\echo '### C07 visao vw_ocupacao_sessao'
CREATE OR REPLACE VIEW vw_ocupacao_sessao AS
SELECT s.sessao_id, f.titulo, sa.nome AS sala, s.inicio, sa.capacidade,
       count(i.*) FILTER (WHERE i.status='VENDIDO') AS vendidos,
       round(100.0*count(i.*) FILTER (WHERE i.status='VENDIDO')/sa.capacidade,1) AS ocupacao_pct
FROM sessao s JOIN filme f USING (filme_id) JOIN sala sa USING (sala_id) LEFT JOIN ingresso i USING (sessao_id)
GROUP BY s.sessao_id, f.titulo, sa.nome, s.inicio, sa.capacidade;
SELECT * FROM vw_ocupacao_sessao WHERE sessao_id IN (1,2,3) ORDER BY sessao_id;
