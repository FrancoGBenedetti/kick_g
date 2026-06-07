// ══════════════════════════════════════════════════════════
// OBJ_DAMAGE_SOURCE_PARENT — Destroy
// Libera la ds_list del anti-multi-hit automáticamente.
//
// GML no tiene GC para estructuras de datos (ds_*).
// Al centralizar la limpieza aquí, ningún hijo necesita
// llamar ds_list_destroy(hit_list) manualmente — se dispara
// para cualquier instance_destroy() en cualquier hijo.
// ══════════════════════════════════════════════════════════
if (ds_exists(hit_list, ds_type_list)) {
    ds_list_destroy(hit_list);
}
