import sys, os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))
from app.database.session import engine, SessionLocal
from app.models.models import Base, SalaRobotica, Leito, Convenio, StatusSala, StatusLeito

def init_db():
    print("🤖 Iniciando banco de dados...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    if not db.query(SalaRobotica).first():
        db.add(SalaRobotica(nome="Sala Robótica 1", sistema_robotico="Da Vinci Xi", status=StatusSala.DISPONIVEL))
        print("✅ Sala robótica criada.")
    if not db.query(Leito).first():
        leitos = [
            Leito(numero="210", andar="2º", tipo="Apartamento", status=StatusLeito.DISPONIVEL),
            Leito(numero="304", andar="3º", tipo="Apartamento", status=StatusLeito.DISPONIVEL),
            Leito(numero="118", andar="1º", tipo="UTI",         status=StatusLeito.DISPONIVEL),
            Leito(numero="422", andar="4º", tipo="Apartamento", status=StatusLeito.DISPONIVEL),
        ]
        db.add_all(leitos)
        print(f"✅ {len(leitos)} leitos criados.")
    if not db.query(Convenio).first():
        convenios = [
            Convenio(nome="Unimed Nacional",  codigo_ans="391900", tipo="Plano"),
            Convenio(nome="Bradesco Saúde",   codigo_ans="005711", tipo="Plano"),
            Convenio(nome="SulAmérica",       codigo_ans="006246", tipo="Plano"),
            Convenio(nome="Amil",             codigo_ans="326305", tipo="Plano"),
            Convenio(nome="Particular",                            tipo="Particular"),
        ]
        db.add_all(convenios)
        print(f"✅ {len(convenios)} convênios criados.")
    db.commit()
    db.close()
    print("\n🚀 Banco pronto! Rode: uvicorn app.main:app --reload\n")

if __name__ == "__main__":
    init_db()
