package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.and
import com.typewritermc.expression.literal
import com.typewritermc.expression.not
import com.typewritermc.expression.or

/** Whether exactly one of this and [other] holds. Both sides evaluate. */
@JvmName("booleanXor")
infix fun <M : MissingPolicy> Expr<Boolean, M>.xor(other: Expr<Boolean, M>): Expr<Boolean, M> = this neq other

/** Whether [other] holds whenever this holds; [other] evaluates only when this holds. */
@JvmName("booleanImplies")
infix fun <M : MissingPolicy> Expr<Boolean, M>.implies(other: Expr<Boolean, M>): Expr<Boolean, M> = not() or other

/** Whether every condition holds, evaluating left to right until one does not; true without conditions. */
fun <M : MissingPolicy> allOf(vararg conditions: Expr<Boolean, M>): Expr<Boolean, M> =
    conditions.reduceOrNull { all, next -> all and next } ?: literal(true).lift()

/** Whether any condition holds, evaluating left to right until one does; false without conditions. */
fun <M : MissingPolicy> anyOf(vararg conditions: Expr<Boolean, M>): Expr<Boolean, M> =
    conditions.reduceOrNull { any, next -> any or next } ?: literal(false).lift()
