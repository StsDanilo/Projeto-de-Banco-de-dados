import subprocess,re,statistics
def q(sql):
    return subprocess.run(["psql","-h","/tmp/pg","-d","cinema","-X","-At","-c","SET search_path=cinema; "+sql],capture_output=True,text=True).stdout
def bench(name,sql):
    plans=[]; times=[]
    for i in range(7):
        out=q("EXPLAIN (ANALYZE) "+sql)
        t=float(re.search(r"Execution Time: ([\d.]+)",out).group(1)); times.append(t)
        if i==0: plans=out
    node=[l.strip() for l in plans.splitlines() if re.search(r"(Seq Scan|Index Scan|Index Only Scan|Bitmap Heap Scan)",l)]
    rows=re.search(r"rows=(\d+)",node[0]) if node else None
    print(f"{name} | {node[0].split('  (')[0].replace('->','').strip()} | mediana {statistics.median(times):.3f} ms")
Q={
 "Q1 ingressos de um cliente":"SELECT * FROM ingresso WHERE cliente_id=1234",
 "Q2 sessoes de um dia":"SELECT * FROM sessao WHERE inicio >= '2026-11-20' AND inicio < '2026-11-21'",
 "Q3 sessoes de um filme":"SELECT * FROM sessao WHERE filme_id=7",
 "Q4 ingressos vendidos de uma sessao":"SELECT * FROM ingresso WHERE sessao_id=1500 AND status='VENDIDO'",
}
print("ANTES (sem indices extras)")
for k,v in Q.items(): bench(k,v)
q("CREATE INDEX idx_ingresso_cliente ON ingresso(cliente_id); CREATE INDEX idx_sessao_inicio ON sessao(inicio); CREATE INDEX idx_sessao_filme ON sessao(filme_id); ANALYZE;")
print("DEPOIS (idx_ingresso_cliente, idx_sessao_inicio, idx_sessao_filme)")
for k,v in Q.items(): bench(k,v)
print(q("SELECT indexname, indexdef FROM pg_indexes WHERE schemaname='cinema' AND tablename IN ('ingresso','sessao') ORDER BY 1"))
