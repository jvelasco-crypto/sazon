from datetime import datetime
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field, StringConstraints, model_validator

RecetaId = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=20)]
NombreReceta = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=200)]
Comentario = Annotated[str, StringConstraints(strip_whitespace=True, max_length=500)]
Calificacion = Annotated[int, Field(ge=1, le=5)]


class ResenaCreate(BaseModel):
    # El autor siempre sale del token (JWT): un usuario_id en el cuerpo se ignora.
    receta_id: RecetaId
    receta_nombre: NombreReceta
    calificacion: Calificacion
    comentario: Comentario


class ResenaPatch(BaseModel):
    """PATCH: solo calificación y comentario; al menos uno y ninguno en null."""

    model_config = ConfigDict(extra="forbid")

    calificacion: Calificacion | None = None
    comentario: Comentario | None = None

    @model_validator(mode="after")
    def _al_menos_un_campo(self):
        if not self.model_fields_set:
            raise ValueError("Debe indicar al menos un campo a modificar")
        if any(getattr(self, c) is None for c in self.model_fields_set):
            raise ValueError("Los campos no pueden ser null")
        return self


class ResenaResponse(BaseModel):
    id: int
    receta_id: str
    receta_nombre: str
    calificacion: int
    comentario: str
    creada: datetime
    autor: str
    es_mia: bool


class ResumenReceta(BaseModel):
    receta_id: str
    cantidad: int
    promedio: float | None
