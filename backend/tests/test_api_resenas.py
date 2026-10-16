"""Reseñas de Sazón: CRUD protegido por JWT y visible para otros usuarios."""
from tests.conftest import registrar_y_loguear

RESENA = {"receta_id": "52772", "receta_nombre": "Teriyaki Chicken Casserole", "calificacion": 5, "comentario": "Muy rica"}


def test_sin_token_responde_401(client):
    assert client.get("/resenas/", params={"receta_id": "52772"}).status_code == 401
    assert client.post("/resenas/", json=RESENA).status_code == 401


def test_crear_listar_editar_y_borrar(client):
    h = registrar_y_loguear(client)
    creada = client.post("/resenas/", json=RESENA, headers=h)
    assert creada.status_code == 201
    datos = creada.json()
    assert datos["autor"] == "a@ejemplo.com" and datos["es_mia"] is True

    lista = client.get("/resenas/", params={"receta_id": "52772"}, headers=h).json()
    assert [r["id"] for r in lista] == [datos["id"]]

    editada = client.patch(f"/resenas/{datos['id']}", json={"calificacion": 3}, headers=h)
    assert editada.status_code == 200 and editada.json()["calificacion"] == 3

    assert client.delete(f"/resenas/{datos['id']}", headers=h).status_code == 204
    assert client.get("/resenas/", params={"receta_id": "52772"}, headers=h).json() == []


def test_otro_usuario_ve_pero_no_modifica(client):
    h1 = registrar_y_loguear(client, "a@ejemplo.com")
    h2 = registrar_y_loguear(client, "b@ejemplo.com")
    rid = client.post("/resenas/", json=RESENA, headers=h1).json()["id"]

    vista = client.get("/resenas/", params={"receta_id": "52772"}, headers=h2).json()
    assert len(vista) == 1 and vista[0]["es_mia"] is False and vista[0]["autor"] == "a@ejemplo.com"

    assert client.patch(f"/resenas/{rid}", json={"comentario": "hack"}, headers=h2).status_code == 403
    assert client.delete(f"/resenas/{rid}", headers=h2).status_code == 403


def test_reglas_de_validacion(client):
    h = registrar_y_loguear(client)
    assert client.post("/resenas/", json={**RESENA, "calificacion": 7}, headers=h).status_code == 422
    assert client.post("/resenas/", json={**RESENA, "comentario": "   "}, headers=h).status_code == 400
    assert client.post("/resenas/", json=RESENA, headers=h).status_code == 201
    duplicada = client.post("/resenas/", json=RESENA, headers=h)
    assert duplicada.status_code == 400 and "Ya escribiste" in duplicada.json()["detail"]
    assert client.patch("/resenas/9999", json={"calificacion": 2}, headers=h).status_code == 404


def test_resumen_promedio(client):
    h1 = registrar_y_loguear(client, "a@ejemplo.com")
    h2 = registrar_y_loguear(client, "b@ejemplo.com")
    client.post("/resenas/", json=RESENA, headers=h1)
    client.post("/resenas/", json={**RESENA, "calificacion": 2}, headers=h2)
    r = client.get("/resenas/resumen", params={"receta_id": "52772"}, headers=h1).json()
    assert r == {"receta_id": "52772", "cantidad": 2, "promedio": 3.5}
