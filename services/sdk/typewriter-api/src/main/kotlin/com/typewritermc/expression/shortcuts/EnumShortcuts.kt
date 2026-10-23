package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.enumEntries
import com.typewritermc.expression.get
import com.typewritermc.expression.indexOf
import com.typewritermc.expression.let
import com.typewritermc.expression.plus
import com.typewritermc.expression.size
import com.typewritermc.expression.toText
import skirout.editor.v1.type_catalog.TypeUse

/*
 * Enumeration shortcuts. The cases come from enum.cases of the catalog enumeration [TypeUse] the caller names, in
 * declaration order.
 */

/** The name of this case. */
@get:JvmName("enumName")
val <E : Enum<E>, M : MissingPolicy> Expr<E, M>.name: Expr<String, M> get() = toText()

/** The position of this case among the cases of the enumeration [type], from 0. */
fun <E, M : MissingPolicy> Expr<E, M>.ordinal(type: TypeUse): Expr<Int, M> = enumEntries<E>(type).lift<List<E>, M>().indexOf(this)

/** The case after this one in the enumeration [type]; the last case is followed by the first. */
fun <E, M : MissingPolicy> Expr<E, M>.next(type: TypeUse): Expr<E, MayBeMissing> = shifted(type, 1)

/** The case before this one in the enumeration [type]; the first case is preceded by the last. */
fun <E, M : MissingPolicy> Expr<E, M>.previous(type: TypeUse): Expr<E, MayBeMissing> = shifted(type, -1)

private fun <E, M : MissingPolicy> Expr<E, M>.shifted(
    type: TypeUse,
    step: Int,
): Expr<E, MayBeMissing> = let(enumEntries<E>(type)) { cases -> cases[(cases.indexOf(this) + step).mod(cases.size)] }
