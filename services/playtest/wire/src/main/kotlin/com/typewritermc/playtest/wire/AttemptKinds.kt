@file:JvmName("AttemptKinds")

package com.typewritermc.playtest.wire

import skirout.harness.v1.wire.AttemptKind

/**
 * The shortest wall clock time between two ticks an attempt of this kind runs at, in milliseconds: a
 * paced attempt's own pace, 0 for one whose Paper grants ticks as fast as the pool steps.
 */
val AttemptKind.paceMillis: Int get() = (this as? AttemptKind.PacedWrapper)?.value ?: 0
