package com.typewritermc.library

import com.typewritermc.elements.ElementOperations
import com.typewritermc.elements.ElementOperationsScope
import com.typewritermc.operations.delete
import com.typewritermc.operations.duplicate
import com.typewritermc.operations.edit
import com.typewritermc.operations.linkWith
import com.typewritermc.operations.linkWithDuplicate
import com.typewritermc.operations.moveToBook
import com.typewritermc.operations.moveToPage
import com.typewritermc.operations.open

object BookResourceOperations : BookOperations {
    override fun BookOperationsScope.operations() {
        primary(open())
        edit()
        duplicate()
        delete()
    }
}

object PageResourceOperations : PageOperations {
    override fun PageOperationsScope.operations() {
        primary(edit())
        moveToBook()
        duplicate()
        delete()
    }
}

object ElementResourceOperations : ElementOperations {
    override fun ElementOperationsScope.operations() {
        primary(edit())
        linkWith()
        moveToPage()
        duplicate()
        linkWithDuplicate()
        delete()
    }
}

object TagResourceOperations : TagOperations {
    override fun TagOperationsScope.operations() {
        primary(edit())
        duplicate()
        linkWithDuplicate()
        delete()
    }
}
