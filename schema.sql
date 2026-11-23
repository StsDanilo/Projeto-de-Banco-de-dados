DROP SCHEMA IF EXISTS cinema CASCADE;
CREATE SCHEMA cinema;
SET search_path = cinema;
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE genero (
  genero_id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome varchar(40) NOT NULL UNIQUE
);

CREATE TABLE filme (
  filme_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  titulo varchar(120) NOT NULL,
  genero_id smallint NOT NULL REFERENCES genero(genero_id) ON DELETE RESTRICT,
  duracao_min smallint NOT NULL CHECK (duracao_min BETWEEN 1 AND 300),
  classificacao varchar(3) NOT NULL CHECK (classificacao IN ('L','10','12','14','16','18')),
  data_estreia date NOT NULL,
  em_cartaz boolean NOT NULL DEFAULT true,
  UNIQUE (titulo, data_estreia)
);

CREATE TABLE sala (
  sala_id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome varchar(20) NOT NULL UNIQUE,
  capacidade smallint NOT NULL CHECK (capacidade BETWEEN 20 AND 100),
  tipo varchar(10) NOT NULL DEFAULT '2D' CHECK (tipo IN ('2D','3D','IMAX','VIP'))
);

CREATE TABLE cliente (
  cliente_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome varchar(100) NOT NULL,
  cpf char(11) NOT NULL UNIQUE CHECK (cpf ~ '^[0-9]{11}$'),
  email varchar(120) NOT NULL UNIQUE CHECK (email LIKE '%_@_%.__%'),
  data_nascimento date NOT NULL CHECK (data_nascimento <= CURRENT_DATE),
  criado_em timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE sessao (
  sessao_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  filme_id integer NOT NULL REFERENCES filme(filme_id) ON DELETE RESTRICT,
  sala_id smallint NOT NULL REFERENCES sala(sala_id) ON DELETE RESTRICT,
  inicio timestamp NOT NULL,
  fim timestamp NOT NULL,
  idioma varchar(10) NOT NULL DEFAULT 'DUBLADO' CHECK (idioma IN ('DUBLADO','LEGENDADO')),
  preco_base numeric(7,2) NOT NULL CHECK (preco_base > 0),
  CHECK (fim > inicio),
  EXCLUDE USING gist (sala_id WITH =, tsrange(inicio, fim) WITH &&)
);

CREATE TABLE ingresso (
  ingresso_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sessao_id integer NOT NULL REFERENCES sessao(sessao_id) ON DELETE RESTRICT,
  cliente_id integer NOT NULL REFERENCES cliente(cliente_id) ON DELETE RESTRICT,
  poltrona smallint NOT NULL CHECK (poltrona >= 1),
  tipo varchar(7) NOT NULL DEFAULT 'INTEIRA' CHECK (tipo IN ('INTEIRA','MEIA')),
  valor_pago numeric(7,2) NOT NULL CHECK (valor_pago >= 0),
  status varchar(10) NOT NULL DEFAULT 'VENDIDO' CHECK (status IN ('VENDIDO','CANCELADO')),
  data_compra timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_ingresso_poltrona_ativa
  ON ingresso (sessao_id, poltrona) WHERE status = 'VENDIDO';

CREATE FUNCTION fn_valida_ingresso() RETURNS trigger AS $$
DECLARE cap smallint;
BEGIN
  SELECT s.capacidade INTO cap FROM sessao se JOIN sala s USING (sala_id) WHERE se.sessao_id = NEW.sessao_id;
  IF NEW.poltrona > cap THEN
    RAISE EXCEPTION 'poltrona % inexistente na sala (capacidade %)', NEW.poltrona, cap;
  END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_ingresso BEFORE INSERT ON ingresso
  FOR EACH ROW EXECUTE FUNCTION fn_valida_ingresso();
