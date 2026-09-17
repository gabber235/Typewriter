package com.typewritermc.realm.routes

import com.typewritermc.capability.RealmSearchQuery
import com.typewritermc.capability.RealmSearchSelector
import com.typewritermc.capability.RealmSearchSelectorExpression
import skirout.editor.v1.search.RealmSearchSelectorExpression as WireSelectorExpression

/** Converts the shared wire query without changing selector identity or boolean structure. */
internal fun skirout.editor.v1.search.RealmSearchQuery.toDomain(): RealmSearchQuery =
    RealmSearchQuery(
        normalizedQuery = normalizedQuery,
        terms = terms,
        selectors = selectors.map { RealmSearchSelector(it.selectorId, it.key, it.value) },
        selectorExpression = selectorExpression?.toDomain(),
    )

private fun WireSelectorExpression.toDomain(): RealmSearchSelectorExpression =
    when (this) {
        is WireSelectorExpression.SelectorWrapper -> {
            RealmSearchSelectorExpression.Selector(value.selectorId)
        }

        is WireSelectorExpression.BinaryWrapper -> {
            when (value.operator_) {
                skirout.editor.v1.search.RealmSearchSelectorOperator.AND -> {
                    RealmSearchSelectorExpression.And(value.left.toDomain(), value.right.toDomain())
                }

                skirout.editor.v1.search.RealmSearchSelectorOperator.OR -> {
                    RealmSearchSelectorExpression.Or(value.left.toDomain(), value.right.toDomain())
                }

                else -> {
                    error("Unknown Realm search selector operator")
                }
            }
        }

        is WireSelectorExpression.NotWrapper -> {
            RealmSearchSelectorExpression.Not(value.expression.toDomain())
        }

        else -> {
            error("Unknown Realm search selector expression")
        }
    }
