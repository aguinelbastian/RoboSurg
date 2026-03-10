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
