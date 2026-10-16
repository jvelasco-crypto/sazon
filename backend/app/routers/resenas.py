from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.usuario import Usuario
from app.repositories import resenas as repo
from app.repositories.resenas import ResenaDuplicadaError
from app.schemas.resena import ResenaCreate, ResenaPatch, ResenaResponse, ResumenReceta

router = APIRouter(prefix="/resenas", tags=["resenas"])


@router.get("/", response_model=list[ResenaResponse])
def listar_de_receta(
    receta_id: str = Query(min_length=1, max_length=20),
    db: Session = Depends(get_db),
    usuario_actual: Usuario = Depends(get_current_user),
):
    """Reseñas de una receta, de todos los usuarios: así otra persona ve lo que escribiste."""
    return repo.de_receta(db, receta_id, usuario_actual.id)


@router.get("/mias", response_model=list[ResenaResponse])
def listar_mias(db: Session = Depends(get_db), usuario_actual: Usuario = Depends(get_current_user)):
    return repo.del_usuario(db, usuario_actual.id)


@router.get("/resumen", response_model=ResumenReceta)
def resumen(
    receta_id: str = Query(min_length=1, max_length=20),
    db: Session = Depends(get_db),
    usuario_actual: Usuario = Depends(get_current_user),
):
    return repo.resumen(db, receta_id)


@router.post("/", response_model=ResenaResponse, status_code=201)
def crear(datos: ResenaCreate, db: Session = Depends(get_db), usuario_actual: Usuario = Depends(get_current_user)):
    if not datos.comentario:
        raise HTTPException(status_code=400, detail="El comentario no puede estar vacío")
    try:
        return repo.crear(db, usuario_actual.id, datos.receta_id, datos.receta_nombre, datos.calificacion, datos.comentario)
    except ResenaDuplicadaError as e:
        raise HTTPException(status_code=400, detail=str(e))


def _propia(db: Session, resena_id: int, usuario_actual: Usuario):
    resena = repo.obtener(db, resena_id)
    if resena is None:
        raise HTTPException(status_code=404, detail="La reseña no existe")
    if resena.usuario_id != usuario_actual.id:
        raise HTTPException(status_code=403, detail="Solo puedes modificar tus propias reseñas")
    return resena


@router.patch("/{resena_id}", response_model=ResenaResponse)
def modificar(
    resena_id: int,
    datos: ResenaPatch,
    db: Session = Depends(get_db),
    usuario_actual: Usuario = Depends(get_current_user),
):
    resena = _propia(db, resena_id, usuario_actual)
    cambios = datos.model_dump(exclude_unset=True)
    if cambios.get("comentario") == "":
        raise HTTPException(status_code=400, detail="El comentario no puede estar vacío")
    return repo.actualizar(db, resena, cambios, usuario_actual.id)


@router.delete("/{resena_id}", status_code=204)
def eliminar(resena_id: int, db: Session = Depends(get_db), usuario_actual: Usuario = Depends(get_current_user)):
    repo.eliminar(db, _propia(db, resena_id, usuario_actual))
    return Response(status_code=204)
