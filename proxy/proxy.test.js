// Pruebas del proxy (sin red ni clave): node --test proxy/
const { test } = require('node:test');
const assert = require('node:assert');
const { limpiarEntrada, responderConReglas, validarSalida } = require('./proxy');

const CANDIDATAS = [
  { id: '1', nombre: 'Chicken Curry' },
  { id: '2', nombre: 'Beef Stew' },
];

test('rechaza una consulta vacía o demasiado larga', () => {
  assert.throws(() => limpiarEntrada({ consulta: '  ' }), /Falta/);
  assert.throws(() => limpiarEntrada({ consulta: 'x'.repeat(501) }), /demasiado larga/);
});

test('recorta las listas y descarta elementos con forma inválida', () => {
  const e = limpiarEntrada({ consulta: 'hola', favoritos: ['a', 3], candidatas: [{ id: '1', nombre: 'A' }, { id: 2 }] });
  assert.deepStrictEqual(e.favoritos, ['a']);
  assert.deepStrictEqual(e.candidatas, [{ id: '1', nombre: 'A' }]);
});

test('modo reglas busca el ingrediente en los nombres', () => {
  const r = responderConReglas({ consulta: '¿Qué cocino con chicken?', favoritos: [], candidatas: CANDIDATAS });
  assert.strictEqual(r.receta_id, '1');
});

test('la IA no puede inventar una receta fuera de las candidatas', () => {
  const r = validarSalida({ respuesta: 'Prueba esta', receta_id: '999' }, CANDIDATAS);
  assert.deepStrictEqual(r, { respuesta: 'Prueba esta' });
  assert.strictEqual(validarSalida({ respuesta: 'Ok', receta_id: '2' }, CANDIDATAS).receta_id, '2');
});
