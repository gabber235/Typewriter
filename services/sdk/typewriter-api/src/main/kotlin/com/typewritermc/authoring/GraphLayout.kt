package com.typewritermc.authoring

import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract

/**
 * A resource whose owned members are laid out on a graph.
 *
 * Moving or duplicating members into a graph layout gives each moved member a collision free graph placement in its
 * published placement field. Destinations that are not graph layouts leave member placements untouched.
 */
@TypewriterRecordContract
interface GraphLayout : Resource
