package fixture

import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.typedPath
import com.typewritermc.library.Book
import com.typewritermc.library.BookDefinition
import skirout.editor.v1.type_catalog.ScalarKind
import com.typewritermc.types.use

// BookFields.title is the intended spelling; generator hooks need an explicit opt in.
val title = typedPath<Book, String>(BookDefinition.id, ValuePath().field("title"), ScalarKind.TEXT.use) // error: Generated SDK hook. Use the API generated for your declaration instead.
