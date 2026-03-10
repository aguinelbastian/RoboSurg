#!/bin/bash
# ══════════════════════════════════════════════════════════
#  RoboSurg — Bootstrap Completo
#  Execute este script UMA VEZ dentro do GitHub Codespace:
#  bash bootstrap.sh
# ══════════════════════════════════════════════════════════

set -e
echo ""
echo "🤖 RoboSurg — Criando estrutura do projeto..."
echo ""

# ── Estrutura de pastas ──────────────────────────────────
mkdir -p .devcontainer
mkdir -p .vscode
mkdir -p .github/workflows
mkdir -p app/core
mkdir -p app/models
mkdir -p app/database
mkdir -p app/api/routes
mkdir -p app/modules/agendamento
mkdir -p app/modules/disponibilidade
mkdir -p app/modules/orcamento
mkdir -p app/modules/tasks
mkdir -p app/modules/validacao
mkdir -p app/modules/publicacao
mkdir -p tests
mkdir -p docs

# ── __init__.py em todos os pacotes ─────────────────────
touch app/__init__.py
touch app/core/__init__.py
touch app/models/__init__.py
touch app/database/__init__.py
touch app/api/__init__.py
touch app/api/routes/__init__.py
touch app/modules/__init__.py
touch app/modules/agendamento/__init__.py
touch app/modules/disponibilidade/__init__.py
touch app/modules/orcamento/__init__.py
touch app/modules/tasks/__init__.py
touch app/modules/validacao/__init__.py
touch app/modules/publicacao/__init__.py

# ── requirements.txt ────────────────────────────────────
cat > requirements.txt << 'EOF'
fastapi==0.111.0
uvicorn[standard]==0.30.1
sqlalchemy==2.0.30
pydantic==2.7.1
pydantic-settings==2.3.0
python-telegram-bot==21.3
streamlit==1.35.0
alembic==1.13.1
python-dotenv==1.0.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
httpx==0.27.0
EOF

# ── .env.example ────────────────────────────────────────
cat > .env.example << 'EOF'
DATABASE_URL=sqlite:///./robosurg.db
SECRET_KEY=mude-esta-chave-em-producao
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
TELEGRAM_BOT_TOKEN=seu-token-aqui
TELEGRAM_ENFERMEIRO_CHEFE_ID=id-do-chat
HOSPITAL_NOME=Nome do Hospital
EOF

# ── .gitignore ───────────────────────────────────────────
cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
venv/
.venv/
*.db
*.sqlite3
.env
!.env.example
.vscode/
*.log
EOF

# ── app/core/config.py ───────────────────────────────────
cat > app/core/config.py << 'EOF'
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./robosurg.db"
    SECRET_KEY: str = "robosurg-secret-key-mude-em-producao"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 480
    TELEGRAM_BOT_TOKEN: str = ""
    TELEGRAM_ENFERMEIRO_CHEFE_ID: str = ""
    HOSPITAL_NOME: str = "Hospital"

    class Config:
        env_file = ".env"

settings = Settings()
EOF

# ── app/database/session.py ──────────────────────────────
cat > app/database/session.py << 'EOF'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

engine = create_engine(
    settings.DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF

# ── app/models/models.py ─────────────────────────────────
cat > app/models/models.py << 'EOF'
from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean, ForeignKey, Enum, Text
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import enum

Base = declarative_base()

class StatusCirurgia(str, enum.Enum):
    SOLICITADA = "solicitada"
    DISPONIBILIDADE_OK = "disponibilidade_ok"
    ORCAMENTO_GERADO = "orcamento_gerado"
    TASKS_DISPARADAS = "tasks_disparadas"
    VALIDADA = "validada"
    CONFIRMADA = "confirmada"
    PUBLICADA = "publicada"
    CANCELADA = "cancelada"

class StatusLeito(str, enum.Enum):
    DISPONIVEL = "disponivel"
    OCUPADO = "ocupado"
    MANUTENCAO = "manutencao"
    RESERVADO = "reservado"

class StatusSala(str, enum.Enum):
    DISPONIVEL = "disponivel"
    OCUPADA = "ocupada"
    MANUTENCAO = "manutencao"
    RESERVADA = "reservada"

class TipoTask(str, enum.Enum):
    ANESTESIA = "anestesia"
    ENFERMAGEM = "enfermagem"
    CME = "cme"
    RECEPCAO = "recepcao"
    FATURAMENTO = "faturamento"
    ROBOTICA = "robotica"

class Paciente(Base):
    __tablename__ = "pacientes"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(200), nullable=False)
    cpf = Column(String(14), unique=True, index=True)
    data_nascimento = Column(DateTime)
    telefone = Column(String(20))
    email = Column(String(100))
    convenio_id = Column(Integer, ForeignKey("convenios.id"))
    numero_carteirinha = Column(String(50))
    criado_em = Column(DateTime, default=datetime.utcnow)
    convenio = relationship("Convenio", back_populates="pacientes")
    cirurgias = relationship("Cirurgia", back_populates="paciente")

class Cirurgiao(Base):
    __tablename__ = "cirurgioes"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(200), nullable=False)
    crm = Column(String(20), unique=True, index=True)
    especialidade = Column(String(100))
    telefone = Column(String(20))
    email = Column(String(100))
    telegram_chat_id = Column(String(50))
    ativo = Column(Boolean, default=True)
    criado_em = Column(DateTime, default=datetime.utcnow)
    cirurgias = relationship("Cirurgia", back_populates="cirurgiao")

class SalaRobotica(Base):
    __tablename__ = "salas_roboticas"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(100), nullable=False)
    sistema_robotico = Column(String(100))
    status = Column(Enum(StatusSala), default=StatusSala.DISPONIVEL)
    observacoes = Column(Text)
    ativo = Column(Boolean, default=True)
    cirurgias = relationship("Cirurgia", back_populates="sala")

class Leito(Base):
    __tablename__ = "leitos"
    id = Column(Integer, primary_key=True, index=True)
    numero = Column(String(20), nullable=False)
    andar = Column(String(20))
    tipo = Column(String(50))
    status = Column(Enum(StatusLeito), default=StatusLeito.DISPONIVEL)
    ativo = Column(Boolean, default=True)
    cirurgias = relationship("Cirurgia", back_populates="leito")

class Convenio(Base):
    __tablename__ = "convenios"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(200), nullable=False)
    codigo_ans = Column(String(20))
    tipo = Column(String(50))
    ativo = Column(Boolean, default=True)
    pacientes = relationship("Paciente", back_populates="convenio")
    pacotes = relationship("PacoteOrcamento", back_populates="convenio")
    cirurgias = relationship("Cirurgia", back_populates="convenio")

class PacoteOrcamento(Base):
    __tablename__ = "pacotes_orcamento"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(200), nullable=False)
    procedimento_codigo = Column(String(50))
    procedimento_descricao = Column(String(300))
    convenio_id = Column(Integer, ForeignKey("convenios.id"))
    valor_total = Column(Float)
    inclui_robotica = Column(Boolean, default=True)
    inclui_anestesia = Column(Boolean, default=True)
    inclui_diaria = Column(Boolean, default=True)
    tempo_previsto_minutos = Column(Integer)
    ativo = Column(Boolean, default=True)
    criado_em = Column(DateTime, default=datetime.utcnow)
    convenio = relationship("Convenio", back_populates="pacotes")

class Cirurgia(Base):
    __tablename__ = "cirurgias"
    id = Column(Integer, primary_key=True, index=True)
    paciente_id = Column(Integer, ForeignKey("pacientes.id"), nullable=False)
    cirurgiao_id = Column(Integer, ForeignKey("cirurgioes.id"), nullable=False)
    procedimento_descricao = Column(String(300), nullable=False)
    procedimento_codigo = Column(String(50))
    sala_id = Column(Integer, ForeignKey("salas_roboticas.id"))
    leito_id = Column(Integer, ForeignKey("leitos.id"))
    convenio_id = Column(Integer, ForeignKey("convenios.id"))
    data_hora_inicio = Column(DateTime, nullable=False)
    tempo_previsto_minutos = Column(Integer, default=120)
    status = Column(Enum(StatusCirurgia), default=StatusCirurgia.SOLICITADA)
    pacote_orcamento_id = Column(Integer, ForeignKey("pacotes_orcamento.id"))
    valor_orcamento = Column(Float)
    orcamento_aprovado = Column(Boolean, default=False)
    validado_por = Column(String(200))
    validado_em = Column(DateTime)
    observacoes_validacao = Column(Text)
    criado_em = Column(DateTime, default=datetime.utcnow)
    atualizado_em = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    criado_por = Column(String(100))
    paciente = relationship("Paciente", back_populates="cirurgias")
    cirurgiao = relationship("Cirurgiao", back_populates="cirurgias")
    sala = relationship("SalaRobotica", back_populates="cirurgias")
    leito = relationship("Leito", back_populates="cirurgias")
    convenio = relationship("Convenio", back_populates="cirurgias")
    tasks = relationship("Task", back_populates="cirurgia")

class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    cirurgia_id = Column(Integer, ForeignKey("cirurgias.id"), nullable=False)
    tipo = Column(Enum(TipoTask), nullable=False)
    descricao = Column(Text)
    responsavel_nome = Column(String(200))
    responsavel_telegram_id = Column(String(50))
    enviada_em = Column(DateTime)
    confirmada_em = Column(DateTime)
    confirmada = Column(Boolean, default=False)
    prazo = Column(DateTime)
    cirurgia = relationship("Cirurgia", back_populates="tasks")
EOF

# ── app/database/init_db.py ──────────────────────────────
cat > app/database/init_db.py << 'EOF'
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
EOF

# ── app/api/routes/agendamento.py ────────────────────────
cat > app/api/routes/agendamento.py << 'EOF'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.database.session import get_db
from app.models.models import Cirurgia, StatusCirurgia

router = APIRouter()

class CirurgiaCreate(BaseModel):
    paciente_id: int
    cirurgiao_id: int
    procedimento_descricao: str
    procedimento_codigo: Optional[str] = None
    convenio_id: Optional[int] = None
    data_hora_inicio: datetime
    tempo_previsto_minutos: int = 120
    criado_por: Optional[str] = None

@router.post("/", summary="Solicitar nova cirurgia")
def solicitar_cirurgia(dados: CirurgiaCreate, db: Session = Depends(get_db)):
    c = Cirurgia(**dados.model_dump(), status=StatusCirurgia.SOLICITADA)
    db.add(c); db.commit(); db.refresh(c)
    return c

@router.get("/", summary="Listar cirurgias")
def listar_cirurgias(status: Optional[StatusCirurgia] = None, db: Session = Depends(get_db)):
    q = db.query(Cirurgia)
    if status: q = q.filter(Cirurgia.status == status)
    return q.order_by(Cirurgia.data_hora_inicio).all()

@router.get("/{cirurgia_id}", summary="Buscar cirurgia")
def buscar_cirurgia(cirurgia_id: int, db: Session = Depends(get_db)):
    c = db.query(Cirurgia).filter(Cirurgia.id == cirurgia_id).first()
    if not c: raise HTTPException(404, "Cirurgia não encontrada")
    return c
EOF

# ── app/api/routes/disponibilidade.py ───────────────────
cat > app/api/routes/disponibilidade.py << 'EOF'
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.database.session import get_db
from app.models.models import SalaRobotica, Leito, Cirurgia, StatusSala, StatusLeito, StatusCirurgia

router = APIRouter()

class VerificacaoDisponibilidade(BaseModel):
    cirurgia_id: int
    data_hora_inicio: datetime
    tempo_previsto_minutos: int = 120

@router.post("/verificar", summary="Verificar disponibilidade")
def verificar_disponibilidade(dados: VerificacaoDisponibilidade, db: Session = Depends(get_db)):
    sala = db.query(SalaRobotica).filter(SalaRobotica.status == StatusSala.DISPONIVEL, SalaRobotica.ativo == True).first()
    if not sala:
        return {"disponivel": False, "mensagem": "❌ Nenhuma sala robótica disponível."}
    leito = db.query(Leito).filter(Leito.status == StatusLeito.DISPONIVEL, Leito.ativo == True).first()
    if not leito:
        return {"disponivel": False, "mensagem": "❌ Nenhum leito disponível."}
    sala.status = StatusSala.RESERVADA
    leito.status = StatusLeito.RESERVADO
    c = db.query(Cirurgia).filter(Cirurgia.id == dados.cirurgia_id).first()
    if c:
        c.sala_id = sala.id; c.leito_id = leito.id
        c.status = StatusCirurgia.DISPONIBILIDADE_OK
    db.commit()
    return {"disponivel": True, "sala": sala.nome, "leito": leito.numero,
            "mensagem": f"✅ Sala: {sala.nome} | Leito: {leito.numero}"}

@router.get("/salas", summary="Listar salas")
def listar_salas(db: Session = Depends(get_db)):
    return db.query(SalaRobotica).filter(SalaRobotica.ativo == True).all()

@router.get("/leitos", summary="Listar leitos")
def listar_leitos(db: Session = Depends(get_db)):
    return db.query(Leito).filter(Leito.ativo == True).all()
EOF

# ── app/api/routes/cirurgias.py ──────────────────────────
cat > app/api/routes/cirurgias.py << 'EOF'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.database.session import get_db
from app.models.models import Cirurgia, StatusCirurgia

router = APIRouter()

class ValidacaoInput(BaseModel):
    validado_por: str
    observacoes: Optional[str] = None

@router.get("/hoje", summary="Cirurgias do dia")
def cirurgias_hoje(db: Session = Depends(get_db)):
    hoje = datetime.utcnow().date()
    result = []
    for c in db.query(Cirurgia).filter(Cirurgia.status.in_([StatusCirurgia.CONFIRMADA, StatusCirurgia.PUBLICADA])).all():
        if c.data_hora_inicio.date() == hoje:
            result.append({
                "id": c.id,
                "paciente": c.paciente.nome if c.paciente else "N/A",
                "cirurgiao": c.cirurgiao.nome if c.cirurgiao else "N/A",
                "procedimento": c.procedimento_descricao,
                "sala": c.sala.nome if c.sala else "N/A",
                "leito": c.leito.numero if c.leito else "N/A",
                "convenio": c.convenio.nome if c.convenio else "N/A",
                "data_hora": c.data_hora_inicio.isoformat(),
                "tempo_previsto_min": c.tempo_previsto_minutos,
                "status": c.status
            })
    return result

@router.post("/{cirurgia_id}/validar", summary="Validar cirurgia")
def validar_cirurgia(cirurgia_id: int, dados: ValidacaoInput, db: Session = Depends(get_db)):
    c = db.query(Cirurgia).filter(Cirurgia.id == cirurgia_id).first()
    if not c: raise HTTPException(404, "Não encontrada")
    c.status = StatusCirurgia.VALIDADA
    c.validado_por = dados.validado_por
    c.validado_em = datetime.utcnow()
    c.observacoes_validacao = dados.observacoes
    db.commit()
    return {"mensagem": f"✅ Cirurgia #{cirurgia_id} validada por {dados.validado_por}"}

@router.post("/{cirurgia_id}/confirmar", summary="Confirmar cirurgia")
def confirmar_cirurgia(cirurgia_id: int, db: Session = Depends(get_db)):
    c = db.query(Cirurgia).filter(Cirurgia.id == cirurgia_id).first()
    if not c: raise HTTPException(404, "Não encontrada")
    if c.status != StatusCirurgia.VALIDADA: raise HTTPException(400, "Precisa ser validada primeiro")
    c.status = StatusCirurgia.CONFIRMADA
    db.commit()
    return {"mensagem": f"✅ Cirurgia #{cirurgia_id} confirmada!"}

@router.post("/{cirurgia_id}/publicar", summary="Publicar no painel")
def publicar_cirurgia(cirurgia_id: int, db: Session = Depends(get_db)):
    c = db.query(Cirurgia).filter(Cirurgia.id == cirurgia_id).first()
    if not c: raise HTTPException(404, "Não encontrada")
    if c.status != StatusCirurgia.CONFIRMADA: raise HTTPException(400, "Precisa estar confirmada primeiro")
    c.status = StatusCirurgia.PUBLICADA
    db.commit()
    return {"mensagem": f"📢 Cirurgia #{cirurgia_id} publicada!"}
EOF

# ── app/main.py ──────────────────────────────────────────
cat > app/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database.session import engine
from app.models.models import Base
from app.api.routes import agendamento, disponibilidade, cirurgias

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="🤖 RoboSurg API",
    description="Sistema de Gestão de Cirurgia Robótica",
    version="0.1.0"
)

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True,
                   allow_methods=["*"], allow_headers=["*"])

app.include_router(cirurgias.router,      prefix="/api/v1/cirurgias",      tags=["Cirurgias"])
app.include_router(agendamento.router,    prefix="/api/v1/agendamento",    tags=["Agendamento"])
app.include_router(disponibilidade.router,prefix="/api/v1/disponibilidade",tags=["Disponibilidade"])

@app.get("/")
def root():
    return {"sistema": "RoboSurg", "versao": "0.1.0", "status": "online"}

@app.get("/health")
def health():
    return {"status": "healthy"}
EOF

# ── .devcontainer/devcontainer.json ─────────────────────
cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "RoboSurg Dev",
  "image": "mcr.microsoft.com/devcontainers/python:3.11",
  "forwardPorts": [8000, 8501],
  "portsAttributes": {
    "8000": { "label": "RoboSurg API" },
    "8501": { "label": "Painel Streamlit" }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-python.black-formatter",
        "mtxr.sqliteviewer",
        "humao.rest-client",
        "eamodio.gitlens",
        "PKief.material-icon-theme"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/usr/local/bin/python",
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "ms-python.black-formatter"
      }
    }
  },
  "postCreateCommand": "pip install -r requirements.txt && cp .env.example .env && python app/database/init_db.py",
  "remoteUser": "vscode"
}
EOF

# ── README.md ────────────────────────────────────────────
cat > README.md << 'EOF'
# 🤖 RoboSurg — Sistema de Gestão de Cirurgia Robótica

Plataforma modular de agendamento, validação e publicação de cirurgias robóticas.

## 🚀 Início Rápido (Codespace)

Abra o Codespace — tudo é instalado automaticamente.

```bash
uvicorn app.main:app --reload --host 0.0.0.0
```

Acesse: `https://SEU-CODESPACE-8000.app.github.dev/docs`

## 🧱 Módulos

| # | Módulo | Status |
|---|--------|--------|
| 1 | Agendamento | ✅ Ativo |
| 2 | Disponibilidade de Sala/Leito | ✅ Ativo |
| 3 | Orçamento Automatizado | 🔜 Em breve |
| 4 | Tasks via Telegram | 🔜 Em breve |
| 5 | Validação (Enfermeiro-chefe) | ✅ Ativo |
| 6 | Painel Executivo | ✅ Ativo |
EOF

# ── Finalização ──────────────────────────────────────────
echo ""
echo "✅ Estrutura criada com sucesso!"
echo ""
echo "📦 Instalando dependências..."
pip install -r requirements.txt -q

echo ""
echo "🗄️  Inicializando banco de dados..."
python app/database/init_db.py

echo ""
echo "🎉 Tudo pronto! Rode agora:"
echo ""
echo "   uvicorn app.main:app --reload --host 0.0.0.0"
echo ""
echo "   Depois abra a porta 8000 e acesse /docs"
echo ""
