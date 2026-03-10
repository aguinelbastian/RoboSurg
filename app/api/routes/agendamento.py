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
