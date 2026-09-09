// Studs, which are the same plastic and take the same wind - and do NOT
// receive shadows.
//
// A stud stands 6cm proud of a large flat brick top. That brick casts into the
// shadow map, and at the stud's texel the recorded depth IS the brick top, so
// the stud's own top surface is classified as being behind a caster and goes
// dark. Every stud in the game rendered as a dark disc lit only by ambient -
// which is why they turned magenta when the sky was turned magenta to test it.
//
// The stud loses nothing by not receiving shadows: it is a 6cm bump, and no
// shadow that matters ever falls on it alone. It still casts none either.
shader_type spatial;
render_mode world_vertex_coords, shadows_disabled;

#include "res://shaders/brick_common.gdshaderinc"
