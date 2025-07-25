package com.typewritermc.example.entries.static

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.AssetManager
import com.typewritermc.engine.paper.entry.entries.ArtifactEntry
import org.koin.java.KoinJavaComponent

//<code-block:artifact_entry>
@Entry("example_artifact", "An example artifact entry.", Colors.BLUE, "material-symbols:home-storage-rounded")
class ExampleArtifactEntry(
    override val id: String = "",
    override val name: String = "",
    override val artifactId: String = "",
) : ArtifactEntry
//</code-block:artifact_entry>

//<code-block:artifact_access>
suspend fun accessArtifactData(ref: Ref<out ArtifactEntry>) {
    val assetManager = KoinJavaComponent.get<AssetManager>(AssetManager::class.java)
    val entry = ref.get() ?: return
    val content: String? = assetManager.fetchStringAsset(entry)
    // Do something with the content
}
//</code-block:artifact_access>