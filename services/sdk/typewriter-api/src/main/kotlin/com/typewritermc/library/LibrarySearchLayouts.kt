package com.typewritermc.library

import com.typewritermc.authoring.text
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.and
import com.typewritermc.expression.eq
import com.typewritermc.expression.gt
import com.typewritermc.expression.length
import com.typewritermc.expression.literal
import com.typewritermc.expression.not
import com.typewritermc.expression.or
import com.typewritermc.expression.orElse
import com.typewritermc.expression.orIfBlank
import com.typewritermc.expression.target
import com.typewritermc.expression.trim
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationInsets
import com.typewritermc.presentation.ResourceExpr
import com.typewritermc.presentation.resource
import com.typewritermc.types.ResourceId

internal fun Expr<String, Handled>.hasText(): Expr<Boolean, Handled> = trim().length gt 0

internal fun Layout.pageLocation(
    page: ResourceExpr<Page>,
    active: Expr<ResourceId, MayBeMissing>,
    includePage: Expr<Boolean, Handled>,
    part: Layout.(Expr<String, Handled>) -> Unit,
    separator: Layout.() -> Unit,
) {
    val book = page.fields.book.resource
    val chapter =
        page.fields.chapter.text
            .orElse(literal(""))
    val activePage = resource<Page>(active)
    val sameBook =
        (book.id eq active).orElse(literal(false)) or
            (book.id eq activePage.fields.book.target).orElse(literal(false))
    val sameChapter =
        (
            chapter eq activePage.fields.chapter.text
        ).orElse(literal(false))
    val showBook = sameBook.not()
    val showChapter = (sameBook.not() or sameChapter.not()) and chapter.hasText()

    fun Layout.prefixed(
        label: Expr<String, Handled>,
        previous: Expr<Boolean, Handled>,
    ) {
        showIf(previous, whenFalse = { part(label) }) {
            padding(PresentationInsets(4.0, 0.0, 0.0, 0.0)) {
                row(spacing = 4.0) {
                    separator()
                    part(label)
                }
            }
        }
    }

    clippedRow(spacing = 0.0) {
        showIf(showBook) {
            showIf(book.exists, whenFalse = {
                prefixed(literal("Unavailable book"), literal(false))
            }) {
                prefixed(book.fields.title.orIfBlank("Unnamed Book"), literal(false))
            }
        }
        showIf(showChapter) { prefixed(chapter, showBook) }
        showIf(includePage) {
            prefixed(page.fields.name.orIfBlank("Unnamed page"), showBook or showChapter)
        }
    }
}
