// Nombre visible para botones de gamepad conocidos.
function scr_controller_button_name(_button) {
    switch (_button) {
        case gp_face1:     return "Face 1 / A / Cruz";
        case gp_face2:     return "Face 2 / B / Circulo";
        case gp_face3:     return "Face 3 / X / Cuadrado";
        case gp_face4:     return "Face 4 / Y / Triangulo";
        case gp_shoulderl: return "LB / L1";
        case gp_shoulderr: return "RB / R1";
        case gp_start:     return "Start / Options";
        case gp_select:    return "Select / Share";
        case gp_padu:      return "D-pad Arriba";
        case gp_padd:      return "D-pad Abajo";
        case gp_padl:      return "D-pad Izquierda";
        case gp_padr:      return "D-pad Derecha";
    }
    return "Boton " + string(_button);
}
