from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database.session import engine
from app.models.models import Base
from app.api.routes import agendamento, disponibilidade, cirurgias

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="🤖 RoboSurg — Sistema de Gestão de Cirurgia Robótica Hosp SOS Cárdio",
    description="Sistema de Gestão de Cirurgia Robótica Hosp SOS Cárdio",
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
