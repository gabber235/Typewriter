package fixture

import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.typedPath
import com.typewritermc.library.Book
import com.typewritermc.library.BookDefinition
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse

// BookFields.title is the intended spelling; generator hooks need an explicit opt in.
val title = typedPath<Book, String>(BookDefinition.id, ValuePath().field("title"), TypeUse.Scalar(ScalarKind.Text)) // error: Generated SDK hook. Use the API generated for your declaration instead.
