package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector

internal val ORIGIN = EditField<Double?>("origin", null)
internal val HALF_X = EditField<Double?>("halfX", null)
internal val HALF_Y = EditField<Double?>("halfY", null)
internal val HALF_Z = EditField<Double?>("halfZ", null)
internal val YAW = EditField<Float?>("yaw", null)
internal val PITCH = EditField<Float?>("pitch", null)
internal val X = EditField<Double?>("x", null)
internal val Y = EditField<Double?>("y", null)
internal val SHIFT = EditField<Double?>("shift", null)
internal val POINTS = EditField<List<Vector>?>("poly.points", null)

internal val PRIMARY = EditField<String?>("marks.primary", null)
internal val SECONDARY = EditField<String?>("marks.secondary", null)
internal val MARKED = EditField<String?>("poly.marked", null)
internal val POLY_POINTS = EditField<String?>("poly.points", null)
internal val WORK_ORIGIN = EditField<String?>("work.origin", null)
internal val WORK_YAW = EditField<Float?>("work.yaw", null)
internal val WORK_PITCH = EditField<Float?>("work.pitch", null)
internal val SIZE_HALF_X = EditField<Double?>("size.halfX", null)
internal val SIZE_HALF_Z = EditField<Double?>("size.halfZ", null)

internal fun state(vararg values: EditValue<*>): EditorState = EditorState.of(*values)
