// Recursos del jugador: API única para vida, maná y flechas.

function clamp_player_resources(_player) {
    if (!instance_exists(_player)) return;
    if (!variable_instance_exists(_player, "health")
    ||  !variable_instance_exists(_player, "max_health")
    ||  !variable_instance_exists(_player, "mana")
    ||  !variable_instance_exists(_player, "max_mana")
    ||  !variable_instance_exists(_player, "arrows")
    ||  !variable_instance_exists(_player, "max_arrows")) return;

    _player.health = clamp(_player.health, 0, _player.max_health);
    _player.mana   = clamp(_player.mana, 0, _player.max_mana);
    _player.arrows = clamp(_player.arrows, 0, _player.max_arrows);
    _player.hp     = _player.health;
    _player.max_hp = _player.max_health;
}

function player_add_mana(_player, _amount) {
    if (!instance_exists(_player) || _amount <= 0) return;
    var _before = _player.mana;
    _player.mana = clamp(_player.mana + _amount, 0, _player.max_mana);
    var _gained = _player.mana - _before;
    if (_gained > 0) {
        _player.hud_mana_gain_amount += _gained;
        _player.hud_mana_gain_timer = 45;
    }
}

function player_add_arrows(_player, _amount) {
    if (!instance_exists(_player) || _amount == 0) return;
    _player.arrows = clamp(_player.arrows + _amount, 0, _player.max_arrows);
}

function player_take_damage(_player, _amount, _source = noone) {
    if (!instance_exists(_player) || _amount <= 0) return;
    _player.take_damage(_amount, _source);
}

function player_can_spend_mana(_player, _amount) {
    return instance_exists(_player) && _amount >= 0 && _player.mana >= _amount;
}

function player_spend_mana(_player, _amount) {
    if (!player_can_spend_mana(_player, _amount)) return false;
    _player.mana -= _amount;
    return true;
}
