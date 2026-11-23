SET search_path = cinema;
SELECT setseed(0.42);
INSERT INTO genero(nome) VALUES ('Ação'),('Comédia'),('Drama'),('Terror'),('Animação'),('Ficção Científica'),('Romance'),('Documentário');
INSERT INTO filme(titulo,genero_id,duracao_min,classificacao,data_estreia,em_cartaz)
SELECT 'Filme '||g, 1+(g%8), 80+(g*7)%51, (ARRAY['L','10','12','14','16','18'])[1+g%6], DATE '2026-01-01'+(g*5), g<=36
FROM generate_series(1,40) g;
INSERT INTO sala(nome,capacidade,tipo) VALUES ('Sala 1',100,'2D'),('Sala 2',80,'2D'),('Sala 3',60,'3D'),('Sala 4',50,'2D'),('Sala 5',100,'IMAX'),('Sala 6',30,'VIP');
INSERT INTO cliente(nome,cpf,email,data_nascimento)
SELECT 'Cliente '||g, lpad(g::text,11,'0'), 'cliente'||g||'@exemplo.com', DATE '1960-01-01'+(g*37%16000)
FROM generate_series(1,20000) g;
INSERT INTO sessao(filme_id,sala_id,inicio,fim,idioma,preco_base)
SELECT f.filme_id, s.sala_id, d.dia + h.hora, d.dia + h.hora + (f.duracao_min+15)*interval '1 minute',
       CASE WHEN (s.sala_id+h.n)%2=0 THEN 'DUBLADO' ELSE 'LEGENDADO' END,
       CASE s.tipo WHEN 'IMAX' THEN 42 WHEN 'VIP' THEN 55 WHEN '3D' THEN 34 ELSE 28 END
FROM generate_series(DATE '2026-09-01', DATE '2026-12-29', interval '1 day') d(dia)
CROSS JOIN sala s
CROSS JOIN (VALUES (1,interval '14 hours'),(2,interval '16 hours 30 minutes'),(3,interval '19 hours'),(4,interval '21 hours 30 minutes')) h(n,hora)
JOIN filme f ON f.filme_id = 1 + ((EXTRACT(doy FROM d.dia)::int*7 + s.sala_id*5 + h.n*3) % 36);
INSERT INTO ingresso(sessao_id,cliente_id,poltrona,tipo,valor_pago,status,data_compra)
SELECT x.sessao_id, 1+floor(random()*20000)::int, x.p, x.t,
       CASE WHEN x.t='MEIA' THEN x.preco_base/2 ELSE x.preco_base END,
       CASE WHEN random()<0.04 THEN 'CANCELADO' ELSE 'VENDIDO' END,
       x.inicio - (random()*7)*interval '1 day'
FROM (
  SELECT se.sessao_id, se.preco_base, se.inicio, p, CASE WHEN random()<0.4 THEN 'MEIA' ELSE 'INTEIRA' END t
  FROM sessao se JOIN sala sa USING (sala_id)
  CROSS JOIN LATERAL generate_series(1, sa.capacidade) p
  WHERE random() < 0.6
) x;
ANALYZE;
SELECT 'generos' t, count(*) FROM genero UNION ALL SELECT 'filmes',count(*) FROM filme UNION ALL SELECT 'salas',count(*) FROM sala UNION ALL SELECT 'clientes',count(*) FROM cliente UNION ALL SELECT 'sessoes',count(*) FROM sessao UNION ALL SELECT 'ingressos',count(*) FROM ingresso;
