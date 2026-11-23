\set VERBOSITY terse
\pset border 2
SET search_path = cinema;
\echo '### T01 tipos de dados'
SELECT table_name AS tabela, column_name AS coluna, data_type || COALESCE('('||character_maximum_length||')', CASE WHEN numeric_precision IS NOT NULL AND data_type='numeric' THEN '('||numeric_precision||','||numeric_scale||')' ELSE '' END) AS tipo, is_nullable AS aceita_nulo
FROM information_schema.columns WHERE table_schema='cinema' AND table_name IN ('filme','sessao','ingresso') ORDER BY table_name, ordinal_position;
\echo '### T02 restricoes por tabela e tipo'
SELECT c.relname AS tabela, count(*) FILTER (WHERE contype='p') pk, count(*) FILTER (WHERE contype='f') fk, count(*) FILTER (WHERE contype='u') uq, count(*) FILTER (WHERE contype='c') ck, count(*) FILTER (WHERE contype='x') excl
FROM pg_constraint k JOIN pg_class c ON c.oid=k.conrelid WHERE c.relnamespace='cinema'::regnamespace GROUP BY c.relname ORDER BY 1;
\echo '### T03 PK duplicada'
INSERT INTO genero(genero_id,nome) OVERRIDING SYSTEM VALUE VALUES (1,'Outro');
\echo '### T04 UNIQUE: cpf, email e titulo+estreia'
INSERT INTO cliente(nome,cpf,email,data_nascimento) VALUES ('Teste','00000000001','novo@exemplo.com','2000-01-01');
INSERT INTO cliente(nome,cpf,email,data_nascimento) VALUES ('Teste','99999999999','cliente1@exemplo.com','2000-01-01');
INSERT INTO filme(titulo,genero_id,duracao_min,classificacao,data_estreia) VALUES ('Filme 1',1,100,'L','2026-01-06');
\echo '### T05 NOT NULL'
INSERT INTO cliente(nome,cpf,email,data_nascimento) VALUES (NULL,'99999999998','a@exemplo.com','2000-01-01');
\echo '### T06 FK: sessao inexistente; excluir genero em uso; excluir cliente com ingresso'
INSERT INTO ingresso(sessao_id,cliente_id,poltrona,valor_pago) VALUES (999999,1,1,28);
DELETE FROM genero WHERE genero_id=1;
DELETE FROM cliente WHERE cliente_id=(SELECT cliente_id FROM ingresso LIMIT 1);
\echo '### T07 CHECK'
INSERT INTO filme(titulo,genero_id,duracao_min,classificacao,data_estreia) VALUES ('X',1,0,'L','2026-01-01');
INSERT INTO filme(titulo,genero_id,duracao_min,classificacao,data_estreia) VALUES ('X',1,100,'20','2026-01-01');
INSERT INTO sala(nome,capacidade) VALUES ('Sala 7',500);
INSERT INTO cliente(nome,cpf,email,data_nascimento) VALUES ('T','abc','t@exemplo.com','2000-01-01');
INSERT INTO cliente(nome,cpf,email,data_nascimento) VALUES ('T','12345678901','t@exemplo.com','2099-01-01');
INSERT INTO sessao(filme_id,sala_id,inicio,fim,preco_base) VALUES (1,1,'2027-01-10 14:00','2027-01-10 13:00',28);
INSERT INTO sessao(filme_id,sala_id,inicio,fim,preco_base) VALUES (1,1,'2027-01-10 14:00','2027-01-10 16:00',0);
\echo '### T08 EXCLUDE: sobreposicao de sessoes na mesma sala'
INSERT INTO sessao(filme_id,sala_id,inicio,fim,preco_base) VALUES (1,1,'2027-01-10 14:00','2027-01-10 16:00',28);
INSERT INTO sessao(filme_id,sala_id,inicio,fim,preco_base) VALUES (2,1,'2027-01-10 15:00','2027-01-10 17:00',28);
INSERT INTO sessao(filme_id,sala_id,inicio,fim,preco_base) VALUES (2,1,'2027-01-10 16:00','2027-01-10 18:00',28);
INSERT INTO sessao(filme_id,sala_id,inicio,fim,preco_base) VALUES (2,2,'2027-01-10 15:00','2027-01-10 17:00',28);
\echo '### T09 poltrona: venda valida, duplicada, inexistente, cancelamento libera'
SELECT sessao_id AS sessao_teste FROM sessao WHERE sala_id=1 AND inicio='2027-01-10 14:00' \gset
INSERT INTO ingresso(sessao_id,cliente_id,poltrona,valor_pago) VALUES (:sessao_teste,1,10,28);
INSERT INTO ingresso(sessao_id,cliente_id,poltrona,valor_pago) VALUES (:sessao_teste,2,10,28);
INSERT INTO ingresso(sessao_id,cliente_id,poltrona,valor_pago) VALUES (:sessao_teste,2,101,28);
UPDATE ingresso SET status='CANCELADO' WHERE sessao_id=:sessao_teste AND poltrona=10;
INSERT INTO ingresso(sessao_id,cliente_id,poltrona,valor_pago) VALUES (:sessao_teste,2,10,28);
SELECT poltrona, cliente_id, status FROM ingresso WHERE sessao_id=:sessao_teste AND poltrona=10 ORDER BY ingresso_id;
\echo '### T10 sala lotada: todas as poltronas vendidas e tentativa extra'
SELECT sessao_id AS sessao_lot FROM sessao WHERE sala_id=6 AND inicio='2026-12-20 14:00' \gset
DELETE FROM ingresso WHERE sessao_id=:sessao_lot;
INSERT INTO ingresso(sessao_id,cliente_id,poltrona,valor_pago) SELECT :sessao_lot, 1, p, 55 FROM generate_series(1,30) p;
SELECT count(*) AS vendidos FROM ingresso WHERE sessao_id=:sessao_lot AND status='VENDIDO';
INSERT INTO ingresso(sessao_id,cliente_id,poltrona,valor_pago) VALUES (:sessao_lot,3,30,55);
INSERT INTO ingresso(sessao_id,cliente_id,poltrona,valor_pago) VALUES (:sessao_lot,3,31,55);
\echo '### T11 tipos: precisao monetaria, limites numericos e datas'
SELECT (0.1::float8 + 0.2::float8 = 0.3::float8) AS float8_soma_exata, (0.1::numeric + 0.2::numeric = 0.3::numeric) AS numeric_soma_exata;
SELECT sum(x)::numeric(10,2) AS soma_float4 FROM (SELECT 0.10::float4 FROM generate_series(1,100000)) t(x);
SELECT sum(x) AS soma_numeric FROM (SELECT 0.10::numeric(7,2) FROM generate_series(1,100000)) t(x);
INSERT INTO ingresso(sessao_id,cliente_id,poltrona,valor_pago) VALUES (1,1,1,100000.00);
INSERT INTO filme(titulo,genero_id,duracao_min,classificacao,data_estreia) VALUES ('Y',1,40000,'L','2026-01-01');
INSERT INTO filme(titulo,genero_id,duracao_min,classificacao,data_estreia) VALUES ('Z',1,100,'L','2026-02-30');
INSERT INTO cliente(nome,cpf,email,data_nascimento) VALUES ('W','1234567890','w@exemplo.com','2000-01-01');
SELECT '2026-12-20 19:00'::timestamp AS sessao_local, to_char(now(),'TZ') AS fuso_servidor, pg_typeof(now()) AS tipo_data_compra;
